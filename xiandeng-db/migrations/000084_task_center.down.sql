-- 首先删除有外键依赖的表
DROP TABLE IF EXISTS public.accountcertificateattachment;
DROP TABLE IF EXISTS public.accountcertificate;
DROP TABLE IF EXISTS public.userreply;
DROP TABLE IF EXISTS public.prototaskelement;
DROP TABLE IF EXISTS public.prototasktags;
DROP TABLE IF EXISTS public.accounttask;
DROP TABLE IF EXISTS public.taskflowrelation;
DROP TABLE IF EXISTS public.prototask;
DROP TABLE IF EXISTS public.taskflownode;
DROP TABLE IF EXISTS public.taskseries;
DROP TABLE IF EXISTS public.homework;

-- 然后删除枚举类型
DROP TYPE IF EXISTS public.taskflownodetype;
DROP TYPE IF EXISTS public.taskflowrelationtype;
DROP TYPE IF EXISTS public.homeworktype;
DROP TYPE IF EXISTS public.prototaskelementtype;
DROP TYPE IF EXISTS public.accounttaskstatus;