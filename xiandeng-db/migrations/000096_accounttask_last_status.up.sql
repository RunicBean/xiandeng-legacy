ALTER TABLE public.accounttask
ADD COLUMN last_status public.accounttaskstatus;


CREATE OR REPLACE FUNCTION update_last_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update last_status if status is changing
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    NEW.last_status := OLD.status;
  END IF;
  -- Update updated_at timestamp
  NEW.updated_at := (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_update_last_status
BEFORE UPDATE ON public.accounttask
FOR EACH ROW
EXECUTE FUNCTION update_last_status();

