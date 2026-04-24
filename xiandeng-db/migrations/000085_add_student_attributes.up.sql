ALTER TABLE public.studentattribute ADD COLUMN entry_date date NULL;
ALTER TABLE public.studentattribute ADD COLUMN degree_years int2 NULL;
ALTER TABLE public.studentattribute ADD COLUMN grade int2 NULL;
ALTER TABLE public.studentattribute ADD COLUMN semester int2 NULL;

CREATE OR REPLACE FUNCTION update_prototask_status_for_account(
    acct_id uuid,
    prototask_ids varchar[],
    new_status accounttaskstatus
)
    RETURNS integer AS $$
DECLARE
    updated_count integer;
BEGIN
    -- 批量更新状态并记录影响的行数
    UPDATE public.accounttask
    SET
        status = new_status,
        updated_at = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text)
    WHERE prototask_id = ANY(prototask_ids) and account_id = acct_id;

    -- 获取更新的记录数
    GET DIAGNOSTICS updated_count = ROW_COUNT;

    -- 返回更新的记录数
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE public.refreshtoken (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    user_id UUID NOT NULL,
    client_id text NOT NULL,
    expires_at timestamp NOT NULL,
    issued_at timestamp NOT NULL,
    token text NOT NULL,
    is_revoked BOOLEAN DEFAULT FALSE, -- 主动失效 session，强制重新获取token
    ip_address VARCHAR(45),             -- 客户端 IP
    created_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,
    updated_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT NULL,

    CONSTRAINT loginsession_user_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
    CONSTRAINT loginsession_pk PRIMARY KEY (id)
);