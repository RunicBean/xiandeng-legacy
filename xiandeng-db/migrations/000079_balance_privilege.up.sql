INSERT INTO public.privilege
("name", description, createdat)
VALUES('agent_balance_menu', '显示“余额概览”菜单', '2025-03-04 18:10:18.135');

INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('e703cf56-fe19-4ba6-a02a-408953027913'::uuid, '8d6425cd-b375-4c4d-bf28-87f6796b5ccd'::uuid, 'agent_balance_menu', true, NULL, '2025-03-04 18:12:20.690', '2025-03-04 18:12:20.690');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('75183289-25bc-44c6-8050-afe724e76e24'::uuid, 'd7c16cdb-86c7-4956-8326-43164f90a15d'::uuid, 'agent_balance_menu', true, NULL, '2025-03-04 18:12:21.011', '2025-03-04 18:12:21.011');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('5484fa8b-acce-44b3-bc0d-505a71c5f23f'::uuid, '5fcf5356-3cf2-422b-9800-97f27fe76532'::uuid, 'agent_balance_menu', true, NULL, '2025-03-04 18:12:21.310', '2025-03-04 18:12:21.310');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('6c1e025a-18e9-44ed-a8c3-4c661f5f4d56'::uuid, 'b40f55b8-1810-4557-8ff5-2a32b889cdb6'::uuid, 'agent_balance_menu', true, NULL, '2025-03-04 18:12:21.618', '2025-03-04 18:12:21.618');
