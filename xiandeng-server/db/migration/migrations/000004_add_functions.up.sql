create unique index idx_qianliaocoupon_studentid on qianliaocoupon (studentid);

CREATE OR REPLACE FUNCTION public.pay_success(order_id bigint)
 RETURNS varchar
 LANGUAGE plpgsql
AS $function$
DECLARE 
    var_orderproduct record;
    var_product record;
    var_student_id UUID;
    var_acc_id UUID;
    var_acc_type varchar := 'STUDENT';
    var_discount decimal(8,2);
    var_entitlement record;
    tmp_purchase_price decimal(8,2);
 tmp_downstream_purchase_price decimal(8,2);
    tmp_sell_price decimal(8,2);
    tmp_upstreamaccount UUID;
    tmp_commision decimal(8,2);
    tmp_balanceafter decimal(8,2);
    var_sumprice decimal(8,2) := 0;
    var_entitlement_name varchar;
begin
 raise notice '====begin====';
 select studentid into var_student_id from orders where id=order_id;
 for var_orderproduct in (select id,productid,couponcode from orderproduct where orderid=order_id)
 loop 
  raise notice 'productid: %',var_orderproduct.productid;
  select * into var_product from product where id=var_orderproduct.productid;
  var_acc_id := var_student_id;
  var_discount := 0;
  if var_orderproduct.couponcode is not null then --有优惠券的时候，设置优惠金额，否则优惠为0
   select discountamount into var_discount from ordercoupon where code=var_orderproduct.couponcode;
  end if; 
  var_sumprice := var_sumprice + var_product.finalprice - var_discount;
  raise notice 'sumprice: % | discount: %',var_sumprice,var_discount;
  for var_entitlement in (select entitlementtypeid,validdays from productentitlementtype where productid=var_orderproduct.productid)--激活学生授权
  loop 
   insert into studententitlement(id,studentid,entitlementtypeid,lastorderid,expiresat) values(uuid_generate_v4(),var_student_id,var_entitlement.entitlementtypeid,order_id,CURRENT_DATE+var_entitlement.validdays)
   on conflict(studentid,entitlementtypeid) do update set lastorderid=order_id,expiresat = studententitlement.expiresat + var_entitlement.validdays;
   raise notice 'ent:%,days:%',var_entitlement.entitlementtypeid,var_entitlement.validdays;
   select name into var_entitlement_name from entitlementtype where id=var_entitlement.entitlementtypeid;
   if var_entitlement_name = '在线视频课' and not exists (select from qianliaocoupon where studentid=var_student_id) then -- 如果没有分配千聊优惠券，则从空余优惠券里选一个分配
    update qianliaocoupon set studentid=var_student_id where couponcode=(select couponcode from qianliaocoupon where studentid is null limit 1);
   end if;
  end loop;
  while (var_acc_type != 'HEAD_QUARTER' and var_product.finalprice > 0)
  loop --执行分账
   select upstreamaccount into tmp_upstreamaccount from account where id=var_acc_id;
   -- 获取upstreamaccount进货价
   select price into tmp_purchase_price from productpriceoverwrite where rootproduct=var_product.id and downstreamaccountid=tmp_upstreamaccount;
   if tmp_purchase_price is null then
    select case a.type  when 'LV2_AGENT' then p.lv2agentprice
         when 'LV1_AGENT' then p.lv1agentprice
         when 'HQ_AGENT' then p.hqagentprice
         when 'HEAD_QUARTER' then 0
         else 0 end as purchaseprice --这个else没啥用
    into tmp_purchase_price
    from account a,product p
    where a.id=tmp_upstreamaccount and p.id=var_product.id;
   end if;
   if var_acc_id = var_student_id then --直接上级代理
    tmp_commision := var_product.finalprice - var_discount - tmp_purchase_price;
    raise notice 'account:% | finalprice:% | purchaseprice:% | commision:%',tmp_upstreamaccount,var_product.finalprice,tmp_purchase_price,tmp_commision;
   else
    tmp_commision := tmp_downstream_purchase_price - tmp_purchase_price;
    raise notice 'account:% | downstreamprice:% | purchaseprice:% | commision:%',tmp_upstreamaccount,tmp_downstream_purchase_price,tmp_purchase_price,tmp_commision;
   end if;
   -- 操作分账
   update account set balance = balance + tmp_commision where id=tmp_upstreamaccount returning balance into tmp_balanceafter;
   -- 操作余额变动
   insert into balanceactivity(id,source,orderid,orderproductid,accountid,amount,balanceafter) values(uuid_generate_v4(),'分成',order_id,var_orderproduct.id,tmp_upstreamaccount,tmp_commision,tmp_balanceafter);
  
   tmp_downstream_purchase_price := tmp_purchase_price;--当前的进货价，是下次循环中的零售价
   var_acc_id := tmp_upstreamaccount;
   select type into var_acc_type from account where id=tmp_upstreamaccount;
  end loop;
 end loop;
 -- 标记订单为成功
 update orders set status='success',payat=now()::timestamp,price=var_sumprice where id=order_id;
 raise notice '====end====';
RETURN 'success';
END; $function$
;

CREATE OR REPLACE FUNCTION public.get_order_price(order_id bigint)
 RETURNS decimal(8,2)
 LANGUAGE plpgsql
AS $$
DECLARE 
    var_orderproduct record;
    var_product_finalprice  decimal(8,2);
    var_student_id UUID;
    var_discount decimal(8,2);
    var_sumprice decimal(8,2) := 0;
begin
 raise notice '====begin====';
 select studentid into var_student_id from orders where id=order_id;
 for var_orderproduct in (select id,productid,couponcode from orderproduct where orderid=order_id)
 loop 
  raise notice 'productid: %',var_orderproduct.productid;
  select finalprice into var_product_finalprice from product where id=var_orderproduct.productid;
  var_discount := 0;
  if var_orderproduct.couponcode is not null then --有优惠券的时候，设置优惠金额，否则优惠为0
   select discountamount into var_discount from ordercoupon where code=var_orderproduct.couponcode;
  end if; 
  var_sumprice := var_sumprice + var_product_finalprice - var_discount;
  raise notice 'sumprice: % | discount: %',var_sumprice,var_discount;

 end loop;
 raise notice '====end====';
RETURN var_sumprice;
END; $$
;