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
	coalesce(
	(select upstreamaccount from account a,useraccountrole uar,roles r where a.id=uar.accountid and uar.userid=user_id and uar.roleid=r.id and r.accountkind in ('HQ','AGENT')),
	(select id from account where type::text='HEAD_QUARTER')
	),-- 如果是总部的成员创建学生账号，则上级依然是总部
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
