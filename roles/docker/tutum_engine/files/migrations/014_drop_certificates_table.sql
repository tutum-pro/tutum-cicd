-- Migration: Drop old 'certificates' table after data migration
-- This migration is IDEMPOTENT - safe to run multiple times
--
-- WARNING: This migration is DESTRUCTIVE - it will drop the old certificates table!
-- Make sure migration 013_migrate_certificates_data.sql has been run first!
--
-- Pre-requisites:
-- - Data migration (013_migrate_certificates_data.sql) must be completed
-- - Verify that certificate_metadata has all the data before running this

-- Safety check: Only drop if new tables have data
DO $$
DECLARE
    metadata_count INTEGER;
    versions_count INTEGER;
    old_count INTEGER;
BEGIN
    -- Check if old certificates table exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'certificates') THEN
        RAISE NOTICE 'Table "certificates" does not exist - already dropped';
        RETURN;
    END IF;

    -- Count records in new tables
    SELECT COUNT(*) INTO metadata_count FROM certificate_metadata;
    SELECT COUNT(*) INTO versions_count FROM certificate_versions;

    -- Count records in old table
    SELECT COUNT(*) INTO old_count FROM certificates;

    IF old_count > 0 AND metadata_count = 0 THEN
        RAISE EXCEPTION 'Cannot drop certificates table: old table has % records but certificate_metadata is empty. Run 013_migrate_certificates_data.sql first!', old_count;
    END IF;

    IF old_count > 0 AND metadata_count < old_count THEN
        RAISE WARNING 'Old certificates table has % records, but certificate_metadata only has %. Some data may not have been migrated.', old_count, metadata_count;
        -- Continue anyway - this might be intentional (e.g., some certs were deleted)
    END IF;

    RAISE NOTICE 'Safety check passed: certificate_metadata has % records, certificate_versions has % records', metadata_count, versions_count;
END $$;

-- Drop dependent objects first

-- Drop triggers
DROP TRIGGER IF EXISTS update_certificate_status_trigger ON certificates;
DROP TRIGGER IF EXISTS update_certificates_updated_at ON certificates;

-- Drop indexes (they will be dropped automatically with the table, but explicit is better)
DROP INDEX IF EXISTS idx_certificates_channel_pid;
DROP INDEX IF EXISTS idx_certificates_created_at;
DROP INDEX IF EXISTS idx_certificates_custom_metadata;
DROP INDEX IF EXISTS idx_certificates_fingerprint;
DROP INDEX IF EXISTS idx_certificates_group_id;
DROP INDEX IF EXISTS idx_certificates_group_namespace_type;
DROP INDEX IF EXISTS idx_certificates_group_pid;
DROP INDEX IF EXISTS idx_certificates_group_pid_status;
DROP INDEX IF EXISTS idx_certificates_id;
DROP INDEX IF EXISTS idx_certificates_name;
DROP INDEX IF EXISTS idx_certificates_namespace;
DROP INDEX IF EXISTS idx_certificates_namespace_pid;
DROP INDEX IF EXISTS idx_certificates_namespace_pid_status;
DROP INDEX IF EXISTS idx_certificates_not_after;
DROP INDEX IF EXISTS idx_certificates_status;
DROP INDEX IF EXISTS idx_certificates_type;

-- Drop the old certificates table
DROP TABLE IF EXISTS certificates CASCADE;

-- Drop the old sequence if it exists and is not used elsewhere
DROP SEQUENCE IF EXISTS certificates_pid_seq CASCADE;

-- Drop the old function that was specific to certificates table
DROP FUNCTION IF EXISTS update_certificate_status() CASCADE;

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'Old certificates table and related objects have been dropped successfully';
    RAISE NOTICE 'The application now uses certificate_metadata + certificate_versions tables exclusively';
END $$;

-- Add comment documenting the migration
COMMENT ON TABLE certificate_metadata IS 'Certificate metadata - migrated from old certificates table. One record per certificate name.';
COMMENT ON TABLE certificate_versions IS 'Certificate versions - stores version history. Initially one version per certificate from migration.';
