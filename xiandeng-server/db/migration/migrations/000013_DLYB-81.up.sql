CREATE OR REPLACE FUNCTION public.reset_orderstatus_reaching_limit()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    var_orderproduct record;
    var_purchase_limit int2;
    var_tmp int;
BEGIN
    IF NEW.status = 'success' THEN
        for var_orderproduct in (select id,productid from orderproduct where orderid=NEW.id)
        loop
	        select count(*) into var_tmp from orderproduct op,orders o where op.orderid=o.id and o.status='success' and op.productid=var_orderproduct.productid and o.studentid=NEW.studentid;
            raise notice 'success count: %',var_tmp;
            select purchaselimit into var_purchase_limit from product where id=var_orderproduct.productid;
            if var_purchase_limit > 0 then
            --当purchaselimt>0且成功的purchase数量>=purchaselimit, 设置order.status=success 会把其他的pending orders设置成失败. 设置failure_reason=reached purchase limit=xx            
                if var_purchase_limit <= var_tmp then
                    update orders set status='failed',failurereason='reached purchase limit' where id!=NEW.id and status!='success' and status!='failed' and studentid=NEW.studentid and id in (select op.orderid from orderproduct op,orders o where op.orderid=o.id and o.studentid=NEW.studentid and op.productid=var_orderproduct.productid);
                end if;
            end if;
        end  loop;
    END IF;
    -- Return the updated order to proceed with the update operation
    RETURN NEW;
END;
$function$
;

create or replace trigger trigger_reset_orderstatus_reaching_limit after
update
    of status on
    public.orders for each row
    when ((((old.status)::text is distinct
from
    (new.status)::text)
        and ((new.status)::text = 'success'::text))) execute function reset_orderstatus_reaching_limit();