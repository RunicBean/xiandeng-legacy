DROP INDEX IF EXISTS public.idx_accounttask_account_prototask;


CREATE UNIQUE INDEX idx_accounttask_account_prototask_unique ON public.accounttask (account_id, prototask_id);

ALTER TABLE public.prototask
ADD COLUMN auto_add boolean DEFAULT false NOT NULL;

CREATE OR REPLACE FUNCTION public.studentattribute_auto_add_task()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_task record;
    v_match integer;
BEGIN
    ------------------------------------------------------------------
    -- 1. Fire only when entry_date / majorcode become NON-NULL
    ------------------------------------------------------------------
    RAISE NOTICE '==== begin studentattribute_auto_add_task() ====';

    IF TG_OP = 'INSERT' THEN
        IF NEW.entry_date IS NULL AND NEW.majorcode IS NULL THEN
            RETURN NEW;  -- nothing to do
        END IF;

    ELSIF TG_OP = 'UPDATE' THEN
        IF ((OLD.entry_date IS NOT DISTINCT FROM NEW.entry_date OR NEW.entry_date IS NULL)
            AND (OLD.majorcode IS NOT DISTINCT FROM NEW.majorcode OR NEW.majorcode IS NULL)) THEN
            RETURN NEW;  -- neither column became non-null / changed
        END IF;
    END IF;

    ------------------------------------------------------------------
    -- 2. Candidate prototasks : auto_add = true and NOT expired
    -- 3. Exclude prototasks already in accounttask for this account
    ------------------------------------------------------------------
    FOR v_task IN
        SELECT p.id, p.publish_condition
        FROM public.prototask p
        WHERE p.auto_add = true
          AND (p.expire_datetime IS NULL OR p.expire_datetime > now())
          AND NOT EXISTS (
              SELECT 1
              FROM public.accounttask at
              WHERE at.account_id = NEW.accountid
                AND at.prototask_id = p.id
          )
    LOOP
        ------------------------------------------------------------------
        -- 4. Does this account satisfy publish_condition ?
        --    publish_condition is arbitrary SQL returning a set with an
        --    "id" (uuid) column that lists qualified account ids.
        ------------------------------------------------------------------
        IF v_task.publish_condition IS NULL OR trim(v_task.publish_condition) = '' THEN
            CONTINUE;  -- nothing to evaluate
        END IF;

        v_match := 0;

        EXECUTE format(
            'SELECT 1 FROM (%s) AS sub(id) WHERE id = $1 LIMIT 1',
            v_task.publish_condition
        )
        INTO v_match
        USING NEW.accountid;

        RAISE NOTICE 'v_match: %', v_match;

        ------------------------------------------------------------------
        -- 5. If it matches => insert into accounttask
        ------------------------------------------------------------------
        IF v_match = 1 THEN
            INSERT INTO public.accounttask (account_id, prototask_id, status)
            VALUES (NEW.accountid, v_task.id, 'NEW')
            ON CONFLICT (account_id, prototask_id) DO NOTHING;  -- safety
        END IF;
    END LOOP;

    RAISE NOTICE '==== end studentattribute_auto_add_task() ====';

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_studentattribute_auto_add_task ON public.studentattribute;

CREATE TRIGGER trg_studentattribute_auto_add_task
AFTER INSERT OR UPDATE OF entry_date, majorcode
ON public.studentattribute
FOR EACH ROW
EXECUTE FUNCTION public.studentattribute_auto_add_task();

