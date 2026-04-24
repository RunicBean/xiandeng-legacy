
DROP TABLE public.privilege;

CREATE TABLE public.privilege (
	"name" varchar(30) NOT NULL,
	description text NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT privilege_pkey PRIMARY KEY ("name")
);


CREATE TABLE public.roleprivilege (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	roleid uuid NOT NULL,
	privname varchar(30) not null,
	isallow boolean,
	isdeny boolean,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT roleprivilege_pk PRIMARY KEY (id),
	CONSTRAINT roleprivilege_roleid_fk FOREIGN KEY (roleid) REFERENCES public.roles(id),
	CONSTRAINT roleprivilege_privname_fk FOREIGN KEY (privname) REFERENCES public.privilege("name")
);
CREATE UNIQUE INDEX idx_roleprivilege_role_priv ON public.roleprivilege USING btree (roleid,privname);
CREATE INDEX idx_roleprivilege_roleid ON public.roleprivilege USING btree (roleid);
CREATE INDEX idx_roleprivilege_privname ON public.roleprivilege USING btree (privname);



CREATE TABLE public.orgprivilege (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	orgid uuid NOT NULL,
	privname varchar(30) not null,
	isallow boolean,
	isdeny boolean,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT orgprivilege_pk PRIMARY KEY (id),
	CONSTRAINT orgprivilege_orgid_fk FOREIGN KEY (orgid) REFERENCES public.organization(id),
	CONSTRAINT orgprivilege_privname_fk FOREIGN KEY (privname) REFERENCES public.privilege(name)
);
CREATE UNIQUE INDEX idx_orgprivilege_org_priv ON public.orgprivilege USING btree (orgid,privname);
CREATE INDEX idx_orgprivilege_orgid ON public.orgprivilege USING btree (orgid);
CREATE INDEX idx_orgprivilege_privname ON public.orgprivilege USING btree (privname);




INSERT INTO privilege ("name", description) VALUES('agent_invitation_code', '显示代理的注册邀请二维码');
INSERT INTO privilege ("name", description) VALUES('agent_myagent_menu', '显示”我的代理“菜单');
INSERT INTO privilege ("name", description) VALUES('agent_delivery_menu', '显示”“菜单');



insert into roleprivilege(roleid,privname,isallow) values(
(select id from roles where accountkind::text='HQ' and rolename='OWNER'),
'agent_invitation_code',
true
);

insert into roleprivilege(roleid,privname,isallow) values(
(select id from roles where accountkind::text='HQ' and rolename='OWNER'),
'agent_myagent_menu',
true
);


insert into roleprivilege(roleid,privname,isallow) values(
(select id from roles where accountkind::text='HQ' and rolename='OWNER'),
'agent_delivery_menu',
true
);


insert into roleprivilege(roleid,privname,isallow) values(
(select id from roles where accountkind::text='HQ' and rolename='ADMIN'),
'agent_invitation_code',
true
);

insert into roleprivilege(roleid,privname,isallow) values(
(select id from roles where accountkind::text='HQ' and rolename='ADMIN'),
'agent_myagent_menu',
true
);


insert into roleprivilege(roleid,privname,isallow) values(
(select id from roles where accountkind::text='HQ' and rolename='ADMIN'),
'agent_delivery_menu',
true
);


insert into roleprivilege(roleid,privname,isallow) values(
(select id from roles where accountkind::text='AGENT' and rolename='OWNER'),
'agent_invitation_code',
true
);

insert into roleprivilege(roleid,privname,isallow) values(
(select id from roles where accountkind::text='AGENT' and rolename='OWNER'),
'agent_myagent_menu',
true
);


insert into roleprivilege(roleid,privname,isallow) values(
(select id from roles where accountkind::text='AGENT' and rolename='OWNER'),
'agent_delivery_menu',
true
);


insert into roleprivilege(roleid,privname,isallow) values(
(select id from roles where accountkind::text='AGENT' and rolename='ADMIN'),
'agent_invitation_code',
true
);

insert into roleprivilege(roleid,privname,isallow) values(
(select id from roles where accountkind::text='AGENT' and rolename='ADMIN'),
'agent_myagent_menu',
true
);


insert into roleprivilege(roleid,privname,isallow) values(
(select id from roles where accountkind::text='AGENT' and rolename='ADMIN'),
'agent_delivery_menu',
true
);


insert into orgprivilege(orgid,privname,isdeny) values(
(select id from organization where uri='linglu'),
'agent_invitation_code',
true
);

insert into orgprivilege(orgid,privname,isdeny) values(
(select id from organization where uri='linglu'),
'agent_myagent_menu',
true
);


insert into orgprivilege(orgid,privname,isdeny) values(
(select id from organization where uri='linglu'),
'agent_delivery_menu',
true
);


UPDATE organization SET config='{"liuliu-qrcode-url": "https://thirdwx.qlogo.cn/mmopen/vi_32/DYAIOgq83eoGeNFkjysxWlupFpdicWGbYibs63QIMsAxx62iblYUmR1QfqQ4nZ10LgaU3PdtJY6ru2DmBJcAEU08w/132"}'::jsonb
WHERE uri='linglu';
