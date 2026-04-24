-- Step 1: Drop the existing foreign key constraint
ALTER TABLE public.liuliustatement DROP CONSTRAINT fk_order;

-- Step 2: Create the function to enforce custom constraint logic
CREATE OR REPLACE FUNCTION check_orderid_constraint()
RETURNS TRIGGER AS $$
BEGIN
    -- Allow orderid to be -1
    IF NEW.orderid = -1 THEN
        RETURN NEW;
    END IF;

    -- Check if orderid exists in the orders table
    IF NOT EXISTS (SELECT 1 FROM public.orders WHERE id = NEW.orderid) THEN
        RAISE EXCEPTION 'orderid % does not exist in orders table', NEW.orderid;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 3: Create the trigger to use the function
CREATE TRIGGER check_orderid_trigger
BEFORE INSERT OR UPDATE ON public.liuliustatement
FOR EACH ROW
EXECUTE FUNCTION check_orderid_constraint();
