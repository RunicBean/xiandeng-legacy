
-- drop triggers
DROP TRIGGER refresh_mv_balance_activity_details_trigger ON balanceactivity;

DROP MATERIALIZED VIEW IF EXISTS mv_balance_activity_details;

-- drop functions
DROP FUNCTION public.get_account_chain(uuid);
DROP FUNCTION public.get_purchase_price(uuid, uuid);
DROP FUNCTION public.refresh_mv_balance_activity_details();

-- drop tables
DROP TABLE IF EXISTS franchisefee;

-- drop types

-- new types
CREATE TYPE public."accountbalancetype" AS ENUM (
	'balance',
	'balanceleft',
	'balanceright',
	'balancetriplelock',
	'balancetriple',
	'pendingreturn');

CREATE TYPE public."accountpartition" AS ENUM (
	'L',
	'R');

-- new table change
CREATE TABLE public.auditlog (
	audit_id serial4 NOT NULL,
	table_name text NULL,
	operation bpchar(1) NULL,
	changed_at timestamptz DEFAULT CURRENT_TIMESTAMP NULL,
	user_name text NULL,
	old_data jsonb NULL,
	new_data jsonb NULL,
	CONSTRAINT auditlog_pkey PRIMARY KEY (audit_id)
);

CREATE TABLE public.datadictionary (
	"key" varchar(255) NOT NULL,
	value text NULL,
	CONSTRAINT datadictionary_pkey PRIMARY KEY (key)
);

CREATE TABLE public.franchiseorder (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	accountid uuid NOT NULL,
	status varchar(255) DEFAULT 'pending'::character varying NULL,
	paymentmethod varchar(255) NULL,
	originaltype public."entitytype" NULL,
	targettype public."entitytype" NOT NULL,
	pendingfee numeric(8, 2) NOT NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	price numeric(8, 2) NOT NULL,
	CONSTRAINT franchiseorder_pkey PRIMARY KEY (id),
	CONSTRAINT fk_accountid FOREIGN KEY (accountid) REFERENCES public.account(id)
);

CREATE TABLE public.partitionaward (
	id serial4 NOT NULL,
	accountid uuid NOT NULL,
	salesaccountid uuid NOT NULL,
	amount numeric(8, 2) NULL,
	orderid int8 NULL,
	linkedaccountid uuid NULL,
	"partition" public."accountpartition" NOT NULL,
	franchiseorderid uuid NULL,
	CONSTRAINT partitionaward_amount_check CHECK ((amount > (0)::numeric)),
	CONSTRAINT partitionaward_pkey PRIMARY KEY (id),
	CONSTRAINT unique_accountid_orderid_linkedaccountid UNIQUE (accountid, orderid, linkedaccountid),
	CONSTRAINT fk_account_accountid FOREIGN KEY (accountid) REFERENCES public.account(id),
	CONSTRAINT fk_account_linkedaccountid FOREIGN KEY (linkedaccountid) REFERENCES public.account(id),
	CONSTRAINT fk_account_salesaccountid FOREIGN KEY (salesaccountid) REFERENCES public.account(id),
	CONSTRAINT fk_franchiseorder_franchiseorderid FOREIGN KEY (franchiseorderid) REFERENCES public.franchiseorder(id),
	CONSTRAINT fk_orders_orderid FOREIGN KEY (orderid) REFERENCES public.orders(id)
);
CREATE INDEX idx_accountid ON public.partitionaward USING btree (accountid);
CREATE INDEX idx_linkedaccountid ON public.partitionaward USING btree (linkedaccountid);
CREATE INDEX idx_orderid ON public.partitionaward USING btree (orderid);
CREATE INDEX idx_partition ON public.partitionaward USING btree (partition);
CREATE INDEX idx_salesaccountid ON public.partitionaward USING btree (salesaccountid);

CREATE TABLE public.projectdelivery (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	orderproductid int8 NULL,
	deliveryaccount uuid NULL,
	price numeric(8, 2) NULL,
	status varchar(255) DEFAULT 'PENDING'::character varying NULL,
	"source" varchar(255) NULL,
	assignmode varchar(255) NULL,
	starttime timestamp NULL,
	endtime timestamp NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT projectdelivery_pkey PRIMARY KEY (id),
	CONSTRAINT fk_deliveryaccount FOREIGN KEY (deliveryaccount) REFERENCES public.account(id),
	CONSTRAINT fk_orderproductid FOREIGN KEY (orderproductid) REFERENCES public.orderproduct(id)
);

CREATE TABLE public.triplecycleaward (
	accountid uuid NOT NULL,
	"number" int4 NOT NULL,
	linkedaccountid uuid NOT NULL,
	originaltype public."entitytype" NULL,
	targettype public."entitytype" NOT NULL,
	amount numeric(8, 2) NOT NULL,
	pendingreturn numeric(8, 2) NOT NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	franchiseorderid uuid NULL,
	CONSTRAINT triplecycleaward_pkey PRIMARY KEY (accountid, number),
	CONSTRAINT fk_accountid FOREIGN KEY (accountid) REFERENCES public.account(id),
	CONSTRAINT fk_franchiseorder_franchiseorderid FOREIGN KEY (franchiseorderid) REFERENCES public.franchiseorder(id),
	CONSTRAINT fk_linkedaccountid FOREIGN KEY (linkedaccountid) REFERENCES public.account(id)
);

ALTER TABLE public.account ADD COLUMN "partition" public."accountpartition" NULL;
ALTER TABLE public.account ADD COLUMN balanceleft numeric(8, 2) DEFAULT 0 NOT NULL;
ALTER TABLE public.account ADD COLUMN balanceright numeric(8, 2) DEFAULT 0 NOT NULL;
ALTER TABLE public.account ADD COLUMN pendingreturn numeric(8, 2) NULL;
ALTER TABLE public.account ADD COLUMN balancetriple numeric(8, 2) DEFAULT 0 NOT NULL;
ALTER TABLE public.account ADD COLUMN balancetriplelock numeric(8, 2) DEFAULT 0 NOT NULL;

DROP INDEX idx_unique_balanceactivity_accountid_orderid_source;
ALTER TABLE public.balanceactivity DROP CONSTRAINT balanceactivity_orderproductid_fkey;
ALTER TABLE public.balanceactivity ALTER COLUMN orderproductid DROP NOT NULL;
ALTER TABLE public.balanceactivity ADD COLUMN franchiseorderid uuid NULL;
ALTER TABLE public.balanceactivity ADD CONSTRAINT balanceactivity_franchiseorderid_fkey FOREIGN KEY (franchiseorderid) REFERENCES public.franchiseorder(id);
ALTER TABLE public.balanceactivity ADD COLUMN balancetype public."accountbalancetype" NULL;
CREATE UNIQUE INDEX idx_unique_balanceactivity ON public.balanceactivity USING btree (accountid, orderid, source, franchiseorderid);

ALTER TABLE public.invitationcode ALTER COLUMN accountid SET NOT NULL;
ALTER TABLE public.invitationcode ALTER COLUMN userid SET NOT NULL;

ALTER TABLE public.product DROP COLUMN hqagentprice;
ALTER TABLE public.product DROP COLUMN lv1agentprice;
ALTER TABLE public.product DROP COLUMN lv2agentprice;
ALTER TABLE public.product ADD COLUMN pricingschedule jsonb NULL;

ALTER TABLE public.users ALTER COLUMN accountid SET NOT NULL;

-- new function change
CREATE OR REPLACE FUNCTION public.get_account_chain(accid uuid, top_level_account uuid DEFAULT NULL::uuid)
 RETURNS TABLE(account_id uuid)
 LANGUAGE plpgsql
AS $function$
declare var_upstream_account RECORD;
begin
	 -- First, fetch the upstream account of the given account and store it in var_account
    SELECT upstreamaccount,type INTO var_upstream_account FROM account WHERE id = accid;

    -- Return the initial account information	
    return query select accid;

	if top_level_account is null then
	    if var_upstream_account.type != 'HEAD_QUARTER' then
	   	    return query select ac.account_id from get_account_chain(var_upstream_account.upstreamaccount) ac;
	    end if;
	else 
	    if accid != top_level_account then
	   	    return query select * from get_account_chain(var_upstream_account.upstreamaccount,top_level_account);
	    end if;
	end if;
END; $function$
;

CREATE OR REPLACE FUNCTION public.get_upstreamaccount_chain(accid uuid)
 RETURNS TABLE(row_num integer, account_id uuid, account_type character varying, account_status character varying, account_name character varying, account_partition accountpartition, account_upstreamaccount uuid)
 LANGUAGE plpgsql
AS $function$
DECLARE 
    var_account RECORD;
BEGIN
    -- First, fetch the upstream account of the given account and store it in var_account
    SELECT upstreamaccount,type,status,accountname,partition,upstreamaccount INTO var_account FROM account WHERE id = accid;

    -- Return the initial account information
    RETURN QUERY 
    SELECT 1 AS row_num, accid, var_account.type::varchar,var_account.status::varchar,var_account.accountname::varchar,var_account.partition,var_account.upstreamaccount;

    -- Check if account type is not 'HEAD_QUARTER'
    IF var_account.type != 'HEAD_QUARTER' THEN
        -- Recursively fetch the upstream account chain
        RETURN QUERY 
        SELECT ac.row_num + 1 AS row_num, ac.account_id, ac.account_type, ac.account_status, ac.account_name, ac.account_partition, ac.account_upstreamaccount 
        FROM get_upstreamaccount_chain(var_account.upstreamaccount) ac;
    END IF;
END;
$function$
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
	SELECT accountid,originaltype,targettype INTO v_franchiseorder FROM franchiseorder where id=franchiseorder_id;
	IF not exists (select from account where id=v_franchiseorder.accountid) THEN
		return cast('failed. Account does not exists：'|| v_franchiseorder.accountid as varchar);
	END IF;

	-- get target account detail
	select * INTO v_target_account FROM account where id=v_franchiseorder.accountid;
	select value into v_award_extension_level from datadictionary where key='award-extension-level';--扩展层级

	IF EXISTS (select from get_account_chain(v_franchiseorder.accountid) ac, account a where ac.account_id=a.id	and a.id!=v_franchiseorder.accountid and a.type!='HEAD_QUARTER' and a.status!='ACTIVE') THEN--只有上游账号全部是active的情况下，才可以激活账号
		RAISE EXCEPTION '激活失败。上游账号状态异常。';
		--RETURN '激活失败。上游账号状态异常。';
	elsif exists (select from get_upstreamaccount_chain(v_franchiseorder.accountid)
		where row_num<=(v_award_extension_level+2) and row_num>1 and account_type in ('LV2_AGENT','LV1_AGENT','HQ_AGENT') and account_partition is null 
		and (SELECT type from account where id=account_upstreamaccount)!='HEAD_QUARTER') then -- 排除掉直接上级是总部的账号
		RAISE EXCEPTION '付款失败。分区设定异常。';
		--return '付款失败。分区设定异常。';
	ELSIF (v_target_account.status='INIT' and v_franchiseorder.originaltype IS NOT NULL) OR (v_target_account.status='ACTIVE' and v_franchiseorder.originaltype IS NULL) THEN
		RAISE EXCEPTION '激活失败。账号设定冲突.状态:% 原账户类型:%',v_target_account.status,v_franchiseorder.originaltype;
		--RETURN cast(('激活失败。账号设定冲突.状态:' || v_target_account.status || ' 原账户类型:' || v_franchiseorder.originaltype) as varchar);
	END IF;

	--进行初始参数设定	
	select value into v_award_y_ratio from datadictionary where key=concat('','award-y-ratio');--扩展奖比例
	-- 设定三单循环和扩展奖的基数。升级账号不是差额，而是补交全额。
	select value into v_award_y from datadictionary where key=concat(v_franchiseorder.targettype,'-award-y');
	select value into v_three_return_award_amount from datadictionary where key=concat(v_franchiseorder.targettype,'-award-x');	

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
					RAISE NOTICE '--三单循环系数:%',v_reward_x;
					v_three_return_award_amount:=v_three_return_award_amount*v_reward_x;
					-- 写余额 Step 1: 三单循环
					if v_three_return_award_amount!=0 then
						update account set balancetriplelock = balancetriplelock+v_three_return_award_amount WHERE id=rec.account_id returning balancetriplelock into tmp_balanceafter;	
						insert into balanceactivity(source,franchiseorderid,accountid,amount,balanceafter,balancetype) 
							values(concat('招商三单循环奖励 (第',(v_number/3+1)::text,'轮第',(v_number%3+1)::text,'单，系数:',v_reward_x::text,')'),franchiseorder_id,rec.account_id,v_three_return_award_amount,tmp_balanceafter,'balancetriplelock');
					end if;
					--如果是升级，解锁之前的所有三单循环奖励（只把pendingreturn设置为0，实际通过三单循环的trigger解锁)
					if v_franchiseorder.originaltype IS NOT NULL then
						update triplecycleaward set pendingreturn=0 where number<=v_number AND pendingreturn>0 AND accountid=rec.account_id AND linkedaccountid=v_franchiseorder.accountid;
					end if;
					-- 同时更新冗余表，方便记录第几轮第几单，以及方便后续查询
					insert into triplecycleaward(accountid,number,linkedaccountid,originaltype,targettype,amount,pendingreturn,franchiseorderid) values(rec.account_id,v_number+1,v_franchiseorder.accountid,v_franchiseorder.originaltype,v_franchiseorder.targettype,v_three_return_award_amount,v_three_return_award_amount,franchiseorder_id);
					RAISE NOTICE '--三单循环奖励:% 金额:%',rec.account_name,v_three_return_award_amount;
				END IF;
				-- 直属招商奖励
				select value into var_tmp_award_amount from datadictionary where key=concat(rec.account_type,'-',v_franchiseorder.targettype,'-direct-award');
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
		update account set status='ACTIVE' where id=v_franchiseorder.accountid;
	ELSE -- 升级商户
		update account set type=v_franchiseorder.targettype where id=v_franchiseorder.accountid;
	END IF;
	update franchiseorder set pendingfee=0,status='success' where id=franchiseorder_id;

	RETURN 'success';
END;
$function$
;

CREATE OR REPLACE FUNCTION public.calculate_pendingfee()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_franchise_fee NUMERIC(8,2);
BEGIN
    -- Retrieve the franchise fee value from the datadictionary table
    SELECT value::NUMERIC(8,2) 
    INTO v_franchise_fee 
    FROM datadictionary 
    WHERE key = CONCAT(NEW.targettype, '-franchise-fee');

    -- Set the pendingfee value in the new record
    NEW.pendingfee := v_franchise_fee;
	NEW.price := v_franchise_fee;

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.check_account_after_insert()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Insert a new record into the franchiseorder table
	IF NEW.type in ('LV2_AGENT','LV1_AGENT','HQ_AGENT') THEN
	    INSERT INTO franchiseorder (
	        accountid, 
	        targettype
	    )
	    VALUES (
	        NEW.id,                   -- accountid
	        NEW.type                 -- targettype, same as account type
	    );
	END IF;

    RETURN NEW;
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
        SELECT partition,status,type,upstreamaccount INTO v_upstream
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
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.check_account_before_update()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_franchise_fee numeric(8,2);
BEGIN
    -- Check state machine
    IF NEW.status = 'INIT' THEN
        IF OLD.status = 'ACTIVE' OR OLD.status = 'CLOSED' THEN
            RAISE EXCEPTION 'Invalid status change from % to %', OLD.status, NEW.status;
        END IF;
	ELSIF OLD.status='INIT' AND NEW.status='ACTIVE' AND NEW.pendingfee!=0 THEN
		RAISE EXCEPTION 'Activate account failed. Pending earnest:%', NEW.pendingfee;
    END IF;

	-- Valid value for upgrade type
	IF NEW.targettype NOT IN ('LV1_AGENT','HQ_AGENT') THEN-- 升级只能区代、总代
		RAISE EXCEPTION 'Invalid upgrade type: %',NEW.targettype;
	ELSIF (NEW.targettype='LV1_AGENT' AND NEW.type!='LV2_AGENT') OR (NEW.targettype='HQ_AGENT' AND NEW.type NOT IN ('LV2_AGENT','LV1_AGENT')) THEN --只能升级、不能降级
		RAISE EXCEPTION 'Invalid upgrade process. Type: % | Upgrade Type: %',NEW.type,NEW.targettype;
	ELSIF (NEW.partition!=OLD.partition or NEW.partition IS NULL) AND OLD.partition in ('L','R') THEN --分区一旦设定，不能更改
		RAISE EXCEPTION 'Invalid partition transition. From: % to %',OLD.partition,NEW.partition;
	ELSIF OLD.targettype IS NOT NULL AND NEW.targettype IS NULL AND NEW.pendingfee!=0 THEN
		RAISE EXCEPTION 'Upgrade account failed. Pending earnest:%', NEW.pendingfee;
	END IF;
    
    RETURN NEW;
END;
$function$
;

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
			select accountid into v_accountid from users where id=p_userid;
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

CREATE OR REPLACE FUNCTION public.check_pending_status()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Check if there is already a record with the same accountid and status='pending'
    IF (NEW.status = 'pending') THEN
        IF EXISTS (
            SELECT 1 
            FROM franchiseorder
            WHERE accountid = NEW.accountid
            AND status = 'pending'
            AND id <> NEW.id
        ) THEN
            RAISE EXCEPTION 'Each accountid can only have one franchiseorder with pending status';
        END IF;
    END IF;
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.check_triple_award_pendingreturn()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Check if the new or updated record has a positive pendingreturn
    IF NEW.pendingreturn > 0 THEN
        -- Check if there is any existing record with a positive pendingreturn for the same linkedaccountid
        IF EXISTS (
            SELECT 1 
            FROM triplecycleaward
            WHERE linkedaccountid = NEW.linkedaccountid
            AND pendingreturn > 0
            AND (accountid, number) <> (NEW.accountid, NEW.number)
        ) THEN
            -- Raise an exception if another record with positive pendingreturn exists for the same linkedaccountid
            RAISE EXCEPTION 'Only one record can have a positive pendingreturn for the same linkedaccountid';
        END IF;
    END IF;
    -- If no records violate the rule, proceed with the operation
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.complete_invitation_codes(user_id uuid)
 RETURNS TABLE(i_code character, create_type entitytype)
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_record RECORD;
    random_code CHAR(13);
	v_accountid UUID;
	code_array bpchar(13)[] := '{}';  -- Initialize the array
    type_array entitytype[] := '{}';  -- Initialize the array
    code_type public."entitytype";    -- Declare the loop variable
BEGIN
    RAISE NOTICE '====begin complete_invitation_codes(user_id UUID)====';
	SELECT accountid into v_accountid FROM users where id=user_id;

    -- Loop through the ENUM values
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

		SELECT code,createtype INTO v_record FROM invitationcode where userid=user_id and accountid=v_accountid and createtype=code_type;
		IF v_record IS NULL THEN--补全邀请码类型
	        INSERT INTO invitationcode (code, userid, accountid, createtype) VALUES (random_code, user_id, v_accountid, code_type)
			RETURNING code, createtype INTO v_record;
		END IF;
        -- Append the record's code and type to the arrays
        code_array := array_append(code_array, v_record.code);
        type_array := array_append(type_array, v_record.createtype);

    END LOOP;

    -- Return the results
    RETURN QUERY SELECT unnest(code_array) AS i_code, unnest(type_array) AS create_type;
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
   	var_allowed_max_discount decimal(8,2);
	var_max_purchase_price decimal(8,2) := 0;--最高进货价
begin
	raise notice '====begin generate_new_coupon(user_id, discount_amount, max_count, product_id, student_id, start_date, due_date)====';
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
		select * into v_product from product where id=product_id;
		var_max_purchase_price := v_product.pricingschedule ->> concat(var_agent.type,'-course-purchase-price');--- 获取进货价
		--select pricingschedule ->> concat(var_agent.type,'-course-purchase-price') into var_max_purchase_price from product where id=product_id; -- 获取进货价
		if discount_amount<0 then
			return cast('创建失败。优惠金额必须非负。' as varchar);
		elsif (v_product.finalprice-var_max_purchase_price-discount_amount-(v_product.finalprice-discount_amount)*0.007)<0 then --考虑手续费
			return cast('创建失败。优惠金额过大。请至少将优惠金额调低：' || (v_product.finalprice-var_max_purchase_price-discount_amount-(v_product.finalprice-discount_amount)*0.007) || '。' as varchar);
		end if;
	end if;
	if start_date is not null and due_date is not null then 
		if start_date > due_date then
			return '创建失败。优惠券起始日期晚于截止日期。';
		end if;
	end if;
	if exists (select from ordercoupon where discountamount=discount_amount and agentid=var_agent.id and productid IS NOT DISTINCT FROM product_id and studentid IS NOT DISTINCT FROM student_id and effectstartdate IS NOT DISTINCT FROM start_date and effectduedate IS NOT DISTINCT FROM due_date) then
		return '创建失败。已存在面向相同商品、学员、金额、有效期的优惠券。';
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


CREATE OR REPLACE FUNCTION public.generate_simple_order(product_id uuid, student_id uuid, coupon_code bigint)
 RETURNS order_price_error
 LANGUAGE plpgsql
AS $function$
DECLARE 
   	var_product record;
   	var_sumprice decimal(8,2) := 0;
   	var_coupon record;
    var_direct_agent_id UUID;
	var_direct_agent_type entitytype;
	var_max_purchase_price decimal(8,2) := 0;
   	var_order_id bigint := -1;
	v_partition accountpartition;
	v_award_extension_level smallint;
begin
	raise notice '====begin====';
	select value into v_award_extension_level from datadictionary where key='award-extension-level';--扩展层级

	if (select type from account where id=student_id)!='STUDENT' then 
		return (var_order_id,var_sumprice,cast('只有学员账号可购买。' as varchar));	
	elsIF EXISTS (select from get_upstreamaccount_chain(student_id) where account_id!=student_id and account_type in ('LV2_AGENT','LV1_AGENT','HQ_AGENT') and account_status!='ACTIVE') THEN--上游账号必须都是active的
		RETURN (var_order_id,var_sumprice,cast('上游账号状态异常。' as varchar));
	elsif exists (select from get_upstreamaccount_chain(student_id) where row_num<=(v_award_extension_level+2) and row_num>1 and account_type in ('LV2_AGENT','LV1_AGENT','HQ_AGENT') and account_partition is null
		and (SELECT type from account where id=account_upstreamaccount)!='HEAD_QUARTER') then
		return (var_order_id,var_sumprice,cast('分区设定异常。' as varchar));
	end if;

	-- 初始化参数
	select id,type,partition into var_direct_agent_id,var_direct_agent_type,v_partition from account where id=(select upstreamaccount from account where id=student_id);
	select finalprice,purchaselimit,productname,pricingschedule into var_product from product where id=product_id; -- 读取商品详情	
	var_max_purchase_price := var_product.pricingschedule ->> concat(var_direct_agent_type,'-course-purchase-price');-- 获取进货价

	IF v_partition IS NULL THEN
		return (var_order_id,var_sumprice,cast('您的销售账号分区状态异常，请联系核实。' as varchar));
	elsif coupon_code is null and var_product.finalprice > 0 then
		return (var_order_id,var_sumprice,cast('销售代码不可以为空。' as varchar));
	elsif coupon_code is not null then -- 对优惠券进行检查
		if not exists (select from ordercoupon where code=coupon_code) then 
			return (var_order_id,var_sumprice,cast('该优惠券码不存在：'||coupon_code as varchar));
		end if;
		select * into var_coupon from ordercoupon where code=coupon_code; -- 读取优惠券详情
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
		/*if var_direct_agent_id!=var_coupon.agentid then
			return (var_order_id,var_sumprice,cast('优惠券不是您的直属代理签发的。' as varchar));
		end if;*/
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
		if (select finalprice-var_max_purchase_price-var_coupon.discountamount-(finalprice-var_coupon.discountamount)*0.007 from product where id=product_id) < 0 then--优惠金额过高：超过直接上级代理的利润。(考虑手续费)
			return (var_order_id,var_sumprice,cast('该优惠金额无效，请与销售人员核实。' as varchar));
		end if;
		if var_coupon.maxcount is not null then
			if (select count(*) from orderproduct where couponcode=coupon_code) >= var_coupon.maxcount then
				return (var_order_id,var_sumprice,cast('优惠券超过最大使用次数（' || var_coupon.maxcount || '次)。' as varchar));
			end if;
		end if;
	end if;	

	if var_product.purchaselimit is not null then
		raise notice 'purchase limit: %',var_product.purchaselimit;
		if (select count(*) from orderproduct op,orders o where op.orderid=o.id and o.status='success' and op.productid=product_id and o.studentid=student_id) >= var_product.purchaselimit then
			return (var_order_id,var_sumprice,cast('超过商品最大购买次数:' || var_product.productname as varchar));
		end if;
	end if;

	raise notice '====create order====';
	if var_product.finalprice > 0 then
		var_sumprice := var_product.finalprice - var_coupon.discountamount;--设置实际付款金额
	else
		var_sumprice := 0;
	end if;
	select ((extract(year from current_date)*100+extract(month from current_date))*100+extract(day from current_date))*100000000+floor(random()*100000000) into var_order_id;--生成订单号 
	if exists(select from orders where id=var_order_id) then -- 检测到重复自动重新生成
		LOOP
	        select ((extract(year from current_date)*100+extract(month from current_date))*100+extract(day from current_date))*100000000+floor(random()*100000000) into var_order_id;
	        IF NOT EXISTS (SELECT from orders where id=var_order_id) THEN
	            EXIT;
	        END IF;
	    END LOOP;
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


CREATE OR REPLACE FUNCTION public.get_child_partitions(account_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    child_partitions JSONB := '{}'::jsonb;
BEGIN
    WITH RECURSIVE account_cte AS (
        SELECT id, "partition", type
        FROM public.account
        WHERE upstreamaccount = account_id
        
        UNION ALL
        
        SELECT a.id, a."partition", a.type
        FROM public.account a
        INNER JOIN account_cte ac ON a.upstreamaccount = ac.id
    )
    SELECT jsonb_object_agg(id::text, "partition") INTO child_partitions
    FROM account_cte
	WHERE type IN ('LV1_AGENT', 'LV2_AGENT', 'HQ_AGENT');
    
    RETURN child_partitions;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.insert_invitation_codes()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    code_type public."entitytype";
    random_code CHAR(13);
BEGIN
    RAISE NOTICE '====begin complete_invitation_codes(user_id UUID)====';

    -- Loop through the ENUM values
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

        -- Insert the record into invitationcode table
        INSERT INTO invitationcode (code, userid, accountid, createtype)
        VALUES (random_code, NEW.id, NEW.accountid, code_type);
    END LOOP;

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.logaudit()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    changes JSONB := '{}';
    v_column_name TEXT;
    new_value TEXT;
	old_row_json JSONB := '{}';
	new_row_json JSONB := '{}';
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO auditlog(table_name, operation, user_name, new_data) VALUES (TG_TABLE_NAME, 'I', current_user, row_to_json(NEW)::jsonb  - 'createdat' - 'updatedat');
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
		-- get JSON of row data
		new_row_json := row_to_json(NEW)::JSONB;
		old_row_json := row_to_json(OLD)::JSONB - 'createdat' - 'updatedat';
        -- Iterate over each column of the row, excluding PRIMARY KEY
        FOR v_column_name IN
            SELECT column_name FROM information_schema.columns WHERE table_name = TG_TABLE_NAME AND column_name NOT IN 
				(SELECT kcu.column_name FROM information_schema.table_constraints tc JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name AND tc.table_name = kcu.table_name WHERE tc.table_name = TG_TABLE_NAME AND tc.constraint_type = 'PRIMARY KEY')
				AND column_name NOT IN ('createdat', 'updatedat')
        LOOP
            -- Get the new value of the column
            EXECUTE format('SELECT ($1).%I', v_column_name) INTO new_value USING NEW;
            -- Check if the value has changed
            IF new_row_json ->> v_column_name IS DISTINCT FROM old_row_json ->> v_column_name THEN
                -- Add the changed column and its new value to the JSONB object
                changes := jsonb_set(changes, ARRAY[v_column_name], to_jsonb(new_value));
				--raise notice 'table:%, col:%, new val:%, json:%, changes:%',TG_TABLE_NAME,v_column_name,new_value,new_row_json ->> v_column_name,changes;
            END IF;
        END LOOP;
        -- Insert the audit record if there are changes
        IF changes != '{}' THEN
			INSERT INTO auditlog(table_name, operation, user_name, old_data, new_data) VALUES (TG_TABLE_NAME, 'U', current_user,old_row_json,changes);
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditlog(table_name, operation, user_name, old_data) VALUES (TG_TABLE_NAME, 'D', current_user, row_to_json(OLD)::jsonb - 'createdat' - 'updatedat');
        RETURN OLD;
    END IF;
END;
$function$
;


CREATE OR REPLACE FUNCTION public.pay_success(order_id bigint)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE 
    v_orderproduct record;
    v_product record;
    v_student_id UUID;
    v_entitlement record;
    tmp_balanceafter decimal(8,2);
	tmp_balanceafter_reverse decimal(8,2);
    v_entitlement_name varchar;
    v_payment_method varchar;
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
BEGIN
    RAISE NOTICE '====begin pay_success(order_id bigint)====';
    
    IF NOT EXISTS (SELECT FROM orders WHERE id = order_id) THEN
        RETURN 'failed. Order does not exist: ' || order_id;
    ELSIF EXISTS (SELECT FROM balanceactivity WHERE orderid = order_id) THEN
        RETURN 'failed. The balance activity already exists for this order';
    ELSIF (SELECT status FROM orders WHERE id = order_id) = 'success' THEN
        RETURN 'failed. The order status had completed previously.';
    END IF;
    
    SELECT studentid, paymentmethod INTO v_student_id, v_payment_method FROM orders WHERE id = order_id;
	select value into v_award_extension_level from datadictionary where key='award-extension-level';--扩展层级

	IF EXISTS (select from get_upstreamaccount_chain(v_student_id) where account_id!=v_student_id and account_type in ('LV2_AGENT','LV1_AGENT','HQ_AGENT') and account_status!='ACTIVE') THEN--上游账号必须都是active的
		RETURN '付款失败。上游账号状态异常。';
	elsif exists (select from get_upstreamaccount_chain(v_student_id) 
		where row_num<=(v_award_extension_level+2) and row_num>1 and account_type in ('LV2_AGENT','LV1_AGENT','HQ_AGENT') and account_partition is null
		and (SELECT type from account where id=account_upstreamaccount)!='HEAD_QUARTER') then
		return '付款失败。分区设定异常。';
	END IF;
    
    FOR v_orderproduct IN (SELECT id, productid, couponcode, actualprice FROM orderproduct WHERE orderid = order_id) 
	LOOP 
        RAISE NOTICE 'productid: %', v_orderproduct.productid;
        IF v_orderproduct.couponcode IS NULL AND v_orderproduct.actualprice>0 THEN --实付金额不为0时，必须填销售代码
			RETURN '付款失败。销售代码为空。';
		END IF;
        -- 初始化各个变量
        SELECT * INTO v_product FROM product  WHERE id = v_orderproduct.productid;
		SELECT agentid INTO v_sales_account FROM ordercoupon where code=v_orderproduct.couponcode;
        v_fee := 0;
		v_award_z:= v_product.pricingschedule ->> 'cross-level-award-base';
		select value into v_award_z_ratio from datadictionary where key=concat('','award-z-ratio');--扩展奖比例
        
        FOR v_entitlement IN (SELECT entitlementtypeid, validdays FROM productentitlementtype  WHERE productid = v_orderproduct.productid) 
		LOOP -- 激活学生授权
            INSERT INTO studententitlement(id,studentid,entitlementtypeid,lastorderid,expiresat) VALUES (uuid_generate_v4(),v_student_id,v_entitlement.entitlementtypeid,order_id,CURRENT_DATE+v_entitlement.validdays)
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
            AND NOT EXISTS (SELECT FROM qianliaocoupon WHERE studentid = v_student_id) THEN -- 如果没有分配千聊优惠券，则从空余优惠券里选一个分配
                UPDATE qianliaocoupon SET studentid=v_student_id,updatedat=(now() AT TIME ZONE 'Asia/Shanghai') WHERE couponcode=(SELECT couponcode FROM qianliaocoupon WHERE studentid IS NULL LIMIT 1);
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

	    FOR rec IN select * from get_upstreamaccount_chain(v_student_id)-- 执行分账
	 	LOOP
	        --raise notice 'row:% | id:% | type:% |name:% |%',rec.row_num,rec.account_id,rec.account_type,rec.account_name,is_indirect_awarded;
			IF (award_layer=3 and is_indirect_awarded) OR rec.account_type='HEAD_QUARTER' or v_orderproduct.actualprice<=0 THEN -- 实付<=0，不分账
				RAISE NOTICE '--exist loop at %',rec.account_name;
				EXIT; -- exist the loop when all awards are distributed
			END IF;
			IF rec.account_id=v_student_id THEN -- 学生
				RAISE NOTICE '-- 学生:%',rec.account_name;
			ELSE -- 上级
				--判断是否属于 直属招商奖励
				IF (award_layer<3 AND rec.account_type='HQ_AGENT') OR (award_layer<2 AND rec.account_type='LV1_AGENT') OR (award_layer<1 AND rec.account_type='LV2_AGENT') OR rec.row_num=2 THEN
					-- 确定剩余意向金返还数额
					select pendingreturn into v_return from account where id=rec.account_id;
					IF rec.row_num=2 THEN -- 直属上级
						v_direct_upstream_account := rec.account_id;
						-- 直接售课奖励
						v_purchase_price := v_product.pricingschedule ->> concat(rec.account_type,'-course-purchase-price');-- 获取进货价
						v_award := v_orderproduct.actualprice - v_purchase_price; -- commission是实际价格减去进货价
						-- 写余额，step 1 写售课奖励
						update account set balance = balance+v_award WHERE id=rec.account_id returning balance into tmp_balanceafter;	
						insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype) 
							values('售课奖励',order_id,v_orderproduct.id,rec.account_id,v_award,tmp_balanceafter,'balance');
						--写余额，step 2 转化订单奖励，给到v_sales_account 
						update account set balance = balance+(v_product.pricingschedule->>'conversion-award')::numeric(8,2) WHERE id=v_sales_account returning balance into tmp_balanceafter;	
						-- 操作余额变动,记录时间为原时间+1毫秒
						insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
							values('转化订单奖励',order_id,v_orderproduct.id,v_sales_account,(v_product.pricingschedule->>'conversion-award')::numeric(8,2),tmp_balanceafter,'balance',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond');

						-- 写余额，step 3 return>0时，返还意向金
						IF v_return > 0 THEN
							update account set balance = balance + (v_product.pricingschedule->>'earnest-return')::numeric, pendingreturn=pendingreturn - (v_product.pricingschedule ->> 'earnest-return')::numeric WHERE id=rec.account_id returning balance,pendingreturn into tmp_balanceafter,tmp_balanceafter_reverse;	
							update triplecycleaward set pendingreturn=pendingreturn-(v_product.pricingschedule->>'earnest-return')::numeric where linkedaccountid=v_direct_upstream_account and pendingreturn>0;
							raise notice '解锁三单循环: 金额% 学生直接上级代理:%',(v_product.pricingschedule->>'earnest-return'),v_direct_upstream_account;
							-- 操作余额变动,记录时间为原时间+2毫秒
							insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
								values('意向金返还(余额)',order_id,v_orderproduct.id,rec.account_id,(v_product.pricingschedule->>'earnest-return')::numeric,tmp_balanceafter,'balance',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond');
							insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
								values('意向金返还(剩余意向金)',order_id,v_orderproduct.id,rec.account_id,-(v_product.pricingschedule->>'earnest-return')::numeric,tmp_balanceafter_reverse,'pendingreturn',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond');
						END IF;
						-- 写余额，step 4 线上付款时，手续费由直接上级代理承担
						if v_payment_method='wechatpay' then
							v_fee := v_orderproduct.actualprice * 0.007;
							-- 扣除手续费
							update account set balance = balance - v_fee where id=rec.account_id returning balance into tmp_balanceafter;
							-- 操作余额变动,记录时间为原时间+3毫秒
							insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
								values('微信支付手续费0.7%',order_id,v_orderproduct.id,rec.account_id,-v_fee,tmp_balanceafter,'balance',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '3 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '3 millisecond');
						end if;		
						--设置发放奖励状态
						award_layer := (accounttype_awardlayer->>rec.account_type)::NUMERIC;	
						RAISE NOTICE '-- 直属售课奖励:% 金额:% 剩余意向金:% 转化费:% 手续费:%  付款方式:% 奖励发放状态:%|%',rec.account_name,v_award,v_return,v_product.pricingschedule->>'conversion-award',v_fee,v_payment_method,award_layer,is_indirect_awarded;
					ELSE
						-- 跨级售课奖励
						v_award := v_product.pricingschedule ->> concat(rec.account_type,'-course-direct-award');
						update account set balance = balance+v_award WHERE id=rec.account_id returning balance into tmp_balanceafter;	
						insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype) 
							values('售课跨级奖励',order_id,v_orderproduct.id,rec.account_id,v_award,tmp_balanceafter,'balance');
						IF v_return > 0 THEN-- 跨级意向金返还
							--v_award := v_product.pricingschedule ->> concat(rec.account_type,'-course-direct-award');
							update triplecycleaward set pendingreturn=pendingreturn-(v_product.pricingschedule ->> 'earnest-return')::numeric where linkedaccountid=rec.account_id and pendingreturn>0;
							update account set balance = balance+(v_product.pricingschedule->>'earnest-return')::numeric,pendingreturn=pendingreturn-(v_product.pricingschedule->>'earnest-return')::numeric WHERE id=rec.account_id returning balance,pendingreturn into tmp_balanceafter,tmp_balanceafter_reverse;	
							-- 操作余额变动,记录时间为原时间+1毫秒							
							insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
								values('跨级意向金返还(余额)',order_id,v_orderproduct.id,rec.account_id,(v_product.pricingschedule->>'earnest-return')::numeric,tmp_balanceafter,'balance',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond');
							insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
								values('跨级意向金返还(剩余意向金)',order_id,v_orderproduct.id,rec.account_id,-(v_product.pricingschedule->>'earnest-return')::numeric,tmp_balanceafter_reverse,'pendingreturn',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 millisecond');
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
    END LOOP;
    
    -- 标记订单为成功
    UPDATE orders  SET status='success',payat=(now() AT TIME ZONE 'Asia/Shanghai'),updatedat=(now() AT TIME ZONE 'Asia/Shanghai') WHERE id=order_id;    
    RAISE NOTICE '====end====';
    RETURN 'success';
END; 
$function$
;

CREATE OR REPLACE FUNCTION public.update_account_balance_locks()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_lockedbalanceafter decimal(8,2);
    v_balanceafter decimal(8,2);
BEGIN
    -- Check if the pendingreturn is modified
    IF NEW.pendingreturn <> OLD.pendingreturn THEN
        
        -- Condition: pendingreturn changed from positive to non-positive
        IF OLD.pendingreturn > 0 AND NEW.pendingreturn <= 0 THEN
            UPDATE account
            SET balancetriplelock = balancetriplelock - NEW.amount,
                balancetriple = balancetriple + NEW.amount
            WHERE id = NEW.accountid returning balancetriplelock,balancetriple into v_lockedbalanceafter,v_balanceafter;
			insert into balanceactivity(source,accountid,amount,balanceafter,balancetype) 
				values('解锁三单循环奖励(未解锁金额)',NEW.accountid,-NEW.amount,v_lockedbalanceafter,'balancetriplelock');
			insert into balanceactivity(source,accountid,amount,balanceafter,balancetype) 
				values('解锁三单循环奖励(已解锁金额)',NEW.accountid,NEW.amount,v_balanceafter,'balancetriple');

        -- Condition: pendingreturn changed from non-positive to positive
        ELSIF OLD.pendingreturn <= 0 AND NEW.pendingreturn > 0 THEN
            UPDATE account
            SET balancetriplelock = balancetriplelock + NEW.amount,
                balancetriple = balancetriple - NEW.amount
            WHERE id = NEW.accountid returning balancetriplelock,balancetriple into v_lockedbalanceafter,v_balanceafter;
			insert into balanceactivity(source,accountid,amount,balanceafter,balancetype) 
				values('【撤销】解锁三单循环奖励(未解锁金额)',NEW.accountid,NEW.amount,v_lockedbalanceafter,'balancetriplelock');
			insert into balanceactivity(source,accountid,amount,balanceafter,balancetype) 
				values('【撤销】解锁三单循环奖励(已解锁金额)',NEW.accountid,-NEW.amount,v_balanceafter,'balancetriple');
        END IF;

    END IF;

    RETURN NEW;
END;
$function$
;


-- new triger change
create trigger account_audit_trigger after
insert
    or
delete
    or
update
    on
    public.account for each row execute function logaudit();
create trigger trigger_check_account_before_insert before
insert
    on
    public.account for each row execute function check_account_before_insert();
create trigger trigger_check_account_before_update before
update
    on
    public.account for each row execute function check_account_before_update();
create trigger trigger_check_account_after_insert after
insert
    on
    public.account for each row execute function check_account_after_insert();

create trigger check_pending_status_trigger before
insert
    or
update
    on
    public.franchiseorder for each row execute function check_pending_status();
create trigger set_pendingfee_before_insert before
insert
    on
    public.franchiseorder for each row execute function calculate_pendingfee();

create trigger orders_audit_trigger after
insert
    or
delete
    or
update
    on
    public.orders for each row execute function logaudit();

create trigger qianliaocoupon_audit_trigger after
insert
    or
delete
    or
update
    on
    public.qianliaocoupon for each row execute function logaudit();

create trigger studentattribute_audit_trigger after
insert
    or
delete
    or
update
    on
    public.studentattribute for each row execute function logaudit();

create trigger trigger_check_triple_award_pendingreturn before
insert
    or
update
    on
    public.triplecycleaward for each row execute function check_triple_award_pendingreturn();
create trigger triplecycleaward_audit_trigger after
insert
    or
delete
    or
update
    on
    public.triplecycleaward for each row execute function logaudit();
create trigger update_account_balance_locks_trigger before
update
    on
    public.triplecycleaward for each row execute function update_account_balance_locks();

create trigger trigger_insert_invitation_codes after
insert
    on
    public.users for each row execute function insert_invitation_codes();    

/* AI reference
In postgres, I would like to change old table structure to new table structure. Help me write SQL to summarize the changes.
- for output SQL, do not add any comments
- for output SQL, do not automatically change lines.


-- old table

-- new table

-- get all triggers
SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    t.tgname AS trigger_name
FROM
    pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE
    NOT t.tgisinternal
ORDER BY
    n.nspname,
    c.relname,
    t.tgname;
*/