CREATE OR REPLACE FUNCTION confirm_delivery(delivery_id uuid)
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
		return 'failed. delivery does not exist: %',delivery_id;
 	ELSIF v_delivery.status NOT IN ('PENDING') THEN
        RETURN cast('failed. The delivery has reached final status: ' || v_delivery.status as varchar);
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
		return 'failed. franchiseorder does not exist: %',franchiseorder_id;
 	ELSIF v_franchiseorder.status IN ('settled','declined','refunded') THEN
        RETURN cast('failed. The order has reached final status: ' || v_franchiseorder.status as varchar);
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

DROP FUNCTION public.revoke_pay(int8, bool);

CREATE OR REPLACE FUNCTION public.revoke_pay(order_id bigint, retain_entitlement boolean DEFAULT false,retain_delivery boolean default false)
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
		return cast('failed. Order does not exists：'|| order_id as varchar);
	elsif v_order.status not in ('success','settled') then
 		return 'failed. Order has not finished yet. Cannot revoke.';
 	elsif v_order.price <= 0 then
 		return 'failed. Order amount need to be greater than zero.';
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


CREATE OR REPLACE FUNCTION public.revoke_delivery(delivery_id uuid, refund_amount numeric(8,2) DEFAULT null)
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
		return cast('failed. Delivery does not exists：'|| v_delivery as varchar);
	elsif v_delivery.status not in ('CONFIRMED') then
 		return 'failed. Delivery has not confirmed yet. Cannot revoke. Status: %',v_delivery.status;
 	elsif refund_amount<=0 then
 		return 'failed. Refund amount needs to be positive. Refund amount: %',refund_amount;
	elsif refund_amount>v_delivery.price then
		return 'failed. Refund amount needs to be no greater than delivery price. Refund amount: % | Price: %',refund_amount,v_delivery.price;
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


DROP FUNCTION IF EXISTS public.get_accounts_by_partition_and_depth(uuid, accountpartition);

CREATE OR REPLACE FUNCTION public.get_accounts_by_partition_and_depth(p_account_id uuid, p_partition accountpartition)
 RETURNS TABLE(account_id uuid, account_name character varying,account_type entitytype, sub_level int)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY WITH RECURSIVE account_tree AS (
        -- Anchor member: start with the direct children of the input account
        SELECT
            a.id,
            a.accountname,
			a.type,
            1 AS level
        FROM
            account a
        WHERE
            a.upstreamaccount = p_account_id
            AND a.partition = p_partition

        UNION ALL

        -- Recursive member: find children of the current level accounts
        SELECT
            a.id,
            a.accountname,
			a.type,
            at.level + 1 AS level
        FROM
            account a
            JOIN account_tree at ON a.upstreamaccount = at.id
        WHERE
            a.type IN ('LV1_AGENT', 'LV2_AGENT', 'HQ_AGENT')
            AND at.level < 7
    )
    SELECT id, accountname, type, level
    FROM account_tree
    WHERE level BETWEEN 1 AND 7;
END;
$function$
;


ALTER TABLE partitionaward ADD COLUMN createdat TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL;

CREATE OR REPLACE FUNCTION public.check_orderid_constraint()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Allow orderid to be null or -1
    IF NEW.orderid IS NULL THEN
        RETURN NEW;
    ELSIF NEW.orderid = -1 THEN
        RETURN NEW;
    END IF;

    -- Check if orderid exists in the orders table
    IF NOT EXISTS (SELECT 1 FROM public.orders WHERE id = NEW.orderid) THEN
        RAISE EXCEPTION 'orderid % does not exist in orders table', NEW.orderid;
    END IF;

    RETURN NEW;
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
    SELECT u.accountid INTO v_accountid FROM users u WHERE RIGHT(u.phone, 10) = TRIM(NEW.memo) LIMIT 1;
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


ALTER TABLE triplecycleaward ADD COLUMN lastorderid BIGINT;


CREATE TABLE public.tripleawardhistory (
	id serial4 NOT NULL,
	sourceid uuid NOT NULL,
	amount numeric(8, 2) NOT NULL,
	orderid int8 NOT NULL,
	pendingreturnafter numeric(8, 2) NOT NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT tripleawardhistory_pkey PRIMARY KEY (id),
	CONSTRAINT tripleawardhistory_orderid_fkey FOREIGN KEY (orderid) REFERENCES public.orders(id),
	CONSTRAINT tripleawardhistory_sourceid_fkey FOREIGN KEY (sourceid) REFERENCES public.triplecycleaward(id)
);


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
        RETURN 'failed. Order does not exist: ' || order_id;
    ELSIF EXISTS (SELECT FROM balanceactivity WHERE orderid = order_id) THEN
        RETURN 'failed. The balance activity already exists for this order';
    ELSIF v_order.status IN ('success','settled','uncommisioned','declined','failed','refunded') THEN
        RETURN cast('failed. The order has reached final status: ' || v_order.status as varchar);
    END IF;
    
	select value into v_award_extension_level from datadictionary where key='award-extension-level';--扩展层级

	IF EXISTS (select from get_upstreamaccount_chain(v_order.studentid) where account_id!=v_order.studentid and account_type in ('LV2_AGENT','LV1_AGENT','HQ_AGENT') and account_status!='ACTIVE') THEN--上游账号必须都是active的
		RETURN '付款失败。上游账号状态异常。';
	elsif exists (select from get_upstreamaccount_chain(v_order.studentid) 
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


CREATE OR REPLACE FUNCTION public.log_triple_award_history()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_franchise_fee numeric(8,2);
BEGIN
	raise notice '====begin log_triple_award_history()====';
    IF OLD.pendingreturn != NEW.pendingreturn THEN
        insert into tripleawardhistory(sourceid,amount,orderid,pendingreturnafter)
		values(NEW.id,NEW.pendingreturn-OLD.pendingreturn,NEW.lastorderid,NEW.pendingreturn);
    END IF;

	raise notice '====end log_triple_award_history()====';
    RETURN NEW;
END;
$function$
;


create trigger log_triple_award_history_trigger after update on
    public.triplecycleaward for each row execute function log_triple_award_history();
