alter table agentattribute add column agentcode varchar(64) unique;
ALTER TABLE public.orders ADD failurereason text NULL;