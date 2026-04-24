-- Create trigger function to auto-create AccountUserTaskData records
-- when a new accounttask is created

CREATE OR REPLACE FUNCTION public.auto_create_accountusertaskdata()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id uuid;
BEGIN
    -- Loop through all users associated with the account
    -- Only include users with rolename in ('GUARDIAN_SUPPLEMENT', 'GUARDIAN_PRIMARY', 'STUDENT')
    FOR v_user_id IN
        SELECT uar.userid
        FROM public.useraccountrole uar
        INNER JOIN public.roles r ON uar.roleid = r.id
        WHERE uar.accountid = NEW.account_id
          AND r.rolename IN ('GUARDIAN_SUPPLEMENT', 'GUARDIAN_PRIMARY', 'STUDENT')
    LOOP
        -- Insert AccountUserTaskData record for each user if not exists
        INSERT INTO public.accountusertaskdata (
            account_task_id,
            user_id,
            notification_sent,
            created_at,
            updated_at
        )
        SELECT
            NEW.id,
            v_user_id,
            false,
            (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'),
            (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai')
        WHERE NOT EXISTS (
            SELECT 1
            FROM public.accountusertaskdata
            WHERE account_task_id = NEW.id
              AND user_id = v_user_id
        );
    END LOOP;

    RETURN NEW;
END;
$$;

-- Create trigger on accounttask table
DROP TRIGGER IF EXISTS trg_auto_create_accountusertaskdata ON public.accounttask;

CREATE TRIGGER trg_auto_create_accountusertaskdata
AFTER INSERT ON public.accounttask
FOR EACH ROW
EXECUTE FUNCTION public.auto_create_accountusertaskdata();

