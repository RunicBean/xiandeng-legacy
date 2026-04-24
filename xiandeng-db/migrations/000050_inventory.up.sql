INSERT INTO datadictionary ("key", value, "namespace") VALUES('STUDENT', '学员', 'entitytype');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('HEAD_QUARTER', '总部', 'entitytype');

CREATE TYPE public."inventoryordertype" AS ENUM (
	'hq_initiated',
	'from_balance',
	'agent_topup');

CREATE TYPE public."inventoryorderstatus" AS ENUM (
	'pending',
	'declined',
	'paid',
	'settled');
	
CREATE TABLE public.inventoryorder (
	id bpchar(16) NOT NULL,
	accountid uuid NOT NULL,
	productid uuid NOT NULL,
	quantity int4 NOT NULL,
	"type" public."inventoryordertype" NOT NULL,
	lastoperateuserid uuid NULL,
	status public."inventoryorderstatus" NOT NULL,
	paymentmethod varchar(255) NULL,
	unitprice numeric(8, 2) NULL,
	payat timestamp NULL,
	settledat timestamp NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT inventoryorder_pkey PRIMARY KEY (id),
	CONSTRAINT fk_inventoryorder_account FOREIGN KEY (accountid) REFERENCES public.account(id),
	CONSTRAINT fk_inventoryorder_operateuser FOREIGN KEY (lastoperateuserid) REFERENCES public.users(id),
	CONSTRAINT fk_inventoryorder_product FOREIGN KEY (productid) REFERENCES public.product(id)
);

ALTER TABLE public.balanceactivity ADD COLUMN inventoryorderid bpchar(16);
ALTER TABLE public.balanceactivity ADD CONSTRAINT fk_balanceactivity_inventoryorder FOREIGN KEY (inventoryorderid) REFERENCES public.inventoryorder(id);

CREATE TABLE public.productinventory (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	accountid uuid NOT NULL,
	productid uuid NOT NULL,
	quantity int4 NOT NULL,
	lastinventoryorderid bpchar(16) NULL,
	lastorderid int8 NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT productinventory_pkey PRIMARY KEY (id),
	CONSTRAINT fk_productinventory_account FOREIGN KEY (accountid) REFERENCES public.account(id),
	CONSTRAINT fk_productinventory_inventoryorder FOREIGN KEY (lastinventoryorderid) REFERENCES public.inventoryorder(id),
	CONSTRAINT fk_productinventory_orders FOREIGN KEY (lastorderid) REFERENCES public.orders(id),
	CONSTRAINT fk_productinventory_product FOREIGN KEY (productid) REFERENCES public.product(id)
);
CREATE UNIQUE INDEX idx_unique_productinventory ON public.productinventory USING btree (accountid, productid);


CREATE TABLE public.inventoryorderproof (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	inventoryorderid bpchar(16) NOT NULL,
	imageurl text NOT NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT pk_inventoryorderproof PRIMARY KEY (id),
	CONSTRAINT fk_inventoryorderproof_inventoryorder FOREIGN KEY (inventoryorderid) REFERENCES public.inventoryorder(id)
);
CREATE UNIQUE INDEX idx_unique_inventoryorderproof ON public.inventoryorderproof USING btree (inventoryorderid, imageurl);


CREATE TABLE public.franchiseorderproof (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	franchiseorderid uuid NOT NULL,
	imageurl text NOT NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT pk_franchiseorderproof PRIMARY KEY (id),
	CONSTRAINT fk_franchiseorderproof_franchiseorder FOREIGN KEY (franchiseorderid) REFERENCES public.franchiseorder(id)
);
CREATE UNIQUE INDEX idx_unique_franchiseorderproof ON public.franchiseorderproof USING btree (franchiseorderid, imageurl);


CREATE TABLE public.productinventoryhistory (
	id serial4 NOT NULL,
	sourceid uuid NOT NULL,
	quantity int4 NOT NULL,
	inventoryorderid bpchar(16) NULL,
	orderid int8 NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT productinventoryhistory_pkey PRIMARY KEY (id),
	CONSTRAINT productinventoryhistory_sourceid_fkey FOREIGN KEY (sourceid) REFERENCES public.productinventory(id)
);


CREATE OR REPLACE FUNCTION public.audit_productinventory()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Insert a new row into productinventoryhistory with relevant details
    INSERT INTO public.productinventoryhistory (
        sourceid, 
        quantity, 
        inventoryorderid, 
		orderid,
        createdat
    ) VALUES (
        NEW.id, 
        NEW.quantity, 
        NEW.lastinventoryorderid, 
		NEW.lastorderid,
        NOW() AT TIME ZONE 'Asia/Shanghai'
    );
    RETURN NEW;
END;
$function$
;


create trigger audit_productinventory_trigger after
insert
    or
update
    on
    public.productinventory for each row execute function audit_productinventory();

CREATE OR REPLACE FUNCTION public.get_max_inventory_quantity(account_id uuid, product_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE 
    v_account record;
	v_product record;
	v_purchase_price numeric(8,2);
	v_quantity int;
begin
	raise notice '====begin get_max_inventory_quantity(account_id uuid,product_id uuid)====';
	select * into v_account from account where id=account_id;
	select * into v_product from product where id=product_id;
	v_purchase_price := v_product.pricingschedule ->> concat(v_account.type,'-course-purchase-price');-- 获取进货价
	raise notice 'purchase price:%',v_purchase_price;
	v_quantity := (v_account.balance + least(v_account.balanceleft,v_account.balanceright)*2 +  v_account.balancetriple) / v_purchase_price;
 	raise notice '====end get_max_inventory_quantity()====';	
	RETURN v_quantity;
END; $function$
;

CREATE OR REPLACE FUNCTION public.set_id()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    new_id CHAR(16);
    cur_date TEXT;
    random_num TEXT;
    check_sql TEXT;
    target_table TEXT;
    prefix bpchar(2);
BEGIN
    -- Access the table name and prefix from TG_ARGV
    target_table := TG_ARGV[0];
    prefix := TG_ARGV[1];

    -- If the id is not provided, generate a new one
    IF NEW.id IS NULL THEN
        cur_date := TO_CHAR(NOW() AT TIME ZONE 'Asia/Shanghai', 'YYYYMMDD');
        random_num := LPAD((FLOOR(RANDOM() * 1000000)::TEXT), 6, '0');
        new_id := prefix || cur_date || random_num;

        -- Ensure uniqueness
        LOOP
            -- Build a dynamic SQL to check if the ID already exists
            check_sql := 'SELECT 1 FROM ' || quote_ident(target_table) || ' WHERE id=' || quote_literal(new_id);
            
            -- Execute the SQL statement using EXECUTE with a parameter
            EXECUTE check_sql INTO NEW.id USING new_id;

            -- If not found, exit the loop
            EXIT WHEN NOT FOUND;

            -- If found, regenerate the id
            random_num := LPAD((FLOOR(RANDOM() * 1000000)::TEXT), 6, '0');
            new_id := prefix || cur_date || random_num;
        END LOOP;

        -- Assign the new_id to the NEW record
        NEW.id := new_id;
    END IF;

    RETURN NEW;
END;
$function$
;



CREATE TRIGGER set_inventoryorder_id_trigger
BEFORE INSERT ON inventoryorder
FOR EACH ROW
EXECUTE FUNCTION set_id('inventoryorder', 'IO');


drop trigger before_insert_withdraw on withdraw;


CREATE TRIGGER set_withdraw_id_trigger
BEFORE INSERT ON withdraw
FOR EACH ROW
EXECUTE FUNCTION set_id('withdraw', 'T');

DROP FUNCTION public.generate_and_set_withdraw_id();

CREATE OR REPLACE FUNCTION public.set_inventory_unitprice()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_account RECORD;
	v_product RECORD;
BEGIN
	raise notice '====begin set_inventory_unitprice()====';
	IF EXISTS (SELECT FROM withdraw where accountid=NEW.accountid and status::text in ('LOCKED','REQUESTED')) THEN
		raise exception 'Blocked buying inventory, as ongoing withdraw detected.';
	END IF;
	select type into v_account from account where id=NEW.accountid;
	select pricingschedule into v_product from product where id=NEW.productid;
	NEW.unitprice := v_product.pricingschedule ->> concat(v_account.type,'-course-purchase-price');-- 获取进货价

	raise notice '====end set_inventory_unitprice()====';
    RETURN NEW;
END;
$function$
;



CREATE TRIGGER set_inventory_unitprice_trigger
BEFORE INSERT ON inventoryorder
FOR EACH ROW
EXECUTE FUNCTION set_inventory_unitprice();

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
					raise exception 'Not enough balance. Price:% BEFORE: Balance:% balancetriple:% balanceleft:% balanceright:% AFTER: Balance:% balancetriple:% balanceleft:% balanceright:%',v_remaining_price,v_account.balance,v_account.balancetriple,v_account.balanceleft,v_account.balanceright,v_account_after.balance,v_account_after.balancetriple,v_account_after.balanceleft,v_account_after.balanceright;
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


CREATE TRIGGER add_inventory_trigger
AFTER INSERT ON inventoryorder
FOR EACH ROW
EXECUTE FUNCTION add_inventory();


CREATE OR REPLACE FUNCTION public.validate_withdraw()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_account RECORD;
BEGIN
    -- Fetch the account balances
    SELECT balance,balanceleft,balanceright,balancetriple INTO v_account FROM account WHERE id = NEW.accountid;
    
	IF EXISTS (SELECT FROM inventoryorder WHERE accountid=NEW.accountid and status::text in ('pending')) THEN
		RAISE EXCEPTION 'Blocked withdraw, as on-going inventory purchase is detected.';
    ELSIF NEW.type::text = 'balance' AND NEW.amount > v_account.balance THEN
        RAISE EXCEPTION 'Cannot withdraw an amount greater than account balance.';
    ELSIF NEW.type::text = 'partition' AND NEW.amount > LEAST(v_account.balanceleft,v_account.balanceright) THEN
        RAISE EXCEPTION 'Cannot withdraw an amount greater than the minimum of balanceleft and balanceright.';
    ELSIF NEW.type::text = 'triple' AND NEW.amount > v_account.balancetriple THEN
        RAISE EXCEPTION 'Cannot withdraw an amount greater than balancetriple.';
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.confirm_inventory(inventoryorder_id character)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_inventoryorder RECORD;
	v_remaining_price numeric(8,2);
	v_account RECORD;
	v_account_after RECORD;
BEGIN
	raise notice '====begin confirm_inventory(inventoryorder_id character)====';
	SELECT * INTO v_inventoryorder FROM inventoryorder where id=inventoryorder_id;
	IF v_inventoryorder IS NULL THEN
		RAISE EXCEPTION 'Inventoryorder does not exist: %',inventoryorder_id;
 	ELSIF v_inventoryorder.status::text NOT IN ('pending') THEN
        RAISE EXCEPTION 'Inventoryorder state machine transition is not allowed. status: %',v_inventoryorder.status::text;
	ELSIF v_inventoryorder.type::text NOT IN ('agent_topup') THEN
        RAISE EXCEPTION 'Inventoryorder type is not allowed. status: %',v_inventoryorder.type::text;
	END IF;

	--分配库存
	INSERT INTO productinventory (accountid,productid,quantity,lastinventoryorderid,lastorderid)
	VALUES (v_inventoryorder.accountid,v_inventoryorder.productid,v_inventoryorder.quantity,v_inventoryorder.id,null)
	ON CONFLICT (accountid,productid)
	DO UPDATE SET quantity=productinventory.quantity+v_inventoryorder.quantity,lastinventoryorderid=v_inventoryorder.id,lastorderid=null;
	update inventoryorder set status='settled' where id=v_inventoryorder.id;

    RAISE NOTICE '====end confirm_inventory()====';
	RETURN 'success';
END;
$function$
;


ALTER TABLE public.ordercoupon ALTER COLUMN issuinguser DROP NOT NULL;


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
							IF v_order.paymentmethod::text NOT IN ('inventory_agent','inventory_student') THEN -- 库存方式, 不分售课奖励。
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


DROP FUNCTION public.generate_simple_order(uuid, uuid, int8);



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
	elsif coupon_code is not null and payment_method not in ('inventory_agent','inventory_student') then -- 对优惠券进行检查. 库存支付无需检查。
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



CREATE OR REPLACE FUNCTION public.assign_award(franchiseorder_id uuid)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
    rec RECORD;
	v_franchiseorder RECORD;
	v_target_account RECORD;
	v_direct_upstream_account UUID; -- 直接上级（销售账号）
	award_layer smallint:=0;-- 0: not rewarded, 1: lv2 rewarded, 2: lv1 rewarded, 3: hq rewarded
	accounttype_awardlayer JSONB := '{"LV2_AGENT": 1, "LV1_AGENT": 2, "HQ_AGENT": 3}';
	partition_balancetype JSONB := '{"L": "balanceleft", "R": "balanceright"}';
	is_indirect_awarded bool:=false;
	var_tmp_award_amount int:=0;--直属招商奖励金额
	v_accumulated_award int=0;
	v_three_return_award_amount numeric(8,2):=0;--三单循环奖励金额
	v_reward_x float;--三单循环系数
	v_x_unlock numeric(8,2):=0;--三单循环解锁金额
	v_award_y numeric(8,2):=0;
	v_award_y_ratio float;
	v_award_extension_level smallint;
	v_partition accountpartition;
    tmp_balanceafter decimal(8,2);
	tmp_balanceafter_reverse decimal(8,2);
	v_tmp bpchar='';--用于跨级奖励的描述
	v_round int;-- 三单循环中第几轮
	v_seq smallint;-- 三单循环中第几单
	v_number int;--三单循环中的最后一单
BEGIN
	raise notice '====begin assign_award(franchiseorder_id UUID)====';
	SELECT * INTO v_franchiseorder FROM franchiseorder where id=franchiseorder_id;
	IF v_franchiseorder IS NULL THEN
		raise exception 'Franchiseorder does not exist: %',franchiseorder_id;
 	ELSIF v_franchiseorder.status IN ('settled','declined','refunded') THEN
        raise exception 'The order has reached final status: %',v_franchiseorder.status;
	END IF;

	-- get target account detail
	select * INTO v_target_account FROM account where id=v_franchiseorder.accountid;
	select value into v_award_extension_level from datadictionary where key='award-extension-level';--扩展层级
	IF v_award_extension_level IS NULL THEN
		raise exception 'parameter not found: award-extension-level';
	END IF;

	IF EXISTS (select from get_account_chain(v_franchiseorder.accountid) ac, account a where ac.account_id=a.id	and a.id!=v_franchiseorder.accountid and a.type!='HEAD_QUARTER' and a.status!='ACTIVE') THEN--只有上游账号全部是active的情况下，才可以激活账号
		RAISE EXCEPTION '激活失败。上游账号状态异常。';
	elsif exists (select from get_upstreamaccount_chain(v_franchiseorder.accountid)
		where row_num<=(v_award_extension_level+2) and row_num>1 and account_type in ('LV2_AGENT','LV1_AGENT','HQ_AGENT') and account_partition is null 
		and (SELECT type from account where id=account_upstreamaccount)!='HEAD_QUARTER') then -- 排除掉直接上级是总部的账号
		RAISE EXCEPTION '付款失败。分区设定异常。';
	ELSIF (v_target_account.status='INIT' and v_franchiseorder.originaltype IS NOT NULL) OR (v_target_account.status='ACTIVE' and v_franchiseorder.originaltype IS NULL) THEN
		RAISE EXCEPTION '激活失败。账号设定冲突.状态:% 原账户类型:%',v_target_account.status,v_franchiseorder.originaltype;
	END IF;

	--进行初始参数设定	
	select value into v_award_y_ratio from datadictionary where key=concat('','award-y-ratio');--扩展奖比例
	IF v_award_y_ratio IS NULL THEN
		raise exception 'parameter not found: award-y-ratio';
	END IF;
	-- 设定三单循环和扩展奖的基数。升级账号不是差额，而是补交全额。
	select value into v_award_y from datadictionary where key=concat(v_franchiseorder.targettype,'-award-y');
	IF v_award_y IS NULL THEN
		raise exception 'parameter not found: %',concat(v_franchiseorder.targettype,'-award-y');
	END IF;
	select value into v_three_return_award_amount from datadictionary where key=concat(v_franchiseorder.targettype,'-award-x');	
	IF v_three_return_award_amount IS NULL THEN
		raise exception 'parameter not found: %',concat(v_franchiseorder.targettype,'-award-x');
	END IF;
	select value into v_x_unlock from datadictionary where key=concat(v_franchiseorder.targettype,'-x-unlock');	
	IF v_x_unlock IS NULL THEN
		raise exception 'parameter not found: %',concat(v_franchiseorder.targettype,'-x-unlock');
	END IF;

    FOR rec IN select * from get_upstreamaccount_chain(v_franchiseorder.accountid)
 	LOOP
        --raise notice 'row:% | id:% | type:% |name:% |%',rec.row_num,rec.account_id,rec.account_type,rec.account_name,is_indirect_awarded;
		IF (award_layer=3 and is_indirect_awarded) OR rec.account_type='HEAD_QUARTER' THEN
			RAISE NOTICE '--exist loop';
			EXIT; -- exist the loop when all awards are distributed
		END IF;
		IF rec.account_id=v_franchiseorder.accountid THEN -- 加盟的商户
			RAISE NOTICE '-- 加盟商:% %',rec.account_name,v_franchiseorder.targettype;
		ELSE -- 上级
			--判断是否属于 直属招商奖励
			IF (award_layer<3 AND rec.account_type='HQ_AGENT') OR (award_layer<2 AND rec.account_type='LV1_AGENT') OR (award_layer<1 AND rec.account_type='LV2_AGENT') OR rec.row_num=2 THEN	
				IF rec.row_num=2 THEN -- 直属上级
					v_direct_upstream_account := rec.account_id;
					-- 三单循环奖励					
					RAISE NOTICE '--三单循环基数:%',v_three_return_award_amount;
					select coalesce(max(number),0) into v_number from triplecycleaward where accountid=rec.account_id;--从三单循环历史表里获取最后一单是第几轮第几单
					select value into v_reward_x from datadictionary where key=concat('award-mod-',(v_number%3+1)::text);
					IF v_reward_x IS NULL THEN
						raise exception 'parameter not found: %',concat('award-mod-',(v_number%3+1)::text);
					END IF;
					RAISE NOTICE '--三单循环系数:%',v_reward_x;
					v_three_return_award_amount:=v_three_return_award_amount*v_reward_x;
					-- 写余额 Step 1: 三单循环
					if v_three_return_award_amount!=0 then
						update account set balancetriplelock = balancetriplelock+v_three_return_award_amount WHERE id=rec.account_id returning balancetriplelock into tmp_balanceafter;	
						insert into balanceactivity(source,franchiseorderid,accountid,amount,balanceafter,balancetype) 
							values(concat('招商三单循环奖励 (第',(v_number/3+1)::text,'轮第',(v_number%3+1)::text,'单，系数:',v_reward_x::text,')'),franchiseorder_id,rec.account_id,v_three_return_award_amount,tmp_balanceafter,'balancetriplelock');
					end if;
					-- 同时更新冗余表，方便记录第几轮第几单，以及方便后续查询
					insert into triplecycleaward(accountid,number,linkedaccountid,originaltype,targettype,amount,pendingreturn,franchiseorderid) values(rec.account_id,v_number+1,v_franchiseorder.accountid,v_franchiseorder.originaltype,v_franchiseorder.targettype,v_three_return_award_amount,v_x_unlock,franchiseorder_id);
					RAISE NOTICE '--三单循环奖励:% 金额:%',rec.account_name,v_three_return_award_amount;
				END IF;
				-- 直属招商奖励
				select value into var_tmp_award_amount from datadictionary where key=concat(rec.account_type,'-',v_franchiseorder.targettype,'-direct-award');
				IF var_tmp_award_amount IS NULL THEN
					raise exception 'parameter not found: %',concat(rec.account_type,'-',v_franchiseorder.targettype,'-direct-award');
				END IF;
				var_tmp_award_amount:=var_tmp_award_amount-v_accumulated_award;
				v_accumulated_award=v_accumulated_award+var_tmp_award_amount;
				-- 写余额，记录时间为原时间+1毫秒
				if var_tmp_award_amount!=0 then
					update account set balance = balance+var_tmp_award_amount WHERE id=rec.account_id returning balance into tmp_balanceafter;	
					if rec.row_num>2 THEN v_tmp := '跨级'; END IF; --跨级奖励的描述
					insert into balanceactivity(source,franchiseorderid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
						values(concat('直属招商',v_tmp,'奖励'),franchiseorder_id,rec.account_id,var_tmp_award_amount,tmp_balanceafter,'balance',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond');
				end if;
				--设置发放奖励状态
				award_layer := (accounttype_awardlayer->>rec.account_type)::NUMERIC;				
				RAISE NOTICE '-- 直属招商奖励:% 金额:%. 奖励发放状态:%|%',rec.account_name,var_tmp_award_amount,award_layer,is_indirect_awarded;
			END IF;
			
			IF rec.row_num >=3 AND rec.row_num <= (v_award_extension_level+2) AND (v_award_y*v_award_y_ratio)::numeric(8,2)!=0 THEN -- 层级小于7时，扩展奖
				IF v_partition IS NULL THEN
					RAISE EXCEPTION '管理职未进行分区设置，请联系核实。';
				ELSIF v_partition='L' THEN
					update account set balanceleft = balanceleft+(v_award_y*v_award_y_ratio)::numeric(8,2) WHERE id=rec.account_id returning balanceleft into tmp_balanceafter;	
				ELSE 
					update account set balanceright = balanceright+(v_award_y*v_award_y_ratio)::numeric(8,2) WHERE id=rec.account_id returning balanceright into tmp_balanceafter;	
				END IF;
				insert into balanceactivity(source,franchiseorderid,accountid,amount,balanceafter,balancetype) 
					values(concat('招商扩展奖:',v_partition,'区'),franchiseorder_id,rec.account_id,(v_award_y*v_award_y_ratio)::numeric(8,2),tmp_balanceafter,(partition_balancetype->>v_partition::TEXT)::accountbalancetype);
				insert into partitionaward(accountid,salesaccountid,linkedaccountid,amount,partition,franchiseorderid) values(rec.account_id,v_direct_upstream_account,v_franchiseorder.accountid,(v_award_y*v_award_y_ratio)::numeric(8,2),v_partition,franchiseorder_id);
				RAISE NOTICE '-- 扩展奖:% 金额:% x % = % ,分区:% 奖励发放状态:%|%',rec.account_name,v_award_y,v_award_y_ratio,v_award_y*v_award_y_ratio,v_partition,award_layer,is_indirect_awarded;
			ELSIF rec.row_num > (v_award_extension_level+2) THEN--层级大于8，设置奖励发放状态
				is_indirect_awarded:=true;
			END IF;
			-- 非加盟的商户时，获取分区，作为下一次循环（上级）的左右分区。这个动作必须在本层完成完成分账之后，给下一层用。
			select partition into v_partition from account where id=rec.account_id;
		END IF;
    END LOOP;

	IF v_franchiseorder.originaltype IS NULL THEN -- 新加盟商户
		update account set status='ACTIVE',updatedat=NOW() AT TIME ZONE 'Asia/Shanghai' where id=v_franchiseorder.accountid;
	ELSE -- 升级商户
		update account set type=v_franchiseorder.targettype,updatedat=NOW() AT TIME ZONE 'Asia/Shanghai' where id=v_franchiseorder.accountid;
	END IF;
	update franchiseorder set pendingfee=0,status='settled',updatedat=NOW() AT TIME ZONE 'Asia/Shanghai' where id=franchiseorder_id;

    RAISE NOTICE '====end assign_award()====';
	RETURN 'success';
END;
$function$
;


CREATE UNIQUE INDEX uniq_ordercoupon_index 
ON public.ordercoupon (
  agentid, 
  issuinguser, 
  discountamount, 
  maxcount, 
  productid, 
  studentid, 
  effectstartdate, 
  effectduedate
);
