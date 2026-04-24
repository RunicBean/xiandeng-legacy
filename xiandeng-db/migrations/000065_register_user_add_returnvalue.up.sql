
DROP FUNCTION public.register_user(varchar, uuid, varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar,varchar);

DROP TYPE public.new_user_acount;

CREATE TYPE public.new_user_account AS (
	userid uuid,
	acocuntid uuid,
	accounttype roletype,
	userrole varchar(255)
);



CREATE OR REPLACE FUNCTION public.register_user(invitation_code varchar(13),exist_account_id uuid,u_phone varchar(255),nick_name varchar(255),open_id varchar(255),account_name varchar(255),u_password varchar(65535),u_relationship varchar(255),u_email varchar(255),avatar_url text,u_source varchar(255),invite_userid varchar(255))
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
	RAISE NOTICE '====begin register_user(invitation_code varchar(13),exist_account_id uuid,u_phone varchar(255),nick_name varchar(255),open_id varchar(255),account_name varchar(255),u_password varchar(65535),u_relationship varchar(255),u_email varchar(255),u_source varchar(255),invite_userid varchar(255))====';
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
	END IF;
	IF exist_account_id IS NOT NULL THEN -- 加入已有账号
		SELECT id,type INTO v_exist_account FROM account WHERE id=exist_account_id;
		IF v_exist_account IS NULL THEN
			raise exception '待加入的账号不存在。Account:%',exist_account_id;
		END IF;
		v_invitation_type := v_exist_account.type;
		v_invite_userid := invite_userid;
		v_accountid :=  v_exist_account.id;

		-- 设置role 和 附加属性
		IF v_invitation_type in ('HQ_AGENT','LV1_AGENT','LV2_AGENT') THEN
			SELECT id,rolename,accountkind INTO v_roleid,v_rolename,v_accountkind FROM roles WHERE rolename='ADMIN' AND accountkind='AGENT';
		ELSIF v_invitation_type = 'HEAD_QUARTER' THEN -- 只有加入已有账号时，才会有总部
			SELECT id,rolename,accountkind INTO v_roleid,v_rolename,v_accountkind FROM roles WHERE rolename='ADMIN' AND accountkind='HQ';
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
		IF v_invitation_type in ('HQ_AGENT','LV1_AGENT','LV2_AGENT') THEN
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
	IF v_invitation_type in ('HEAD_QUARTER','HQ_AGENT','LV1_AGENT','LV2_AGENT') THEN
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
