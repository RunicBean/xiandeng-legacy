-- notification_status_trigger.sql
-- 创建触发器函数来验证notification_status状态转换

CREATE OR REPLACE FUNCTION check_notification_status_transition()
RETURNS TRIGGER AS $$
BEGIN
    -- 只在UPDATE操作且notification_status字段实际发生变化时进行检查
    IF TG_OP = 'UPDATE' AND OLD.notification_status IS DISTINCT FROM NEW.notification_status THEN
        
        -- 禁止从SENT状态变更为SENDING状态
        IF OLD.notification_status = 'SENT' AND NEW.notification_status = 'SENDING' THEN
            RAISE EXCEPTION 'Invalid status transition: Cannot change from SENT to SENDING'
                USING ERRCODE = 'check_violation',
                      HINT = 'Status cannot be reverted from SENT to SENDING state',
                      DETAIL = 'Old status: SENT, New status: SENDING';
        END IF;
        
        -- 禁止从FAILED状态变更为SENDING状态  
        IF OLD.notification_status = 'FAILED' AND NEW.notification_status = 'SENDING' THEN
            RAISE EXCEPTION 'Invalid status transition: Cannot change from FAILED to SENDING'
                USING ERRCODE = 'check_violation',
                      HINT = 'Status cannot be reverted from FAILED to SENDING state',
                      DETAIL = 'Old status: FAILED, New status: SENDING';
        END IF;
        
    END IF;   
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 在accountusertaskdata表上创建BEFORE UPDATE触发器
DROP TRIGGER IF EXISTS trigger_check_notification_status_transition ON public.accountusertaskdata;

CREATE TRIGGER trigger_check_notification_status_transition
    BEFORE UPDATE ON public.accountusertaskdata
    FOR EACH ROW
    EXECUTE FUNCTION check_notification_status_transition();

-- 添加函数和触发器的注释说明
COMMENT ON FUNCTION check_notification_status_transition() IS 
'触发器函数：验证notification_status字段的状态转换规则
- 禁止从SENT状态变更为SENDING状态
- 禁止从FAILED状态变更为SENDING状态';

COMMENT ON TRIGGER trigger_check_notification_status_transition ON public.accountusertaskdata IS 
'列级触发器：在更新notification_status字段前检查状态转换的有效性，防止不合理的状态回退';

-- 测试用例和使用示例
/*
=== 测试用例 ===

-- 1. 创建测试数据（需要有效的account_task_id和user_id）
INSERT INTO public.accountusertaskdata (account_task_id, user_id, notification_status) 
VALUES (
    'your-account-task-uuid-here',  -- 替换为有效的account_task_id
    'your-user-uuid-here',          -- 替换为有效的user_id
    'NEW'
);

-- 假设插入的记录ID为 test_id，以下是各种状态转换测试：

-- 2. 允许的状态转换（这些应该成功）

-- NEW -> SENDING
UPDATE public.accountusertaskdata 
SET notification_status = 'SENDING' 
WHERE id = 'test_id';

-- SENDING -> SENT  
UPDATE public.accountusertaskdata 
SET notification_status = 'SENT' 
WHERE id = 'test_id';

-- SENT -> FAILED
UPDATE public.accountusertaskdata 
SET notification_status = 'FAILED' 
WHERE id = 'test_id';

-- FAILED -> NEW
UPDATE public.accountusertaskdata 
SET notification_status = 'NEW' 
WHERE id = 'test_id';

-- 3. 禁止的状态转换（这些会抛出异常）

-- 先设置为SENT状态
UPDATE public.accountusertaskdata 
SET notification_status = 'SENT' 
WHERE id = 'test_id';

-- 尝试 SENT -> SENDING（会被阻止）
UPDATE public.accountusertaskdata 
SET notification_status = 'SENDING' 
WHERE id = 'test_id';
-- 预期错误：ERROR: Invalid status transition: Cannot change from SENT to SENDING

-- 先设置为FAILED状态
UPDATE public.accountusertaskdata 
SET notification_status = 'FAILED' 
WHERE id = 'test_id';

-- 尝试 FAILED -> SENDING（会被阻止）
UPDATE public.accountusertaskdata 
SET notification_status = 'SENDING' 
WHERE id = 'test_id';
-- 预期错误：ERROR: Invalid status transition: Cannot change from FAILED to SENDING

=== 状态转换流程图 ===

允许的转换：
NEW ←→ SENDING
NEW ←→ SENT  
NEW ←→ FAILED
SENDING → SENT
SENDING → FAILED
SENT → FAILED (但不能回到SENDING)
FAILED → NEW (但不能回到SENDING)

禁止的转换：
SENT → SENDING  ❌
FAILED → SENDING ❌

*/
