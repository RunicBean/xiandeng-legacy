-- DROP FUNCTION public.pay_success(int8, bool, bool);

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
								update productinventory set quantity=quantity-1,lastorderid=v_order.id,updatedat=NOW() AT TIME ZONE 'Asia/Shanghai' where productid=v_orderproduct.productid AND accountid=rec.account_id;
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



CREATE OR REPLACE FUNCTION public.confirm_inventory(inventoryorder_id character)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_inventoryorder RECORD;
	v_remaining_price numeric(10,2);
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
	INSERT INTO productinventory (accountid,productid,quantity,lastinventoryorderid)
	VALUES (v_inventoryorder.accountid,v_inventoryorder.productid,v_inventoryorder.quantity,v_inventoryorder.id)
	ON CONFLICT (accountid,productid)
	DO UPDATE SET quantity=productinventory.quantity+v_inventoryorder.quantity,lastinventoryorderid=v_inventoryorder.id;
	update inventoryorder set status='settled' where id=v_inventoryorder.id;

    RAISE NOTICE '====end confirm_inventory()====';
	RETURN 'success';
END;
$function$
;



CREATE OR REPLACE FUNCTION public.add_inventory()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_remaining_price numeric(10,2);
	v_account RECORD;
	v_account_after RECORD;
BEGIN
	raise notice '====begin add_inventory()====';
    IF NEW.type::text = 'hq_initiated' THEN
		INSERT INTO productinventory (accountid,productid,quantity,lastinventoryorderid)
		VALUES (NEW.accountid,NEW.productid,NEW.quantity,NEW.id)
		ON CONFLICT (accountid,productid)
		DO UPDATE SET quantity = productinventory.quantity + NEW.quantity,lastinventoryorderid=NEW.id;
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
		INSERT INTO productinventory (accountid,productid,quantity,lastinventoryorderid)
		VALUES (NEW.accountid,NEW.productid,NEW.quantity,NEW.id)
		ON CONFLICT (accountid,productid)
		DO UPDATE SET quantity = productinventory.quantity + NEW.quantity,lastinventoryorderid=NEW.id;
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


CREATE OR REPLACE FUNCTION public.upsert_inventory_order()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  -- Try updating the record; if no rows are affected, insert a new row
  -- 为了保证每个agent同一个商品只能有一个active的进货单。如果agent_topup类型存在（其他类型会直接完成，不会卡在active状态），则更新已有进货单。
  UPDATE inventoryorder 
  SET quantity = NEW.quantity, updatedat = (now() AT TIME ZONE 'Asia/Shanghai')
  WHERE accountid = NEW.accountid 
    AND productid = NEW.productid 
    AND TYPE::text = 'agent_topup' 
    AND status = 'pending';

  -- FOUND is a special variable in PL/pgSQL that is automatically set to true if the last SQL command affected one or more rows; otherwise, it is false.
  -- If the UPDATE affects any rows (FOUND is true), the function returns NULL, indicating that the original INSERT should be canceled.	
  IF FOUND THEN
    RETURN NULL; -- Cancel the original INSERT
  ELSE
    RETURN NEW; -- Proceed with the original INSERT
  END IF;
END;
$function$
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
   	tmp_balanceafter decimal(10,2);
	dynamic_query text;
	v_original_ids text;
	v_revoke_delivery_msg text;
	v_tripleawardhistory record;
	v_direct_upstream_account UUID;
    v_orderproduct record;
begin
	raise notice '====begin revoke_pay(order_id bigint, retain_entitlement boolean DEFAULT false,retain_delivery boolean default false)====';
 	select * into v_order from orders where id=order_id;
    IF v_order IS NULL THEN
		raise exception 'Order does not exists：%',order_id;
	elsif v_order.status IS NOT NULL and v_order.status::text not in ('success','settled') then
 		raise exception 'Order has not finished yet. Cannot revoke.';
 	elsif v_order.price <= 0 then
 		raise exception 'Order amount need to be greater than zero.';
 	end if;
	
	-- 初始化变量
	SELECT upstreamaccount INTO v_direct_upstream_account FROM account where id=v_order.studentid;

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
		-- 还一个库存回去
		if v_order.paymentmethod IS NOT NULL and v_order.paymentmethod::text in ('inventory_agent','inventory_student') then
		    FOR v_orderproduct IN (SELECT id,productid FROM orderproduct WHERE orderid = order_id) 
			LOOP 
				update productinventory set quantity=quantity+1,lastorderid=v_order.id,
				updatedat=NOW() AT TIME ZONE 'Asia/Shanghai' where productid=v_orderproduct.productid AND accountid=v_direct_upstream_account;
			END LOOP;
		end if;
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

