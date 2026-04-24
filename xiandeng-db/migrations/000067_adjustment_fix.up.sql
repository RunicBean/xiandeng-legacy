CREATE OR REPLACE FUNCTION public.after_adjustment_insert()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE 
   	tmp_balanceafter numeric(10,2);
	dynamic_query text;
BEGIN

		dynamic_query := 
          'UPDATE account SET ' || NEW.balancetype || 
          ' = ' || NEW.balancetype || 
          ' + ' || NEW.amount || 
          ' WHERE id = ' || quote_literal(NEW.accountid) || 
          ' RETURNING ' || NEW.balancetype || ';';
		raise notice 'query: %',dynamic_query;
		EXECUTE dynamic_query INTO tmp_balanceafter;
    -- Insert into balanceactivity table
    INSERT INTO public.balanceactivity(source, adjustmentid, accountid, amount, balanceafter, balancetype) 
    VALUES ('【调账】' || NEW.notes, NEW.id, NEW.accountid, NEW.amount, tmp_balanceafter, NEW.balancetype);

    -- Return the newly inserted row
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION get_agent_accountid_by_userid(user_id uuid)
    RETURNS uuid
    LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN (select accountid from useraccountrole
                                      left join account acct on acct.id=useraccountrole.accountid
            where userid=user_id and acct.type in ('LV1_AGENT','LV2_AGENT', 'HQ_AGENT', 'HEAD_QUARTER'));
END;
$$;

CREATE OR REPLACE FUNCTION get_student_accountid_by_userid(user_id uuid)
    RETURNS uuid
    LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN (select accountid from useraccountrole
                                      left join account acct on acct.id=useraccountrole.accountid
            where userid=$1 and acct.type in ('STUDENT')
    );
END;
$$;