-- Migration: Add password_secret_pid column for X509 certificates with encrypted private keys
-- This migration adds support for associating a password secret with an X509 certificate.
-- The password secret stores the passphrase used to decrypt the private key.
--
-- Business rules:
-- 1. Password secret inherits lifecycle (not_before/not_after) from parent X509
-- 2. New X509 version creates new secret version (if password exists)
-- 3. X509 deletion cascades to delete associated password secret
-- 4. Direct PUT/DELETE on password secrets is blocked (via application layer)
-- 5. Password change requires PUT on X509 with new password field

-- Step 1: Add password_secret_pid column to certificate_metadata
-- This references another certificate_metadata entry (of type 'secret') that stores the password
ALTER TABLE certificate_metadata
ADD COLUMN IF NOT EXISTS password_secret_pid BIGINT REFERENCES certificate_metadata(pid) ON DELETE SET NULL;

-- Step 2: Create index for efficient lookup of X509 certificates by their password secret
CREATE INDEX IF NOT EXISTS idx_certificate_metadata_password_secret_pid
ON certificate_metadata (password_secret_pid)
WHERE password_secret_pid IS NOT NULL;

-- Step 3: Create index for finding X509 that owns a given password secret (reverse lookup)
-- This is useful for checking if a secret is a password secret before allowing DELETE
CREATE INDEX IF NOT EXISTS idx_certificate_metadata_password_secret_reverse
ON certificate_metadata (password_secret_pid);

-- Step 4: Update certificates_latest view to include password_secret_id
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
    ps.id as password_secret_id,  -- UUID of password secret for API response
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
) v ON true;

-- Step 5: Update certificates_effective view to include password_secret_id
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
    ps.id as password_secret_id,  -- UUID of password secret for API response
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
WHERE v.is_effective = TRUE;

-- Comments for documentation
COMMENT ON COLUMN certificate_metadata.password_secret_pid IS 'Reference to password secret (certificate_metadata.pid of type secret) that stores the passphrase for encrypted private key. NULL if private key is not password-protected.';
