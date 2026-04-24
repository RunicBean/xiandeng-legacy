ALTER TABLE public.prototask
ADD COLUMN send_notification bool NOT NULL DEFAULT true;

-- DROP FUNCTION public.auto_create_accountusertaskdata();

CREATE OR REPLACE FUNCTION public.auto_create_accountusertaskdata()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_user_id uuid;
    insert_count INTEGER;
BEGIN
	-- If prototask's send_notification flag is false, skip inserting
	IF (SELECT send_notification FROM prototask WHERE id=NEW.prototask_id)=false THEN
		RETURN NEW;
	END IF;
    -- Loop through all users associated with the account
    -- Only include users with rolename in ('GUARDIAN_SUPPLEMENT', 'GUARDIAN_PRIMARY', 'STUDENT')
    FOR v_user_id IN
        SELECT uar.userid
        FROM public.useraccountrole uar
        INNER JOIN public.roles r ON uar.roleid = r.id
        WHERE uar.accountid = NEW.account_id
          AND r.accountkind = 'STUDENT'
    LOOP
        -- 检查该用户一分钟内已经插入的accountusertaskdata记录数量
        SELECT COUNT(*) INTO insert_count
        FROM accountusertaskdata autd
        WHERE autd.user_id = v_user_id
		AND autd.created_at > CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text - INTERVAL '1 minute';

        -- 如果该用户的记录数少于3条，则插入新记录
        IF insert_count < 3 THEN
	        -- Insert AccountUserTaskData record for each user if not exists
	        INSERT INTO public.accountusertaskdata (
	            account_task_id,
	            user_id
	        )
	        SELECT
	            NEW.id,
	            v_user_id
	        WHERE NOT EXISTS (
	            SELECT 1
	            FROM public.accountusertaskdata
	            WHERE account_task_id = NEW.id
	              AND user_id = v_user_id
	        );
		END IF;
    END LOOP;

    RETURN NEW;
END;
$function$
;
