CREATE TABLE public.liuliustatement (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	transactionid varchar(255) NOT NULL,
	transactiontime timestamp NOT NULL,
	store varchar(255) NULL,
	cashier varchar(255) NULL,
	item varchar(255) NULL,
	paymentmethod varchar(255) NULL,
	transactionamount numeric(8, 2) NOT NULL,
	fee numeric(8, 2) NULL,
	settleamount numeric(8, 2) NULL,
	memo text NULL,
	filename varchar(64) NULL,
	orderid int8 NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	automationlog text NULL,
	CONSTRAINT liuliustatement_pkey PRIMARY KEY (id),
	CONSTRAINT fk_order FOREIGN KEY (orderid) REFERENCES public.orders(id)
);

ALTER TABLE public.agentattribute ADD COLUMN paymentmethodliuliupay bool DEFAULT true NOT NULL;
ALTER TABLE public.agentattribute ADD COLUMN liuliuqrcode text NULL;
ALTER TABLE public.agentattribute ADD COLUMN liuliustoreaddress text NULL;

ALTER TABLE public.triplecycleaward ADD COLUMN id uuid DEFAULT uuid_generate_v4() NOT NULL;
ALTER TABLE public.triplecycleaward DROP CONSTRAINT triplecycleaward_pkey;
ALTER TABLE public.triplecycleaward ADD CONSTRAINT triplecycleaward_pkey PRIMARY KEY (id);
CREATE INDEX idx_triplecycleaward_accountid ON public.triplecycleaward USING btree (accountid);
CREATE INDEX idx_triplecycleaward_linkedaccountid ON public.triplecycleaward USING btree (linkedaccountid);
CREATE INDEX idx_triplecycleaward_number ON public.triplecycleaward USING btree ("number");

ALTER TABLE public.orders ADD COLUMN settledat TIMESTAMP NULL;

DROP FUNCTION public.pay_success(int8);


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
								-- account的pendingreturn 远大于解锁三单循环的pendingreturn。 解锁三单循环的pendingreturn不需要考虑>0的条件（即使是负数的也接着扣）
								update triplecycleaward set pendingreturn=pendingreturn-(v_product.pricingschedule->>'earnest-return')::numeric,updatedat=NOW() AT TIME ZONE 'Asia/Shanghai' where linkedaccountid=v_direct_upstream_account;
								raise notice '解锁三单循环: 金额% 学生直接上级代理:%',(v_product.pricingschedule->>'earnest-return'),v_direct_upstream_account;
								-- 操作余额变动,记录时间为原时间+2毫秒
								insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
									values('意向金返还(余额)',order_id,v_orderproduct.id,rec.account_id,(v_product.pricingschedule->>'earnest-return')::numeric,tmp_balanceafter,'balance',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond');
								insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype,createdat,updatedat) 
									values('意向金返还(剩余意向金)',order_id,v_orderproduct.id,rec.account_id,-(v_product.pricingschedule->>'earnest-return')::numeric,tmp_balanceafter_reverse,'pendingreturn',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond',NOW() AT TIME ZONE 'Asia/Shanghai' + INTERVAL '2 millisecond');
							END IF;
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


DROP TRIGGER trigger_check_triple_award_pendingreturn ON triplecycleaward;

DROP FUNCTION public.check_triple_award_pendingreturn();


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
          AND o.status IN ('created', 'paid')
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


CREATE TRIGGER after_insert_liuliustatement_trigger
AFTER INSERT ON public.liuliustatement
FOR EACH ROW
EXECUTE FUNCTION after_insert_liuliustatement();


CREATE OR REPLACE FUNCTION public.revoke_pay(order_id bigint, retain_entitlement boolean DEFAULT false)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE 
    v_order record;
    v_balanceactivity record;
   	v_productentitlementtype record;
   	tmp_balanceafter decimal(8,2);
	dynamic_query text;
	v_original_ids text;
begin
	raise notice '====begin revoke_pay(order_id bigint, retain_entitlement boolean DEFAULT false)====';
 	select * into v_order from orders where id=order_id;
    IF v_order IS NULL THEN
		return cast('failed. Order does not exists：'|| order_id as varchar);
	elsif v_order.status not in ('success','settled') then
 		return 'failed. Order has not finished yet. Cannot revoke.';
 	elsif v_order.price <= 0 then
 		return 'failed. Order amount need to be greater than zero.';
 	end if;
 	for v_balanceactivity in (select * from balanceactivity where orderid=order_id and source not like '【%')
 	loop
	 	-- 操作逆分账，按余额变动反向操作分账
    	--dynamic_query := 'update account set ' || v_balanceactivity.balancetype || '=' || v_balanceactivity.balancetype || '-v_balanceactivity.amount,updatedat=(now() AT TIME ZONE ''Asia/Shanghai'') where id=v_balanceactivity.accountid returning ' || v_balanceactivity.balancetype || ' into tmp_balanceafter;';    	   
        --raise notice 'literal: %',quote_literal(v_balanceactivity.balancetype);
        --raise notice 'ident: %',quote_ident(v_balanceactivity.balancetype);
		dynamic_query := 
          'UPDATE account SET ' || v_balanceactivity.balancetype || 
          ' = ' || v_balanceactivity.balancetype || 
          ' - ' || v_balanceactivity.amount || 
          ', updatedat = (NOW() AT TIME ZONE ''Asia/Shanghai'') ' || 
          'WHERE id = ' || quote_literal(v_balanceactivity.accountid) || 
          ' RETURNING ' || v_balanceactivity.balancetype || ';';
		raise notice 'query: %',dynamic_query;
		EXECUTE dynamic_query INTO tmp_balanceafter;
		-- 增加余额变动信息
 		insert into balanceactivity(source,orderid,orderproductid,accountid,amount,balanceafter,balancetype) values
 			(concat('【撤销】',v_balanceactivity.source),v_balanceactivity.orderid,v_balanceactivity.orderproductid,v_balanceactivity.accountid,-v_balanceactivity.amount,tmp_balanceafter,v_balanceactivity.balancetype);
		IF v_balanceactivity.source='意向金返还(余额)' THEN --直属上级意向金返还，同时还需要回滚冗余表的解锁状态
			update triplecycleaward set pendingreturn=pendingreturn+v_balanceactivity.amount,updatedat=NOW() AT TIME ZONE 'Asia/Shanghai' where linkedaccountid=(select upstreamaccount from account where id=v_order.studentid);
		END IF;
 	end loop;
	-- 删除扩展奖的冗余记录
	delete from partitionaward where orderid=v_order.id;
	-- 把原始记录加前缀
	update balanceactivity set source = concat('【已撤销】',source) where orderid=order_id and source not like '【%';

 	if retain_entitlement=false then -- 撤销权限
 		for v_productentitlementtype in (select * from productentitlementtype where productid in (select productid from orderproduct where orderid=order_id))
 		loop
	 		update studententitlement set expiresat=expiresat - v_productentitlementtype.validdays,updatedat=(now() AT TIME ZONE 'Asia/Shanghai') where studentid=v_order.studentid and entitlementtypeid=v_productentitlementtype.entitlementtypeid;
	 	end loop;
	 	-- 取消优惠券	
	 	UPDATE orderproduct SET couponcode = null WHERE orderid = order_id and couponcode is not null;
	 end if;

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

create trigger partitionaward_audit_trigger after
insert
    or
delete
    or
update
    on
    public.partitionaward for each row execute function logaudit();

create trigger franchiseorder_audit_trigger after
insert
    or
delete
    or
update
    on
    public.franchiseorder for each row execute function logaudit();

