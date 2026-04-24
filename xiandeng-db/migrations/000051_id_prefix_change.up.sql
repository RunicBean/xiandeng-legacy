DROP TRIGGER IF EXISTS set_withdraw_id_trigger ON public.withdraw;

CREATE TRIGGER set_withdraw_id_trigger 
BEFORE INSERT ON public.withdraw 
FOR EACH ROW 
EXECUTE FUNCTION set_id('withdraw', 'TX');

DROP TRIGGER IF EXISTS set_inventoryorder_id_trigger ON public.inventoryorder;

CREATE TRIGGER set_inventoryorder_id_trigger 
BEFORE INSERT ON public.inventoryorder 
FOR EACH ROW 
EXECUTE FUNCTION set_id('inventoryorder', 'KC');
