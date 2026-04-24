ALTER TABLE public.productinventoryhistory ADD quantityafter int4 NOT NULL;

CREATE OR REPLACE FUNCTION public.audit_productinventory()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Insert a new row into productinventoryhistory with relevant details
    IF TG_OP = 'INSERT' THEN
	    INSERT INTO public.productinventoryhistory (
	        sourceid, 
	        quantity, 
			quantityafter,
	        inventoryorderid, 
			orderid,
	        createdat
	    ) VALUES (
	        NEW.id, 
			NEW.quantity,
	        NEW.quantity, 
	        NEW.lastinventoryorderid, 
			NEW.lastorderid,
	        NOW() AT TIME ZONE 'Asia/Shanghai'
	    );
	    RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
	    INSERT INTO public.productinventoryhistory (
	        sourceid, 
	        quantity, 
			quantityafter,
	        inventoryorderid, 
			orderid,
	        createdat
	    ) VALUES (
	        NEW.id, 
			(NEW.quantity-OLD.quantity),
	        NEW.quantity, 
	        NEW.lastinventoryorderid, 
			NEW.lastorderid,
	        NOW() AT TIME ZONE 'Asia/Shanghai'
	    );
	    RETURN NEW;
	END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_simple_order(product_id uuid, student_id uuid, coupon_code bigint, payment_method text DEFAULT NULL::text)
 RETURNS order_price_error
 LANGUAGE plpgsql
AS $function$
DECLARE 
   	v_product record;
   	v_sumprice decimal(8,2);
   	v_coupon record;
    v_direct_agent_id UUID;
	v_direct_agent_type entitytype;
	v_max_purchase_price decimal(8,2) := 0;
   	v_order_id bigint := -1;
	v_partition accountpartition;
	v_award_extension_level smallint;
	tmp_coupon_code int8;
	tmp_inventory_quantity int4;
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
	elsif payment_method is not null then 
		if payment_method not in ('inventory_agent','inventory_student') THEN
			raise exception '无效的付款方式:%',payment_method;
		elsif coupon_code is not null then
			raise exception '线下付款无需填写销售代码';
		end if;
	end if;

	-- 初始化参数
	select id,type,partition into v_direct_agent_id,v_direct_agent_type,v_partition from account where id=(select upstreamaccount from account where id=student_id);
	/*if payment_method is not null then 
		if payment_method not in ('inventory_agent','inventory_student') THEN
			raise exception '无效的付款方式:%',payment_method;
		elsif coupon_code is not null then
			raise exception '线下付款无需填写销售代码';
		elsif payment_method in ('inventory_agent') then
			SELECT COALESCE((SELECT quantity  FROM productinvetory  WHERE productid=product_id AND accountid=v_direct_agent_id),0) INTO tmp_inventory_quantity;
			if tmp_inventory_quantity<1 then
				raise exception '库存不足. 数量:%',tmp_inventory_quantity;
			end if;
		end if;
	end if;*/
	select finalprice,purchaselimit,productname,pricingschedule into v_product from product where id=product_id; -- 读取商品详情	
	v_max_purchase_price := v_product.pricingschedule ->> concat(v_direct_agent_type,'-course-purchase-price');-- 获取进货价
	IF v_max_purchase_price IS NULL THEN
		raise exception 'parameter not found: pricingschedule.%',concat(v_direct_agent_type,'-course-purchase-price');
	END IF;

	IF payment_method in ('inventory_agent','inventory_student') THEN -- 支付方式=库存，不需要用户在前端输入销售代码
		select * into v_coupon from ordercoupon where agentid=v_direct_agent_id and issuinguser is null and discountamount=0 
			and maxcount is null and productid is null and studentid is null and effectstartdate is null and effectduedate is null;
		if v_coupon IS NULL then -- account下没有user=null的coupon，就自动生成一个
			LOOP -- 监测到code冲突的话，自动重新生成
		        tmp_coupon_code := FLOOR(random() * (99999999 - 10000000 + 1) + 10000000);	
		        IF NOT EXISTS (SELECT 1 FROM ordercoupon WHERE code = tmp_coupon_code) THEN
		            EXIT;
		        END IF;
		    END LOOP;
			insert into ordercoupon(code,agentid,discountamount) values(tmp_coupon_code,v_direct_agent_id,0) returning * INTO v_coupon;
		end if;
	END IF;

	IF coupon_code is null and v_product.finalprice > 0 and payment_method not in ('inventory_agent','inventory_student') then
		raise exception '销售代码不可以为空。';
	elsif coupon_code is not null and payment_method is null then -- 对优惠券进行检查. 库存支付无需检查。
		if not exists (select from ordercoupon where code=coupon_code) then 
			raise exception '该优惠券码不存在:%',coupon_code::text;
		end if;
		select * into v_coupon from ordercoupon where code=coupon_code; -- 读取优惠券详情
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
		if (select finalprice-v_max_purchase_price-v_coupon.discountamount-(finalprice-v_coupon.discountamount)*0.007 from product where id=product_id) < 0 then--优惠金额过高：超过直接上级代理的利润。(考虑手续费)
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
		if (select count(*) from orderproduct op,orders o where op.orderid=o.id and o.status='success' and op.productid=product_id and o.studentid=student_id) >= v_product.purchaselimit then
			raise exception '超过商品最大购买次数. product:%',v_product.productname;
		end if;
	end if;

	raise notice '====create order====';
	if payment_method is not null then -- 库存模式，不填写金额。代理自己事后填写
		v_sumprice := null;
	elsif v_product.finalprice > 0 then
		v_sumprice := v_product.finalprice - v_coupon.discountamount;--设置实际付款金额
	else
		v_sumprice := 0;
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
	IF payment_method in ('inventory_agent') THEN 
		perform pay_success(v_order_id);
	END IF;
	raise notice '====end generate_simple_order()====';
RETURN (v_order_id,v_sumprice,cast('' as varchar));
END; $function$
;



CREATE OR REPLACE FUNCTION public.pay_success(order_id bigint, force_settle boolean DEFAULT false)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE 
	v_order record;
    v_orderproduct record;
    v_product record;
    v_entitlement record;
    tmp_balanceafter decimal(8,2);
	tmp_balanceafter_reverse decimal(8,2);
    v_entitlement_name varchar;
    v_fee decimal(8,2):=0;
	rec RECORD;
	award_layer smallint:=0;-- 0: not rewarded, 1: lv2 rewarded, 2: lv1 rewarded, 3: hq rewarded
	accounttype_awardlayer JSONB := '{"LV2_AGENT": 1, "LV1_AGENT": 2, "HQ_AGENT": 3}';
	partition_balancetype JSONB := '{"L": "balanceleft", "R": "balanceright"}';
	is_indirect_awarded bool:=false;
	v_purchase_price numeric(8,2):=0;--进货价
	v_award numeric(8,2);--临时记录奖励金额   
	v_award_z numeric(8,2):=0;
	v_award_z_ratio float;
	v_award_extension_level smallint;
	v_partition accountpartition;
	v_return numeric(8,2):=0;
	v_sales_account UUID; -- 实际销售账号
	v_direct_upstream_account UUID;
	v_delivery_price numeric(8,2);
	v_delivery_account UUID;
	v_conversion_award numeric(8,2);
	v_earnest_return numeric(8,2);
	tmp_inventory_quantity int4;
BEGIN
    RAISE NOTICE '====begin pay_success(order_id bigint,force_settle boolean DEFAULT false)====';
    SELECT * INTO v_order FROM orders WHERE id = order_id;
    IF v_order IS NULL THEN
        RAISE EXCEPTION 'Order does not exist: %',order_id;
    ELSIF EXISTS (SELECT FROM balanceactivity WHERE orderid = order_id) THEN
        RAISE EXCEPTION 'The balance activity already exists for this order';
    ELSIF v_order.status::text IN ('success','settled','uncommisioned','declined','failed','refunded') THEN
        RAISE EXCEPTION 'The order has reached final status: %',v_order.status::text;
    END IF;
    
	select value into v_award_extension_level from datadictionary where key='award-extension-level';--扩展层级
	IF v_award_extension_level IS NULL THEN
		raise exception 'parameter not found: award-extension-level';
	END IF;

	IF EXISTS (select from get_upstreamaccount_chain(v_order.studentid) where account_id!=v_order.studentid and account_type in ('LV2_AGENT','LV1_AGENT','HQ_AGENT') and account_status!='ACTIVE') THEN--上游账号必须都是active的
		RAISE EXCEPTION '付款失败。上游账号状态异常。';
	elsif exists (select from get_upstreamaccount_chain(v_order.studentid) 
		where row_num<=(v_award_extension_level+2) and row_num>1 and account_type in ('LV2_AGENT','LV1_AGENT','HQ_AGENT') and account_partition is null
		and (SELECT type from account where id=account_upstreamaccount)!='HEAD_QUARTER') then
		RAISE EXCEPTION '付款失败。分区设定异常。';
	END IF;
    
    FOR v_orderproduct IN (SELECT id, productid, couponcode, actualprice FROM orderproduct WHERE orderid = order_id) 
	LOOP 
        RAISE NOTICE 'productid: %', v_orderproduct.productid;
        IF v_orderproduct.couponcode IS NULL AND v_orderproduct.actualprice>0 THEN --实付金额不为0时，必须填销售代码
			RAISE EXCEPTION '付款失败。销售代码为空。';
		END IF;
        -- 初始化各个变量
        SELECT * INTO v_product FROM product  WHERE id = v_orderproduct.productid;
		SELECT agentid INTO v_sales_account FROM ordercoupon where code=v_orderproduct.couponcode;
        v_fee := 0;
		v_award_z:= v_product.pricingschedule ->> 'cross-level-award-base';
		IF v_award_z IS NULL THEN
			raise exception 'parameter not found: cross-level-award-base. Product:%',v_product.id;
		END IF;
		select value into v_award_z_ratio from datadictionary where key=concat('','award-z-ratio');--扩展奖比例
		IF v_award_z_ratio IS NULL THEN
			raise exception 'parameter not found: award-z-ratio. Product:%',v_product.id;
		END IF;
		v_conversion_award:=(v_product.pricingschedule->>'conversion-award')::numeric(8,2);
		IF v_conversion_award IS NULL THEN
			raise exception 'parameter not found: conversion-award. Product:%',v_product.id;
		END IF;
		v_earnest_return:=(v_product.pricingschedule->>'earnest-return')::numeric(8,2);
		IF v_earnest_return IS NULL THEN
			raise exception 'parameter not found: earnest-return. Product:%',v_product.id;
		END IF;

		IF v_order.status::text != 'paid' THEN  -- 执行所有付款成功应触发的动作      
	        FOR v_entitlement IN (SELECT entitlementtypeid, validdays FROM productentitlementtype  WHERE productid = v_orderproduct.productid) 
			LOOP -- 激活学生授权
	            INSERT INTO studententitlement(id,studentid,entitlementtypeid,lastorderid,expiresat) VALUES (uuid_generate_v4(),v_order.studentid,v_entitlement.entitlementtypeid,order_id,CURRENT_DATE+v_entitlement.validdays)
	            ON CONFLICT (studentid, entitlementtypeid) DO 
	            UPDATE SET 
	                lastorderid = order_id,
	                expiresat = CASE 
	                                WHEN studententitlement.expiresat < CURRENT_DATE THEN CURRENT_DATE + v_entitlement.validdays 
	                                ELSE studententitlement.expiresat + v_entitlement.validdays 
	                            END,
	                updatedat = (now() AT TIME ZONE 'Asia/Shanghai');           
	            RAISE NOTICE '授权:%,days:%', v_entitlement.entitlementtypeid, v_entitlement.validdays;
	            
	            SELECT name INTO v_entitlement_name FROM entitlementtype WHERE id = v_entitlement.entitlementtypeid;
	            
	            IF v_entitlement_name = '在线视频课' 
	            AND NOT EXISTS (SELECT FROM qianliaocoupon WHERE studentid = v_order.studentid) THEN -- 如果没有分配千聊优惠券，则从空余优惠券里选一个分配
	                UPDATE qianliaocoupon SET studentid=v_order.studentid,updatedat=(now() AT TIME ZONE 'Asia/Shanghai') WHERE couponcode=(SELECT couponcode FROM qianliaocoupon WHERE studentid IS NULL LIMIT 1);
	            END IF;
	        END LOOP;
	
			-- 分配服务提供商
			v_delivery_price:= v_product.pricingschedule ->> 'external-delivery-price';
			v_delivery_account:= v_product.pricingschedule ->> 'external-delivery-account';
			IF v_delivery_price > 0 THEN
				IF (SELECT type FROM account where id=v_delivery_account) NOT IN ('HEAD_QUARTER','HQ_AGENT','LV1_AGENT','LV2_AGENT') THEN
					RAISE EXCEPTION '交付账号异常: %',v_delivery_account;
				END IF;
				-- 设定初始交付周期为产品对应的任意一个entitlementtype的validdays
				INSERT INTO projectdelivery(orderproductid,deliveryaccount,price,source,assignmode,starttime,endtime) VALUES(v_orderproduct.id,v_delivery_account,v_delivery_price,'PRODUCT','AUTO',NOW() AT TIME ZONE 'Asia/Shanghai',(NOW() AT TIME ZONE 'Asia/Shanghai') + (SELECT CONCAT(validdays,' day')::INTERVAL FROM productentitlementtype  WHERE productid = v_orderproduct.productid LIMIT 1));
			END IF; 
		END IF;

		IF v_order.paymentmethod::text NOT IN ('liuliupay') OR force_settle=true THEN -- 执行所有背靠背结算动作 （微信直连的结算暂时没有做，也在付款时直接分账）
		    FOR rec IN select * from get_upstreamaccount_chain(v_order.studentid)-- 执行分账
		 	LOOP
		        --raise notice 'row:% | id:% | type:% |name:% |%',rec.row_num,rec.account_id,rec.account_type,rec.account_name,is_indirect_awarded;
				IF (award_layer=3 and is_indirect_awarded) OR rec.account_type='HEAD_QUARTER' or v_orderproduct.actualprice<=0 THEN -- 实付<=0，不分账
					RAISE NOTICE '--exist loop at %',rec.account_name;
					EXIT; -- exist the loop when all awards are distributed
				END IF;
				IF rec.account_id=v_order.studentid THEN -- 学生
					RAISE NOTICE '-- 学生:%',rec.account_name;
				ELSE -- 上级
					--判断是否属于 直属招商奖励
					IF (award_layer<3 AND rec.account_type='HQ_AGENT') OR (award_layer<2 AND rec.account_type='LV1_AGENT') OR (award_layer<1 AND rec.account_type='LV2_AGENT') OR rec.row_num=2 THEN
						-- 确定剩余意向金返还数额
						select pendingreturn into v_return from account where id=rec.account_id;
						IF rec.row_num=2 THEN -- 直属上级
							v_direct_upstream_account := rec.account_id;
							IF v_order.paymentmethod::text in ('inventory_agent','inventory_student') then -- 库存方式时，检查库存是否充足
								SELECT COALESCE((SELECT quantity FROM productinventory WHERE productid=v_orderproduct.productid AND accountid=rec.account_id),0) INTO tmp_inventory_quantity;
								if tmp_inventory_quantity<1 then
									raise exception '库存不足. 数量:%',tmp_inventory_quantity;
								end if;
								-- 消耗一个库存
								update productinventory set quantity=quantity-1,lastinventoryorderid=null,lastorderid=v_order.id,updatedat=NOW() AT TIME ZONE 'Asia/Shanghai' where productid=v_orderproduct.productid AND accountid=rec.account_id;
							ELSE -- 库存方式, 不分售课奖励。
								-- 直接售课奖励
								v_purchase_price := v_product.pricingschedule ->> concat(rec.account_type,'-course-purchase-price');-- 获取进货价
								IF v_purchase_price IS NULL THEN
									raise exception 'parameter not found: %. Product:%',concat(rec.account_type,'-course-purchase-price'),v_product.id;
								END IF;
								v_award := v_orderproduct.actualprice - v_purchase_price; -- commission是实际价格减去进货价
								-- 写余额，step 1 写售课奖励
								update account set balance = balance+v_award WHERE id=rec.account_id returning balance into tmp_balanceafter;	
								insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype) 
									values('售课奖励',order_id,v_orderproduct.id,rec.account_id,v_award,tmp_balanceafter,'balance');
							END IF;
							--写余额，step 2 转化订单奖励，给到v_sales_account 
							update account set balance = balance+v_conversion_award WHERE id=v_sales_account returning balance into tmp_balanceafter;	
							-- 操作余额变动,记录时间为原时间+1毫秒
							insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
								values('转化订单奖励',order_id,v_orderproduct.id,v_sales_account,v_conversion_award,tmp_balanceafter,'balance',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond');
	
							-- 写余额，step 3 return>0时，返还意向金
							IF v_return > 0 THEN
								update account set balance=balance+v_earnest_return, pendingreturn=pendingreturn-v_earnest_return WHERE id=rec.account_id returning balance,pendingreturn into tmp_balanceafter,tmp_balanceafter_reverse;	
								-- 操作余额变动,记录时间为原时间+2毫秒
								insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
									values('意向金返还(余额)',order_id,v_orderproduct.id,rec.account_id,v_earnest_return,tmp_balanceafter,'balance',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond');
								insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
									values('意向金返还(剩余意向金)',order_id,v_orderproduct.id,rec.account_id,-v_earnest_return,tmp_balanceafter_reverse,'pendingreturn',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond');
							END IF;
							-- ！！！ 不管意向金是否还完，下级售课了就可以返回解锁三单循环的金额（即使是负数的也接着扣）
							update triplecycleaward set pendingreturn=pendingreturn-v_earnest_return,lastorderid=order_id,updatedat=NOW() AT TIME ZONE 'Asia/Shanghai' where linkedaccountid=v_direct_upstream_account;
							raise notice '解锁三单循环: 金额% 学生直接上级代理:%',v_earnest_return,v_direct_upstream_account;
							-- 写余额，step 4 线上付款时，手续费由直接上级代理承担
							if v_order.paymentmethod::text='wechatpay' then
								v_fee := v_orderproduct.actualprice * 0.007;
								-- 扣除手续费
								update account set balance = balance - v_fee where id=rec.account_id returning balance into tmp_balanceafter;
								-- 操作余额变动,记录时间为原时间+3毫秒
								insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
									values('微信支付手续费0.7%',order_id,v_orderproduct.id,rec.account_id,-v_fee,tmp_balanceafter,'balance',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '3 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '3 millisecond');
							end if;		
							--设置发放奖励状态
							award_layer := (accounttype_awardlayer->>rec.account_type)::NUMERIC;	
							RAISE NOTICE '-- 直属售课奖励:% 金额:% 剩余意向金:% 转化费:% 手续费:%  付款方式:% 奖励发放状态:%|%',rec.account_name,v_award,v_return,v_conversion_award,v_fee,v_order.paymentmethod::text,award_layer,is_indirect_awarded;
						ELSE
							-- 跨级售课奖励
							v_award := v_product.pricingschedule ->> concat(rec.account_type,'-course-direct-award');
							IF v_purchase_price IS NULL THEN
								raise exception 'parameter not found: %. Product:%',concat(rec.account_type,'-course-direct-award'),v_product.id;
							END IF;
							update account set balance = balance+v_award WHERE id=rec.account_id returning balance into tmp_balanceafter;	
							insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype) 
								values('售课跨级奖励',order_id,v_orderproduct.id,rec.account_id,v_award,tmp_balanceafter,'balance');
							IF v_return > 0 THEN-- 跨级意向金返还
								update account set balance = balance+v_earnest_return,pendingreturn=pendingreturn-v_earnest_return WHERE id=rec.account_id returning balance,pendingreturn into tmp_balanceafter,tmp_balanceafter_reverse;	
								-- 操作余额变动,记录时间为原时间+1毫秒							
								insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
									values('跨级意向金返还(余额)',order_id,v_orderproduct.id,rec.account_id,v_earnest_return,tmp_balanceafter,'balance',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond');
								insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
									values('跨级意向金返还(剩余意向金)',order_id,v_orderproduct.id,rec.account_id,-v_earnest_return,tmp_balanceafter_reverse,'pendingreturn',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond');
							END IF;
							--设置发放奖励状态
							award_layer := (accounttype_awardlayer->>rec.account_type)::NUMERIC;				
							RAISE NOTICE '-- 跨级奖励:% 金额:%. 奖励发放状态:%|%',rec.account_name,v_award,award_layer,is_indirect_awarded;		
						END IF;		
					END IF;
					IF rec.row_num >=3 AND rec.row_num <= (v_award_extension_level+2) THEN -- 层级小于7时，扩展奖
						v_award := v_award_z * v_award_z_ratio;
						IF v_partition IS NULL THEN
							RAISE EXCEPTION '管理职未进行分区设置，请联系核实。';
						ELSIF v_partition='L' THEN
							update account set balanceleft = balanceleft+v_award WHERE id=rec.account_id returning balanceleft into tmp_balanceafter;	
						ELSE
							update account set balanceright = balanceright+v_award WHERE id=rec.account_id returning balanceright into tmp_balanceafter;	
						END IF;
						insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype) 
							values(concat('售课扩展奖:',v_partition,'区'),order_id,v_orderproduct.id,rec.account_id,v_award,tmp_balanceafter,(partition_balancetype->>v_partition::TEXT)::accountbalancetype);
						insert into partitionaward(accountid,salesaccountid,orderid,amount,partition) values(rec.account_id,v_direct_upstream_account,order_id,v_award,v_partition);
						RAISE NOTICE '-- 扩展奖:% 金额:% x % = % ,分区:% 奖励发放状态:%|%',rec.account_name,v_award_z,v_award_z_ratio,v_award,v_partition,award_layer,is_indirect_awarded;
					ELSIF rec.row_num > (v_award_extension_level+2) THEN--层级大于8，设置奖励发放状态
						is_indirect_awarded:=true;
					END IF;
					-- 非学生账号时，获取分区，作为下一次循环（上级）的左右分区。这个动作必须在本层完成完成分账之后，给下一层用。
					select partition into v_partition from account where id=rec.account_id;
				END IF;
		    END LOOP;
		END IF;
    END LOOP;  
    
	IF v_order.paymentmethod::text IN ('wechatpay','liuliupay') AND force_settle=false THEN -- 标记订单状态
	    UPDATE orders  SET status='paid',payat=(now() AT TIME ZONE 'Asia/Shanghai'),updatedat=(now() AT TIME ZONE 'Asia/Shanghai') WHERE id=order_id;    
	ELSIF v_order.status::text = 'paid' THEN
	    UPDATE orders  SET status='settled',settledat=(now() AT TIME ZONE 'Asia/Shanghai'),updatedat=(now() AT TIME ZONE 'Asia/Shanghai') WHERE id=order_id;   
	ELSE
	    UPDATE orders  SET status='settled',payat=(now() AT TIME ZONE 'Asia/Shanghai'),settledat=(now() AT TIME ZONE 'Asia/Shanghai'),updatedat=(now() AT TIME ZONE 'Asia/Shanghai') WHERE id=order_id; 
	END IF;

    RAISE NOTICE '====end pay_success()====';
    RETURN 'success';
END; 
$function$
;
