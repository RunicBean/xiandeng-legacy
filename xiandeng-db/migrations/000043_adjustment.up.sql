CREATE TABLE public.adjustment (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	accountid uuid NOT NULL,
	amount numeric(8, 2) NOT NULL,
	balancetype public."accountbalancetype" NOT NULL,
	"type" uuid NULL, -- Reserved for future use
	notes varchar(255) NOT NULL,
	operateuserid uuid NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT adjustment_pkey PRIMARY KEY (id),
	CONSTRAINT fk_account FOREIGN KEY (accountid) REFERENCES public.account(id),
	CONSTRAINT fk_operateuser FOREIGN KEY (operateuserid) REFERENCES public.users(id)
);

-- Column comments

COMMENT ON COLUMN public.adjustment."type" IS 'Reserved for future use';


CREATE USER read_user WITH PASSWORD 'Yan123ban';
GRANT CONNECT ON DATABASE yanban TO read_user;
GRANT USAGE ON SCHEMA public TO read_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO read_user;
GRANT EXECUTE ON FUNCTION public.get_account_chain(uuid, uuid) TO read_user;
GRANT EXECUTE ON FUNCTION public.get_accounts_by_partition_and_depth(uuid, accountpartition) TO read_user;
GRANT EXECUTE ON FUNCTION public.get_upstreamaccount_chain(uuid) TO read_user;


ALTER TABLE public.balanceactivity ADD COLUMN adjustmentid uuid;
ALTER TABLE public.balanceactivity ADD CONSTRAINT fk_balanceactivity_adjustment FOREIGN KEY (adjustmentid) REFERENCES public.adjustment(id);


CREATE OR REPLACE FUNCTION public.after_adjustment_insert()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE 
   	tmp_balanceafter decimal(8,2);
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
    VALUES ('【调账】' || NEW.notes, NEW.id, NEW.accountid, NEW.amount, tmp_balanceafter, 'balance');

    -- Return the newly inserted row
    RETURN NEW;
END;
$function$
;


 
CREATE TRIGGER adjustment_after_insert
AFTER INSERT ON public.adjustment
FOR EACH ROW
EXECUTE FUNCTION public.after_adjustment_insert();
