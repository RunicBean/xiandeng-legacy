ALTER TABLE public.balanceactivity ALTER COLUMN accountid SET NOT NULL;
CREATE UNIQUE INDEX idx_unique_balanceactivity_accountid_orderid ON balanceactivity(accountid, orderid);
CREATE OR REPLACE FUNCTION public.generate_new_coupon(user_id UUID,discount_amount decimal(8,2),max_count int4,product_id UUID,student_id UUID,start_date date,due_date date)
 RETURNS varchar
 LANGUAGE plpgsql
AS $$
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
  select finalprice-get_purchase_price(product_id,var_agent.id) into var_allowed_max_discount from product where id=product_id;
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
END; $$
;