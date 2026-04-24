CREATE TABLE public.AccountUserTaskData (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_task_id UUID NOT NULL,
    user_id UUID NOT NULL,
    notification_sent boolean DEFAULT false,
    created_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
    updated_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
    CONSTRAINT accountusertaskdata_user_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
    CONSTRAINT accountusertaskdata_accounttask_fkey FOREIGN KEY (account_task_id) REFERENCES public.accounttask(id),
    CONSTRAINT accountusertaskdata_pk PRIMARY KEY (id)
);
