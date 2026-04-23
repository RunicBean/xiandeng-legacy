CREATE OR REPLACE FUNCTION refresh_mv_balance_activity_details()
RETURNS TRIGGER AS $$
BEGIN
    REFRESH MATERIALIZED VIEW public.mv_balance_activity_details;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger on balanceactivity table
CREATE TRIGGER refresh_mv_balance_activity_details_trigger
AFTER INSERT OR UPDATE OR DELETE ON balanceactivity
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_mv_balance_activity_details();