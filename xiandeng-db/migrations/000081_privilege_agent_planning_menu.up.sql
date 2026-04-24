  
delete from public.roleprivilege    where id in (
'31faa150-899c-4795-bb8b-6be6b5cbe0f9',
'7cd677cf-b701-4a5b-8e5e-bc1eea4f65af',
'd973d906-cee2-4f5e-8ef1-b24eaabdda0d',
'3f6bdbd0-7fd2-4fc4-a335-43072796b684'
);
    
delete from public.privilege where name='agent_plannings_menu';
    
INSERT INTO public.privilege
("name", description, createdat)
VALUES('agent_planning_menu', '显示所有学员的规划报告', '2025-03-06 21:47:08.777');
 
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('31faa150-899c-4795-bb8b-6be6b5cbe0f9'::uuid, '8d6425cd-b375-4c4d-bf28-87f6796b5ccd'::uuid, 'agent_planning_menu', true, NULL, '2025-03-06 21:50:03.972', '2025-03-06 21:50:03.972');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('7cd677cf-b701-4a5b-8e5e-bc1eea4f65af'::uuid, 'd7c16cdb-86c7-4956-8326-43164f90a15d'::uuid, 'agent_planning_menu', true, NULL, '2025-03-06 21:50:04.280', '2025-03-06 21:50:04.280');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('d973d906-cee2-4f5e-8ef1-b24eaabdda0d'::uuid, '5fcf5356-3cf2-422b-9800-97f27fe76532'::uuid, 'agent_planning_menu', true, NULL, '2025-03-06 21:50:04.576', '2025-03-06 21:50:04.576');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('3f6bdbd0-7fd2-4fc4-a335-43072796b684'::uuid, 'b40f55b8-1810-4557-8ff5-2a32b889cdb6'::uuid, 'agent_planning_menu', true, NULL, '2025-03-06 21:50:04.867', '2025-03-06 21:50:04.867');
