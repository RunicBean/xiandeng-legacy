-- 创建更新时间自动更新的触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text;
    RETURN NEW;
END;
$$ language 'plpgsql';

COMMENT ON FUNCTION update_updated_at_column() IS '自动更新updated_at字段的触发器函数，使用上海时区时间';



CREATE TRIGGER update_accountusertaskdata_updated_at BEFORE UPDATE ON accountusertaskdata FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();