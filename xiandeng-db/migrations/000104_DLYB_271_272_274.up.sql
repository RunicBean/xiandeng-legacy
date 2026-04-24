CREATE TYPE public."notification_status_type" AS ENUM (
	'NEW',
	'SENDING',
	'SENT',
	'FAILED');

ALTER TABLE accountusertaskdata
  ADD COLUMN notification_status notification_status_type NOT NULL DEFAULT 'NEW';

ALTER TABLE accountusertaskdata
  ADD COLUMN retry_count int2 NOT NULL DEFAULT 0;

ALTER TABLE accountusertaskdata
  ADD COLUMN last_error_message TEXT;

ALTER TABLE accountusertaskdata
  DROP column notification_sent;

CREATE UNIQUE INDEX idx_accountusertaskdata_task_user_unique ON public.accountusertaskdata USING btree (account_task_id, user_id);

-- DROP FUNCTION public.auto_create_accountusertaskdata();

CREATE OR REPLACE FUNCTION public.auto_create_accountusertaskdata()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_user_id uuid;
    insert_count INTEGER;
BEGIN
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

ALTER TABLE public.account ALTER COLUMN max_user_count SET NOT NULL;


-- DROP FUNCTION public.studentattribute_auto_add_task();

CREATE OR REPLACE FUNCTION public.studentattribute_auto_add_task()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_task record;
    v_match integer;
BEGIN
    RAISE NOTICE '==== begin studentattribute_auto_add_task() ====';
	raise notice 'major: %, entry_date: %',new.majorcode, new.entry_date;
    ------------------------------------------------------------------
    -- 1. Fire only when entry_date become NON-NULL
    ------------------------------------------------------------------
    IF NEW.entry_date IS NULL THEN
        RETURN NEW;  -- nothing to do
    END IF;

    ------------------------------------------------------------------
    -- 2. Fire only when 在线视频 entitlement presents and not expired
    ------------------------------------------------------------------
	IF NOT EXISTS (
		SELECT FROM studententitlement se
			LEFT JOIN entitlementtype et on se.entitlementtypeid=et.id
			WHERE se.studentid=NEW.accountid 
			AND (se.expiresat > CURRENT_DATE AT TIME ZONE 'Asia/Shanghai'::text OR se.expiresat IS NULL)
			AND et.name='在线视频课'
		)
	THEN
        RETURN NEW;  -- nothing to do
	END IF;
    ------------------------------------------------------------------
    -- 3. Candidate prototasks : auto_add = true and NOT expired and ALREADY published
	-- Note, ALREADY published = last_publish_datetime IS NOT NULL
    -- 4. Exclude prototasks already in accounttask for this account
    ------------------------------------------------------------------
    FOR v_task IN
        SELECT p.id, p.publish_condition
        FROM public.prototask p
        WHERE p.auto_add = true
          AND (p.expire_datetime IS NULL OR p.expire_datetime > now())
		  AND p.last_publish_datetime IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM public.accounttask at
              WHERE at.account_id = NEW.accountid
                AND at.prototask_id = p.id
          )
    LOOP
        ------------------------------------------------------------------
        -- 5. Does this account satisfy publish_condition ?
        --    publish_condition is arbitrary SQL returning a set with an
        --    "id" (uuid) column that lists qualified account ids.
        ------------------------------------------------------------------
		raise notice 'prototask: %, publish_condition: %',v_task.id,v_task.publish_condition;
        IF v_task.publish_condition IS NULL OR trim(v_task.publish_condition) = '' THEN
            CONTINUE;  -- nothing to evaluate
        END IF;

        v_match := 0;
		v_task.publish_condition := regexp_replace(btrim(v_task.publish_condition), ';$', '');

        EXECUTE format(
            'SELECT 1 FROM (%s) AS sub(id) WHERE id = $1 LIMIT 1',
            v_task.publish_condition
        )
        INTO v_match
        USING NEW.accountid;

        RAISE NOTICE 'v_match: %', v_match;

        ------------------------------------------------------------------
        -- 6. If it matches => insert into accounttask
        ------------------------------------------------------------------
        IF v_match = 1 THEN
            INSERT INTO public.accounttask (account_id, prototask_id, status)
            VALUES (NEW.accountid, v_task.id, 'NEW')
            ON CONFLICT (account_id, prototask_id) DO NOTHING;  -- safety
        END IF;
    END LOOP;

    RAISE NOTICE '==== end studentattribute_auto_add_task() ====';

    RETURN NEW;
END;
$function$
;


-- DROP FUNCTION public.enforce_role_constraints();

CREATE OR REPLACE FUNCTION public.enforce_role_constraints()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    existing_count INTEGER;
    v_rolename TEXT;
    v_accountkind roletype;
	v_max_user_count INTEGER;
BEGIN
    -- Retrieve the role details for the new/updated user role
    SELECT r.rolename, r.accountkind
    INTO v_rolename, v_accountkind
    FROM roles r
    WHERE r.id = NEW.roleid;

    -- Ensure we're working with a valid role description
    IF v_rolename IS NULL THEN
        RAISE EXCEPTION 'Role ID % not found in roles table', NEW.roleid;
    END IF;

    -- Check when accountkind is 'STUDENT' and rolename is 'STUDENT'
    IF v_accountkind = 'STUDENT' AND v_rolename = 'STUDENT' THEN
        SELECT COUNT(*)
        INTO existing_count
        FROM useraccountrole uar
        JOIN roles r ON uar.roleid = r.id
        WHERE uar.accountid = NEW.accountid
          AND r.accountkind = 'STUDENT'
          AND r.rolename = 'STUDENT';

        IF existing_count > 0 THEN
            RAISE EXCEPTION 'Operation blocked: A STUDENT role already exists for this account.';
        END IF;
    END IF;

    -- Check when accountkind is 'STUDENT' and rolename is 'GUARDIAN_PRIMARY'
    IF v_accountkind = 'STUDENT' AND v_rolename = 'GUARDIAN_PRIMARY' THEN
        SELECT COUNT(*)
        INTO existing_count
        FROM useraccountrole uar
        JOIN roles r ON uar.roleid = r.id
        WHERE uar.accountid = NEW.accountid
          AND r.accountkind = 'STUDENT'
          AND r.rolename = 'GUARDIAN_PRIMARY';

        IF existing_count > 0 THEN
            RAISE EXCEPTION 'Operation blocked: A GUARDIAN_PRIMARY role already exists for this account.';
        END IF;
    END IF;

    -- Check when accountkind is in ('HQ', 'AGENT') and rolename is 'OWNER'
    IF v_accountkind IN ('HQ', 'AGENT') AND v_rolename = 'OWNER' THEN
        SELECT COUNT(*)
        INTO existing_count
        FROM useraccountrole uar
        JOIN roles r ON uar.roleid = r.id
        WHERE uar.accountid = NEW.accountid
          AND r.accountkind IN ('HQ', 'AGENT')
          AND r.rolename = 'OWNER';

        IF existing_count > 0 THEN
            RAISE EXCEPTION 'Operation blocked: An OWNER role already exists for this account in HQ or AGENT.';
        END IF;
    END IF;

    -- 代理的第一个用户必须是owner
    IF v_accountkind IN ('HQ', 'AGENT') AND v_rolename != 'OWNER' THEN
        SELECT COUNT(*)
        INTO existing_count
        FROM useraccountrole uar
        JOIN roles r ON uar.roleid = r.id
        WHERE uar.accountid = NEW.accountid
          AND r.accountkind IN ('HQ', 'AGENT')
          AND r.rolename = 'OWNER';

        IF existing_count = 0 THEN
            RAISE EXCEPTION 'Operation blocked: Agent / HQ must have OWNER.';
        END IF;
    END IF;

   
    IF v_accountkind = 'STUDENT' THEN
		 -- 一个user不能同时加入两个学员账号
        SELECT COUNT(*)
        INTO existing_count
        FROM useraccountrole uar
        JOIN roles r ON uar.roleid = r.id
        WHERE uar.userid = NEW.userid
          AND r.accountkind = 'STUDENT';

        IF existing_count > 0 THEN
            RAISE EXCEPTION 'Operation blocked: A user cannot join more than 1 student account.';
        END IF;
		
		-- 为后续两个限制准备数据
		SELECT max_user_count INTO v_max_user_count FROM ACCOUNT WHERE id=NEW.accountid;	
        SELECT COUNT(*)
        INTO existing_count -- 同一account里的user数量
        FROM useraccountrole uar
        WHERE uar.accountid=NEW.accountid;

		-- 一个学生账号的用户数量不能超过account.max_user_count
		IF v_max_user_count > 0 AND existing_count >= v_max_user_count THEN
            RAISE EXCEPTION 'Operation blocked: exceed user count limit: %',v_max_user_count;
        END IF;

		-- 一个学生账号的第二个用户不可以是GUARDIAN_SUPPLEMENT
		IF existing_count = 1 AND v_rolename='GUARDIAN_SUPPLEMENT' THEN
			RAISE EXCEPTION 'Operation blocked: 账号里前两个用户不可以都是家长。';
		END IF;
    END IF;

    -- 一个user不能同时加入两个代理账号
    IF v_accountkind IN ('HQ', 'AGENT') THEN
        SELECT COUNT(*)
        INTO existing_count
        FROM useraccountrole uar
        JOIN roles r ON uar.roleid = r.id
        WHERE uar.userid = NEW.userid
          AND r.accountkind IN ('HQ', 'AGENT');

        IF existing_count > 0 THEN
            RAISE EXCEPTION 'Operation blocked: A user cannot join more than 1 agent account.';
        END IF;
    END IF;

    -- If none of the conditions block the operation, allow it
    RETURN NEW;
END;
$function$
;
