CREATE TABLE public.franchiseorder (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	accountid uuid NOT NULL,
	status varchar(255) DEFAULT 'PENDING'::character varying NULL,
	paymentmethod varchar(255) NULL,
	originaltype public."entitytype" NULL,
	targettype public."entitytype" NOT NULL,
	pendingfee numeric(8, 2) NOT NULL,
	createdat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	updatedat timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NULL,
	CONSTRAINT franchiseorder_pkey PRIMARY KEY (id),
	CONSTRAINT fk_accountid FOREIGN KEY (accountid) REFERENCES public.account(id)
);

create trigger check_pending_status_trigger before
insert
    or
update
    on
    public.franchiseorder for each row execute function check_pending_status();
create trigger set_pendingfee_before_insert before
insert
    on
    public.franchiseorder for each row execute function calculate_pendingfee();