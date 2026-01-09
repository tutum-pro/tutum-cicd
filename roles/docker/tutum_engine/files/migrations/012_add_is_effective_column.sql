-- Migration: Add is_effective column for certificate version selection
-- This migration adds the is_effective column to track which version is currently active
-- Only one version per certificate (metadata) can have is_effective = TRUE at a time
-- NOTE: The effective version selection algorithm is implemented in Go business logic,
-- not in SQL functions. This keeps us database-engine independent and allows unit testing.

-- Step 1: Add is_effective column to certificate_versions
ALTER TABLE certificate_versions
ADD COLUMN IF NOT EXISTS is_effective BOOLEAN NOT NULL DEFAULT FALSE;

-- Step 2: Add effective_since timestamp to track when this version became effective
ALTER TABLE certificate_versions
ADD COLUMN IF NOT EXISTS effective_since TIMESTAMP WITH TIME ZONE;

-- Step 3: Create partial unique index to ensure only one effective version per certificate
-- This constraint ensures data integrity at the database level
CREATE UNIQUE INDEX IF NOT EXISTS idx_certificate_versions_one_effective
ON certificate_versions (certificate_metadata_pid)
WHERE is_effective = TRUE;

-- Step 4: Create index for efficient querying of effective versions
CREATE INDEX IF NOT EXISTS idx_certificate_versions_is_effective
ON certificate_versions (is_effective)
WHERE is_effective = TRUE;

-- Step 5: Create composite index for effective version lookup by metadata
CREATE INDEX IF NOT EXISTS idx_certificate_versions_effective_lookup
ON certificate_versions (certificate_metadata_pid, is_effective, not_after DESC, version DESC);

-- Step 6: Update the certificates_latest view to prefer is_effective version
CREATE OR REPLACE VIEW certificates_latest AS
SELECT
    m.pid,
    m.id,
    m.name,
    m.group_pid,
    m.namespace_pid,
    m.group_id,
    m.namespace,
    v.version,
    v.certificate_pem,
    v.private_key_pem,
    v.ca_chain_pem,
    v.subject,
    v.issuer,
    v.serial_number,
    v.not_before,
    v.not_after,
    v.fingerprint_sha256,
    v.subject_alt_names,
    v.key_usage,
    v.extended_key_usage,
    v.is_ca,
    v.status,
    v.days_until_expiry,
    v.is_effective,
    v.effective_since,
    m.custom_metadata,
    m.created_at,
    m.created_by,
    m.updated_at,
    m.updated_by
FROM certificate_metadata m
INNER JOIN LATERAL (
    -- Prefer is_effective version, fallback to latest by version number
    SELECT *
    FROM certificate_versions
    WHERE certificate_metadata_pid = m.pid
    ORDER BY is_effective DESC, version DESC
    LIMIT 1
) v ON true;

-- Step 7: Create view for effective certificates only (for gRPC default behavior)
CREATE OR REPLACE VIEW certificates_effective AS
SELECT
    m.pid,
    m.id,
    m.name,
    m.group_pid,
    m.namespace_pid,
    m.group_id,
    m.namespace,
    v.version,
    v.certificate_pem,
    v.private_key_pem,
    v.ca_chain_pem,
    v.subject,
    v.issuer,
    v.serial_number,
    v.not_before,
    v.not_after,
    v.fingerprint_sha256,
    v.subject_alt_names,
    v.key_usage,
    v.extended_key_usage,
    v.is_ca,
    v.status,
    v.days_until_expiry,
    v.is_effective,
    v.effective_since,
    m.custom_metadata,
    m.created_at,
    m.created_by,
    m.updated_at,
    m.updated_by
FROM certificate_metadata m
INNER JOIN certificate_versions v ON v.certificate_metadata_pid = m.pid
WHERE v.is_effective = TRUE;

-- Comments for documentation
COMMENT ON COLUMN certificate_versions.is_effective IS 'TRUE if this version is currently the effective/active version for this certificate. Only one version per certificate can be effective.';
COMMENT ON COLUMN certificate_versions.effective_since IS 'Timestamp when this version became effective. Used for audit trail.';
COMMENT ON VIEW certificates_effective IS 'View showing only certificates that have an effective version (for gRPC API default behavior)';
