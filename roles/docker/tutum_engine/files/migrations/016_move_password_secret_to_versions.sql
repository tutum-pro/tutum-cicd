-- Migration: Move password_secret_pid from certificate_metadata to certificate_versions
-- This migration implements version-level association between X509 certificates and their password secrets.
-- Each X509 version can now have its own corresponding password secret version.
--
-- Business rules:
-- 1. X509 version N is associated with password_secret version N (version numbers are synchronized)
-- 2. When fetching X509 version N, the system retrieves password from password_secret version N
-- 3. The password_secret_pid in certificate_metadata is kept for identifying which secret belongs to this X509
-- 4. password_secret_version_pid in certificate_versions links to specific password secret version

-- Step 1: Add password_secret_version_pid column to certificate_versions
-- This references a specific version of the password secret (in certificate_versions table)
ALTER TABLE certificate_versions
ADD COLUMN IF NOT EXISTS password_secret_version_pid BIGINT REFERENCES certificate_versions(pid) ON DELETE SET NULL;

-- Step 2: Create index for efficient lookup of X509 versions by their password secret version
CREATE INDEX IF NOT EXISTS idx_certificate_versions_password_secret_version_pid
ON certificate_versions (password_secret_version_pid)
WHERE password_secret_version_pid IS NOT NULL;

-- Step 3: Populate password_secret_version_pid for existing X509 versions
-- For each X509 version, find the corresponding password secret version with the same version number
-- This migration assumes version numbers are synchronized (X509 v1 -> password_secret v1, etc.)
UPDATE certificate_versions xv
SET password_secret_version_pid = psv.pid
FROM certificate_metadata xm
JOIN certificate_metadata ps ON xm.password_secret_pid = ps.pid
JOIN certificate_versions psv ON psv.certificate_metadata_pid = ps.pid AND psv.version = xv.version
WHERE xv.certificate_metadata_pid = xm.pid
  AND xm.password_secret_pid IS NOT NULL;

-- Step 4: Update certificates_latest view to include password_secret_id from version level
DROP VIEW IF EXISTS certificates_latest;
CREATE OR REPLACE VIEW certificates_latest AS
SELECT
    m.pid,
    m.id,
    m.name,
    m.group_pid,
    m.namespace_pid,
    m.group_id,
    m.namespace,
    m.type,
    m.password_secret_pid,
    ps.id as password_secret_id,  -- UUID of password secret metadata (for API response - identifies the secret)
    psv.pid as password_secret_version_pid, -- PID of the specific password version
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
LEFT JOIN certificate_metadata ps ON m.password_secret_pid = ps.pid
INNER JOIN LATERAL (
    -- Prefer is_effective version, fallback to latest by version number
    SELECT *
    FROM certificate_versions
    WHERE certificate_metadata_pid = m.pid
    ORDER BY is_effective DESC, version DESC
    LIMIT 1
) v ON true
LEFT JOIN certificate_versions psv ON v.password_secret_version_pid = psv.pid;

-- Step 5: Update certificates_effective view to include password_secret_id from version level
DROP VIEW IF EXISTS certificates_effective;
CREATE OR REPLACE VIEW certificates_effective AS
SELECT
    m.pid,
    m.id,
    m.name,
    m.group_pid,
    m.namespace_pid,
    m.group_id,
    m.namespace,
    m.type,
    m.password_secret_pid,
    ps.id as password_secret_id,  -- UUID of password secret metadata (for API response - identifies the secret)
    psv.pid as password_secret_version_pid, -- PID of the specific password version
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
LEFT JOIN certificate_metadata ps ON m.password_secret_pid = ps.pid
INNER JOIN certificate_versions v ON v.certificate_metadata_pid = m.pid
LEFT JOIN certificate_versions psv ON v.password_secret_version_pid = psv.pid
WHERE v.is_effective = TRUE;

-- Comments for documentation
COMMENT ON COLUMN certificate_versions.password_secret_version_pid IS 'Reference to specific password secret version (certificate_versions.pid) that stores the passphrase for this X509 version. NULL if private key is not password-protected or for non-X509 certificates.';
