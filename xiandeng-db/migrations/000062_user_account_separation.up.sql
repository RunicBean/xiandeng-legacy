
CREATE TYPE public."roletype" AS ENUM (
	'HQ',
	'AGENT',
	'STUDENT');

ALTER TABLE public.account ALTER COLUMN pendingreturn SET DEFAULT 0;

drop table public.role;

CREATE TABLE public.roles (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	rolename varchar(255) not NULL,
	accountkind public."roletype" NOT NULL,
	issystem bool not NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT role_pkey PRIMARY KEY (id)
);

INSERT INTO roles (id, rolename, accountkind, issystem) VALUES('5fcf5356-3cf2-422b-9800-97f27fe76532'::uuid, 'OWNER', 'HQ'::public."roletype", true);
INSERT INTO roles (id, rolename, accountkind, issystem) VALUES('8d6425cd-b375-4c4d-bf28-87f6796b5ccd'::uuid, 'ADMIN', 'HQ'::public."roletype", true);
INSERT INTO roles (id, rolename, accountkind, issystem) VALUES('b40f55b8-1810-4557-8ff5-2a32b889cdb6'::uuid, 'OWNER', 'AGENT'::public."roletype", true);
INSERT INTO roles (id, rolename, accountkind, issystem) VALUES('d7c16cdb-86c7-4956-8326-43164f90a15d'::uuid, 'ADMIN', 'AGENT'::public."roletype", true);
INSERT INTO roles (id, rolename, accountkind, issystem) VALUES('241f0967-01ad-4a32-8876-733af187dd78'::uuid, 'STUDENT', 'STUDENT'::public."roletype", true);
INSERT INTO roles (id, rolename, accountkind, issystem) VALUES('023d6e7e-82e7-4055-82d1-70b839f1266c'::uuid, 'GUARDIAN_PRIMARY', 'STUDENT'::public."roletype", true);
INSERT INTO roles (id, rolename, accountkind, issystem) VALUES('909286fd-68ce-4784-b647-5170df550da6'::uuid, 'GUARDIAN_SUPPLEMENT', 'STUDENT'::public."roletype", true);


CREATE TABLE public.useraccountrole (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	userid uuid NOT NULL,
	accountid uuid NOT NULL,
	roleid uuid NOT NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT useraccountrole_pkey PRIMARY KEY (id),
	CONSTRAINT useraccountrole_userid_fkey FOREIGN KEY (userid) REFERENCES public.users(id),
	CONSTRAINT useraccountrole_roleid_fkey FOREIGN KEY (roleid) REFERENCES public.roles(id),
	CONSTRAINT useraccount_accountid_fkey FOREIGN KEY (accountid) REFERENCES public.account(id)
);

CREATE INDEX idx_useraccountrole_userid ON public.useraccountrole (userid);
CREATE INDEX idx_useraccountrole_roleid ON public.useraccountrole (roleid);
CREATE INDEX idx_useraccountrole_accountid ON public.useraccountrole (accountid);
CREATE UNIQUE INDEX idx_useraccountrole_account_user_role ON public.useraccountrole (accountid, userid, roleid);

 

CREATE OR REPLACE FUNCTION public.enforce_role_constraints()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    existing_count INTEGER;
    rolename TEXT;
    accountkind roletype;
BEGIN
    -- Retrieve the role details for the new/updated user role
    SELECT r.rolename, r.accountkind
    INTO rolename, accountkind
    FROM roles r
    WHERE r.id = NEW.roleid;

    -- Ensure we're working with a valid role description
    IF rolename IS NULL THEN
        RAISE EXCEPTION 'Role ID % not found in roles table', NEW.roleid;
    END IF;

    -- Check when accountkind is 'STUDENT' and rolename is 'STUDENT'
    IF accountkind = 'STUDENT' AND rolename = 'STUDENT' THEN
        SELECT COUNT(*)
        INTO existing_count
        FROM useraccountrole uar
        JOIN roles r ON uar.roleid = r.id
        WHERE uar.accountid = NEW.accountid
          AND r.accountkind = 'STUDENT'
          AND r.rolename = 'STUDENT';

        IF existing_count > 0 THEN
            RAISE EXCEPTION 'Operation blocked: A STUDENT role already exists for this account.';
        END IF;
    END IF;

    -- Check when accountkind is 'STUDENT' and rolename is 'GUARDIAN_PRIMARY'
    IF accountkind = 'STUDENT' AND rolename = 'GUARDIAN_PRIMARY' THEN
        SELECT COUNT(*)
        INTO existing_count
        FROM useraccountrole uar
        JOIN roles r ON uar.roleid = r.id
        WHERE uar.accountid = NEW.accountid
          AND r.accountkind = 'STUDENT'
          AND r.rolename = 'GUARDIAN_PRIMARY';

        IF existing_count > 0 THEN
            RAISE EXCEPTION 'Operation blocked: A GUARDIAN_PRIMARY role already exists for this account.';
        END IF;
    END IF;

    -- Check when accountkind is in ('HQ', 'AGENT') and rolename is 'OWNER'
    IF accountkind IN ('HQ', 'AGENT') AND rolename = 'OWNER' THEN
        SELECT COUNT(*)
        INTO existing_count
        FROM useraccountrole uar
        JOIN roles r ON uar.roleid = r.id
        WHERE uar.accountid = NEW.accountid
          AND r.accountkind IN ('HQ', 'AGENT')
          AND r.rolename = 'OWNER';

        IF existing_count > 0 THEN
            RAISE EXCEPTION 'Operation blocked: An OWNER role already exists for this account in HQ or AGENT.';
        END IF;
    END IF;

    -- 一个user不能同时加入两个学员账号
    IF accountkind = 'STUDENT' THEN
        SELECT COUNT(*)
        INTO existing_count
        FROM useraccountrole uar
        JOIN roles r ON uar.roleid = r.id
        WHERE uar.userid = NEW.userid
          AND r.accountkind = 'STUDENT';

        IF existing_count > 0 THEN
            RAISE EXCEPTION 'Operation blocked: A user cannot join more than 1 student account.';
        END IF;
    END IF;

    -- 一个user不能同时加入两个代理账号
    IF accountkind IN ('HQ', 'AGENT') THEN
        SELECT COUNT(*)
        INTO existing_count
        FROM useraccountrole uar
        JOIN roles r ON uar.roleid = r.id
        WHERE uar.userid = NEW.userid
          AND r.accountkind IN ('HQ', 'AGENT');

        IF existing_count > 0 THEN
            RAISE EXCEPTION 'Operation blocked: A user cannot join more than 1 agent account.';
        END IF;
    END IF;


    -- If none of the conditions block the operation, allow it
    RETURN NEW;
END;
$function$
;



CREATE TRIGGER check_user_role_constraints
BEFORE INSERT OR UPDATE ON useraccountrole
FOR EACH ROW
EXECUTE FUNCTION enforce_role_constraints();


ALTER TABLE public.agentattribute
DROP COLUMN liuliuqrcode,
DROP COLUMN liuliustoreaddress,
DROP COLUMN couponinputenabled;


CREATE TYPE public.new_user_acount AS (
	userid uuid,
	acocuntid uuid);


ALTER TABLE public.users DROP CONSTRAINT users_accountid_fkey;

drop view if exists v_studentdetails;

drop view if exists v_users;

-- ALTER TABLE public.users DROP COLUMN accountid;

DROP TRIGGER trigger_insert_invitation_codes ON public.users;

DROP FUNCTION public.insert_invitation_codes();

CREATE OR REPLACE FUNCTION public.check_and_insert_invitationcode(p_userid uuid)
 RETURNS TABLE(o_code character, o_userid uuid, o_accountid uuid, o_createtype entitytype)
 LANGUAGE plpgsql
AS $function$
DECLARE
    code_type public."entitytype";
    random_code char(13);
	v_accountid uuid;
BEGIN
        -- Enumerate through the code types excluding 'HEAD_QUARTER'
    FOR code_type IN SELECT unnest(enum_range(NULL::public."entitytype"))
                     EXCEPT SELECT 'HEAD_QUARTER'::public."entitytype"
    LOOP

    	IF NOT EXISTS (SELECT FROM public.invitationcode WHERE userid=p_userid AND createtype=code_type) THEN
            -- Generate a random 13-character uppercase code
            random_code := (
                SELECT string_agg(chr(65 + floor(random() * 26)::integer), '')
                FROM generate_series(1, 13)
            );

            -- Insert the new invitation code
			select accountid into v_accountid from useraccountrole uar,roles r where uar.roleid=r.id and userid=p_userid AND r.accountkind in ('HQ','AGENT');
            INSERT INTO public.invitationcode (code, userid, accountid, createtype)
            VALUES (random_code, p_userid,  v_accountid, code_type);
        END IF;
    END LOOP;

    -- Return all records from invitationcode table for the given userid
    RETURN QUERY
    SELECT code, userid, accountid, createtype
    FROM public.invitationcode
    WHERE userid = p_userid;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.register_user(invitation_code varchar(13),exist_account_id uuid,u_phone varchar(255),nick_name varchar(255),open_id varchar(255),account_name varchar(255),u_password varchar(65535),u_relationship varchar(255),u_email varchar(255),u_source varchar(255),invite_userid varchar(255))
 RETURNS new_user_acount
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_invitation RECORD;
	v_exist_account RECORD;
	v_new_userid uuid;
	v_invitation_type entitytype; -- 不管新建or加入，最终的account type
	v_password varchar(65535); -- 不管新建or加入，最终的password
	v_invite_userid uuid; -- 不管新建or加入，最终的邀请用户
	v_roleid uuid;
	v_accountid uuid; -- 不管新建or加入，最终的accountid
    code_type public."entitytype";
    random_code CHAR(13);
BEGIN
	RAISE NOTICE '====begin register_user(invitation_code varchar(13),exist_account_id uuid,u_phone varchar(255),nick_name varchar(255),open_id varchar(255),account_name varchar(255),u_password varchar(65535),u_relationship varchar(255),u_email varchar(255),u_source varchar(255),invite_userid varchar(255))====';
	RAISE NOTICE 'input param: invitation_code:%, u_phone:%, nick_name:%, open_id:%, account_name:%, u_password:%, u_relationship:%, u_email:%, exist_account_id:%, u_source:%, invite_userid:%'
		,invitation_code,u_phone,nick_name,open_id,account_name,u_password,u_relationship,u_email,exist_account_id, u_source, invite_userid;
	-- 如果exist_account_id非空，则是加入账号，否则新建。
	-- exist_account时，要填入invite_userid. 通过code新建时，invite_user自动填入invitationcode中的userid
	-- 如果account对应学生，u_relationship非空，则是家长，否则学生
	-- 输出：如果accountid不为空，是新建账号。否则是加入账号
	-- 输出：如果userid为空，则没有创建成功

	SELECT * INTO v_invitation FROM invitationcode WHERE code=invitation_code;
	v_password := u_password;
	IF v_invitation IS NULL AND exist_account_id IS NULL THEN
		raise exception 'Invitation code & exist account are both empty.';
	ELSIF v_invitation IS NOT NULL AND exist_account_id IS NOT NULL THEN -- 如果同时有邀请码 和 exist account id，以后者为准
		v_invitation := NULL;
	ELSIF u_phone IS NULL THEN
		raise exception '手机号为必填项。';
	ELSIF nick_name IS NULL THEN
		raise exception '昵称不可为空。';
	ELSIF open_id IS NULL THEN
		raise exception 'openid不可为空。';
	ELSIF exists (select from users where phone=u_phone) THEN
		raise exception '手机号已注册。号码:%',u_phone;
	ELSIF exists (select from users where wechatopenid=open_id) THEN
		raise exception '微信号已注册。Open Id:%',open_id;
	END IF;
	IF exist_account_id IS NOT NULL THEN -- 加入已有账号
		SELECT id,type INTO v_exist_account FROM account WHERE id=exist_account_id;
		IF v_exist_account IS NULL THEN
			raise exception '待加入的账号不存在。Account:%',exist_account_id;
		END IF;
		v_invitation_type := v_exist_account.type;
		v_invite_userid := invite_userid;
		v_accountid :=  v_exist_account.id;

		-- 设置role 和 附加属性
		IF v_invitation_type in ('HQ_AGENT','LV1_AGENT','LV2_AGENT') THEN
			SELECT id INTO v_roleid FROM roles WHERE rolename='ADMIN' AND accountkind='AGENT';
		ELSIF v_invitation_type = 'HEAD_QUARTER' THEN -- 只有加入已有账号时，才会有总部
			SELECT id INTO v_roleid FROM roles WHERE rolename='ADMIN' AND accountkind='HQ';
		ELSIF u_relationship IS NULL THEN -- 如果没有relationship，则是学生. (同一账号多个学生的情况不用检查，enforce_role_constraints 会检查
			SELECT id INTO v_roleid FROM roles WHERE rolename='STUDENT' AND accountkind='STUDENT';
		ELSIF NOT EXISTS (SELECT FROM useraccountrole uar,roles r WHERE uar.roleid=r.id AND uar.accountid=v_accountid and r.rolename='GUARDIAN_PRIMARY') THEN -- 家长账号
			SELECT id INTO v_roleid FROM roles WHERE rolename='GUARDIAN_PRIMARY' AND accountkind='STUDENT';	
		ELSE 
			SELECT id INTO v_roleid FROM roles WHERE rolename='GUARDIAN_SUPPLEMENT' AND accountkind='STUDENT';				
		END IF;

	ELSE -- 因为invitation_code 与 exist_account_id 互斥，这里相当于通过邀请码新建account
		IF NOT EXISTS (SELECT FROM invitationcode where code=invitation_code) THEN
			RAISE EXCEPTION '邀请码无效:%',invitation_code;
		ELSIF v_invitation.createtype IS NULL THEN
			raise exception 'create account type cannot be null';
		ELSIF account_name IS NULL THEN
			raise exception '账号名不可为空。';
		END IF;
		v_invitation_type := v_invitation.createtype;
		v_invite_userid := v_invitation.userid;
		-- 生成account
		INSERT INTO ACCOUNT(type,upstreamaccount,accountname) VALUES(v_invitation_type,v_invitation.accountid,account_name) RETURNING id INTO v_accountid;
		IF v_accountid IS NULL THEN
			raise exception 'create account return null.';
		END IF;

		-- 设置role 和 附加属性
		IF v_invitation_type in ('HQ_AGENT','LV1_AGENT','LV2_AGENT') THEN
			SELECT id INTO v_roleid FROM roles WHERE rolename='OWNER' AND accountkind='AGENT';
			INSERT INTO agentattribute(accountid) VALUES(v_accountid); 
		ELSE -- 不经过上面分支，则必然是学生账号。 
			INSERT INTO studentattribute(accountid) VALUES(v_accountid);
			IF u_relationship IS NULL THEN -- 如果没有relationship，则是学生
				SELECT id INTO v_roleid FROM roles WHERE rolename='STUDENT' AND accountkind='STUDENT';
			ELSE -- 家长账号
				SELECT id INTO v_roleid FROM roles WHERE rolename='GUARDIAN_PRIMARY' AND accountkind='STUDENT';				
			END IF;
		END IF;
	END IF;

	IF v_invitation_type::text!='STUDENT' AND u_relationship IS NOT NULL THEN
		raise exception 'Agent should not assign relationship.';
	END IF;
	IF v_invitation_type::text='STUDENT' AND v_password IS NULL THEN -- 学生默认不用填密码。 此时自动生成一下dummy的密码
		v_password := 'password';
	END IF;

	-- 创建用户
	INSERT INTO users(password,phone,email,nickname,wechatopenid,status,source,referaluserid) VALUES
		(v_password,u_phone,u_email,nick_name,open_id,'ACTIVE',u_source,v_invite_userid) RETURNING id INTO v_new_userid;
	IF v_new_userid IS NULL THEN
		raise exception 'create user return null';
	END IF;
	-- 生成家长属性
	IF v_invitation_type::text='STUDENT' AND u_relationship IS NOT NULL THEN
		INSERT INTO guardian(guardianid,studentid,relationship) VALUES(v_new_userid,v_accountid,u_relationship);
	END IF;
	-- 生成useraccountrole
	INSERT INTO useraccountrole(userid,accountid,roleid) VALUES(v_new_userid,v_accountid,v_roleid);
	-- 生成invitation code
	IF v_invitation_type in ('HEAD_QUARTER','HQ_AGENT','LV1_AGENT','LV2_AGENT') THEN
	    FOREACH code_type IN ARRAY ARRAY['HQ_AGENT', 'LV1_AGENT', 'LV2_AGENT', 'STUDENT']::public."entitytype"[] LOOP
	        -- Generate a random 13-character code
	        random_code := (SELECT string_agg(chr((65+floor(random()*26)::integer)),'')FROM generate_series(1,13));
			if exists (select from invitationcode where code=random_code) then -- 监测到code冲突的话，自动重新生成
				LOOP
			        random_code := (SELECT string_agg(chr((65+floor(random()*26)::integer)),'')FROM generate_series(1,13));	
			        IF NOT EXISTS (select from invitationcode where code=random_code) THEN
			            EXIT;
			        END IF;
			    END LOOP;
			end if;
	
	        -- Insert the record into invitationcode table。因为一个用户只能有一个agent访问权限，可以直接通过useraccountrole表获取
	        INSERT INTO invitationcode (code, userid, accountid, createtype)
	        VALUES (random_code,v_new_userid,v_accountid,code_type);
	    END LOOP;
	END IF;

    RAISE NOTICE '====end register_user()====';
	return (v_new_userid,v_accountid);
END;
$function$
;


DROP FUNCTION public.pay_success(int8, bool);

CREATE OR REPLACE FUNCTION public.pay_success(order_id bigint, force_settle boolean DEFAULT false, test_mode boolean default false)
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
        SELECT * INTO v_product FROM product  WHERE id = v_orderproduct.productid;
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
							v_direct_upstream_account := rec.account_id;
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


CREATE OR REPLACE FUNCTION public.after_insert_liuliustatement()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_accountid UUID;
    v_order RECORD;
	v_log text;
BEGIN
    -- Step 1: Match memo with users.phone
    SELECT uar.accountid INTO v_accountid FROM users u, useraccountrole uar, roles r 
	WHERE u.id=uar.userid AND uar.roleid=r.id AND r.accountkind::text='STUDENT'
	AND RIGHT(u.phone, 10) = TRIM(NEW.memo) LIMIT 1;
	raise notice 'user accountid: %',v_accountid;
    
    -- Step 2: Match order conditions
    IF v_accountid IS NOT NULL THEN
        SELECT o.id,o.paymentmethod INTO v_order FROM orders o
        WHERE o.studentid = v_accountid
          AND o.createdat < NEW.transactiontime
          AND NEW.transactionamount = o.price
          AND o.status IN ('created','pending_confirmation','paid')
        ORDER BY o.createdat DESC
        LIMIT 1;
		raise notice 'matched order: %',v_order.id;
		
        
        -- Step 3: Update order details and call function if conditions met
        IF v_order.id IS NOT NULL THEN
			IF v_order.paymentmethod IS NULL OR v_order.paymentmethod!='liuliupay' THEN
	            UPDATE orders SET paymentmethod = 'liuliupay' WHERE id = v_order.id;
			END IF;
			           
            -- Call pay_success function
			BEGIN
				select * from pay_success(v_order.id,true) into v_log;
			EXCEPTION WHEN OTHERS THEN
 				v_log := 'pay_success exception: ' || SQLERRM;
			END;

			update liuliustatement set orderid=v_order.id,automationlog=v_log where id=NEW.id;

			raise notice 'pay success';
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
		select * into v_product from product where id=product_id;
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

