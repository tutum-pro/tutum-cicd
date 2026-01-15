-- Migration: Update audit_logs constraints to include NAMESPACE resource type
-- This migration updates the CHECK constraint on audit_logs table

-- Drop the old constraint if it exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.constraint_column_usage
        WHERE constraint_name = 'audit_logs_resource_type_check'
        AND table_name = 'audit_logs'
    ) THEN
        ALTER TABLE audit_logs DROP CONSTRAINT audit_logs_resource_type_check;
        RAISE NOTICE 'Dropped old audit_logs_resource_type_check constraint';
    END IF;
END $$;

-- Add the updated constraint
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.constraint_column_usage
        WHERE constraint_name = 'audit_logs_resource_type_check'
        AND table_name = 'audit_logs'
    ) THEN
        ALTER TABLE audit_logs
        ADD CONSTRAINT audit_logs_resource_type_check
        CHECK (resource_type IN ('CERTIFICATE', 'GROUP', 'NAMESPACE'));
        RAISE NOTICE 'Added updated audit_logs_resource_type_check constraint';
    END IF;
END $$;
