CREATE OR REPLACE FUNCTION public.get_account_chain(accid uuid)
 RETURNS TABLE(account_id uuid)
 LANGUAGE plpgsql
AS $function$
declare var_upstream_account UUID;
begin	
    return query select accid;
	select upstreamaccount into var_upstream_account from account where id=accid;
    if (select type from account where id=accid) != 'HEAD_QUARTER' then
   	    return query select * from get_account_chain(var_upstream_account);
    end if;
END; $function$
;

create MATERIALIZED VIEW public.mv_balance_activity_details AS
SELECT
    ba.orderid,
    ba.createdat,
    ba.accountid,
    ba.source,
    CASE
        WHEN ba.orderid IS NOT NULL THEN p.productname
        ELSE NULL
    END AS productname,
    child.accountname AS child_accountname,
    child.type AS child_account_type,
    ba.amount,
    ba.balanceafter
FROM
    public.balanceactivity AS ba
LEFT JOIN
    public.orders AS o ON ba.orderid = o.id
LEFT JOIN
    public.orderproduct AS op ON o.id = op.orderid
LEFT JOIN
    public.product AS p ON op.productid = p.id
LEFT JOIN
    public.account AS child ON ba.accountid = child.upstreamaccount 
   and child.id in (select account_id from get_account_chain(o.studentid));
 
CREATE INDEX idx_mv_createdat ON public.mv_balance_activity_details (createdat);
CREATE INDEX idx_mv_accountid ON public.mv_balance_activity_details (accountid);
CREATE INDEX idx_mv_productname ON public.mv_balance_activity_details (productname);
CREATE INDEX idx_mv_source ON public.mv_balance_activity_details (source);
CREATE INDEX idx_mv_child_accountname ON public.mv_balance_activity_details (child_accountname);
CREATE INDEX idx_mv_child_account_type ON public.mv_balance_activity_details (child_account_type);
CREATE INDEX idx_mv_amount ON public.mv_balance_activity_details (amount);