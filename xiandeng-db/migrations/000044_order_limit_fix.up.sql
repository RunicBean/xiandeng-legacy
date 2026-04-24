-- Step 1: Drop the existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_reset_orderstatus_reaching_limit ON public.orders;

-- Step 2: Create the updated trigger
CREATE TRIGGER trigger_reset_orderstatus_reaching_limit
AFTER UPDATE OF status ON public.orders
FOR EACH ROW
WHEN (
    OLD.status::text IN ('created', 'pending_confirmation') AND
    NEW.status::text IN ('paid', 'settled') 
)
EXECUTE FUNCTION reset_orderstatus_reaching_limit();


CREATE OR REPLACE FUNCTION public.reset_orderstatus_reaching_limit()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    var_orderproduct record;
    var_purchase_limit int2;
    var_tmp int;
BEGIN
	raise notice '====begin reset_orderstatus_reaching_limit()====';
    for var_orderproduct in (select id,productid from orderproduct where orderid=NEW.id)
    loop
        select count(*) into var_tmp from orderproduct op,orders o where op.orderid=o.id and o.status::text in ('paid','settled','uncommisioned') and op.productid=var_orderproduct.productid and o.studentid=NEW.studentid;
        raise notice 'success count: %',var_tmp;
        select purchaselimit into var_purchase_limit from product where id=var_orderproduct.productid;
        if var_purchase_limit > 0 then
        --当purchaselimt>0且成功的purchase数量>=purchaselimit, 设置order.status=success 会把其他的pending orders设置成失败. 设置failure_reason=reached purchase limit=xx            
            if var_purchase_limit <= var_tmp then
                update orders set status='failed',failurereason='reached purchase limit',updatedat=(now() AT TIME ZONE 'Asia/Shanghai') 
				where id!=NEW.id and status::text in ('created','pending_confirmation') and studentid=NEW.studentid 
				and id in (
					select op.orderid from orderproduct op,orders o 
					where op.orderid=o.id and o.studentid=NEW.studentid and op.productid=var_orderproduct.productid
				);
            end if;
        end if;
    end  loop;

    -- Return the updated order to proceed with the update operation
	raise notice '====end reset_orderstatus_reaching_limit()====';
    RETURN NEW;
END;
$function$
;



-- Step 1: Drop the existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_reset_couponcode_on_failed_status ON public.orders;

-- Step 2: Create the updated trigger with the new conditions
CREATE TRIGGER trigger_reset_couponcode_on_failed_status
AFTER UPDATE OF status ON public.orders
FOR EACH ROW
WHEN (
    OLD.status IS DISTINCT FROM NEW.status AND
    NEW.status::text IN ('failed', 'declined')
)
EXECUTE FUNCTION reset_couponcode_on_failed_status();

CREATE OR REPLACE FUNCTION public.reset_couponcode_on_failed_status()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
	raise notice '====begin reset_couponcode_on_failed_status()====';
    -- Update the couponcode in orderproduct to NULL for the related orderid
    UPDATE orderproduct SET couponcode = NULL WHERE orderproduct.orderid = OLD.id;

    -- Return the updated order to proceed with the update operation
	raise notice '====end reset_couponcode_on_failed_status()====';
    RETURN NEW;
END;
$function$
;

