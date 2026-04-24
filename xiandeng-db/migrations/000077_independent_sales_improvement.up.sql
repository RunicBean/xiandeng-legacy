INSERT INTO public.privilege
("name", description, createdat)
VALUES('agent_students_menu', '显示“学员管理”菜单', '2025-02-17 23:32:31.092');
INSERT INTO public.privilege
("name", description, createdat)
VALUES('agent_my_student_menu', '显示“我的学员”菜单', '2025-02-17 23:32:31.326');


-- indenpendent sales
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('88a4a251-2059-41d6-a81b-cabd44c49df8'::uuid, '52fb97ee-d89a-4079-ab14-e541e3161517'::uuid, 'agent_my_student_menu', true, NULL, '2025-02-17 23:50:29.712', '2025-02-17 23:50:29.712');

-- other agent roles
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('67190bdc-4744-48c3-a29b-0156f8c91c0d'::uuid, 'd7c16cdb-86c7-4956-8326-43164f90a15d'::uuid, 'agent_students_menu', true, NULL, '2025-02-17 23:52:37.717', '2025-02-17 23:52:37.717');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('fdcb197e-1020-49d0-bebc-c1e76fd984b6'::uuid, 'b40f55b8-1810-4557-8ff5-2a32b889cdb6'::uuid, 'agent_students_menu', true, NULL, '2025-02-17 23:52:37.430', '2025-02-17 23:52:37.430');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('7b910862-0088-406d-acfa-d14abaf39336'::uuid, '8d6425cd-b375-4c4d-bf28-87f6796b5ccd'::uuid, 'agent_students_menu', true, NULL, '2025-02-17 23:52:37.149', '2025-02-17 23:52:37.149');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('68f021c0-ba99-4ddd-9354-1c121a1c2d35'::uuid, '5fcf5356-3cf2-422b-9800-97f27fe76532'::uuid, 'agent_students_menu', true, NULL, '2025-02-17 23:52:36.859', '2025-02-17 23:52:36.859');
