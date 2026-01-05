-- Migration: 003_unique_name_per_group_namespace
-- Description: Change certificate name uniqueness from global to (name, group_pid, namespace_pid)
-- Author: System
-- Date: 2025-11-20

BEGIN;

-- Drop the old unique constraint on name
ALTER TABLE certificates DROP CONSTRAINT IF EXISTS certificates_name_key;

-- Add composite unique constraint on (name, group_pid, namespace_pid)
-- This allows the same certificate name to be used in different groups or namespaces
ALTER TABLE certificates
    ADD CONSTRAINT certificates_name_group_namespace_unique
    UNIQUE (name, group_pid, namespace_pid);

-- Update certificate_metadata table similarly
ALTER TABLE certificate_metadata DROP CONSTRAINT IF EXISTS certificate_metadata_name_key;

ALTER TABLE certificate_metadata
    ADD CONSTRAINT certificate_metadata_name_group_namespace_unique
    UNIQUE (name, group_pid, namespace_pid);

COMMIT;
