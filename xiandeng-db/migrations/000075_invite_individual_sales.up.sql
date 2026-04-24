ALTER TABLE public.orgprivilege ALTER COLUMN orgid DROP NOT NULL;


insert into privilege ("name",description) values ('agent_invite_user','显示“邀请用户”按钮');
insert into privilege ("name",description) values ('agent_invite_independent_sales','可以邀请独立销售');

INSERT INTO public.roleprivilege (id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('370c4075-c61f-4025-808f-05dd0658a2e0'::uuid, '5fcf5356-3cf2-422b-9800-97f27fe76532'::uuid, 'agent_invite_user', true, NULL, '2025-01-30 14:54:18.326', '2025-01-30 14:54:18.326');
INSERT INTO public.roleprivilege (id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('c1ac0dd6-4d22-49cc-9a3b-6b28e21a1dd1'::uuid, '5fcf5356-3cf2-422b-9800-97f27fe76532'::uuid, 'agent_invite_independent_sales', true, NULL, '2025-01-30 14:54:18.619', '2025-01-30 14:54:18.619');
INSERT INTO public.roleprivilege (id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('0f7c7279-bcd8-48a0-8dc6-2494034a2a3c'::uuid, 'b40f55b8-1810-4557-8ff5-2a32b889cdb6'::uuid, 'agent_invite_user', true, NULL, '2025-01-30 14:54:18.902', '2025-01-30 14:54:18.902');
INSERT INTO public.roleprivilege (id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('12db24ee-35c6-4f79-926c-0f41c408f4d2'::uuid, 'b40f55b8-1810-4557-8ff5-2a32b889cdb6'::uuid, 'agent_invite_independent_sales', true, NULL, '2025-01-30 14:54:19.182', '2025-01-30 14:54:19.182');

INSERT INTO public.orgprivilege (id, orgid, privname, isallow, isdeny, createdat, updatedat)
VALUES('072063f4-15a5-46fa-9cbf-bcd7c6ea3717'::uuid, NULL, 'agent_invite_independent_sales', NULL, true, '2025-01-30 14:56:29.524', '2025-01-30 14:56:29.524');
INSERT INTO public.orgprivilege (id, orgid, privname, isallow, isdeny, createdat, updatedat)
VALUES('65765339-45f0-4c21-a0be-05908bed3fb2'::uuid, 'cb52ee24-2aa2-462f-ac7c-86490bd87ab8'::uuid, 'agent_invite_independent_sales', NULL, true, '2025-01-30 14:57:25.180', '2025-01-30 14:57:25.180');

ALTER TABLE public.roles ADD rolename_cn varchar(255) NULL;

UPDATE public.roles set rolename_cn='超级管理员' WHERE id='5fcf5356-3cf2-422b-9800-97f27fe76532'::uuid;
UPDATE public.roles set rolename_cn='管理员' WHERE id='8d6425cd-b375-4c4d-bf28-87f6796b5ccd'::uuid;
UPDATE public.roles set rolename_cn='超级管理员' WHERE id='b40f55b8-1810-4557-8ff5-2a32b889cdb6'::uuid;
UPDATE public.roles set rolename_cn='管理员' WHERE id='d7c16cdb-86c7-4956-8326-43164f90a15d'::uuid;
UPDATE public.roles set rolename_cn='学员' WHERE id='241f0967-01ad-4a32-8876-733af187dd78'::uuid;
UPDATE public.roles set rolename_cn='家长（主要）' WHERE id='023d6e7e-82e7-4055-82d1-70b839f1266c'::uuid;
UPDATE public.roles set rolename_cn='家长（补充）' WHERE id='909286fd-68ce-4784-b647-5170df550da6'::uuid;
UPDATE public.roles set rolename_cn='独立销售' WHERE id='52fb97ee-d89a-4079-ab14-e541e3161517'::uuid;

ALTER TABLE public.roles ALTER COLUMN rolename_cn SET NOT NULL;

DROP FUNCTION public.register_user(varchar, uuid, varchar, varchar, varchar, varchar, varchar, varchar, varchar, text, varchar, varchar);

CREATE OR REPLACE FUNCTION public.register_user(invitation_code character varying, exist_account_id uuid, u_phone character varying, nick_name character varying, open_id character varying, account_name character varying, u_password character varying, u_relationship character varying, u_email character varying, avatar_url text, u_source character varying, invite_userid uuid,role_id uuid default null)
 RETURNS new_user_account
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_invitation RECORD;
	v_exist_account RECORD;
	v_new_userid uuid;
	v_invitation_type entitytype; -- 不管新建or加入，最终的account type
	v_password varchar(65535); -- 不管新建or加入，最终的password
	v_invite_userid uuid; -- 不管新建or加入，最终的邀请用户
	v_roleid uuid;
	v_rolename varchar(255);
	v_accountkind roletype;
	v_accountid uuid; -- 不管新建or加入，最终的accountid
    code_type public."entitytype";
    random_code CHAR(13);
BEGIN
	RAISE NOTICE '====begin register_user(invitation_code varchar(13),exist_account_id uuid,u_phone varchar(255),nick_name varchar(255),open_id varchar(255),account_name varchar(255),u_password varchar(65535),u_relationship varchar(255),u_email varchar(255),u_source varchar(255),invite_userid uuid,role_id uuid default null)====';
	RAISE NOTICE 'input param: invitation_code:%, u_phone:%, nick_name:%, open_id:%, account_name:%, u_password:%, u_relationship:%, u_email:%, exist_account_id:%, u_source:%, invite_userid:%'
		,invitation_code,u_phone,nick_name,open_id,account_name,u_password,u_relationship,u_email,exist_account_id, u_source, invite_userid;
	-- 如果exist_account_id非空，则是加入账号，否则新建。
	-- exist_account时，要填入invite_userid. 通过code新建时，invite_user自动填入invitationcode中的userid
	-- 如果account对应学生，u_relationship非空，则是家长，否则学生
	-- 输出：如果accountid不为空，是新建账号。否则是加入账号
	-- 输出：如果userid为空，则没有创建成功
	SELECT * INTO v_invitation FROM invitationcode WHERE code=invitation_code;
	v_password := u_password;
	IF v_invitation IS NULL AND exist_account_id IS NULL THEN
		raise exception 'Invitation code & exist account are both empty.';
	ELSIF v_invitation IS NOT NULL AND exist_account_id IS NOT NULL THEN -- 如果同时有邀请码 和 exist account id，以后者为准
		v_invitation := NULL;
	ELSIF u_phone IS NULL THEN
		raise exception '手机号为必填项。';
	ELSIF nick_name IS NULL THEN
		raise exception '昵称不可为空。';
	ELSIF open_id IS NULL THEN
		raise exception 'openid不可为空。';
	ELSIF exists (select from users where phone=u_phone) THEN
		raise exception '手机号已注册。号码:%',u_phone;
	ELSIF exists (select from users where wechatopenid=open_id) THEN
		raise exception '微信号已注册。Open Id:%',open_id;
	ELSIF exist_account_id IS NULL AND role_id IS NOT NULL THEN
		raise exception '只有在加入账号时才可以选择角色。roleid:%',role_id;
	
	END IF;
	IF exist_account_id IS NOT NULL THEN -- 加入已有账号
		SELECT id,type,orgid INTO v_exist_account FROM account WHERE id=exist_account_id;
		IF v_exist_account IS NULL THEN
			raise exception '待加入的账号不存在。Account:%',exist_account_id;
		END IF;
		v_invitation_type := v_exist_account.type;
		v_invite_userid := invite_userid;
		v_accountid :=  v_exist_account.id;

		-- 设置role 和 附加属性
		IF v_invitation_type in ('HQ_AGENT','LV1_AGENT','LV2_AGENT','HEAD_QUARTER') THEN
			SELECT id,rolename,accountkind INTO v_roleid,v_rolename,v_accountkind FROM roles WHERE id=role_id;
			-- 错误处理
			IF exist_account_id IS NOT NULL AND role_id IS NULL THEN
				raise exception '加入账号时必须选择角色。accountid:%',exist_account_id;
			ELSIF (v_invitation_type::text LIKE '%_AGENT' AND v_accountkind != 'AGENT') OR (v_invitation_type::text='HEAD_QUARTER' AND v_accountkind != 'HQ') THEN
				raise exception '当前账户类型与角色类型不符。当前账户类型:% ,角色类型:%',v_invitation_type,v_accountkind;
			ELSIF v_rolename='INDEPENDENT_SALES' AND v_exist_account.orgid IS NULL THEN -- 独立销售对应的org不能为空
					raise exception 'default org cannot add INDEPENDENT_SALES role.';
			END IF;
		ELSIF u_relationship IS NULL THEN -- 如果没有relationship，则是学生. (同一账号多个学生的情况不用检查，enforce_role_constraints 会检查
			SELECT id,rolename,accountkind INTO v_roleid,v_rolename,v_accountkind FROM roles WHERE rolename='STUDENT' AND accountkind='STUDENT';
		ELSIF NOT EXISTS (SELECT FROM useraccountrole uar,roles r WHERE uar.roleid=r.id AND uar.accountid=v_accountid and r.rolename='GUARDIAN_PRIMARY') THEN -- 家长账号
			SELECT id,rolename,accountkind INTO v_roleid,v_rolename,v_accountkind FROM roles WHERE rolename='GUARDIAN_PRIMARY' AND accountkind='STUDENT';	
		ELSE 
			SELECT id,rolename,accountkind INTO v_roleid,v_rolename,v_accountkind FROM roles WHERE rolename='GUARDIAN_SUPPLEMENT' AND accountkind='STUDENT';				
		END IF;
	ELSE -- 因为invitation_code 与 exist_account_id 互斥，这里相当于通过邀请码新建account
		IF NOT EXISTS (SELECT FROM invitationcode where code=invitation_code) THEN
			RAISE EXCEPTION '邀请码无效:%',invitation_code;
		ELSIF v_invitation.createtype IS NULL THEN
			raise exception 'create account type cannot be null';
		ELSIF account_name IS NULL THEN
			raise exception '账号名不可为空。';
		END IF;
		v_invitation_type := v_invitation.createtype;
		v_invite_userid := v_invitation.userid;
		-- 生成account
		INSERT INTO ACCOUNT(type,upstreamaccount,accountname) VALUES(v_invitation_type,v_invitation.accountid,account_name) RETURNING id INTO v_accountid;
		IF v_accountid IS NULL THEN
			raise exception 'create account return null.';
		END IF;

		-- 设置role 和 附加属性
		IF v_invitation_type::text in ('HQ_AGENT','LV1_AGENT','LV2_AGENT') THEN
			SELECT id,rolename,accountkind INTO v_roleid,v_rolename,v_accountkind FROM roles WHERE rolename='OWNER' AND accountkind='AGENT';
			INSERT INTO agentattribute(accountid) VALUES(v_accountid); 
		ELSE -- 不经过上面分支，则必然是学生账号。 
			INSERT INTO studentattribute(accountid) VALUES(v_accountid);
			IF u_relationship IS NULL THEN -- 如果没有relationship，则是学生
				SELECT id,rolename,accountkind INTO v_roleid,v_rolename,v_accountkind FROM roles WHERE rolename='STUDENT' AND accountkind='STUDENT';
			ELSE -- 家长账号
				SELECT id,rolename,accountkind INTO v_roleid,v_rolename,v_accountkind FROM roles WHERE rolename='GUARDIAN_PRIMARY' AND accountkind='STUDENT';				
			END IF;
		END IF;
	END IF;

	IF v_invitation_type::text!='STUDENT' AND u_relationship IS NOT NULL THEN
		raise exception 'Agent should not assign relationship.';
	END IF;
	IF v_invitation_type::text='STUDENT' AND v_password IS NULL THEN -- 学生默认不用填密码。 此时自动生成一下dummy的密码
		v_password := 'password';
	END IF;

	-- 创建用户
	INSERT INTO users(password,phone,email,nickname,wechatopenid,status,avatarurl,source,referaluserid) VALUES
		(v_password,u_phone,u_email,nick_name,open_id,'ACTIVE',avatar_url,u_source,v_invite_userid) RETURNING id INTO v_new_userid;
	IF v_new_userid IS NULL THEN
		raise exception 'create user return null';
	END IF;
	-- 生成家长属性
	IF v_invitation_type::text='STUDENT' AND u_relationship IS NOT NULL THEN
		INSERT INTO guardian(guardianid,studentid,relationship) VALUES(v_new_userid,v_accountid,u_relationship);
	END IF;
	-- 生成useraccountrole
	INSERT INTO useraccountrole(userid,accountid,roleid) VALUES(v_new_userid,v_accountid,v_roleid);
	-- 生成invitation code
	IF v_invitation_type::text in ('HEAD_QUARTER','HQ_AGENT','LV1_AGENT','LV2_AGENT') THEN
	    FOREACH code_type IN ARRAY ARRAY['HQ_AGENT', 'LV1_AGENT', 'LV2_AGENT', 'STUDENT']::public."entitytype"[] LOOP
	        -- Generate a random 13-character code
	        random_code := (SELECT string_agg(chr((65+floor(random()*26)::integer)),'')FROM generate_series(1,13));
			if exists (select from invitationcode where code=random_code) then -- 监测到code冲突的话，自动重新生成
				LOOP
			        random_code := (SELECT string_agg(chr((65+floor(random()*26)::integer)),'')FROM generate_series(1,13));	
			        IF NOT EXISTS (select from invitationcode where code=random_code) THEN
			            EXIT;
			        END IF;
			    END LOOP;
			end if;
	
	        -- Insert the record into invitationcode table。因为一个用户只能有一个agent访问权限，可以直接通过useraccountrole表获取
	        INSERT INTO invitationcode (code, userid, accountid, createtype)
	        VALUES (random_code,v_new_userid,v_accountid,code_type);
	    END LOOP;
	END IF;

    RAISE NOTICE '====end register_user()====';
	return (v_new_userid,v_accountid,v_accountkind,v_rolename);
END;
$function$
;




CREATE OR REPLACE FUNCTION public.student_join_agent(user_id uuid, account_id uuid, role_id uuid)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
	v_id uuid;
	v_role RECORD;
	v_account RECORD; -- 最终的accountid
	v_uar RECORD;
BEGIN
	RAISE NOTICE '====begin student_join_agent(user_id uuid, account_id uuid, role_id uuid)====';
	RAISE NOTICE 'input param: user_id:%, account_id:%, role_id:%',user_id,account_id,role_id;

	IF user_id IS NULL THEN
		raise exception '用户不可为空。';
	ELSIF account_id IS NULL THEN
		raise exception '账号不可为空。';
	ELSIF role_id IS NULL THEN
		raise exception '角色不可为空。';
	ELSIF NOT EXISTS (select from users where id=user_id) THEN
		raise exception '用户不存在。%',user_id;
	ELSIF EXISTS (select from useraccountrole uar,roles r where uar.userid=user_id and uar.roleid=r.id and r.accountkind::text in ('AGENT','HQ')) THEN
		raise exception '该用户已注册过代理账号。%',user_id;
	END IF;

	select accountkind,rolename INTO v_role from roles where id=role_id;
	select type,orgid into v_account from account where id=account_id;
	SELECT r.accountkind as rolekind,a.type as accounttype,a.upstreamaccount as upstreamaccount INTO v_uar 
		from useraccountrole uar,roles r,account a where uar.userid=user_id and uar.roleid=r.id and uar.accountid=a.id;

	IF v_role IS NULL THEN
		raise exception '该角色不存在。role_id:%',role_id;
	ELSIF v_role.accountkind::text != 'AGENT' THEN
		raise exception '角色类型非代理。';
	ELSIF v_role.rolename::text = 'OWNER' THEN
		raise exception '角色类型不可为owner。';
	ELSIF v_account IS NULL THEN
		raise exception '该账号不存在。account_id:%',account_id;
	ELSIF v_account.type::text not in ('LV2_AGENT','LV1_AGENT','HQ_AGENT') THEN
		raise exception '账号类型非代理。account_id: %',account_id;
	ELSIF v_role.rolename='INDEPENDENT_SALES' AND v_account.orgid IS NULL THEN -- 独立销售对应的org不能为空
		raise exception 'default org cannot add INDEPENDENT_SALES role.';
	ELSIF v_uar IS NULL THEN
		raise exception '没有对应useraccountrole记录。user_id:%',user_id;
	ELSIF v_uar.upstreamaccount != account_id THEN
		raise exception '加入账号(%)必须是学员直接代理(%)。',account_id,v_uar.upstreamaccount;
	ELSIF v_uar.rolekind in ('AGENT','HQ') THEN
		raise exception '该用户已注册过代理账号。%',user_id;
	END IF;
	
	-- 生成useraccountrole
	INSERT INTO useraccountrole(userid,accountid,roleid) VALUES(user_id,account_id,role_id) RETURNING id INTO v_id;
	IF v_id IS NULL THEN
		raise exception 'Join account return null.';
	END IF;
	
    RAISE NOTICE '====end student_join_agent()====';
	return 'success';
END;
$function$
;

