create type actual_price_with_error as (actualprice decimal(8,2), errmsg varchar);

CREATE OR REPLACE FUNCTION public.order_coupon_check(order_id bigint,coupon_code bigint)
 RETURNS actual_price_with_error
 LANGUAGE plpgsql
AS $$
DECLARE 
    var_orderproduct record;
    var_product_finalprice  decimal(8,2);
    var_student_id UUID;
    var_discount decimal(8,2);
    var_sumprice decimal(8,2) := 0;
    var_coupon record;
    var_errmsg varchar;
    var_random_product_flag boolean;
begin
 raise notice '====begin====';
 select studentid into var_student_id from orders where id=order_id;
 if not exists (select from orders where id=order_id) then 
  --raise no_data_found using message='该订单号不存在：'||order_id;
  return (cast(-1 as decimal(8,2)),cast('该订单号不存在：'|| order_id as varchar));
 end if;
 if coupon_code is not null then
  if not exists (select from ordercoupon where code=coupon_code) then 
   --raise no_data_found using message='该优惠券码不存在：'||coupon_code;
   return (cast(-1 as decimal(8,2)),cast('该优惠券码不存在：'||coupon_code as varchar));
  end if;
  select * into var_coupon from ordercoupon where code=coupon_code;
  if var_coupon.effectstartdate is not null then
   if CURRENT_DATE < var_coupon.effectstartdate then
    --raise data_exception using message='优惠券不在有效期(起始日期:' || var_coupon.effectstartdate || ')。';
    return (cast(-1 as decimal(8,2)),cast('优惠券不在有效期(起始日期:' || var_coupon.effectstartdate || ')。' as varchar));
   end if;
  end if;
  if var_coupon.effectduedate is not null then
   if CURRENT_DATE > var_coupon.effectduedate then
    --raise data_exception using message='优惠券不在有效期(截止日期:' || var_coupon.effectduedate || ')。';
    return (cast(-1 as decimal(8,2)),cast('优惠券不在有效期(截止日期:' || var_coupon.effectduedate || ')。' as varchar));
   end if;
  end if;
  if (select upstreamaccount from account where id=var_student_id)!=var_coupon.agentid then
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
   if (select finalprice-var_coupon.discountamount from product where id=var_coupon.productid) < 0 then
    return (cast(-1 as decimal(8,2)),cast('优惠金额无效。该优惠券金额大于商品售价。' as varchar));
   end if;
  end if;
  if var_coupon.maxcount is not null then
   if (select count(*) from orderproduct where couponcode=coupon_code) >= var_coupon.maxcount then
    --raise data_exception using message='优惠券超过最大使用次数（' || var_coupon.maxcount || '次)。';
    return (cast(-1 as decimal(8,2)),cast('优惠券超过最大使用次数（' || var_coupon.maxcount || '次)。' as varchar));
   end if;
  end if;
 end if; 
 
 if var_coupon.productid is null then -- 如果没有product id，则把coupon随便apply到一个比优惠金额大的orderproduct上
  var_coupon.productid := (select op.productid from orderproduct op,product p where op.productid=p.id and orderid=order_id and p.finalprice>=var_coupon.discountamount limit 1);
  if var_coupon.productid is null then
   return (cast(-1 as decimal(8,2)),cast('优惠券金额超过订单中所有商品售价。' as varchar));
  end if;
 end if;
 for var_orderproduct in (select id,productid from orderproduct where orderid=order_id)
 loop 
  raise notice 'productid: %',var_orderproduct.productid;
  select finalprice into var_product_finalprice from product where id=var_orderproduct.productid;
  var_discount := 0;
  if coupon_code is not null and var_coupon.productid=var_orderproduct.productid then --有优惠券的时候，设置优惠金额，否则优惠为0
   select discountamount into var_discount from ordercoupon where code=coupon_code;
   update orderproduct set couponcode=coupon_code where id=var_orderproduct.id;--商品上设置优惠券
  end if; 
  var_sumprice := var_sumprice + var_product_finalprice - var_discount;
  raise notice 'sumprice: % | discount: %',var_sumprice,var_discount;
  update orderproduct set originalprice=var_product_finalprice,actualprice = var_product_finalprice - var_discount where id=var_orderproduct.id;--更新商品价格
 end loop;
 update orders set price=var_sumprice where id=order_id;--更新订单价格
 raise notice '====end====';
RETURN (var_sumprice,cast('' as varchar));
END; $$
;