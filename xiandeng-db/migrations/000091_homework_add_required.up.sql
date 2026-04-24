-- 作业是否为必填（提交作业用）
ALTER TABLE public.homework ADD COLUMN required bool DEFAULT false;

-- 任务作业是否已提交
ALTER TABLE public.accounttask ADD COLUMN homework_submitted bool DEFAULT false;
