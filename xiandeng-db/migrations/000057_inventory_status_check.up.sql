
update inventoryorder set status='declined' where status='pending';


CREATE OR REPLACE FUNCTION public.check_inventoryorder_status()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Check if there is already a record with the same accountid and status='REQUESTED'
    IF NEW.status::text = 'pending' AND NEW.type='agent_topup' THEN
        IF EXISTS (
            SELECT FROM inventoryorder
            WHERE accountid = NEW.accountid
			AND productid = NEW.productid
			AND type = NEW.type
            AND status = NEW.status
            AND id <> NEW.id
        ) THEN
            RAISE EXCEPTION 'Each account & product can only have one inventoryorder in pending status';
        END IF;
    END IF;
    RETURN NEW;
END;
$function$
;


create trigger check_inventoryorder_status_trigger before
insert
    or
update
    on
    public.inventoryorder for each row execute function check_inventoryorder_status();


CREATE OR REPLACE FUNCTION upsert_inventory_order()
RETURNS TRIGGER AS $$
BEGIN
  -- Try updating the record; if no rows are affected, insert a new row
  UPDATE inventoryorder 
  SET quantity = NEW.quantity, updatedat = (now() AT TIME ZONE 'Asia/Shanghai')
  WHERE accountid = NEW.accountid 
    AND productid = NEW.productid 
    AND TYPE::text = 'agent_topup' 
    AND status = 'pending';

  IF FOUND THEN
    RETURN NULL; -- Cancel the original INSERT
  ELSE
    RETURN NEW; -- Proceed with the original INSERT
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER inventoryorder_upsert_trigger
BEFORE INSERT ON inventoryorder
FOR EACH ROW
WHEN (NEW.type::text = 'agent_topup')
EXECUTE FUNCTION upsert_inventory_order();
