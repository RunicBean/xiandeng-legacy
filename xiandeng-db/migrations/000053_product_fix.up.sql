UPDATE product SET pricingschedule='{"earnest-return": 600, "conversion-award": 1800, "cross-level-award-base": 2100, "HQ_AGENT-course-direct-award": 300, "LV1_AGENT-course-direct-award": 300, "HQ_AGENT-course-purchase-price": 19600, "LV1_AGENT-course-purchase-price": 19900, "LV2_AGENT-course-purchase-price": 20200, "HEAD_QUARTER-course-purchase-price": 0}'::jsonb WHERE id='5e89d000-7044-467f-ad13-9b490f05313d'::uuid;
UPDATE product SET pricingschedule='{"earnest-return": 0, "conversion-award": 0, "cross-level-award-base": 0, "HQ_AGENT-course-direct-award": 0, "LV1_AGENT-course-direct-award": 0, "HQ_AGENT-course-purchase-price": 50, "LV1_AGENT-course-purchase-price": 50, "LV2_AGENT-course-purchase-price": 50, "HEAD_QUARTER-course-purchase-price": 0}'::jsonb WHERE id='f8c211f8-50c9-4968-8c4e-61b07ddfda9c'::uuid;
UPDATE product SET pricingschedule='{"earnest-return": 200, "conversion-award": 600, "cross-level-award-base": 700, "HQ_AGENT-course-direct-award": 100, "LV1_AGENT-course-direct-award": 100, "HQ_AGENT-course-purchase-price": 2300, "LV1_AGENT-course-purchase-price": 2400, "LV2_AGENT-course-purchase-price": 2500, "HEAD_QUARTER-course-purchase-price": 0}'::jsonb WHERE id='86223835-013e-4fb3-9515-a1483de7cd64'::uuid;
UPDATE product SET pricingschedule='{"earnest-return": 600, "conversion-award": 1800, "cross-level-award-base": 2100, "HQ_AGENT-course-direct-award": 300, "LV1_AGENT-course-direct-award": 300, "HQ_AGENT-course-purchase-price": 15600, "LV1_AGENT-course-purchase-price": 15900, "LV2_AGENT-course-purchase-price": 16200, "HEAD_QUARTER-course-purchase-price": 0}'::jsonb WHERE id='471e7eb5-fa9d-48bd-9048-eb23e142358f'::uuid;
UPDATE product SET pricingschedule='{"earnest-return": 50, "conversion-award": 200, "cross-level-award-base": 200, "external-delivery-price": 300, "external-delivery-account": "cc961f55-bbd5-4c9d-91f5-ee7b70e4ab29", "HQ_AGENT-course-direct-award": 30, "LV1_AGENT-course-direct-award": 30, "HQ_AGENT-course-purchase-price": 840, "LV1_AGENT-course-purchase-price": 870, "LV2_AGENT-course-purchase-price": 900, "HEAD_QUARTER-course-purchase-price": 0}'::jsonb WHERE id='2650418f-522e-43a6-8463-e7fe28007345'::uuid;
UPDATE product SET pricingschedule='{"earnest-return": 0, "conversion-share": 0, "cross-level-award-base": 0, "HQ_AGENT-course-direct-award": 0, "LV1_AGENT-course-direct-award": 0, "LV2_AGENT-course-purchase-price": 0, "HEAD_QUARTER-course-purchase-price": 0}'::jsonb WHERE id='234350a5-880b-4866-ab93-7d2a6818fdbd'::uuid;



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
	v_purchase_price decimal(8,2) := 0;
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
	select finalprice,purchaselimit,productname,pricingschedule into v_product from product where id=product_id; -- 读取商品详情	
	v_purchase_price := v_product.pricingschedule ->> concat(v_direct_agent_type,'-course-purchase-price');-- 获取进货价
	IF v_purchase_price IS NULL THEN
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
	
	select * into v_coupon from ordercoupon where code=coupon_code; -- 读取优惠券详情
	IF coupon_code is null and v_product.finalprice > 0 and payment_method is not null then
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
	--insert into orderproduct(id,orderid,productid,originalprice,couponcode,actualprice) values(v_order_id*10,v_order_id,product_id,v_product.finalprice,case when v_coupon is null then null else v_coupon.code end,v_sumprice);
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



CREATE OR REPLACE FUNCTION public.add_inventory()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_remaining_price numeric(8,2);
	v_account RECORD;
	v_account_after RECORD;
BEGIN
	raise notice '====begin add_inventory()====';
    IF NEW.type::text = 'hq_initiated' THEN
		INSERT INTO productinventory (accountid,productid,quantity,lastinventoryorderid,lastorderid)
		VALUES (NEW.accountid,NEW.productid,NEW.quantity,NEW.id,null)
		ON CONFLICT (accountid,productid)
		DO UPDATE SET quantity = productinventory.quantity + NEW.quantity,lastinventoryorderid=NEW.id,lastorderid=null;
		update inventoryorder set status='settled' where id = NEW.id;
	ELSIF NEW.type::text = 'from_balance' THEN
		v_remaining_price:=NEW.unitprice*NEW.quantity;
		select * into v_account from account where id=NEW.accountid;
		IF v_account.balance >= v_remaining_price THEN -- 余额足够cover订单金额时
			update account set balance=balance-v_remaining_price where id=NEW.accountid returning * INTO v_account_after;
			insert into balanceactivity(source,inventoryorderid,accountid,amount,balanceafter,balancetype) 
				values('余额购买库存',NEW.id,NEW.accountid,-v_remaining_price,v_account_after.balance,'balance');
		ELSE
			v_remaining_price=v_remaining_price-v_account.balance;
			IF v_account.balancetriple >= v_remaining_price THEN -- 三单循环余额足够cover订单金额时
				update account set balance=0,balancetriple=balancetriple-v_remaining_price where id=NEW.accountid returning * INTO v_account_after;
				insert into balanceactivity(source,inventoryorderid,accountid,amount,balanceafter,balancetype) 
					values('余额购买库存',NEW.id,NEW.accountid,-v_account.balance,v_account_after.balance,'balance');
				insert into balanceactivity(source,inventoryorderid,accountid,amount,balanceafter,balancetype) 
					values('三单循环余额购买库存',NEW.id,NEW.accountid,-v_remaining_price,v_account_after.balance,'balancetriple');
			ELSE
				v_remaining_price=v_remaining_price-v_account.balancetriple;
				IF LEAST(v_account.balanceleft,v_account.balanceright)*2 >= v_remaining_price THEN -- 分区余额足够cover订单金额时
					update account set balance=0,balancetriple=0,balanceleft=balanceleft-(v_remaining_price/2),balanceright=balanceright-(v_remaining_price/2) where id=NEW.accountid returning * INTO v_account_after;
					insert into balanceactivity(source,inventoryorderid,accountid,amount,balanceafter,balancetype) 
						values('余额购买库存',NEW.id,NEW.accountid,-v_account.balance,v_account_after.balance,'balance');
					insert into balanceactivity(source,inventoryorderid,accountid,amount,balanceafter,balancetype) 
						values('三单循环余额购买库存',NEW.id,NEW.accountid,-v_account.balancetriple,v_account_after.balancetriple,'balancetriple');
					insert into balanceactivity(source,inventoryorderid,accountid,amount,balanceafter,balancetype) 
						values('左区余额购买库存',NEW.id,NEW.accountid,-(v_remaining_price/2),v_account_after.balanceleft,'balanceleft');
					insert into balanceactivity(source,inventoryorderid,accountid,amount,balanceafter,balancetype) 
						values('右区余额购买库存',NEW.id,NEW.accountid,-(v_remaining_price/2),v_account_after.balanceright,'balanceright');
				ELSE
					--raise exception 'Not enough balance. Price:% BEFORE: Balance:% balancetriple:% balanceleft:% balanceright:% AFTER: Balance:% balancetriple:% balanceleft:% balanceright:%',v_remaining_price,v_account.balance,v_account.balancetriple,v_account.balanceleft,v_account.balanceright,v_account_after.balance,v_account_after.balancetriple,v_account_after.balanceleft,v_account_after.balanceright;
					raise exception 'Not enough balance. GAP:% BEFORE: Balance:% balancetriple:% balanceleft:% balanceright:% product:% unitprice:% quantity:%',v_remaining_price,v_account.balance,v_account.balancetriple,v_account.balanceleft,v_account.balanceright,NEW.productid,NEW.unitprice,NEW.quantity;
				END IF;
			END IF;
		END IF;
		INSERT INTO productinventory (accountid,productid,quantity,lastinventoryorderid,lastorderid)
		VALUES (NEW.accountid,NEW.productid,NEW.quantity,NEW.id,null)
		ON CONFLICT (accountid,productid)
		DO UPDATE SET quantity = productinventory.quantity + NEW.quantity,lastinventoryorderid=NEW.id,lastorderid=null;
		update inventoryorder set status='settled' where id = NEW.id;
	ELSIF NEW.type::text = 'agent_topup' THEN
	ELSE
		raise exception 'Invalid type: %',NEW.type; -- 事实上，这里只能是空值
    END IF;

	raise notice '====end add_inventory()====';
    RETURN NEW;
END;
$function$
;
