
CREATE OR REPLACE FUNCTION public.check_withdraw_status()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
	raise notice '====begin .check_withdraw_status()====';
    -- Check if there is already a record with the same accountid and status='REQUESTED'
	raise notice 'new id: %',NEW.id;
    IF (NEW.status::text = 'REQUESTED') THEN
		raise notice 'start checking withdraw...';
        IF EXISTS (
            SELECT 1 FROM withdraw
            WHERE accountid = NEW.accountid
			AND "type" = NEW."type"
            AND status::text IN ('REQUESTED','LOCKED')
            --AND id <> NEW.id
        ) THEN
            RAISE EXCEPTION 'Each accountid can only have one withdraw in REQUESTED/LOCKED status for same withdraw type';
        END IF;
    END IF;
	raise notice '====end .check_withdraw_status()====';
    RETURN NEW;
END;
$function$
;
