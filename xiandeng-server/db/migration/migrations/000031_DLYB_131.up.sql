-- public.franchisefee definition

-- Drop table

-- DROP TABLE public.franchisefee;

CREATE TYPE accountstatus AS ENUM ('INIT', 'ACTIVE', 'CLOSED');

CREATE TABLE public.franchisefee (
                                     agenttype public."entitytype" NOT NULL,
                                     price numeric(8, 2) NOT NULL,
                                     description text NULL,
                                     CONSTRAINT franchisefee_pk PRIMARY KEY (agenttype)
);

ALTER TABLE public.account ADD status public.accountstatus NULL;