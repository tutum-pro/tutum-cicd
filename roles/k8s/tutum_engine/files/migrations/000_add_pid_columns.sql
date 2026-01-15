-- Migration: Add pid columns to existing tables
-- This migration adds pid (private ID) columns to tables that need them for new schema compatibility

-- Step 1: Add pid columns to all tables first (without changing constraints yet)

-- Add pid column to certificate_groups if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'certificate_groups' AND column_name = 'pid') THEN
        ALTER TABLE certificate_groups ADD COLUMN pid BIGSERIAL UNIQUE;
        RAISE NOTICE 'Added pid column to certificate_groups';
    END IF;
END $$;

-- Add pid column to namespaces if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'namespaces' AND column_name = 'pid') THEN
        ALTER TABLE namespaces ADD COLUMN pid BIGSERIAL UNIQUE;
        RAISE NOTICE 'Added pid column to namespaces';
    END IF;
END $$;

-- Add pid column to certificates if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'certificates' AND column_name = 'pid') THEN
        ALTER TABLE certificates ADD COLUMN pid BIGSERIAL UNIQUE;
        RAISE NOTICE 'Added pid column to certificates';
    END IF;
END $$;

-- Step 2: Add and populate group_pid column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'certificates' AND column_name = 'group_pid') THEN
        -- Add group_pid column (nullable initially)
        ALTER TABLE certificates ADD COLUMN group_pid BIGINT;

        -- Populate group_pid from group_id using the pid column we just added
        UPDATE certificates c
        SET group_pid = g.pid
        FROM certificate_groups g
        WHERE c.group_id = g.id AND g.pid IS NOT NULL;

        -- Make it NOT NULL after populating (if we have data)
        IF (SELECT COUNT(*) FROM certificates WHERE group_pid IS NULL) = 0 THEN
            ALTER TABLE certificates ALTER COLUMN group_pid SET NOT NULL;
        END IF;

        -- Add foreign key constraint
        ALTER TABLE certificates
        ADD CONSTRAINT certificates_group_pid_fkey
        FOREIGN KEY (group_pid) REFERENCES certificate_groups(pid) ON DELETE RESTRICT;

        -- Add index
        CREATE INDEX IF NOT EXISTS idx_certificates_group_pid ON certificates(group_pid);

        RAISE NOTICE 'Added group_pid column to certificates';
    END IF;
END $$;

-- Step 3: Add and populate namespace_pid column
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'certificates' AND column_name = 'namespace_pid') THEN
        -- Add namespace_pid column (nullable initially)
        ALTER TABLE certificates ADD COLUMN namespace_pid BIGINT;

        -- Populate namespace_pid from namespace name
        UPDATE certificates c
        SET namespace_pid = n.pid
        FROM namespaces n
        WHERE c.namespace = n.name AND n.pid IS NOT NULL;

        -- Make it NOT NULL after populating (if we have data)
        IF (SELECT COUNT(*) FROM certificates WHERE namespace_pid IS NULL) = 0 THEN
            ALTER TABLE certificates ALTER COLUMN namespace_pid SET NOT NULL;
        END IF;

        -- Add foreign key constraint
        ALTER TABLE certificates
        ADD CONSTRAINT certificates_namespace_pid_fkey
        FOREIGN KEY (namespace_pid) REFERENCES namespaces(pid) ON DELETE RESTRICT;

        -- Add index
        CREATE INDEX IF NOT EXISTS idx_certificates_namespace_pid ON certificates(namespace_pid);

        RAISE NOTICE 'Added namespace_pid column to certificates';
    END IF;
END $$;

-- Add composite indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_certificates_group_pid_status ON certificates(group_pid, status);
CREATE INDEX IF NOT EXISTS idx_certificates_namespace_pid_status ON certificates(namespace_pid, status);

-- Recreate view with proper columns
DROP VIEW IF EXISTS certificate_group_stats;
CREATE OR REPLACE VIEW certificate_group_stats AS
SELECT
    g.id AS group_id,
    g.name AS group_name,
    COUNT(c.id) AS total_certificates,
    COUNT(CASE WHEN c.status = 'ACTIVE' THEN 1 END) AS active_certificates,
    COUNT(CASE WHEN c.status = 'EXPIRED' THEN 1 END) AS expired_certificates,
    COUNT(CASE WHEN c.status = 'REVOKED' THEN 1 END) AS revoked_certificates,
    COUNT(CASE WHEN c.days_until_expiry <= 30 AND c.status = 'ACTIVE' THEN 1 END) AS expiring_soon
FROM certificate_groups g
LEFT JOIN certificates c ON g.pid = c.group_pid
GROUP BY g.id, g.name
ORDER BY g.name;

COMMENT ON VIEW certificate_group_stats IS 'Statistics about certificates grouped by certificate group';
