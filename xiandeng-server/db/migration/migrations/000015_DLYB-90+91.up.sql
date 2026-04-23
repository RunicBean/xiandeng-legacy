CREATE INDEX idx_majorcode ON public.majorenterprise (majorcode) ON CONFLICT DO NOTHING;
CREATE INDEX idx_enterpriseid ON public.majorenterprise (enterpriseid);

-- DROP FUNCTION public.generate_simple_order(uuid, uuid, int8);

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
	insert into orders(id,status,studentid,price) values(var_order_id,'created',student_id,var_sumprice);
	insert into orderproduct(id,orderid,productid,originalprice,couponcode,actualprice) values(var_order_id*10,var_order_id,product_id,var_product.finalprice,coupon_code,var_sumprice);
	if coupon_code is not null then
		update ordercoupon set lastusedat=(now() AT TIME ZONE 'Asia/Shanghai') where code=coupon_code;
	end if;
	raise notice '====end====';
RETURN (var_order_id,var_sumprice,cast('' as varchar));
END; $function$
;