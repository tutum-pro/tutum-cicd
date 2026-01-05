-- Migration: 010_add_type_column_and_update_constraints
-- Description: Add 'type' column to certificates and certificate_metadata tables,
--              update unique constraint to allow same name for X509 and secret types
-- Author: System
-- Date: 2025-12-18

BEGIN;

-- Step 1: Add 'type' column to certificates table
-- Default to 'X509' for existing records (backward compatibility)
ALTER TABLE certificates
    ADD COLUMN type VARCHAR(20) NOT NULL DEFAULT 'X509';

-- Add check constraint for type column
ALTER TABLE certificates
    ADD CONSTRAINT certificates_type_check CHECK (type IN ('X509', 'secret'));

-- Step 2: Add 'type' column to certificate_metadata table
ALTER TABLE certificate_metadata
    ADD COLUMN type VARCHAR(20) NOT NULL DEFAULT 'X509';

-- Add check constraint for type column
ALTER TABLE certificate_metadata
    ADD CONSTRAINT certificate_metadata_type_check CHECK (type IN ('X509', 'secret'));

-- Step 3: Update existing records to set correct type based on subject field
-- If subject is NULL or empty, it's a secret; otherwise it's X509
UPDATE certificates
SET type = CASE
    WHEN subject IS NULL OR subject = '' THEN 'secret'
    ELSE 'X509'
END;

UPDATE certificate_metadata cm
SET type = (
    SELECT CASE
        WHEN cv.subject IS NULL OR cv.subject = '' THEN 'secret'
        ELSE 'X509'
    END
    FROM certificate_versions cv
    WHERE cv.certificate_metadata_pid = cm.pid
    ORDER BY cv.version DESC
    LIMIT 1
);

-- Step 4: Drop old unique constraints
ALTER TABLE certificates
    DROP CONSTRAINT IF EXISTS certificates_name_group_namespace_unique;

ALTER TABLE certificate_metadata
    DROP CONSTRAINT IF EXISTS certificate_metadata_name_group_namespace_unique;

-- Step 5: Add new unique constraints including type
-- This allows same name in same group/namespace if type differs (X509 vs secret)
ALTER TABLE certificates
    ADD CONSTRAINT certificates_name_group_namespace_type_unique
    UNIQUE (name, group_pid, namespace_pid, type);

ALTER TABLE certificate_metadata
    ADD CONSTRAINT certificate_metadata_name_group_namespace_type_unique
    UNIQUE (name, group_pid, namespace_pid, type);

-- Step 6: Create index on type column for better query performance
CREATE INDEX IF NOT EXISTS idx_certificates_type ON certificates(type);
CREATE INDEX IF NOT EXISTS idx_certificate_metadata_type ON certificate_metadata(type);

-- Step 7: Create composite index for common queries (group + namespace + type)
CREATE INDEX IF NOT EXISTS idx_certificates_group_namespace_type
    ON certificates(group_pid, namespace_pid, type);

CREATE INDEX IF NOT EXISTS idx_certificate_metadata_group_namespace_type
    ON certificate_metadata(group_pid, namespace_pid, type);

COMMIT;
