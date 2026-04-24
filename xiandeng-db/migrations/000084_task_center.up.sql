-- public.prototask definition

-- Drop table

-- DROP TABLE public.prototask;

------------------ Enum types declarations
create type public."taskflownodetype" AS ENUM (
    'CONDITION',
    'PROTO_TASK',
    'INITIATE',
    'ACTION'
);

create type public."taskflowrelationtype" AS ENUM (
    'DEFAULT',
    'CHAIN'
);

CREATE TYPE public."homeworktype" AS ENUM (
	'SINGLE_OPTION',
	'MULTIPLE_OPTION',
	'TEXT'
);

CREATE TYPE public."prototaskelementtype" AS ENUM (
	'RICH_TEXT',
	'VIDEO',
	'NETDISK',
	'DOC',
	'HOMEWORK'
);

CREATE TYPE public."accounttaskstatus" AS ENUM (
	'NEW', -- 未读
	'VIEWED', -- 已读
	'ACKED', -- 已知晓
	'DONE', -- 已完成
	'ABANDONED' -- 放弃
-- 	'NEW_REPLY'
);

------------------- Table declarations
create table public.taskseries (
   id uuid not null default gen_random_uuid (),
   created_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
   title text null,
   constraint taskseries_pkey primary key (id)
);

CREATE TABLE public.taskflownode (
    id uuid not null default gen_random_uuid (),
	title varchar(40) NOT NULL,
    description text NULL,
    condition text NULL,
    position_x real NOT NULL,
    position_y real NOT NULL,
    type public."taskflownodetype" NOT NULL,
    task_series_id uuid null,
    action text null,
    enabled boolean not null default false,
	created_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
	updated_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
	CONSTRAINT taskflownode_pk PRIMARY KEY (id),
    constraint taskflownode_task_series_fkey foreign KEY (task_series_id) references taskseries (id)
);

CREATE TABLE public.prototask (
    id varchar(16) NOT NULL,
    title varchar(40) NOT NULL,
    description text NULL,
    publish_condition text NULL,
    complete_condition text NULL,
    completion_notes text NULL,
    first_publish_datetime timestamp NULL,
    last_publish_datetime timestamp NULL,
    expire_datetime timestamp NULL,
    task_flow_node_id uuid NULL,
    created_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
    updated_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
    CONSTRAINT prototask_pk PRIMARY KEY (id),
    constraint prototask_task_flow_node_fkey foreign KEY (task_flow_node_id) references taskflownode (id)
);

create table public.taskflowrelation (
     id uuid not null default gen_random_uuid (),
     created_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
     updated_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
     source_node_id uuid null,
     target_node_id uuid null,
     task_series_id uuid null,
     type public."taskflowrelationtype" not null default 'DEFAULT'::"taskflowrelationtype",
     condition text null,
     constraint taskflowrelation_pkey primary key (id),
     constraint taskflowrelation_source_node_fkey foreign KEY (source_node_id) references taskflownode (id),
     constraint taskflowrelation_target_node_fkey foreign KEY (target_node_id) references taskflownode (id),
     constraint taskflowrelation_task_series_fkey foreign KEY (task_series_id) references taskseries (id)
);

CREATE TABLE public.accounttask (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_id UUID NOT NULL,
    prototask_id varchar(16) NOT NULL,
    status public."accounttaskstatus" NOT NULL,
    created_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
    updated_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
    CONSTRAINT accounttask_prototask_fkey FOREIGN KEY (prototask_id) REFERENCES public.prototask(id),
    CONSTRAINT accounttask_account_fkey FOREIGN KEY (account_id) REFERENCES public.account(id),
    CONSTRAINT accounttask_pk PRIMARY KEY (id)
);
-- Table Triggers

-- create trigger set_prototask_id_trigger before
-- insert
--     on
--     public.prototask for each row execute function set_id('prototask',
--     'PT');

CREATE TABLE public.prototasktags (
	prototask_id varchar(16) NOT NULL,
	tag varchar(255) NOT NULL,
	CONSTRAINT prototasktags_pkey PRIMARY KEY (prototask_id, tag),
	CONSTRAINT prototasktags_prototask_id_fk FOREIGN KEY (prototask_id) REFERENCES public.prototask(id)
);

CREATE TABLE public.homework (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	"type" public."homeworktype" NOT NULL, 
	topic text NULL,
	a text NULL,
	b text NULL,
	c text NULL,
	d text NULL,
	e text NULL,
	f text NULL,
	g text NULL,
	h text NULL,
	correct_answer text NULL,
	created_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
	updated_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
	CONSTRAINT homework_pk PRIMARY KEY (id)
);

CREATE TABLE public.prototaskelement (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    prototask_id varchar(16) NOT NULL,
    sequence int2 NULL,
    title varchar(40) NOT NULL,
    "type" public."prototaskelementtype" NOT NULL,
    content text NULL,
    --    contentformat text NULL,
    display_condition text NULL,
    skip_condition boolean NOT NULL default false,
    "source" text NULL,
    url text NULL,
    homework_id UUID NULL,
    created_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
    updated_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
    CONSTRAINT prototaskelement_prototask_fkey FOREIGN KEY (prototask_id) REFERENCES public.prototask(id),
    CONSTRAINT prototaskelement_homework_fkey FOREIGN KEY (homework_id) REFERENCES public.homework(id),
    CONSTRAINT prototaskelementtype_pk PRIMARY KEY (id)
);

CREATE TABLE public.userreply (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	user_id uuid NOT NULL,
	account_id uuid NOT NULL,
	prototask_id varchar(16) NOT NULL,
	homework_id uuid NOT NULL,
	"content" text NULL,
	is_correct bool NULL,
	created_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
	updated_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
	CONSTRAINT userreply_pk PRIMARY KEY (id),
	CONSTRAINT userreply_account_fkey FOREIGN KEY (account_id) REFERENCES public.account(id),
	CONSTRAINT userreply_prototask_fkey FOREIGN KEY (prototask_id) REFERENCES public.prototask(id),
	CONSTRAINT userreply_homework_fkey FOREIGN KEY (homework_id) REFERENCES public.homework(id),
	CONSTRAINT userreply_user_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);


CREATE TABLE public.accountcertificate (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	account_id UUID NOT NULL,
	"type" text NULL,
	description text NULL,
	created_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
	updated_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
	CONSTRAINT accountcertificate_account_fkey FOREIGN KEY (account_id) REFERENCES public.account(id),
	CONSTRAINT accountcertificate_pk PRIMARY KEY (id)
);



CREATE TABLE public.accountcertificateattachment (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	account_certificate_id UUID NOT NULL,
	url TEXT NOT NULL,
	CONSTRAINT accountcertificateattachment_pk PRIMARY KEY (id),
	CONSTRAINT accountcertificateattachment_accountcertificate_fk FOREIGN KEY (account_certificate_id) REFERENCES public.accountcertificate(id)
);


