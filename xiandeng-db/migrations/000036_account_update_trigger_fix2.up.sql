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
    END IF;

	-- Valid value for upgrade type
	IF (NEW.partition!=OLD.partition or NEW.partition IS NULL) AND OLD.partition in ('L','R') THEN --分区一旦设定，不能更改
		RAISE EXCEPTION 'Invalid partition transition. From: % to %',OLD.partition,NEW.partition;
	END IF;
    
    RETURN NEW;
END;
$function$
;
