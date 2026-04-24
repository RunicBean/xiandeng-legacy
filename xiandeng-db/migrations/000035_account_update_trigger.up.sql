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
