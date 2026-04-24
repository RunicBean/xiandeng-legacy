-- E2E Test Data Fixtures
-- This file contains minimal test data for E2E testing

-- Test password is "TestPassword123" hashed with bcrypt

-- Create a test HQ account
INSERT INTO account (id, type, reserve_balance, balance, upstream_account, account_name)
VALUES ('00000000-0000-0000-0000-000000000001', 'HEAD_QUARTER', 0, 0, NULL, 'Test HQ')
ON CONFLICT (id) DO NOTHING;

-- Create a test agent account
INSERT INTO account (id, type, reserve_balance, balance, upstream_account, account_name)
VALUES ('00000000-0000-0000-0000-000000000002', 'LV1_AGENT', 0, 1000.00, '00000000-0000-0000-0000-000000000001', 'Test Agent')
ON CONFLICT (id) DO NOTHING;

-- Create agent attribute
INSERT INTO agent_attribute (account_id, province, city)
VALUES ('00000000-0000-0000-0000-000000000002', '广东', '深圳')
ON CONFLICT (account_id) DO NOTHING;

-- Create a test user (agent)
INSERT INTO users (id, password, phone, email, nickname, status, source, account_id)
VALUES (
    '00000000-0000-0000-0000-000000000010',
    '$2a$10$slYQmyNdGzTn7ZLBXBChFOC9f6kFjAqPhccnP6DxlWXx2lPk1C3G6',  -- TestPassword123
    '13800138001',
    'agent@test.com',
    'TestAgent',
    'ACTIVE',
    'test',
    '00000000-0000-0000-0000-000000000002'
) ON CONFLICT (phone) DO NOTHING;

-- Create a test student account
INSERT INTO account (id, type, reserve_balance, balance, upstream_account, account_name)
VALUES ('00000000-0000-0000-0000-000000000003', 'STUDENT', 0, 0, '00000000-0000-0000-0000-000000000002', 'Test Student')
ON CONFLICT (id) DO NOTHING;

-- Create a test user (student)
INSERT INTO users (id, password, phone, email, nickname, status, source, account_id)
VALUES (
    '00000000-0000-0000-0000-000000000011',
    '$2a$10$slYQmyNdGzTn7ZLBXBChFOC9f6kFjAqPhccnP6DxlWXx2lPk1C3G6',  -- TestPassword123
    '13800138002',
    'student@test.com',
    'TestStudent',
    'ACTIVE',
    'test',
    '00000000-0000-0000-0000-000000000003'
) ON CONFLICT (phone) DO NOTHING;

-- Create test invitation code for agent signup (13 characters)
INSERT INTO invitation_code (code, account_id, user_id, create_type, expires_at)
VALUES ('TESTAGENT001X', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000010', 'LV1_AGENT', '2030-12-31 23:59:59')
ON CONFLICT (code) DO NOTHING;

-- Create test invitation code for student signup (13 characters)
INSERT INTO invitation_code (code, account_id, user_id, create_type, expires_at)
VALUES ('TESTSTUDENT00', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000010', 'STUDENT', '2030-12-31 23:59:59')
ON CONFLICT (code) DO NOTHING;

-- Verify data
SELECT 'Test data loaded successfully' as status;
SELECT count(*) as user_count FROM users;
SELECT count(*) as account_count FROM account;