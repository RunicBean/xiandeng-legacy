CREATE USER app_user WITH PASSWORD 'I3d75X$4_]Cn';

-- Grant the user permission to connect to the database
GRANT CONNECT ON DATABASE yanban TO app_user;

-- Grant the user usage on the schema
GRANT USAGE ON SCHEMA public TO app_user;

-- Grant DML privileges on all current tables
GRANT SELECT, INSERT, UPDATE, delete, TRIGGER  ON ALL TABLES IN SCHEMA public TO app_user;

-- Ensure the privileges are granted on any new tables created in the future
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ,TRIGGER ON TABLES TO app_user;

-- Grant EXECUTE privilege on all current functions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO app_user;

-- Ensure the EXECUTE privilege is granted on any new functions created in the future
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO app_user;

-- Grant privilege on all sequence
DO $$
DECLARE
    seq RECORD;
BEGIN
    FOR seq IN SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = 'public'
    LOOP
        EXECUTE format('GRANT USAGE, SELECT ON SEQUENCE %I TO app_user', seq.sequence_name);
    END LOOP;
END $$;

-- Ensure the privilege is granted on any new sequence created in the future
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO app_user;