DROP FUNCTION public.complete_invitation_codes(uuid);
DROP FUNCTION public.get_child_partition_pv(uuid, accountpartition);

CREATE TABLE public.organization (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	uri varchar(10) NOT NULL,
	rootaccountid uuid NULL,
	config jsonb NULL,
	isinherit bool DEFAULT false NOT NULL,
	logourl text NULL,
	sitename varchar(32) NULL,
	wxappid varchar(100) NULL,
	wxappsecret varchar(255) NULL,
	redirecturl varchar(255) NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT organization_pkey PRIMARY KEY (id),
	CONSTRAINT organization_uri_key UNIQUE (uri),
	CONSTRAINT organization_accountid_fkey FOREIGN KEY (rootaccountid) REFERENCES public.account(id)
);

ALTER TABLE account
ADD COLUMN orgid UUID NULL,
ADD CONSTRAINT account_orgid_fk FOREIGN KEY (orgid) REFERENCES organization(id);

INSERT INTO organization (id, uri, rootaccountid, config) VALUES('cb52ee24-2aa2-462f-ac7c-86490bd87ab8'::uuid, 'linglu', '3443aed2-c10d-492e-8a35-79123c2fe24f'::uuid, NULL);

update account set orgid='cb52ee24-2aa2-462f-ac7c-86490bd87ab8' where accountname='聆鹿';

CREATE TABLE public.product4org (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	"type" varchar(255) DEFAULT 'Entitlement'::character varying NULL,
	productname varchar(255) NOT NULL,
	finalprice numeric(10, 2) NOT NULL,
	publishstatus bool NOT NULL,
	description text NOT NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	purchaselimit int2 NULL,
	pricingschedule jsonb NULL,
	orgid uuid NOT NULL,
	expiresat date DEFAULT (CURRENT_DATE AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
	CONSTRAINT product4org_pk PRIMARY KEY (id, orgid),
	CONSTRAINT product4org_id_fk FOREIGN KEY (id) REFERENCES public.product(id),
	CONSTRAINT product4org_orgid_fk FOREIGN KEY (orgid) REFERENCES public.organization(id)
);

INSERT INTO product4org (id, "type", productname, finalprice, publishstatus, description, purchaselimit, orgid, pricingschedule) 
VALUES('86223835-013e-4fb3-9515-a1483de7cd64'::uuid, 'Entitlement', '基础会员', 19800.00, true, '大学规划陪跑服务', 1, 'cb52ee24-2aa2-462f-ac7c-86490bd87ab8',
'{"earnest-return": 200, "conversion-award": 600, "cross-level-award-base": 700, "HQ_AGENT-course-direct-award": 100, "LV1_AGENT-course-direct-award": 100, "HQ_AGENT-course-purchase-price": 2300, "LV1_AGENT-course-purchase-price": 2400, "LV2_AGENT-course-purchase-price": 2500, "HEAD_QUARTER-course-purchase-price": 0}'::jsonb);

/*
INSERT INTO product4org (id, "type", productname, finalprice, publishstatus, description, purchaselimit, orgid, pricingschedule) 
VALUES('f8c211f8-50c9-4968-8c4e-61b07ddfda9c'::uuid, 'Entitlement', '大学规划报告', 999.00, true, '大学规划报告自助生成下载', 1, 'cb52ee24-2aa2-462f-ac7c-86490bd87ab8',
'{"earnest-return": 0, "conversion-award": 0, "cross-level-award-base": 0, "HQ_AGENT-course-direct-award": 0, "LV1_AGENT-course-direct-award": 0, "HQ_AGENT-course-purchase-price": 50, "LV1_AGENT-course-purchase-price": 50, "LV2_AGENT-course-purchase-price": 50, "HEAD_QUARTER-course-purchase-price": 0}'::jsonb);
*/



CREATE OR REPLACE FUNCTION public.get_product(account_id uuid, product_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(id uuid, type character varying, productname character varying, finalprice numeric, publishstatus boolean, description text, createdat timestamp without time zone, updatedat timestamp without time zone, purchaselimit smallint, pricingschedule jsonb)
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_orgid uuid;
BEGIN
	SELECT orgid INTO v_orgid FROM account a WHERE a.id = account_id;
    -- Return 
	IF product_id IS NULL THEN
	    RETURN QUERY
	    SELECT p4o.id,p4o."type",p4o.productname,p4o.finalprice,p4o.publishstatus,p4o.description,p4o.createdat,p4o.updatedat,p4o.purchaselimit,p4o.pricingschedule
	    FROM product4org p4o WHERE p4o.orgid=v_orgid AND p4o.expiresat > (CURRENT_DATE AT TIME ZONE 'Asia/Shanghai'::text)
	    UNION ALL
	    SELECT p.id,p."type",p.productname,p.finalprice,p.publishstatus,p.description,p.createdat,p.updatedat,p.purchaselimit,p.pricingschedule
	    FROM product p WHERE p.id NOT IN (SELECT po.id FROM product4org po where po.orgid=v_orgid AND po.expiresat > (CURRENT_DATE AT TIME ZONE 'Asia/Shanghai'::text));
	ELSE
		RETURN QUERY
	    SELECT p4o.id,p4o."type",p4o.productname,p4o.finalprice,p4o.publishstatus,p4o.description,p4o.createdat,p4o.updatedat,p4o.purchaselimit,p4o.pricingschedule
	    FROM product4org p4o WHERE p4o.orgid=v_orgid and p4o.id=product_id AND p4o.expiresat > (CURRENT_DATE AT TIME ZONE 'Asia/Shanghai'::text)
	    UNION ALL
	    SELECT p.id,p."type",p.productname,p.finalprice,p.publishstatus,p.description,p.createdat,p.updatedat,p.purchaselimit,p.pricingschedule
	    FROM product p WHERE p.id=product_id
		AND p.id NOT IN (SELECT po.id FROM product4org po where po.orgid=v_orgid and po.id=product_id AND po.expiresat > (CURRENT_DATE AT TIME ZONE 'Asia/Shanghai'::text));
	END IF;
END;
$function$
;



CREATE OR REPLACE FUNCTION public.check_account_before_insert()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_upstream RECORD;
BEGIN
    IF NEW.upstreamaccount IS NOT NULL THEN
        -- Fetch the partition of the upstreamaccount
        SELECT partition,status,type,upstreamaccount,orgid INTO v_upstream
        FROM public.account
        WHERE id = NEW.upstreamaccount;

        -- Check if the partition is NULL
        IF v_upstream.partition IS NULL AND v_upstream.type!='HEAD_QUARTER' AND (SELECT type from account where id=v_upstream.upstreamaccount)!='HEAD_QUARTER' THEN
            RAISE EXCEPTION '您的推荐人的账号状态异常：没有进行分区设置，无法邀请新商户';
		ELSIF v_upstream.status != 'ACTIVE' THEN
            RAISE EXCEPTION '您的推荐人的账号状态异常：非活跃账号';
        END IF;
    END IF;

    -- Allow insert to proceed if checks pass	
	-- set account status based on type
	IF NEW.type in ('LV2_AGENT','LV1_AGENT','HQ_AGENT') THEN
		NEW.status='INIT';
		-- set 意向金返还
		SELECT value INTO NEW.pendingreturn from datadictionary where key=concat(NEW.type,'-franchise-fee');
	ELSE
		NEW.status='ACTIVE';
	END IF;
	-- inherit parent's orgid
	IF v_upstream.orgid IS NOT NULL THEN
		IF NEW.type::text='STUDENT' OR (SELECT isinherit FROM organization where id=v_upstream.orgid)=true THEN -- 学员账号必然继承。下级代理由isInherit决定
			NEW.orgid=v_upstream.orgid;
		END IF;
	END IF;
    RETURN NEW;
END;
$function$
;



CREATE OR REPLACE FUNCTION public.generate_new_coupon(user_id uuid, discount_amount numeric, max_count integer, product_id uuid, student_id uuid, start_date date, due_date date)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE 
   	var_coupon_code int8 := FLOOR(random() * (99999999 - 10000000 + 1) + 10000000);
   	var_agent record;
	v_product record;
   	var_allowed_max_discount decimal(10,2);
	var_max_purchase_price decimal(10,2) := 0;--最高进货价
begin
	raise notice '====begin generate_new_coupon(user_id, discount_amount, max_count, product_id, student_id, start_date, due_date)====';
	raise notice 'code:%',var_coupon_code;
	if user_id is null then
		raise exception '创建失败。用户名不可以为空值。';
	end if;
	select id,type into var_agent from account where id=(select uar.accountid from users u,useraccountrole uar,roles r 
	where u.id=uar.userid AND uar.roleid=r.id AND r.accountkind in ('HQ','AGENT') AND u.id=user_id);
	if var_agent is null then
		raise exception '创建失败。该用户没有代理权限。user:%',user_id;
	end if;
	if discount_amount is null then
		raise exception '创建失败。优惠金额不可以为空值。';
	end if;
	if product_id is not null then
		select * into v_product from get_product(var_agent.id,product_id); --product where id=product_id;
		var_max_purchase_price := v_product.pricingschedule ->> concat(var_agent.type,'-course-purchase-price');--- 获取进货价
		--select pricingschedule ->> concat(var_agent.type,'-course-purchase-price') into var_max_purchase_price from product where id=product_id; -- 获取进货价
		if discount_amount<0 then
			raise exception '创建失败。优惠金额必须非负。';
		elsif (v_product.finalprice-var_max_purchase_price-discount_amount-(v_product.finalprice-discount_amount)*0.007)<0 then --考虑手续费
			raise exception '创建失败。优惠金额过大。请至少将优惠金额调低：%',(v_product.finalprice-var_max_purchase_price-discount_amount-(v_product.finalprice-discount_amount)*0.007);
		end if;
	end if;
	if start_date is not null and due_date is not null then 
		if start_date > due_date then
			raise exception '创建失败。优惠券起始日期晚于截止日期。';
		end if;
	end if;
	if exists (select from ordercoupon where discountamount=discount_amount and agentid=var_agent.id and productid IS NOT DISTINCT FROM product_id and studentid IS NOT DISTINCT FROM student_id and effectstartdate IS NOT DISTINCT FROM start_date and effectduedate IS NOT DISTINCT FROM due_date) then
		raise exception '创建失败。已存在面向相同商品、学员、金额、有效期的优惠券。';
	end if;
	if exists (select from ordercoupon where code=var_coupon_code) then -- 监测到code冲突的话，自动重新生成
		LOOP
	        var_coupon_code := FLOOR(random() * (99999999 - 10000000 + 1) + 10000000);	
	        IF NOT EXISTS (SELECT 1 FROM ordercoupon WHERE code = var_coupon_code) THEN
	            EXIT;
	        END IF;
	    END LOOP;
	end if;

	insert into ordercoupon(code,agentid,issuinguser,discountamount,maxcount,productid,studentid,effectstartdate,effectduedate)
		values(var_coupon_code,var_agent.id,user_id,discount_amount,max_count,product_id,student_id,start_date,due_date);
	raise notice '====end====';
	RETURN cast('创建成功。券码：' || var_coupon_code  as varchar);
END; $function$
;



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
	select finalprice,purchaselimit,productname,pricingschedule into v_product from get_product(v_direct_agent_id,product_id); --product where id=product_id; -- 读取商品详情	
	IF  v_product IS NULL THEN
		raise exception 'Product is invalid. Agent id:% product id:%',v_direct_agent_id,product_id;
	END IF;
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
		if (select finalprice-v_purchase_price-v_coupon.discountamount-(finalprice-v_coupon.discountamount)*0.007 from get_product(v_direct_agent_id,product_id)) < 0 then--优惠金额过高：超过直接上级代理的利润。(考虑手续费)
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


CREATE OR REPLACE FUNCTION public.pay_success(order_id bigint, force_settle boolean DEFAULT false, test_mode boolean DEFAULT false)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE 
	v_order record;
    v_orderproduct record;
    v_product record;
    v_entitlement record;
    tmp_balanceafter numeric(10,2);
	tmp_balanceafter_reverse numeric(10,2);
    v_entitlement_name varchar;
    v_fee numeric(10,2):=0;
	rec RECORD;
	award_layer smallint:=0;-- 0: not rewarded, 1: lv2 rewarded, 2: lv1 rewarded, 3: hq rewarded
	accounttype_awardlayer JSONB := '{"LV2_AGENT": 1, "LV1_AGENT": 2, "HQ_AGENT": 3}';
	partition_balancetype JSONB := '{"L": "balanceleft", "R": "balanceright"}';
	is_indirect_awarded bool:=false;
	v_purchase_price numeric(10,2):=0;--进货价
	v_award numeric(10,2);--临时记录奖励金额   
	v_award_z numeric(10,2):=0;
	v_award_z_ratio float;
	v_extend_award numeric(10,2);
	v_award_extension_level smallint;
	v_partition accountpartition;
	v_return numeric(10,2):=0;
	v_sales_account UUID; -- 实际销售账号
	v_direct_upstream_account UUID;
	v_delivery_price numeric(10,2);
	v_delivery_account UUID;
	v_conversion_award numeric(10,2);
	v_earnest_return numeric(10,2);
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
	ELSIF v_order.paymentmethod::text IN ('inventory_agent','inventory_student') and test_mode=true THEN
		RAISE EXCEPTION 'Inventory mode does not support test mode.';
	ELSIF v_order.status::text='paid' AND force_settle=FALSE THEN
		RAISE EXCEPTION 'Paid order need to force settle.';
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
        -- 初始化各个变量
		SELECT upstreamaccount INTO v_direct_upstream_account FROM account where id=v_order.studentid;
        SELECT * INTO v_product FROM get_product(v_direct_upstream_account,v_orderproduct.productid);--product  WHERE id = v_orderproduct.productid;
		v_conversion_award:=(v_product.pricingschedule->>'conversion-award')::numeric(10,2);
		IF v_conversion_award IS NULL THEN
			raise exception 'parameter not found: conversion-award. Product:%',v_product.id;
		END IF;
        IF v_orderproduct.couponcode IS NULL AND v_orderproduct.actualprice>0 AND v_conversion_award>0 THEN --实付金额不为0时，必须填销售代码
			RAISE EXCEPTION '付款失败。销售代码为空。';
		END IF;
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
		v_extend_award := v_award_z * v_award_z_ratio;
		v_earnest_return:=(v_product.pricingschedule->>'earnest-return')::numeric(10,2);
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

		IF test_mode=false AND (v_order.paymentmethod IS NULL OR v_order.paymentmethod::text NOT IN ('liuliupay') OR force_settle=true) THEN -- 执行所有背靠背结算动作 （微信直连的结算暂时没有做，也在付款时直接分账）
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
							--v_direct_upstream_account := rec.account_id;
							IF v_order.paymentmethod::text in ('inventory_agent','inventory_student') then -- 库存方式时，检查库存是否充足
								SELECT COALESCE((SELECT quantity FROM productinventory WHERE productid=v_orderproduct.productid AND accountid=rec.account_id),0) INTO tmp_inventory_quantity;
								if tmp_inventory_quantity<1 then
									raise exception '库存不足. 数量:%',tmp_inventory_quantity;
								end if;
								-- 消耗一个库存
								update productinventory set quantity=quantity-1,lastinventoryorderid=null,lastorderid=v_order.id,updatedat=NOW() AT TIME ZONE 'Asia/Shanghai' where productid=v_orderproduct.productid AND accountid=rec.account_id;
							ELSE -- 库存方式, 不分售课奖励。不分
								-- 直接售课奖励
								v_purchase_price := v_product.pricingschedule ->> concat(rec.account_type,'-course-purchase-price');-- 获取进货价
								IF v_purchase_price IS NULL THEN
									raise exception 'parameter not found: %. Product:%',concat(rec.account_type,'-course-purchase-price'),v_product.id;
								END IF;
								v_award := v_orderproduct.actualprice - v_purchase_price; -- commission是实际价格减去进货价
								-- 写余额，step 1 写售课奖励
								IF v_award!=0 THEN
									update account set balance = balance+v_award WHERE id=rec.account_id returning balance into tmp_balanceafter;	
									insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype) 
										values('售课奖励',order_id,v_orderproduct.id,rec.account_id,v_award,tmp_balanceafter,'balance');		
								END IF;					
								--写余额，step 2 转化订单奖励，给到v_sales_account 
								IF v_conversion_award!=0 AND (v_order.paymentmethod IS NULL or v_order.paymentmethod::text not in ('inventory_agent','inventory_student')) THEN
									update account set balance = balance+v_conversion_award WHERE id=v_sales_account returning balance into tmp_balanceafter;	
									-- 操作余额变动,记录时间为原时间+1毫秒
									insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
										values('转化订单奖励',order_id,v_orderproduct.id,v_sales_account,v_conversion_award,tmp_balanceafter,'balance',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond');
								END IF;
							END IF;
							-- 写余额，step 3 pendingreturn>0时，返还意向金
							IF v_return > 0 AND v_earnest_return != 0 THEN
								update account set balance=balance+v_earnest_return, pendingreturn=pendingreturn-v_earnest_return WHERE id=rec.account_id returning balance,pendingreturn into tmp_balanceafter,tmp_balanceafter_reverse;	
								-- 操作余额变动,记录时间为原时间+2毫秒
								insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
									values('意向金返还(余额)',order_id,v_orderproduct.id,rec.account_id,v_earnest_return,tmp_balanceafter,'balance',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond');
								insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
									values('意向金返还(剩余意向金)',order_id,v_orderproduct.id,rec.account_id,-v_earnest_return,tmp_balanceafter_reverse,'pendingreturn',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond');
								-- ！！！ 不管意向金是否还完，下级售课了就可以返回解锁三单循环的金额（即使是负数的也接着扣）
								update triplecycleaward set pendingreturn=pendingreturn-v_earnest_return,lastorderid=order_id,updatedat=NOW() AT TIME ZONE 'Asia/Shanghai' 
									where linkedaccountid=v_direct_upstream_account;
							END IF;

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
							IF v_award!=0 THEN
								update account set balance = balance+v_award WHERE id=rec.account_id returning balance into tmp_balanceafter;	
								insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype) 
									values('售课跨级奖励',order_id,v_orderproduct.id,rec.account_id,v_award,tmp_balanceafter,'balance');
							END IF;
							IF v_return > 0 AND v_earnest_return != 0 THEN-- 跨级意向金返还
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
					IF rec.row_num >=3 AND rec.row_num <= (v_award_extension_level+2) AND v_extend_award!=0 THEN -- 层级小于7时且扩展奖不为0时，扩展奖
						IF v_partition IS NULL THEN
							RAISE EXCEPTION '账号分区设置，请联系核实。';
						ELSIF v_partition='L' THEN
							update account set balanceleft = balanceleft+v_extend_award WHERE id=rec.account_id returning balanceleft into tmp_balanceafter;	
						ELSE
							update account set balanceright = balanceright+v_extend_award WHERE id=rec.account_id returning balanceright into tmp_balanceafter;	
						END IF;
						insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype) 
							values(concat('售课扩展奖:',v_partition,'区'),order_id,v_orderproduct.id,rec.account_id,v_extend_award,tmp_balanceafter,(partition_balancetype->>v_partition::TEXT)::accountbalancetype);
						insert into partitionaward(accountid,salesaccountid,orderid,amount,partition) values(rec.account_id,v_direct_upstream_account,order_id,v_extend_award,v_partition);
						RAISE NOTICE '-- 扩展奖:% 金额:% x % = % ,分区:% 奖励发放状态:%|%',rec.account_name,v_award_z,v_award_z_ratio,v_extend_award,v_partition,award_layer,is_indirect_awarded;
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



CREATE OR REPLACE FUNCTION public.get_max_inventory_quantity(account_id uuid, product_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE 
    v_account record;
	v_product record;
	v_purchase_price numeric(10,2);
	v_quantity int;
begin
	raise notice '====begin get_max_inventory_quantity(account_id uuid,product_id uuid)====';
	select * into v_account from account where id=account_id;
	select * into v_product from get_product(v_account.id,product_id);--product where id=product_id;
	v_purchase_price := (v_product.pricingschedule->>concat(v_account.type,'-course-purchase-price'))::numeric(10,2) - (v_product.pricingschedule->>'conversion-award')::numeric(10,2);-- 获取进货价
	raise notice 'purchase price:%',v_purchase_price;
	v_quantity := (v_account.balance + least(v_account.balanceleft,v_account.balanceright)*2 +  v_account.balancetriple) / v_purchase_price;
 	raise notice '====end get_max_inventory_quantity()====';	
	RETURN v_quantity;
END; $function$
;



CREATE OR REPLACE FUNCTION public.get_order_price(order_id bigint)
 RETURNS numeric
 LANGUAGE plpgsql
AS $function$
DECLARE 
    var_orderproduct record;
    var_product_finalprice  decimal(10,2);
    var_student_id UUID;
    var_discount decimal(10,2);
    var_sumprice decimal(10,2) := 0;
	v_direct_agent_id uuid;
begin
 raise notice '====begin====';
 select studentid into var_student_id from orders where id=order_id;
 select upstreamaccount into v_direct_agent_id from account where id=var_student_id;
 for var_orderproduct in (select id,productid,couponcode from orderproduct where orderid=order_id)
 loop 
  raise notice 'productid: %',var_orderproduct.productid;
  select finalprice into var_product_finalprice from get_product(v_direct_agent_id,var_orderproduct.productid);--product where id=var_orderproduct.productid;
  var_discount := 0;
  if var_orderproduct.couponcode is not null then --有优惠券的时候，设置优惠金额，否则优惠为0
   select discountamount into var_discount from ordercoupon where code=var_orderproduct.couponcode;
  end if; 
  var_sumprice := var_sumprice + var_product_finalprice - var_discount;
  raise notice 'sumprice: % | discount: %',var_sumprice,var_discount;

 end loop;
 raise notice '====end====';
RETURN var_sumprice;
END; $function$
;




