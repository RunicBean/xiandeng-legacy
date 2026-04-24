
ALTER TABLE public.liuliustatement ADD CONSTRAINT unique_transactionid UNIQUE (transactionid);

ALTER TABLE public.datadictionary ADD "namespace" varchar(255) NULL;

INSERT INTO datadictionary ("key", value, "namespace") VALUES('LV2_AGENT', '学习站', 'entitytype');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('LV1_AGENT', '学习总站', 'entitytype');
INSERT INTO datadictionary ("key", value, "namespace") VALUES('HQ_AGENT', '学习中心', 'entitytype');

CREATE INDEX idx_namespace ON public.datadictionary ("namespace");

CREATE TABLE public.userwithdrawmethod (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    userid UUID NOT NULL,
    withdrawmethod VARCHAR(255) NOT NULL, -- 'bank'
    accountname VARCHAR(64),
    accountnumber VARCHAR(64),
    bank VARCHAR(64),
    createdat TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
    updatedat TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
    CONSTRAINT fk_userwithdrawmethod_userid FOREIGN KEY (userid) REFERENCES public.users(id)
);
   
CREATE TYPE withdrawtype AS ENUM ('balance', 'partition', 'triple');

ALTER TABLE public.balanceactivity DROP CONSTRAINT balanceactivity_withdrawid_fkey;
ALTER TABLE public.balanceactivity DROP COLUMN withdrawid;

DROP TABLE public.withdrawattachment;
DROP TABLE public.withdraw;

CREATE TABLE public.withdraw (
	id bpchar(16) NOT NULL,
	accountid uuid NULL,
	amount numeric(8, 2) NULL,
	status varchar(255) DEFAULT 'REQUESTED'::character varying NOT NULL,
	"type" public."withdrawtype" NOT NULL,
	memo varchar(255) NULL,
	lastoperateuserid uuid NULL,
	userwithdrawmethodid uuid null,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT withdraw_pkey PRIMARY KEY (id),
	CONSTRAINT withdraw_acctid_fkey FOREIGN KEY (accountid) REFERENCES public.account(id),
	CONSTRAINT withdraw_userid_fkey FOREIGN KEY (lastoperateuserid) REFERENCES public.users(id),
	CONSTRAINT withdraw_method_fkey FOREIGN KEY (userwithdrawmethodid) REFERENCES public.userwithdrawmethod(id)
);

ALTER TABLE public.balanceactivity ADD COLUMN withdrawid bpchar(16);
ALTER TABLE public.balanceactivity ADD CONSTRAINT fk_balanceactivity_withdraw FOREIGN KEY (withdrawid) REFERENCES public.withdraw(id);

CREATE TABLE public.withdrawattachment (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	withdrawid char(16) NULL,
	imageurl text NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT withdrawattachment_pkey PRIMARY KEY (id),
	CONSTRAINT withdrawattachment_withdrawid_fkey FOREIGN KEY (withdrawid) REFERENCES public.withdraw(id)
);

CREATE OR REPLACE FUNCTION public.generate_and_set_withdraw_id()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    new_id CHAR(16);
    cur_date TEXT;
    random_num TEXT;
BEGIN
    -- If the id is not provided, generate a new one
    IF NEW.id IS NULL THEN
        cur_date := TO_CHAR(now() AT TIME ZONE 'Asia/Shanghai', 'YYYYMMDD');
        random_num := LPAD((FLOOR(RANDOM() * 1000000)::TEXT), 6, '0');
        new_id := 'T' || cur_date || random_num;

        -- Ensure uniqueness
        LOOP
            -- Check if the ID already exists
            PERFORM 1 FROM public.withdraw WHERE id = new_id;
            IF NOT FOUND THEN
                -- If not found, exit the loop
                EXIT;
            END IF;
            -- If found, regenerate the id
            random_num := LPAD((FLOOR(RANDOM() * 1000000)::TEXT), 6, '0');
            new_id := 'T' || cur_date || random_num;
        END LOOP;

        -- Assign the new_id to the NEW record
        NEW.id := new_id;
    END IF;

    RETURN NEW;
END;
$function$
;


CREATE TRIGGER before_insert_withdraw
BEFORE INSERT ON public.withdraw
FOR EACH ROW
EXECUTE FUNCTION generate_and_set_withdraw_id();


CREATE OR REPLACE FUNCTION public.check_withdraw_status()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Check if there is already a record with the same accountid and status='REQUESTED'
    IF (NEW.status = 'REQUESTED') THEN
        IF EXISTS (
            SELECT FROM withdraw
            WHERE accountid = NEW.accountid
			AND type = NEW.type
            AND status IN ('REQUESTED','LOCKED')
            AND id <> NEW.id
        ) THEN
            RAISE EXCEPTION 'Each accountid can only have one withdraw in REQUESTED/LOCKED status for same withdraw type';
        END IF;
    END IF;
    RETURN NEW;
END;
$function$
;



create trigger check_withdraw_status_trigger before
insert
    or
update
    on
    public.withdraw for each row execute function check_withdraw_status();



CREATE TABLE public.withdrawhistory (
	id serial4 NOT NULL,
	sourceid bpchar(16) NOT NULL,
	status varchar(255) not null,
	operateuserid uuid,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT withdrawhistory_pkey PRIMARY KEY (id),
	CONSTRAINT withdrawhistory_sourceid_fkey FOREIGN KEY (sourceid) REFERENCES public.withdraw(id)
);

CREATE OR REPLACE FUNCTION public.audit_withdraw()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Insert a new row into withdrawhistory with relevant details
    INSERT INTO public.withdrawhistory (
        sourceid, 
        status, 
        operateuserid, 
        createdat
    ) VALUES (
        NEW.id, 
        NEW.status, 
        NEW.lastoperateuserid, 
        NOW() AT TIME ZONE 'Asia/Shanghai'
    );
    RETURN NEW;
END;
$function$
;



CREATE TRIGGER audit_withdraw_trigger
AFTER insert or update ON public.withdraw
FOR EACH ROW
EXECUTE FUNCTION audit_withdraw();


CREATE OR REPLACE FUNCTION public.enforce_withdraw_immutable_columns()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Check if any of the specified columns have changed
    IF (OLD.accountid IS DISTINCT FROM NEW.accountid) THEN
        RAISE EXCEPTION 'Cannot change column "accountid" after insert. % -> %',OLD.accountid,NEW.accountid;
    ELSIF (OLD.amount < NEW.amount) THEN
        RAISE EXCEPTION 'Cannot increase withdraw amount. ￥% -> ￥%',OLD.amoount,NEW.amount;
    ELSIF (OLD.type IS DISTINCT FROM NEW.type) THEN
        RAISE EXCEPTION 'Cannot change column "type" after insert. % -> %',OLD.type,NEW.type;
    ELSIF (OLD.memo IS DISTINCT FROM NEW.memo) THEN
        RAISE EXCEPTION 'Cannot change column "memo" after insert. % -> %',OLD.memo,NEW.memo;
    END IF;
    RETURN NEW;
END;
$function$
;


-- Trigger to Call the Function Before Update

CREATE TRIGGER trigger_enforce_withdraw_immutable_columns
BEFORE UPDATE ON public.withdraw
FOR EACH ROW
EXECUTE FUNCTION enforce_withdraw_immutable_columns();



CREATE OR REPLACE FUNCTION public.validate_withdraw()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_account RECORD;
BEGIN
    -- Fetch the account balances
    SELECT balance,balanceleft,balanceright,balancetriple INTO v_account FROM account WHERE id = NEW.accountid;
    
    IF NEW.type::text = 'balance' AND NEW.amount > v_account.balance THEN
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


-- Trigger to Validate Withdrawals Before Insertion

CREATE TRIGGER validate_withdraw_trigger
BEFORE INSERT ON public.withdraw
FOR EACH ROW
EXECUTE FUNCTION validate_withdraw();




CREATE OR REPLACE FUNCTION public.confirm_withdraw(withdraw_id character, user_id uuid)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_withdraw RECORD;
    tmp_balanceafter decimal(8,2);
    tmp_balanceafter_1 decimal(8,2);
	v_account RECORD;
BEGIN
	raise notice '====begin confirm_withdraw(withdraw_id bpchar(16))====';
	SELECT * INTO v_withdraw FROM withdraw where id=withdraw_id;
	IF v_withdraw IS NULL THEN
		RAISE EXCEPTION 'Withdraw does not exist: %',withdraw_id;
 	ELSIF v_withdraw.status NOT IN ('LOCKED') THEN
        RAISE EXCEPTION 'Withdraw state machine transition is not allowed. status: %',v_withdraw.status;
	ELSIF user_id IS NOT NULL THEN
		IF NOT EXISTS(SELECT FROM users WHERE id=user_id) THEN
			RAISE EXCEPTION 'Operation user id not exist. %',user_id;
		END IF;
	END IF;

	-- 分账
	SELECT * INTO v_account FROM account where id=v_withdraw.accountid;
	IF v_withdraw.type::TEXT='balance' THEN
		IF v_withdraw.amount > v_account.balance THEN
			RAISE EXCEPTION 'Cannot withdraw an amount greater than account balance. Withdraw amount: % Account balance: %',v_withdraw.amount,v_account.balance;
		END IF;
		update account set balance = balance-v_withdraw.amount WHERE id=v_withdraw.accountid returning balance into tmp_balanceafter;	
		insert into balanceactivity(source,withdrawid,accountid,amount,balanceafter,balancetype) 
			values('余额提现',withdraw_id,v_withdraw.accountid,-v_withdraw.amount,tmp_balanceafter,'balance');
	ELSIF v_withdraw.type::TEXT='partition' THEN
		IF (v_withdraw.amount/2) > LEAST(v_account.balanceleft,v_account.balanceright) THEN
			RAISE EXCEPTION 'Cannot withdraw an amount greater than the minimum of balanceleft and balanceright。 Withdraw amount: % balanceleft: % balanceright: %'
				,v_withdraw.amount,v_account.balanceleft,v_account.balanceright;
		END IF;
		update account set balanceleft=balanceleft-(v_withdraw.amount/2),balanceright=balanceright-(v_withdraw.amount/2) 
			WHERE id=v_withdraw.accountid returning balanceleft,balanceright into tmp_balanceafter,tmp_balanceafter_1;	
		insert into balanceactivity(source,withdrawid,accountid,amount,balanceafter,balancetype) 
			values('分区奖提现【左】区',withdraw_id,v_withdraw.accountid,-(v_withdraw.amount/2),tmp_balanceafter,'balanceleft');
		insert into balanceactivity(source,withdrawid,accountid,amount,balanceafter,balancetype) 
			values('分区奖提现【右】区',withdraw_id,v_withdraw.accountid,-(v_withdraw.amount/2),tmp_balanceafter_1,'balanceright');
	ELSIF v_withdraw.type::TEXT='triple' THEN
		IF v_withdraw.amount > v_account.balancetriple THEN
			RAISE EXCEPTION 'Cannot withdraw an amount greater than balancetriple. Withdraw amount: % balancetriple: %',v_withdraw.amount,v_account.balancetriple;
		END IF;
		update account set balancetriple = balancetriple-v_withdraw.amount WHERE id=v_withdraw.accountid returning balancetriple into tmp_balanceafter;	
		insert into balanceactivity(source,withdrawid,accountid,amount,balanceafter,balancetype) 
			values('三单循环奖提现',withdraw_id,v_withdraw.accountid,-v_withdraw.amount,tmp_balanceafter,'balancetriple');
	END IF;


	-- 更新提现记录状态
	update withdraw set status='PAID',lastoperateuserid=user_id,updatedat=NOW() AT TIME ZONE 'Asia/Shanghai' where id=withdraw_id;

    RAISE NOTICE '====end confirm_withdraw()====';
	RETURN 'success';
END;
$function$
;

CREATE OR REPLACE FUNCTION public.confirm_delivery(delivery_id uuid)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_delivery RECORD;
    tmp_balanceafter decimal(8,2);
	v_orderid bigint;
BEGIN
	raise notice '====begin confirm_delivery(delivry_id uuid)====';
	SELECT * INTO v_delivery FROM projectdelivery where id=delivery_id;
	IF v_delivery IS NULL THEN
		raise exception 'Delivery does not exist: %',delivery_id;
 	ELSIF v_delivery.status NOT IN ('PENDING') THEN
        raise exception 'The delivery has reached final status: %',v_delivery.status;
	END IF;

	-- 分账
	SELECT orderid INTO v_orderid FROM orderproduct where id=(SELECT orderproductid FROM projectdelivery WHERE id=delivery_id);
	update account set balance = balance+v_delivery.price WHERE id=v_delivery.deliveryaccount returning balance into tmp_balanceafter;	
	insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype) 
		values('服务供应商分成',v_orderid,v_delivery.orderproductid,v_delivery.deliveryaccount,v_delivery.price,tmp_balanceafter,'balance');
	update projectdelivery set status='CONFIRMED',confirmedat=NOW() AT TIME ZONE 'Asia/Shanghai' where id=delivery_id;

    RAISE NOTICE '====end confirm_delivery()====';
	RETURN 'success';
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
	-- 设定三单循环和扩展奖的基数。升级账号不是差额，而是补交全额。
	select value into v_award_y from datadictionary where key=concat(v_franchiseorder.targettype,'-award-y');
	select value into v_three_return_award_amount from datadictionary where key=concat(v_franchiseorder.targettype,'-award-x');	
	select value into v_x_unlock from datadictionary where key=concat(v_franchiseorder.targettype,'-x-unlock');	

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
					-- 同时更新冗余表，方便记录第几轮第几单，以及方便后续查询
					insert into triplecycleaward(accountid,number,linkedaccountid,originaltype,targettype,amount,pendingreturn,franchiseorderid) values(rec.account_id,v_number+1,v_franchiseorder.accountid,v_franchiseorder.originaltype,v_franchiseorder.targettype,v_three_return_award_amount,v_x_unlock,franchiseorder_id);
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
BEGIN
    RAISE NOTICE '====begin pay_success(order_id bigint,force_settle boolean DEFAULT false)====';
    SELECT * INTO v_order FROM orders WHERE id = order_id;
    IF v_order IS NULL THEN
        RAISE EXCEPTION 'Order does not exist: %',order_id;
    ELSIF EXISTS (SELECT FROM balanceactivity WHERE orderid = order_id) THEN
        RAISE EXCEPTION 'The balance activity already exists for this order';
    ELSIF v_order.status IN ('success','settled','uncommisioned','declined','failed','refunded') THEN
        RAISE EXCEPTION 'The order has reached final status: %',v_order.status;
    END IF;
    
	select value into v_award_extension_level from datadictionary where key='award-extension-level';--扩展层级

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
		select value into v_award_z_ratio from datadictionary where key=concat('','award-z-ratio');--扩展奖比例


		IF v_order.status != 'paid' THEN  -- 执行所有付款成功应触发的动作      
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

		IF v_order.paymentmethod NOT IN ('liuliupay') OR force_settle=true THEN -- 执行所有背靠背结算动作 （微信直连的结算暂时没有做，也在付款时直接分账）
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
								-- 操作余额变动,记录时间为原时间+2毫秒
								insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
									values('意向金返还(余额)',order_id,v_orderproduct.id,rec.account_id,(v_product.pricingschedule->>'earnest-return')::numeric,tmp_balanceafter,'balance',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond');
								insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
									values('意向金返还(剩余意向金)',order_id,v_orderproduct.id,rec.account_id,-(v_product.pricingschedule->>'earnest-return')::numeric,tmp_balanceafter_reverse,'pendingreturn',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond');
							END IF;
							-- ！！！ 不管意向金是否还完，下级售课了就可以返回解锁三单循环的金额（即使是负数的也接着扣）
							update triplecycleaward set pendingreturn=pendingreturn-(v_product.pricingschedule->>'earnest-return')::numeric,lastorderid=order_id,updatedat=NOW() AT TIME ZONE 'Asia/Shanghai' where linkedaccountid=v_direct_upstream_account;
							raise notice '解锁三单循环: 金额% 学生直接上级代理:%',(v_product.pricingschedule->>'earnest-return'),v_direct_upstream_account;
							-- 写余额，step 4 线上付款时，手续费由直接上级代理承担
							if v_order.paymentmethod='wechatpay' then
								v_fee := v_orderproduct.actualprice * 0.007;
								-- 扣除手续费
								update account set balance = balance - v_fee where id=rec.account_id returning balance into tmp_balanceafter;
								-- 操作余额变动,记录时间为原时间+3毫秒
								insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
									values('微信支付手续费0.7%',order_id,v_orderproduct.id,rec.account_id,-v_fee,tmp_balanceafter,'balance',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '3 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '3 millisecond');
							end if;		
							--设置发放奖励状态
							award_layer := (accounttype_awardlayer->>rec.account_type)::NUMERIC;	
							RAISE NOTICE '-- 直属售课奖励:% 金额:% 剩余意向金:% 转化费:% 手续费:%  付款方式:% 奖励发放状态:%|%',rec.account_name,v_award,v_return,v_product.pricingschedule->>'conversion-award',v_fee,v_order.paymentmethod,award_layer,is_indirect_awarded;
						ELSE
							-- 跨级售课奖励
							v_award := v_product.pricingschedule ->> concat(rec.account_type,'-course-direct-award');
							update account set balance = balance+v_award WHERE id=rec.account_id returning balance into tmp_balanceafter;	
							insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype) 
								values('售课跨级奖励',order_id,v_orderproduct.id,rec.account_id,v_award,tmp_balanceafter,'balance');
							IF v_return > 0 THEN-- 跨级意向金返还
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
		END IF;
    END LOOP;  
    
	IF v_order.paymentmethod IN ('wechatpay','liuliupay') AND force_settle=false THEN -- 标记订单状态
	    UPDATE orders  SET status='paid',payat=(now() AT TIME ZONE 'Asia/Shanghai'),updatedat=(now() AT TIME ZONE 'Asia/Shanghai') WHERE id=order_id;    
	ELSIF v_order.status = 'paid' THEN
	    UPDATE orders  SET status='settled',settledat=(now() AT TIME ZONE 'Asia/Shanghai'),updatedat=(now() AT TIME ZONE 'Asia/Shanghai') WHERE id=order_id;   
	ELSE
	    UPDATE orders  SET status='settled',payat=(now() AT TIME ZONE 'Asia/Shanghai'),settledat=(now() AT TIME ZONE 'Asia/Shanghai'),updatedat=(now() AT TIME ZONE 'Asia/Shanghai') WHERE id=order_id; 
	END IF;

    RAISE NOTICE '====end pay_success()====';
    RETURN 'success';
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
		raise exception '创建失败。用户名不可以为空值。';
	end if;
	select id,type into var_agent from account where id=(select accountid from users where id=user_id);
	if var_agent.type = 'STUDENT' then
		raise exception '创建失败。账户类型不可以为“学员”。';
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


CREATE OR REPLACE FUNCTION public.revoke_delivery(delivery_id uuid, refund_amount numeric DEFAULT NULL::numeric)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE 
    v_delivery record;
	v_refund_amount decimal(8,2);
    v_orderid bigint;
   	tmp_balanceafter decimal(8,2);
	v_status TEXT;
begin
	raise notice '====begin revoke_delivery(delivery_id uuid, refund_amount boolean DEFAULT null)====';
 	select * into v_delivery from projectdelivery where id=delivery_id;
    IF v_delivery IS NULL THEN
		raise exception 'Delivery does not exists：%',v_delivery;
	elsif v_delivery.status not in ('CONFIRMED') then
 		raise exception 'Delivery has not confirmed yet. Cannot revoke. Status: %',v_delivery.status;
 	elsif refund_amount<=0 then
 		raise exception 'Refund amount needs to be positive. Refund amount: %',refund_amount;
	elsif refund_amount>v_delivery.price then
		raise exception '\Refund amount needs to be no greater than delivery price. Refund amount: % | Price: %',refund_amount,v_delivery.price;
 	end if;
	-- fully refund if amount is not specified
	IF refund_amount IS NULL THEN
		v_refund_amount=v_delivery.price;
		v_status='REFUNDED';
	ELSE
		v_refund_amount=refund_amount;
		v_status='PARTIALLY_REFUNDED';
	END IF;
	-- get order id
	SELECT orderid INTO v_orderid FROM orderproduct WHERE id=v_delivery.orderproductid;

	UPDATE account SET balance=balance-v_refund_amount WHERE id=v_delivery.deliveryaccount RETURNING balance INTO tmp_balanceafter;
	insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype) values
		('【撤销】服务供应商分成',v_orderid,v_delivery.orderproductid,v_delivery.deliveryaccount,-v_refund_amount,tmp_balanceafter,'balance');

	-- 标记订单状态
	update projectdelivery set status=v_status,updatedat=(now() AT TIME ZONE 'Asia/Shanghai') where id=delivery_id;

 	raise notice '====end revoke_delivery()====';
RETURN 'success';
END; $function$
;


CREATE OR REPLACE FUNCTION public.revoke_pay(order_id bigint, retain_entitlement boolean DEFAULT false, retain_delivery boolean DEFAULT false)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE 
    v_order record;
    v_balanceactivity record;
   	v_productentitlementtype record;
	v_delivery record;
   	tmp_balanceafter decimal(8,2);
	dynamic_query text;
	v_original_ids text;
	v_revoke_delivery_msg text;
	v_tripleawardhistory record;
begin
	raise notice '====begin revoke_pay(order_id bigint, retain_entitlement boolean DEFAULT false,retain_delivery boolean default false)====';
 	select * into v_order from orders where id=order_id;
    IF v_order IS NULL THEN
		raise exception 'Order does not exists：%',order_id;
	elsif v_order.status not in ('success','settled') then
 		raise exception 'Order has not finished yet. Cannot revoke.';
 	elsif v_order.price <= 0 then
 		raise exception 'Order amount need to be greater than zero.';
 	end if;
 	for v_balanceactivity in (select * from balanceactivity where orderid=order_id and source not like '【%' and source!='服务供应商分成')
 	loop
	 	-- 操作逆分账，按余额变动反向操作分账
		dynamic_query := 
          'UPDATE account SET ' || v_balanceactivity.balancetype || 
          ' = ' || v_balanceactivity.balancetype || 
          ' - ' || v_balanceactivity.amount || 
          ' WHERE id = ' || quote_literal(v_balanceactivity.accountid) || 
          ' RETURNING ' || v_balanceactivity.balancetype || ';';
		raise notice 'query: %',dynamic_query;
		EXECUTE dynamic_query INTO tmp_balanceafter;
		-- 增加余额变动信息
 		insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype) values
 			(concat('【撤销】',v_balanceactivity.source),v_balanceactivity.orderid,v_balanceactivity.orderproductid,v_balanceactivity.accountid,-v_balanceactivity.amount,tmp_balanceafter,v_balanceactivity.balancetype);
		/*IF v_balanceactivity.source='意向金返还(余额)' THEN --直属上级意向金返还，同时还需要回滚冗余表的解锁状态
			update triplecycleaward set pendingreturn=pendingreturn+v_balanceactivity.amount,updatedat=NOW() AT TIME ZONE 'Asia/Shanghai' where linkedaccountid=(select upstreamaccount from account where id=v_order.studentid);
		END IF;*/
 	end loop;
	-- 根据冗余表的audit进行回滚
	for v_tripleawardhistory in (select * from tripleawardhistory where orderid=order_id)
 	loop
		update triplecycleaward set pendingreturn=pendingreturn+v_tripleawardhistory.amount,updatedat=NOW() AT TIME ZONE 'Asia/Shanghai' where id=v_tripleawardhistory.sourceid;
	end loop;
	-- 删除扩展奖的冗余记录
	delete from partitionaward where orderid=v_order.id;
	-- 把原始记录加前缀
	update balanceactivity set source = concat('【已撤销】',source) where orderid=order_id and source not like '【%'  and source!='服务供应商分成';

 	if retain_entitlement=false then -- 撤销权限
 		for v_productentitlementtype in (select * from productentitlementtype where productid in (select productid from orderproduct where orderid=order_id))
 		loop
	 		update studententitlement set expiresat=expiresat - v_productentitlementtype.validdays,updatedat=(now() AT TIME ZONE 'Asia/Shanghai') where studentid=v_order.studentid and entitlementtypeid=v_productentitlementtype.entitlementtypeid;
	 	end loop;
	 	-- 取消优惠券	
	 	UPDATE orderproduct SET couponcode = null WHERE orderid = order_id and couponcode is not null;
	 end if;

	IF retain_delivery=false THEN -- 撤销服务商分账,但原始收入记录不加【已撤销】（因为有可能只是部分撤销）
   		FOR v_delivery IN select * from projectdelivery where orderproductid in (select id from orderproduct where orderid=order_id)
	 	LOOP
			select * into v_revoke_delivery_msg from revoke_delivery(v_delivery.id);
			IF v_revoke_delivery_msg != 'success' THEN
				RETURN v_revoke_delivery_msg;
			END IF;
		END LOOP;
	END IF;

	-- 标记订单状态
	IF retain_entitlement THEN
	 	update orders set status='uncommisioned',updatedat=(now() AT TIME ZONE 'Asia/Shanghai') where id=order_id;
	ELSE
	 	update orders set status='refunded',updatedat=(now() AT TIME ZONE 'Asia/Shanghai') where id=order_id;
	END IF;

 	raise notice '====end revoke_pay()====';
RETURN 'success';
END; $function$
;
