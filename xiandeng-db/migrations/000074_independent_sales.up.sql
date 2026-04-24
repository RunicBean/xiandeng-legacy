
CREATE TABLE public.ordertags (
	orderid int8 NOT NULL,
	tag varchar(255) NOT NULL,
	CONSTRAINT ordertags_pkey PRIMARY KEY (orderid, tag),
	CONSTRAINT ordertags_orderid_fk FOREIGN KEY (orderid) REFERENCES public.orders(id)
);

INSERT INTO public.privilege
("name", description, createdat)
VALUES('agent_orders_menu', '显示“订单管理”菜单', '2024-12-25 15:08:07.282');
INSERT INTO public.privilege
("name", description, createdat)
VALUES('agent_my_orders_menu', '显示“我的订单”菜单', '2024-12-25 15:08:07.447');
INSERT INTO public.privilege
("name", description, createdat)
VALUES('agent_my_inventory_menu', '显示“我的库存”菜单', '2024-12-25 15:08:07.447');
INSERT INTO public.privilege
("name", description, createdat)
VALUES('agent_inventory_menu', '显示“产品库存”菜单', '2024-12-25 16:27:54.001');

INSERT INTO public.roles
(id, rolename, accountkind, issystem, createdat, updatedat)
VALUES('52fb97ee-d89a-4079-ab14-e541e3161517'::uuid, 'INDEPENDENT_SALES', 'AGENT'::public."roletype", true, '2024-12-25 16:20:42.334', '2024-12-25 16:20:42.334');

UPDATE public.privilege
SET description='显示“服务单”菜单'
WHERE "name"='agent_delivery_menu';

INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('87ae51b2-0c06-482d-bbd5-74f24575f214'::uuid, '5fcf5356-3cf2-422b-9800-97f27fe76532'::uuid, 'agent_orders_menu', true, NULL, '2024-12-25 16:25:53.438', '2024-12-25 16:25:53.438');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('83cf5662-8706-4808-a1a9-8198c9e58e99'::uuid, '8d6425cd-b375-4c4d-bf28-87f6796b5ccd'::uuid, 'agent_orders_menu', true, NULL, '2024-12-25 16:25:53.598', '2024-12-25 16:25:53.598');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('f0918236-731f-4581-bad0-f21b22db58cb'::uuid, 'b40f55b8-1810-4557-8ff5-2a32b889cdb6'::uuid, 'agent_orders_menu', true, NULL, '2024-12-25 16:25:53.762', '2024-12-25 16:25:53.762');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('705913ae-1b2e-48a0-bdad-caf0f1156c89'::uuid, 'd7c16cdb-86c7-4956-8326-43164f90a15d'::uuid, 'agent_orders_menu', true, NULL, '2024-12-25 16:25:53.922', '2024-12-25 16:25:53.922');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('228574a1-79b2-4361-9b1f-42fd54ab163d'::uuid, '5fcf5356-3cf2-422b-9800-97f27fe76532'::uuid, 'agent_inventory_menu', true, NULL, '2024-12-25 16:31:51.275', '2024-12-25 16:31:51.275');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('a7c0cfdc-e182-4b97-bcff-3a073ff2f953'::uuid, '8d6425cd-b375-4c4d-bf28-87f6796b5ccd'::uuid, 'agent_inventory_menu', true, NULL, '2024-12-25 16:31:51.437', '2024-12-25 16:31:51.437');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('43765948-91ac-426a-a37c-a09895c20607'::uuid, 'b40f55b8-1810-4557-8ff5-2a32b889cdb6'::uuid, 'agent_inventory_menu', true, NULL, '2024-12-25 16:31:51.597', '2024-12-25 16:31:51.597');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('a93161f1-d228-4236-904e-de43c19d7cc1'::uuid, 'd7c16cdb-86c7-4956-8326-43164f90a15d'::uuid, 'agent_inventory_menu', true, NULL, '2024-12-25 16:31:51.757', '2024-12-25 16:31:51.757');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('19311e8e-e9df-4882-93da-e6b0055f4e2d'::uuid, '52fb97ee-d89a-4079-ab14-e541e3161517'::uuid, 'agent_my_orders_menu', true, NULL, '2024-12-25 16:33:45.550', '2024-12-25 16:33:45.550');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('f780be20-d619-4e3c-836a-e8ae58bd655a'::uuid, '52fb97ee-d89a-4079-ab14-e541e3161517'::uuid, 'agent_my_inventory_menu', true, NULL, '2024-12-25 16:33:45.710', '2024-12-25 16:33:45.710');
