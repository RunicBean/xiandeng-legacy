ALTER TABLE public.agentattribute
    ADD COLUMN demo_flag bool NOT NULL DEFAULT false;

ALTER TABLE agentattribute
    ADD COLUMN demo_account UUID,
    ADD CONSTRAINT fk_agentattribute_demo_account
        FOREIGN KEY (demo_account)
            REFERENCES account(id)
            ON DELETE SET NULL;

-- 创建触发器函数
CREATE OR REPLACE FUNCTION trg_check_demo_account()
    RETURNS TRIGGER AS $$
BEGIN
    -- 只在 demo_flag = true 时检查
    IF NEW.demo_flag THEN
        IF NEW.demo_account IS NULL THEN
            RAISE EXCEPTION 'demo_flag is true but demo_account is null';
        ELSIF (SELECT type FROM account where id=NEW.demo_account) != 'STUDENT'::entitytype THEN
            RAISE EXCEPTION 'demo_flag is not a student account';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--  把触发器挂到表上
CREATE TRIGGER tg_agentattribute_demo_check
    BEFORE INSERT OR UPDATE ON public.agentattribute
    FOR EACH ROW
EXECUTE FUNCTION trg_check_demo_account();
