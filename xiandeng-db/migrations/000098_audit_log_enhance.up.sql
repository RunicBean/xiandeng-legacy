-- DROP FUNCTION public.logaudit();

CREATE OR REPLACE FUNCTION public.logaudit()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    changes JSONB := '{}';
    v_column_name TEXT;
    new_value TEXT;
	old_row_json JSONB := '{}';
	new_row_json JSONB := '{}';
BEGIN
	raise notice 'initial changes: %',changes;
    IF TG_OP = 'INSERT' THEN
        INSERT INTO auditlog(table_name, operation, user_name, new_data) VALUES (TG_TABLE_NAME, 'I', current_user, row_to_json(NEW)::jsonb  -'createdat'-'updatedat'-'created_at'-'updated_at');
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
		-- get JSON of row data
		new_row_json := row_to_json(NEW)::JSONB;
		old_row_json := row_to_json(OLD)::JSONB -'createdat'-'updatedat'-'created_at'-'updated_at';
        -- Iterate over each column of the row, excluding PRIMARY KEY
        FOR v_column_name IN
            SELECT column_name FROM information_schema.columns WHERE table_name = TG_TABLE_NAME AND column_name NOT IN 
				(SELECT kcu.column_name FROM information_schema.table_constraints tc JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name AND tc.table_name = kcu.table_name WHERE tc.table_name = TG_TABLE_NAME AND tc.constraint_type = 'PRIMARY KEY')
				AND column_name NOT IN ('createdat', 'updatedat', 'created_at', 'updated_at')
        LOOP
            -- Get the new value of the column
            EXECUTE format('SELECT ($1).%I', v_column_name) INTO new_value USING NEW;
			raise notice 'column to eval: %, value:%, old:%, new:%',v_column_name,new_value,old_row_json ->> v_column_name,new_row_json ->> v_column_name;
            -- Check if the value has changed
            IF new_row_json ->> v_column_name IS DISTINCT FROM old_row_json ->> v_column_name THEN
                -- Add the changed column and its new value to the JSONB object
                --changes := jsonb_set(changes, ARRAY[v_column_name], to_jsonb(new_value));
			changes :=
			    jsonb_set(
			        changes,
			        ARRAY[v_column_name],
			        COALESCE(to_jsonb(new_value), 'null'::jsonb),  -- write JSON null
			        true                                           -- create missing
			    );	
			raise notice 'changes: %',changes;
				--raise notice 'table:%, col:%, new val:%, json:%, changes:%',TG_TABLE_NAME,v_column_name,new_value,new_row_json ->> v_column_name,changes;
            END IF;
        END LOOP;
        -- Insert the audit record if there are changes
		raise notice 'final changes: %',changes;	
        IF changes != '{}' THEN
			INSERT INTO auditlog(table_name, operation, user_name, old_data, new_data) VALUES (TG_TABLE_NAME, 'U', current_user,old_row_json,changes);
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditlog(table_name, operation, user_name, old_data) VALUES (TG_TABLE_NAME, 'D', current_user, row_to_json(OLD)::jsonb -'createdat'-'updatedat'-'created_at'-'updated_at');
        RETURN OLD;
    END IF;
END;
$function$
;
