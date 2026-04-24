-- 商品的purchaselimit如果为空，则没有购买限制（原先是purchaselimit=0） 
ALTER TABLE public.product ALTER COLUMN purchaselimit DROP DEFAULT;

-- QianliaoCoupon PK
ALTER TABLE QianliaoCoupon ADD COLUMN Id serial PRIMARY KEY;

create type order_price_error as (orderid bigint, actualprice decimal(8,2), errmsg varchar);

CREATE OR REPLACE FUNCTION public.generate_simple_order(product_id UUID,student_id UUID, coupon_code bigint)
 RETURNS order_price_error
 LANGUAGE plpgsql
AS $$
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
  if (select finalprice-get_purchase_price(id,var_direct_agent_id)-var_coupon.discountamount from product where id=product_id) < 0 then--优惠金额过高：超过直接上级代理的利润。
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
END; $$
;

-- 通过下面的function去拿agent的进货价 （在其他的function中需要引用这个）
CREATE OR REPLACE FUNCTION public.get_purchase_price(product_id UUID,account_id UUID)
 RETURNS decimal(8,2)
 LANGUAGE plpgsql
AS $$
DECLARE 
    tmp_purchase_price decimal(8,2);
begin
 raise notice '====begin====';
 select price into tmp_purchase_price from productpriceoverwrite where rootproduct=product_id and downstreamaccountid=account_id;
 if tmp_purchase_price is null then
  select case a.type  when 'LV2_AGENT' then p.lv2agentprice
       when 'LV1_AGENT' then p.lv1agentprice
       when 'HQ_AGENT' then p.hqagentprice
       when 'HEAD_QUARTER' then 0
       else 0 end as purchaseprice --这个else没啥用
   into tmp_purchase_price
   from account a,product p
   where a.id=account_id and p.id=product_id;
 end if;   
RETURN tmp_purchase_price;
END; $$
;

-- 付款成功的函数不再检查优惠券和更新订单价格了。这两个动作在下单时的order_coupon_check就做了
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
    var_entitlement record;
    tmp_purchase_price decimal(8,2);
 tmp_downstream_purchase_price decimal(8,2);
    tmp_upstreamaccount UUID;
    tmp_commision decimal(8,2);
    tmp_balanceafter decimal(8,2);
    var_entitlement_name varchar;
begin
 raise notice '====begin====';
 select studentid into var_student_id from orders where id=order_id;
 for var_orderproduct in (select id,productid,couponcode,actualprice from orderproduct where orderid=order_id)
 loop 
  raise notice 'productid: %',var_orderproduct.productid;
  select * into var_product from product where id=var_orderproduct.productid;
  var_acc_id := var_student_id;
  var_acc_type := 'STUDENT';
  /*var_discount := 0;
  if var_orderproduct.couponcode is not null then --有优惠券的时候，设置优惠金额，否则优惠为0
   select discountamount into var_discount from ordercoupon where code=var_orderproduct.couponcode;
  end if; 
  var_sumprice := var_sumprice + var_product.finalprice - var_discount;
  raise notice 'sumprice: % | discount: %',var_sumprice,var_discount;*/
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
    tmp_commision := var_orderproduct.actualprice - tmp_purchase_price;
    raise notice 'account:% | finalprice:% | actualprice:% | purchaseprice:% | commision:%',tmp_upstreamaccount,var_product.finalprice,var_orderproduct.actualprice,tmp_purchase_price,tmp_commision;
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
 update orders set status='success',payat=now()::timestamp where id=order_id;
 raise notice '====end====';
RETURN 'success';
END; $function$
;

-- 下单前检查优惠券，加了一些validation rule，修复了一些bug。这些我尽量都mock数据去测试了
CREATE OR REPLACE FUNCTION public.order_coupon_check(order_id bigint,coupon_code bigint)
 RETURNS actual_price_with_error
 LANGUAGE plpgsql
AS $$
DECLARE 
    var_orderproduct record;
    var_product_finalprice  decimal(8,2);
    var_product record;
    var_student_id UUID;
    var_discount decimal(8,2);
    var_sumprice decimal(8,2) := 0;
    var_coupon record;
    var_errmsg varchar;
    var_random_product_flag boolean;
    var_direct_agent_id UUID;
begin
 raise notice '====begin====';
 select studentid into var_student_id from orders where id=order_id;
 select upstreamaccount into var_direct_agent_id from account where id=var_student_id;
 if not exists (select from orders where id=order_id) then 
  --raise no_data_found using message='该订单号不存在：'||order_id;
  return (cast(-1 as decimal(8,2)),cast('该订单号不存在：'|| order_id as varchar));
 end if;

 if coupon_code is not null then -- 对优惠券进行检查
  if not exists (select from ordercoupon where code=coupon_code) then 
   return (cast(-1 as decimal(8,2)),cast('该优惠券码不存在：'||coupon_code as varchar));
  end if;
  select * into var_coupon from ordercoupon where code=coupon_code;
  if var_coupon.effectstartdate is not null then
   if CURRENT_DATE < var_coupon.effectstartdate then
    return (cast(-1 as decimal(8,2)),cast('优惠券不在有效期(起始日期:' || var_coupon.effectstartdate || ')。' as varchar));
   end if;
  end if;
  if var_coupon.effectduedate is not null then
   if CURRENT_DATE > var_coupon.effectduedate then
    return (cast(-1 as decimal(8,2)),cast('优惠券不在有效期(截止日期:' || var_coupon.effectduedate || ')。' as varchar));
   end if;
  end if;
  if var_direct_agent_id!=var_coupon.agentid then
   return (cast(-1 as decimal(8,2)),cast('优惠券不是您的直属代理签发的。' as varchar));
  end if;
  if var_coupon.studentid is not null then
   if var_coupon.studentid!=var_student_id then
    return (cast(-1 as decimal(8,2)),cast('您不是优惠券的有效学员。' as varchar));
   end if;
  end if;
  if var_coupon.productid is not null then
   if not exists (select from orderproduct where orderid=order_id and productid=var_coupon.productid) then
    return (cast(-1 as decimal(8,2)),cast('该优惠券对您本次购买的商品无效。' as varchar));
   end if;
   if (select finalprice-get_purchase_price(id,var_direct_agent_id)-var_coupon.discountamount from product where id=var_coupon.productid) < 0 then--优惠金额过高：超过直接上级代理的利润。
    return (cast(-1 as decimal(8,2)),cast('该优惠金额无效，请与销售人员核实。' as varchar));
   end if;
  else
   raise notice 'direct agent: % | discount: %',var_direct_agent_id,var_coupon.discountamount;
   var_coupon.productid := (select op.productid from orderproduct op,product p where op.productid=p.id and orderid=order_id and p.finalprice - get_purchase_price(p.id,var_direct_agent_id) >= var_coupon.discountamount limit 1);
   if var_coupon.productid is null then
    return (cast(-1 as decimal(8,2)),cast('优惠券金额超过订单中所有商品售价。' as varchar));
   end if;
  end if;
  if var_coupon.maxcount is not null then
   if (select count(*) from orderproduct where couponcode=coupon_code) >= var_coupon.maxcount then
    return (cast(-1 as decimal(8,2)),cast('优惠券超过最大使用次数（' || var_coupon.maxcount || '次)。' as varchar));
   end if;
  end if;
 end if; 

 for var_orderproduct in (select id,productid from orderproduct where orderid=order_id)
 loop 
  raise notice 'productid: %',var_orderproduct.productid;
  select finalprice,purchaselimit,productname into var_product from product where id=var_orderproduct.productid;
  if var_product.purchaselimit is not null then
   if (select count(*) from orderproduct op,orders o where op.orderid=o.id and o.status='success' and op.productid=var_orderproduct.productid and o.studentid=var_student_id) >= var_product.purchaselimit then
   update orderproduct set originalprice=null,actualprice=null,couponcode=null where orderid=order_id;--function不支持rollback。模拟rollback的效果
   return (cast(-1 as decimal(8,2)),cast('超过商品最大购买次数:' || var_product.productname as varchar));
   end if;
  end if;
  var_discount := 0;
  if coupon_code is not null then
   if var_coupon.productid=var_orderproduct.productid then --有优惠券的时候，设置优惠金额，否则优惠为0
    var_discount := var_coupon.discountamount;
    update orderproduct set couponcode=coupon_code where id=var_orderproduct.id;--商品上设置优惠券
   end if; 
  end if;
  var_sumprice := var_sumprice + var_product.finalprice - var_discount;
  raise notice 'sumprice: % | discount: %',var_sumprice,var_discount;
  update orderproduct set originalprice=var_product.finalprice,actualprice = var_product.finalprice - var_discount where id=var_orderproduct.id;--更新商品价格
 end loop;
 update orders set price=var_sumprice where id=order_id;--更新订单价格
 raise notice '====end====';
RETURN (var_sumprice,cast('' as varchar));
END; $$
;
