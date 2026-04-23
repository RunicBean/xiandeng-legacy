-- DROP FUNCTION public.pay_success(int8);

CREATE OR REPLACE FUNCTION public.pay_success(order_id bigint)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE 
    var_orderproduct record;
    var_product record;
    var_student_id UUID;
    var_acc_id UUID;
    var_acc_type varchar := 'STUDENT';
    var_entitlement record;
    tmp_purchase_price decimal(8,2);
 	tmp_downstream_purchase_price decimal(8,2);
    tmp_upstreamaccount UUID;
    tmp_commision decimal(8,2);
    tmp_balanceafter decimal(8,2);
    var_entitlement_name varchar;
   	var_payment_method varchar;
   	var_fee decimal(8,2);
begin
 raise notice '====begin====';
 if exists (select from balanceactivity where orderid=order_id) then
  return 'failed. The balance activity already exists for this order';
 end if;
 if (select status from orders where id=order_id) = 'success' then
  return 'failed. The order status had completed previously.';
 end if;
 select studentid,paymentmethod into var_student_id,var_payment_method from orders where id=order_id;
 for var_orderproduct in (select id,productid,couponcode,actualprice from orderproduct where orderid=order_id)
 loop 
  raise notice 'productid: %',var_orderproduct.productid;
  --初始化各个变量
  select * into var_product from product where id=var_orderproduct.productid;
  var_acc_id := var_student_id;
  var_acc_type := 'STUDENT';
  var_fee := 0;
  for var_entitlement in (select entitlementtypeid,validdays from productentitlementtype where productid=var_orderproduct.productid)--激活学生授权
  loop 
   insert into studententitlement(id,studentid,entitlementtypeid,lastorderid,expiresat) values(uuid_generate_v4(),var_student_id,var_entitlement.entitlementtypeid,order_id,CURRENT_DATE+var_entitlement.validdays)
   on conflict(studentid,entitlementtypeid) do update set lastorderid=order_id,expiresat = case WHEN studententitlement.expiresat < CURRENT_DATE THEN CURRENT_DATE + var_entitlement.validdays ELSE studententitlement.expiresat + var_entitlement.validdays end,updatedat=(now() AT TIME ZONE 'Asia/Shanghai');
   raise notice 'ent:%,days:%',var_entitlement.entitlementtypeid,var_entitlement.validdays;
   select name into var_entitlement_name from entitlementtype where id=var_entitlement.entitlementtypeid;
   if var_entitlement_name = '在线视频课' and not exists (select from qianliaocoupon where studentid=var_student_id) then -- 如果没有分配千聊优惠券，则从空余优惠券里选一个分配
    update qianliaocoupon set studentid=var_student_id,updatedat=(now() AT TIME ZONE 'Asia/Shanghai') where couponcode=(select couponcode from qianliaocoupon where studentid is null limit 1);
   end if;
  end loop;
  while (var_acc_type != 'HEAD_QUARTER' and var_orderproduct.actualprice > 0)
  loop --执行分账
   select upstreamaccount into tmp_upstreamaccount from account where id=var_acc_id;
   -- 获取upstreamaccount进货价
   select * into tmp_purchase_price from get_purchase_price(var_product.id,tmp_upstreamaccount);
   if var_acc_id = var_student_id then --直接上级代理 
    tmp_commision := var_orderproduct.actualprice - tmp_purchase_price;
    raise notice 'account:% | finalprice:% | actualprice:% | purchaseprice:% | commision:%',tmp_upstreamaccount,var_product.finalprice,var_orderproduct.actualprice,tmp_purchase_price,tmp_commision;
   else
    tmp_commision := tmp_downstream_purchase_price - tmp_purchase_price;
    raise notice 'account:% | downstreamprice:% | purchaseprice:% | commision:%',tmp_upstreamaccount,tmp_downstream_purchase_price,tmp_purchase_price,tmp_commision;
   end if;
   if tmp_commision != 0 then -- 0元的时候不分账，不写余额变动
    -- 操作分账
    update account set balance = balance + tmp_commision where id=tmp_upstreamaccount returning balance into tmp_balanceafter;
    -- 操作余额变动
    insert into balanceactivity(id,source,orderid,orderproductid,accountid,amount,balanceafter) values(uuid_generate_v4(),'分成',order_id,var_orderproduct.id,tmp_upstreamaccount,tmp_commision,tmp_balanceafter);
   end if;
   if var_payment_method='wechatpay' and var_acc_id = var_student_id then--线上付款时，手续费由直接上级代理承担
    var_fee := var_orderproduct.actualprice*0.006;
    -- 扣除手续费
    update account set balance = balance - var_fee where id=tmp_upstreamaccount returning balance into tmp_balanceafter;
    -- 操作余额变动,记录时间为原时间+1秒
    insert into balanceactivity(id,source,orderid,orderproductid,accountid,amount,balanceafter,createdat,updatedat) values(uuid_generate_v4(),'微信支付手续费0.6%',order_id,var_orderproduct.id,tmp_upstreamaccount,-var_fee,tmp_balanceafter,NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 second',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 second');
   end if;
   tmp_downstream_purchase_price := tmp_purchase_price;--当前的进货价，是下次循环中的零售价
   var_acc_id := tmp_upstreamaccount;
   select type into var_acc_type from account where id=tmp_upstreamaccount;
  end loop;
 end loop;
 -- 标记订单为成功
 update orders set status='success',payat=(now() AT TIME ZONE 'Asia/Shanghai'),updatedat=(now() AT TIME ZONE 'Asia/Shanghai') where id=order_id;
 raise notice '====end====';
RETURN 'success';
END; $function$
;