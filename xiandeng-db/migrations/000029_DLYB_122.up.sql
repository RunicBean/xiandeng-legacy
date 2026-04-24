DROP MATERIALIZED VIEW IF EXISTS public.mv_balance_activity_details;

CREATE MATERIALIZED VIEW public.mv_balance_activity_details
TABLESPACE pg_default
AS SELECT ba.orderid,
          ba.createdat,
          ba.accountid,
          ba.source,
          CASE
              WHEN ba.orderid IS NOT NULL THEN p.productname
              ELSE NULL::character varying
END AS productname,
    child.accountname AS child_accountname,
    CASE child.type
    	WHEN 'HQ_AGENT' THEN '总部代理'
    	WHEN 'LV1_AGENT' THEN '一级代理'
    	WHEN 'LV2_AGENT' THEN '二级代理'
    	WHEN 'STUDENT' THEN '学员'
END AS child_account_type,
    ba.amount,
    ba.balanceafter
   FROM balanceactivity ba
     LEFT JOIN orders o ON ba.orderid = o.id
     LEFT JOIN orderproduct op ON o.id = op.orderid
     LEFT JOIN product p ON op.productid = p.id
     LEFT JOIN account child ON ba.accountid = child.upstreamaccount AND (child.id IN ( SELECT get_account_chain.account_id
           FROM get_account_chain(o.studentid) get_account_chain(account_id)))
WITH DATA;

-- View indexes:
CREATE INDEX idx_mv_accountid ON public.mv_balance_activity_details USING btree (accountid);
CREATE INDEX idx_mv_amount ON public.mv_balance_activity_details USING btree (amount);
CREATE INDEX idx_mv_child_account_type ON public.mv_balance_activity_details USING btree (child_account_type);
CREATE INDEX idx_mv_child_accountname ON public.mv_balance_activity_details USING btree (child_accountname);
CREATE INDEX idx_mv_createdat ON public.mv_balance_activity_details USING btree (createdat);
CREATE INDEX idx_mv_productname ON public.mv_balance_activity_details USING btree (productname);
CREATE INDEX idx_mv_source ON public.mv_balance_activity_details USING btree (source);