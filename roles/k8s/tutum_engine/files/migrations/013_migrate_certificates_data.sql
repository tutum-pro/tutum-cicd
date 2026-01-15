-- Migration: Migrate data from old 'certificates' table to new versioning tables
-- This migration is IDEMPOTENT - safe to run multiple times
--
-- Pre-requisites:
-- - certificate_metadata and certificate_versions tables must exist (001_add_versioning.sql)
-- - type column must exist in certificate_metadata (010_add_type_column_and_update_constraints.sql)
-- - is_effective column must exist in certificate_versions (012_add_is_effective_column.sql)

-- Only run if certificates table exists AND has data AND certificate_metadata is empty
DO $$
DECLARE
    old_cert_count INTEGER;
    new_cert_count INTEGER;
    migrated_count INTEGER := 0;
    cert_record RECORD;
    metadata_pid BIGINT;
BEGIN
    -- Check if old certificates table exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'certificates') THEN
        RAISE NOTICE 'Table "certificates" does not exist - nothing to migrate';
        RETURN;
    END IF;

    -- Count records in old table
    SELECT COUNT(*) INTO old_cert_count FROM certificates;

    IF old_cert_count = 0 THEN
        RAISE NOTICE 'Table "certificates" is empty - nothing to migrate';
        RETURN;
    END IF;

    -- Count records in new table
    SELECT COUNT(*) INTO new_cert_count FROM certificate_metadata;

    IF new_cert_count > 0 THEN
        RAISE NOTICE 'Table "certificate_metadata" already has % records - skipping migration to avoid duplicates', new_cert_count;
        RETURN;
    END IF;

    RAISE NOTICE 'Starting migration of % certificates from old table...', old_cert_count;

    -- Migrate each certificate
    FOR cert_record IN
        SELECT * FROM certificates ORDER BY created_at ASC
    LOOP
        -- Insert into certificate_metadata
        INSERT INTO certificate_metadata (
            id,
            name,
            group_pid,
            namespace_pid,
            group_id,
            namespace,
            custom_metadata,
            created_at,
            created_by,
            updated_at,
            updated_by,
            type
        ) VALUES (
            cert_record.id,
            cert_record.name,
            cert_record.group_pid,
            cert_record.namespace_pid,
            cert_record.group_id,
            cert_record.namespace,
            cert_record.custom_metadata,
            cert_record.created_at,
            cert_record.created_by,
            cert_record.updated_at,
            cert_record.updated_by,
            COALESCE(cert_record.type, 'X509')
        )
        RETURNING pid INTO metadata_pid;

        -- Insert into certificate_versions as version 1
        INSERT INTO certificate_versions (
            certificate_metadata_pid,
            version,
            certificate_pem,
            private_key_pem,
            ca_chain_pem,
            subject,
            issuer,
            serial_number,
            not_before,
            not_after,
            fingerprint_sha256,
            subject_alt_names,
            key_usage,
            extended_key_usage,
            is_ca,
            status,
            days_until_expiry,
            created_at,
            created_by,
            is_effective,
            effective_since
        ) VALUES (
            metadata_pid,
            1,  -- First version
            cert_record.certificate_pem,
            cert_record.private_key_pem,
            cert_record.ca_chain_pem,
            cert_record.subject,
            cert_record.issuer,
            cert_record.serial_number,
            cert_record.not_before,
            cert_record.not_after,
            cert_record.fingerprint_sha256,
            cert_record.subject_alt_names,
            cert_record.key_usage,
            cert_record.extended_key_usage,
            cert_record.is_ca,
            cert_record.status,
            cert_record.days_until_expiry,
            cert_record.created_at,
            cert_record.created_by,
            -- Set is_effective based on validity window
            CASE
                WHEN cert_record.status IN ('REVOKED', 'INVALID') THEN FALSE
                WHEN cert_record.not_before IS NOT NULL AND cert_record.not_before > NOW() THEN FALSE
                WHEN cert_record.not_after IS NOT NULL AND cert_record.not_after < NOW() THEN FALSE
                ELSE TRUE
            END,
            -- Set effective_since if effective
            CASE
                WHEN cert_record.status IN ('REVOKED', 'INVALID') THEN NULL
                WHEN cert_record.not_before IS NOT NULL AND cert_record.not_before > NOW() THEN NULL
                WHEN cert_record.not_after IS NOT NULL AND cert_record.not_after < NOW() THEN NULL
                ELSE NOW()
            END
        );

        migrated_count := migrated_count + 1;
    END LOOP;

    RAISE NOTICE 'Migration completed: % certificates migrated to certificate_metadata + certificate_versions', migrated_count;

    -- Verify migration
    SELECT COUNT(*) INTO new_cert_count FROM certificate_metadata;
    IF new_cert_count != old_cert_count THEN
        RAISE WARNING 'Migration verification failed: expected % records, got %', old_cert_count, new_cert_count;
    ELSE
        RAISE NOTICE 'Migration verified: % records in certificate_metadata', new_cert_count;
    END IF;
END $$;

-- Update sequences to avoid conflicts
-- Find the max pid from migrated data and set sequences accordingly
DO $$
DECLARE
    max_metadata_pid BIGINT;
    max_versions_pid BIGINT;
BEGIN
    SELECT COALESCE(MAX(pid), 0) INTO max_metadata_pid FROM certificate_metadata;
    SELECT COALESCE(MAX(pid), 0) INTO max_versions_pid FROM certificate_versions;

    IF max_metadata_pid > 0 THEN
        PERFORM setval('certificate_metadata_pid_seq', max_metadata_pid, true);
        RAISE NOTICE 'Updated certificate_metadata_pid_seq to %', max_metadata_pid;
    END IF;

    IF max_versions_pid > 0 THEN
        PERFORM setval('certificate_versions_pid_seq', max_versions_pid, true);
        RAISE NOTICE 'Updated certificate_versions_pid_seq to %', max_versions_pid;
    END IF;
END $$;
