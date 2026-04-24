INSERT INTO public.privilege
("name", description, createdat)
VALUES('agent_display_purchase_price', '库存页面显示进货价', '2025-02-24 16:54:36.158');

INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('4e3eec2b-6359-419b-b23b-9f5c5dac7e50'::uuid, '8d6425cd-b375-4c4d-bf28-87f6796b5ccd'::uuid, 'agent_display_purchase_price', true, NULL, '2025-02-24 16:57:53.961', '2025-02-24 16:57:53.961');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('c403c46b-3008-412c-b302-9d5aca17862a'::uuid, 'd7c16cdb-86c7-4956-8326-43164f90a15d'::uuid, 'agent_display_purchase_price', true, NULL, '2025-02-24 16:57:54.327', '2025-02-24 16:57:54.327');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('c43c62c9-5ab3-4152-9559-794cf2879519'::uuid, 'b40f55b8-1810-4557-8ff5-2a32b889cdb6'::uuid, 'agent_display_purchase_price', true, NULL, '2025-02-24 16:57:54.614', '2025-02-24 16:57:54.614');
INSERT INTO public.roleprivilege
(id, roleid, privname, isallow, isdeny, createdat, updatedat)
VALUES('ce1e51ad-8a50-4771-a785-04ddd0b8eec3'::uuid, '5fcf5356-3cf2-422b-9800-97f27fe76532'::uuid, 'agent_display_purchase_price', true, NULL, '2025-02-24 16:57:54.897', '2025-02-24 16:57:54.897');
