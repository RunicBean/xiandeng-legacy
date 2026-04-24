-- 1. Index on account_id
CREATE INDEX idx_accounttask_account_id
  ON public.accounttask (account_id);

-- 2. Index on prototask_id
CREATE INDEX idx_accounttask_prototask_id
  ON public.accounttask (prototask_id);

-- 3. Composite index on (account_id, prototask_id)
CREATE INDEX idx_accounttask_account_prototask
  ON public.accounttask (account_id, prototask_id);
