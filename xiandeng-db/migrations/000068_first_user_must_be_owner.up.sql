
CREATE OR REPLACE FUNCTION public.enforce_role_constraints()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    existing_count INTEGER;
    rolename TEXT;
    accountkind roletype;
BEGIN
    -- Retrieve the role details for the new/updated user role
    SELECT r.rolename, r.accountkind
    INTO rolename, accountkind
    FROM roles r
    WHERE r.id = NEW.roleid;

    -- Ensure we're working with a valid role description
    IF rolename IS NULL THEN
        RAISE EXCEPTION 'Role ID % not found in roles table', NEW.roleid;
    END IF;

    -- Check when accountkind is 'STUDENT' and rolename is 'STUDENT'
    IF accountkind = 'STUDENT' AND rolename = 'STUDENT' THEN
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
    IF accountkind = 'STUDENT' AND rolename = 'GUARDIAN_PRIMARY' THEN
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
    IF accountkind IN ('HQ', 'AGENT') AND rolename = 'OWNER' THEN
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
    IF accountkind IN ('HQ', 'AGENT') AND rolename != 'OWNER' THEN
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

    -- 一个user不能同时加入两个学员账号
    IF accountkind = 'STUDENT' THEN
        SELECT COUNT(*)
        INTO existing_count
        FROM useraccountrole uar
        JOIN roles r ON uar.roleid = r.id
        WHERE uar.userid = NEW.userid
          AND r.accountkind = 'STUDENT';

        IF existing_count > 0 THEN
            RAISE EXCEPTION 'Operation blocked: A user cannot join more than 1 student account.';
        END IF;
    END IF;

    -- 一个user不能同时加入两个代理账号
    IF accountkind IN ('HQ', 'AGENT') THEN
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



CREATE OR REPLACE FUNCTION public.agent_to_student(user_id uuid, account_name character varying, u_relationship character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_roleid uuid;
	v_accountid uuid; -- 不管新建or加入，最终的accountid
BEGIN
	RAISE NOTICE '====begin agent_to_student(user_id uuid,account_name character varying,u_relationship character varying)====';
	RAISE NOTICE 'input param: user_id:%, account_name:%, u_relationship:%',user_id,account_name,u_relationship;

	IF account_name IS NULL THEN
		raise exception '账号名不可为空。';
	ELSIF user_id IS NULL THEN
		raise exception '用户名不可为空。';
	ELSIF NOT EXISTS (select from users where id=user_id) THEN
		raise exception '用户不存在。%',user_id;
	ELSIF EXISTS (select from useraccountrole uar,roles r where uar.userid=user_id and uar.roleid=r.id and r.accountkind='STUDENT') THEN
		raise exception '该用户已注册过学生账号。%',user_id;
	END IF;

	-- 生成account
	INSERT INTO ACCOUNT(type,upstreamaccount,accountname) VALUES('STUDENT'::entitytype,
	(select upstreamaccount from account a,useraccountrole uar,roles r where a.id=uar.accountid and uar.userid=user_id and uar.roleid=r.id and r.accountkind in ('HQ','AGENT')),
	account_name) RETURNING id INTO v_accountid;
	IF v_accountid IS NULL THEN
		raise exception 'create account return null.';
	END IF;

	INSERT INTO studentattribute(accountid) VALUES(v_accountid);
	IF u_relationship IS NULL THEN -- 如果没有relationship，则是学生
		SELECT id INTO v_roleid FROM roles WHERE rolename='STUDENT' AND accountkind='STUDENT';
	ELSE -- 家长账号
		SELECT id INTO v_roleid FROM roles WHERE rolename='GUARDIAN_PRIMARY' AND accountkind='STUDENT';	
		INSERT INTO guardian(guardianid,studentid,relationship) VALUES(user_id,v_accountid,u_relationship);			
	END IF;

	-- 生成useraccountrole
	INSERT INTO useraccountrole(userid,accountid,roleid) VALUES(user_id,v_accountid,v_roleid);
	
    RAISE NOTICE '====end agent_to_student()====';
	return 'success';
END;
$function$
;



CREATE OR REPLACE FUNCTION public.student_to_agent(user_id uuid, account_name character varying, account_type entitytype)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_roleid uuid;
	v_accountid uuid; -- 最终的accountid
BEGIN
	RAISE NOTICE '====begin student_to_agent(user_id uuid, account_name character varying, account_type entitytype)====';
	RAISE NOTICE 'input param: user_id:%, account_name:%, account_type:%',user_id,account_name,account_type::text;

	IF account_name IS NULL THEN
		raise exception '账号名不可为空。';
	ELSIF user_id IS NULL THEN
		raise exception '用户名不可为空。';
	ELSIF NOT EXISTS (select from users where id=user_id) THEN
		raise exception '用户不存在。%',user_id;
	ELSIF EXISTS (select from useraccountrole uar,roles r where uar.userid=user_id and uar.roleid=r.id and r.accountkind in ('AGENT','HQ')) THEN
		raise exception '该用户已注册过代理账号。%',user_id;
	ELSIF account_type IS NULL THEN
		raise exception '账号类型不可为空。';
	ELSIF account_type::text not in ('LV2_AGENT','LV1_AGENT','HQ_AGENT') THEN
		raise exception '账号类型有误。%',account_type::text;
	END IF;

	-- 生成account
	INSERT INTO ACCOUNT(type,upstreamaccount,accountname) VALUES(account_type,
	(select upstreamaccount from account a,useraccountrole uar,roles r where a.id=uar.accountid and uar.userid=user_id and uar.roleid=r.id and r.accountkind='STUDENT'),
	account_name) RETURNING id INTO v_accountid;
	IF v_accountid IS NULL THEN
		raise exception 'create account return null.';
	END IF;

	-- 设置role
	SELECT id INTO v_roleid FROM roles WHERE rolename='OWNER' AND accountkind='AGENT';
	
	-- 生成useraccountrole
	INSERT INTO useraccountrole(userid,accountid,roleid) VALUES(user_id,v_accountid,v_roleid);
	
    RAISE NOTICE '====end student_to_agent()====';
	return 'success';
END;
$function$
;
