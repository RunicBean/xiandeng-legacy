-- DROP FUNCTION public.revoke_pay(int8);

CREATE OR REPLACE FUNCTION public.revoke_pay(order_id bigint,retain_entitlement BOOLEAN DEFAULT FALSE)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE 
    var_order record;
    var_balanceactivity record;
   	var_productentitlementtype record;
   	tmp_balanceafter decimal(8,2);
begin
	raise notice '====begin====';
 	select * into var_order from orders where id=order_id;
 	if var_order.status!='success' then
 		return 'failed. Order status must be "success" to be revoked.';
 	end if;
 	if var_order.paymentmethod = 'wechatpay' then
 		return 'failed. Only offline order can be revoked';
 	end if;
 	if var_order.price <= 0 then
 		return 'failed. Order amount need to be greater than zero.';
 	end if;
 	for var_balanceactivity in (select * from balanceactivity where orderid=order_id)
 	loop
	 	-- 操作逆分账，按余额变动反向操作分账
    	update account set balance = balance - var_balanceactivity.amount,updatedat=(now() AT TIME ZONE 'Asia/Shanghai') where id=var_balanceactivity.accountid returning balance into tmp_balanceafter;
    	-- 增加余额变动信息
 		insert into balanceactivity(id,source,orderid,orderproductid,accountid,amount,balanceafter) values
 			(uuid_generate_v4(),concat('撤销',var_balanceactivity.source),var_balanceactivity.orderid,var_balanceactivity.orderproductid,var_balanceactivity.accountid,-var_balanceactivity.amount,tmp_balanceafter);
 	end loop;
 	if retain_entitlement=false then
 		-- 撤销权限
 		for var_productentitlementtype in (select * from productentitlementtype where productid in (select productid from orderproduct where orderid=order_id))
 		loop
	 		update studententitlement set expiresat=expiresat - var_productentitlementtype.validdays,updatedat=(now() AT TIME ZONE 'Asia/Shanghai') where studentid=var_order.studentid and entitlementtypeid=var_productentitlementtype.entitlementtypeid;
	 	end loop;
	 	-- 取消优惠券	
	 	UPDATE orderproduct SET couponcode = null WHERE orderid = order_id and couponcode is not null;
	 end if;
	-- 标记订单为deleted
 	update orders set status='deleted',updatedat=(now() AT TIME ZONE 'Asia/Shanghai') where id=order_id;
 	raise notice '====end====';
RETURN 'success';
END; $function$
;