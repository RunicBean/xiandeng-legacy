-- 作业解析
ALTER TABLE public.homework ADD COLUMN explanation text NULL;

-- 作业homework id为空，则为普通对话
ALTER TABLE public.userreply ALTER COLUMN homework_id DROP NOT NULL;

-- 回复改论坛模式, homework_id为空则为公共回复，有值则为私密回复
ALTER TABLE public.userreply ADD COLUMN likes int DEFAULT 0;
ALTER TABLE public.userreply ADD COLUMN refer_reply uuid NULL;

