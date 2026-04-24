
CREATE OR REPLACE FUNCTION public.generate_simple_order(product_id uuid, student_id uuid, coupon_code bigint, payment_method text DEFAULT NULL::text)
 RETURNS order_price_error
 LANGUAGE plpgsql
AS $function$
DECLARE 
   	v_product record;
   	v_sumprice decimal(10,2);
   	v_coupon record;
    v_direct_agent_id UUID;
	v_direct_agent_type entitytype;
	v_purchase_price decimal(10,2) := 0;
   	v_order_id bigint := -1;
	v_partition accountpartition;
	v_award_extension_level smallint;
	tmp_coupon_code int8;
	tmp_inventory_quantity int4;
	v_conversion_award numeric(10,2);
	v_purchased_count int2;
begin
	raise notice '====begin generate_simple_order(product_id uuid, student_id uuid, coupon_code bigint, payment_method text default null)====';
	select value into v_award_extension_level from datadictionary where key='award-extension-level' and namespace='award.factor';--扩展层级
	IF v_award_extension_level IS NULL THEN
		raise exception 'parameter not found: award-extension-level';
	END IF;
	

	if (select type from account where id=student_id)!='STUDENT' then 
		raise exception '只有学员账号可购买。student_id: %',student_id;
	elsIF EXISTS (select from get_upstreamaccount_chain(student_id) where account_id!=student_id and account_type in ('LV2_AGENT','LV1_AGENT','HQ_AGENT') and account_status!='ACTIVE') THEN--上游账号必须都是active的
		raise exception '上游账号状态异常。student_id: %',student_id;
	elsif exists (select from get_upstreamaccount_chain(student_id) where row_num<=(v_award_extension_level+2) and row_num>1 and account_type in ('LV2_AGENT','LV1_AGENT','HQ_AGENT') 
	and account_partition is null and (SELECT type from account where id=account_upstreamaccount)!='HEAD_QUARTER') then
		raise exception '上游账号分区设定异常。student_id: %',student_id;
	end if;

	-- 初始化参数
	select id,type,partition into v_direct_agent_id,v_direct_agent_type,v_partition from account where id=(select upstreamaccount from account where id=student_id);
	if payment_method is not null then 
		if payment_method not in ('inventory_agent','inventory_student') THEN
			raise exception '无效的付款方式:%',payment_method;
		elsif coupon_code is not null then
			raise exception '线下付款无需填写销售代码';
		elsif v_direct_agent_type::text='HEAD_QUARTER' then
			raise exception '该支付方式对总部直属学员无效';
		end if;
	end if;
	select * into v_coupon from ordercoupon where code=coupon_code; -- 读取优惠券详情
	select finalprice,purchaselimit,productname,pricingschedule into v_product from product where id=product_id; -- 读取商品详情	
	v_purchase_price := v_product.pricingschedule ->> concat(v_direct_agent_type,'-course-purchase-price');-- 获取进货价
	IF v_purchase_price IS NULL THEN
		raise exception 'parameter not found: pricingschedule.%',concat(v_direct_agent_type,'-course-purchase-price');
	END IF;
	v_conversion_award:=(v_product.pricingschedule->>'conversion-award')::numeric(10,2);
	IF v_conversion_award IS NULL THEN
		raise exception 'parameter not found: conversion-award. Product:%',v_product.id;
	END IF;

	IF coupon_code is null and v_product.finalprice > 0 and payment_method is null AND v_conversion_award!=0 then-- 生成订单时，只有库存才会预设payment_method
		raise exception '销售代码不可以为空。';
	elsif coupon_code is not null and payment_method is null then -- 对优惠券进行检查. 库存支付无需检查。
		if v_coupon is null then 
			raise exception '该优惠券码不存在:%',coupon_code::text;
		end if;
		--select * into v_coupon from ordercoupon where code=coupon_code; -- 读取优惠券详情
		if v_coupon.effectstartdate is not null then
			if CURRENT_DATE < v_coupon.effectstartdate then
				raise exception '优惠券不在有效期. 起始日期:%',v_coupon.effectstartdate;
			end if;
		end if;
		if v_coupon.effectduedate is not null then
			if CURRENT_DATE > v_coupon.effectduedate then
				raise exception '优惠券不在有效期. 截止日期:%',v_coupon.effectduedate;
			end if;
		end if;
		if v_coupon.studentid is not null then
			if v_coupon.studentid!=student_id then
				raise exception '您不是优惠券的有效学员。coupon:% student_id:%',v_coupon.code,student_id;
			end if;
		end if;
		if v_coupon.productid is not null then
			if v_coupon.productid != product_id then
				raise exception '该优惠券对您本次购买的商品无效。coupon:% product_id:%',v_coupon.code,product_id;
			end if;
		end if;
		if (select finalprice-v_purchase_price-v_coupon.discountamount-(finalprice-v_coupon.discountamount)*0.007 from product where id=product_id) < 0 then--优惠金额过高：超过直接上级代理的利润。(考虑手续费)
			raise exception '该优惠金额无效，请与销售人员核实。';
		end if;
		if v_coupon.maxcount is not null then
			if (select count(*) from orderproduct where couponcode=coupon_code) >= v_coupon.maxcount then
				raise exception '优惠券超过最大使用次数. coupon:%',coupon_code;
			end if;
		end if;
	end if;	

	if v_product.purchaselimit is not null then
		raise notice 'purchase limit: %',v_product.purchaselimit;
		select count(*) into v_purchased_count from orderproduct op,orders o where op.orderid=o.id and o.status::text in ('paid','settled') 
			and op.productid=product_id and o.studentid=student_id;
		if v_purchased_count >= v_product.purchaselimit then
			raise exception '超过商品最大购买次数. product:%, limit:%, purchased:%',v_product.productname,v_product.purchaselimit,v_purchased_count;
		end if;
	end if;

	raise notice '====create order====';
	if payment_method is not null then -- 库存模式，不填写金额。代理自己事后填写
		v_sumprice := null;
	elsif v_product.finalprice > 0 AND v_coupon is not null then
		v_sumprice := v_product.finalprice - v_coupon.discountamount;--设置实际付款金额
	else
		v_sumprice := v_product.finalprice;
	end if;

	select ((extract(year from current_date)*100+extract(month from current_date))*100+extract(day from current_date))*100000000+floor(random()*100000000) into v_order_id;--生成订单号 
	if exists(select from orders where id=v_order_id) then -- 检测到重复自动重新生成
		LOOP
	        select ((extract(year from current_date)*100+extract(month from current_date))*100+extract(day from current_date))*100000000+floor(random()*100000000) into v_order_id;
	        IF NOT EXISTS (SELECT from orders where id=v_order_id) THEN
	            EXIT;
	        END IF;
	    END LOOP;
	end if;
	insert into orders(id,status,studentid,price,paymentmethod) values(v_order_id,'created',student_id,v_sumprice,payment_method);
	insert into orderproduct(id,orderid,productid,originalprice,couponcode,actualprice) values(v_order_id*10,v_order_id,product_id,v_product.finalprice,v_coupon.code,v_sumprice);
	if v_coupon is not null then
		update ordercoupon set lastusedat=(now() AT TIME ZONE 'Asia/Shanghai') where code=v_coupon.code;
	end if;
	IF payment_method in ('inventory_agent') or v_sumprice=0 THEN 
		perform pay_success(v_order_id);
	END IF;
	raise notice '====end generate_simple_order()====';
RETURN (v_order_id,v_sumprice,cast('' as varchar));
END; $function$
;
