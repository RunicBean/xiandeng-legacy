CREATE TABLE public.orderofflinepayproof (
 orderid int8 NOT NULL,
 imageurl text NOT NULL,
 id uuid DEFAULT uuid_generate_v4() NOT NULL,
 createdat timestamp DEFAULT CURRENT_TIMESTAMP NULL,
 CONSTRAINT orderofflinepayproof_pk PRIMARY KEY (id)
);
CREATE UNIQUE INDEX orderofflinepayproof_orderid_idx ON public.orderofflinepayproof USING btree (orderid, imageurl);


-- public.orderofflinepayproof foreign keys

ALTER TABLE public.orderofflinepayproof ADD CONSTRAINT orderofflinepayproof_orders_fk FOREIGN KEY (orderid) REFERENCES public.orders(id);

ALTER TABLE Guardian DROP CONSTRAINT guardian_studentid_fkey;
ALTER TABLE Guardian ADD CONSTRAINT guardian_studentid_fkey FOREIGN KEY (StudentId) REFERENCES Account (Id);

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
   on conflict(studentid,entitlementtypeid) do update set lastorderid=order_id,expiresat = studententitlement.expiresat + var_entitlement.validdays;
   raise notice 'ent:%,days:%',var_entitlement.entitlementtypeid,var_entitlement.validdays;
   select name into var_entitlement_name from entitlementtype where id=var_entitlement.entitlementtypeid;
   if var_entitlement_name = '在线视频课' and not exists (select from qianliaocoupon where studentid=var_student_id) then -- 如果没有分配千聊优惠券，则从空余优惠券里选一个分配
    update qianliaocoupon set studentid=var_student_id where couponcode=(select couponcode from qianliaocoupon where studentid is null limit 1);
   end if;
  end loop;
  while (var_acc_type != 'HEAD_QUARTER' and var_orderproduct.actualprice > 0)
  loop --执行分账
   select upstreamaccount into tmp_upstreamaccount from account where id=var_acc_id;
   -- 获取upstreamaccount进货价
   select * into tmp_purchase_price from get_purchase_price(var_product.id,tmp_upstreamaccount);
   if var_acc_id = var_student_id then --直接上级代理
    if var_payment_method='wechatpay' then
     var_fee := var_orderproduct.actualprice*0.006;--线上付款时，手续费由直接上级代理承担
    end if;
    tmp_commision := var_orderproduct.actualprice - tmp_purchase_price - var_fee;
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
   tmp_downstream_purchase_price := tmp_purchase_price;--当前的进货价，是下次循环中的零售价
   var_acc_id := tmp_upstreamaccount;
   select type into var_acc_type from account where id=tmp_upstreamaccount;
  end loop;
 end loop;
 -- 标记订单为成功
 update orders set status='success',payat=now()::timestamp where id=order_id;
 raise notice '====end====';
RETURN 'success';
END; $function$
;

CREATE OR REPLACE FUNCTION public.generate_simple_order(product_id uuid, student_id uuid, coupon_code bigint)
 RETURNS order_price_error
 LANGUAGE plpgsql
AS $function$
DECLARE 
    var_product record;
    var_discount decimal(8,2) := 0;
    var_sumprice decimal(8,2) := 0;
    var_coupon record;
    var_direct_agent_id UUID;
    var_order_id bigint := -1;
begin
 raise notice '====begin====';
 select upstreamaccount into var_direct_agent_id from account where id=student_id;
 if coupon_code is not null then -- 对优惠券进行检查
  if not exists (select from ordercoupon where code=coupon_code) then 
   return (var_order_id,var_sumprice,cast('该优惠券码不存在：'||coupon_code as varchar));
  end if;
  select * into var_coupon from ordercoupon where code=coupon_code; -- 读取优惠券详情
  var_discount := var_coupon.discountamount; -- 设置优惠金额
  if var_coupon.effectstartdate is not null then
   if CURRENT_DATE < var_coupon.effectstartdate then
    return (var_order_id,var_sumprice,cast('优惠券不在有效期(起始日期:' || var_coupon.effectstartdate || ')。' as varchar));
   end if;
  end if;
  if var_coupon.effectduedate is not null then
   if CURRENT_DATE > var_coupon.effectduedate then
    return (var_order_id,var_sumprice,cast('优惠券不在有效期(截止日期:' || var_coupon.effectduedate || ')。' as varchar));
   end if;
  end if;
  if var_direct_agent_id!=var_coupon.agentid then
   return (var_order_id,var_sumprice,cast('优惠券不是您的直属代理签发的。' as varchar));
  end if;
  if var_coupon.studentid is not null then
   if var_coupon.studentid!=student_id then
    return (var_order_id,var_sumprice,cast('您不是优惠券的有效学员。' as varchar));
   end if;
  end if;
  if var_coupon.productid is not null then
   if var_coupon.productid != product_id then
    return (var_order_id,var_sumprice,cast('该优惠券对您本次购买的商品无效。' as varchar));
   end if;
  end if;
  if (select finalprice-get_purchase_price(id,var_direct_agent_id)-var_coupon.discountamount-(finalprice-var_coupon.discountamount)*0.006 from product where id=product_id) < 0 then--优惠金额过高：超过直接上级代理的利润。(考虑手续费)
   return (var_order_id,var_sumprice,cast('该优惠金额无效，请与销售人员核实。' as varchar));
  end if;
  if var_coupon.maxcount is not null then
   if (select count(*) from orderproduct where couponcode=coupon_code) >= var_coupon.maxcount then
    return (var_order_id,var_sumprice,cast('优惠券超过最大使用次数（' || var_coupon.maxcount || '次)。' as varchar));
   end if;
  end if;
 end if; 
 select finalprice,purchaselimit,productname into var_product from product where id=product_id; -- 读取商品详情 
 if var_product.purchaselimit is not null then
  raise notice 'purchase limit: %',var_product.purchaselimit;
  if (select count(*) from orderproduct op,orders o where op.orderid=o.id and o.status='success' and op.productid=product_id and o.studentid=student_id) >= var_product.purchaselimit then
   return (var_order_id,var_sumprice,cast('超过商品最大购买次数:' || var_product.productname as varchar));
  end if;
 end if;

 raise notice '====create order====';
 var_sumprice := var_product.finalprice - var_discount;--设置实际付款金额
 select ((extract(year from current_date)*100+extract(month from current_date))*100+extract(day from current_date))*100000000+floor(random()*100000000) into var_order_id;--生成订单号 
 if exists(select from orders where id=var_order_id) then 
  return (cast(-1 as bigint),var_sumprice,cast('订单号重复:' || cast(var_order_id as varchar) as varchar));
 end if;
 insert into orders(id,status,studentid,paymentmethod,price) values(var_order_id,'created',student_id,'wechatpay',var_sumprice);
 insert into orderproduct(id,orderid,productid,originalprice,couponcode,actualprice) values(var_order_id*10,var_order_id,product_id,var_product.finalprice,coupon_code,var_sumprice);
 raise notice '====end====';
RETURN (var_order_id,var_sumprice,cast('' as varchar));
END; $function$
;

CREATE OR REPLACE FUNCTION public.generate_new_coupon(user_id uuid, discount_amount numeric, max_count integer, product_id uuid, student_id uuid, start_date date, due_date date)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE 
    var_coupon_code int8 := FLOOR(random() * (99999999 - 10000000 + 1) + 10000000);
    var_agent record;
    var_allowed_max_discount decimal(8,2);
begin
 raise notice '====begin====';
 raise notice 'code:%',var_coupon_code;
 if user_id is null then
  return '创建失败。用户名不可以为空值。';
 end if;
 select id,type into var_agent from account where id=(select accountid from users where id=user_id);
 if var_agent.type = 'STUDENT' then
  return '创建失败。账户类型不可以为“学员”。';
 end if;
 if discount_amount is null then
  return '创建失败。优惠金额不可以为空值。';
 end if;
 if product_id is not null then
  select finalprice-get_purchase_price(product_id,var_agent.id)/0.994 into var_allowed_max_discount from product where id=product_id;--考虑手续费
  raise notice 'max_discount:% | purchase_price:%',var_allowed_max_discount,get_purchase_price(product_id,var_agent.id);
  if discount_amount<0 or discount_amount > var_allowed_max_discount then  
   return cast('创建失败。优惠金额必须为正，且小于￥' || var_allowed_max_discount || '。' as varchar);
  end if;
 end if;
 if start_date is not null and due_date is not null then 
  if start_date > due_date then
   return '创建失败。优惠券起始日期晚于截止日期。';
  end if;
 end if;
 if exists (select from ordercoupon where code=var_coupon_code) then 
  return '创建失败。优惠券码重复，请重新生成。';
 end if;
 if exists (select from ordercoupon where discountamount=discount_amount and agentid=var_agent.id and productid IS NOT DISTINCT FROM product_id and studentid IS NOT DISTINCT FROM student_id and effectstartdate IS NOT DISTINCT FROM start_date and effectduedate IS NOT DISTINCT FROM due_date) then
  return '创建失败。已存在面向相同商品、学员、金额、有效期的优惠券。';
 end if;
 insert into ordercoupon(code,agentid,issuinguser,discountamount,maxcount,productid,studentid,effectstartdate,effectduedate)
  values(var_coupon_code,var_agent.id,user_id,discount_amount,max_count,product_id,student_id,start_date,due_date);
 raise notice '====end====';
 RETURN cast('创建成功。券码：' || var_coupon_code  as varchar);
END; $function$
;