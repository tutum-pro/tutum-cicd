-- Migration: Add certificate versioning
-- This migration splits certificates into metadata and versions tables

-- Step 1: Create new certificate_metadata table
CREATE TABLE IF NOT EXISTS certificate_metadata (
    pid BIGSERIAL PRIMARY KEY,
    id UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    group_pid BIGINT NOT NULL REFERENCES certificate_groups(pid) ON DELETE RESTRICT,
    namespace_pid BIGINT NOT NULL REFERENCES namespaces(pid) ON DELETE RESTRICT,
    CONSTRAINT certificate_metadata_name_group_namespace_unique UNIQUE (name, group_pid, namespace_pid),

    -- Legacy fields for backward compatibility
    group_id UUID,
    namespace VARCHAR(255) NOT NULL DEFAULT 'default',

    -- Custom metadata (shared across all versions)
    custom_metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by VARCHAR(255),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_by VARCHAR(255),

    -- Constraints
    CONSTRAINT certificate_metadata_name_check CHECK (char_length(name) > 0)
);

-- Step 2: Create certificate_versions table
CREATE TABLE IF NOT EXISTS certificate_versions (
    pid BIGSERIAL PRIMARY KEY,
    id UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    certificate_metadata_pid BIGINT NOT NULL REFERENCES certificate_metadata(pid) ON DELETE CASCADE,
    version INTEGER NOT NULL,

    -- Certificate data (PEM encoded)
    certificate_pem TEXT NOT NULL,
    private_key_pem TEXT NOT NULL,  -- ENCRYPTED
    ca_chain_pem TEXT,

    -- Parsed X.509 metadata (version-specific)
    subject VARCHAR(500),
    issuer VARCHAR(500),
    serial_number VARCHAR(100),
    not_before TIMESTAMP WITH TIME ZONE,
    not_after TIMESTAMP WITH TIME ZONE,
    fingerprint_sha256 VARCHAR(64),
    subject_alt_names TEXT[],
    key_usage TEXT[],
    extended_key_usage TEXT[],
    is_ca BOOLEAN DEFAULT FALSE,

    -- Status (version-specific)
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    days_until_expiry INTEGER,

    -- Audit fields (version-specific)
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by VARCHAR(255),

    -- Constraints
    CONSTRAINT certificate_versions_version_positive CHECK (version > 0),
    CONSTRAINT certificate_versions_status_check CHECK (status IN ('ACTIVE', 'EXPIRED', 'REVOKED', 'INVALID')),
    -- Unique constraint: one version number per certificate
    CONSTRAINT certificate_versions_unique_version UNIQUE (certificate_metadata_pid, version)
);

-- Indexes for certificate_metadata
CREATE INDEX IF NOT EXISTS idx_certificate_metadata_id ON certificate_metadata(id);
CREATE INDEX IF NOT EXISTS idx_certificate_metadata_name ON certificate_metadata(name);
CREATE INDEX IF NOT EXISTS idx_certificate_metadata_group_pid ON certificate_metadata(group_pid);
CREATE INDEX IF NOT EXISTS idx_certificate_metadata_namespace_pid ON certificate_metadata(namespace_pid);
CREATE INDEX IF NOT EXISTS idx_certificate_metadata_created_at ON certificate_metadata(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_certificate_metadata_group_id ON certificate_metadata(group_id);
CREATE INDEX IF NOT EXISTS idx_certificate_metadata_namespace ON certificate_metadata(namespace);

-- GIN index for custom_metadata JSONB searches
CREATE INDEX IF NOT EXISTS idx_certificate_metadata_custom_metadata ON certificate_metadata USING GIN (custom_metadata);

-- Indexes for certificate_versions
CREATE INDEX IF NOT EXISTS idx_certificate_versions_id ON certificate_versions(id);
CREATE INDEX IF NOT EXISTS idx_certificate_versions_metadata_pid ON certificate_versions(certificate_metadata_pid);
CREATE INDEX IF NOT EXISTS idx_certificate_versions_version ON certificate_versions(certificate_metadata_pid, version DESC);
CREATE INDEX IF NOT EXISTS idx_certificate_versions_status ON certificate_versions(status);
CREATE INDEX IF NOT EXISTS idx_certificate_versions_not_after ON certificate_versions(not_after);
CREATE INDEX IF NOT EXISTS idx_certificate_versions_fingerprint ON certificate_versions(fingerprint_sha256);
CREATE INDEX IF NOT EXISTS idx_certificate_versions_created_at ON certificate_versions(created_at DESC);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_certificate_versions_metadata_status ON certificate_versions(certificate_metadata_pid, status);
CREATE INDEX IF NOT EXISTS idx_certificate_versions_latest ON certificate_versions(certificate_metadata_pid, version DESC, created_at DESC);

-- Trigger for certificate_metadata
CREATE TRIGGER update_certificate_metadata_updated_at
    BEFORE UPDATE ON certificate_metadata
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to update certificate version status
CREATE OR REPLACE FUNCTION update_certificate_version_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate days until expiry (only if not_after is set - for X509 certs)
    IF NEW.not_after IS NOT NULL THEN
        NEW.days_until_expiry := EXTRACT(EPOCH FROM (NEW.not_after - NOW())) / 86400;

        -- Update status based on expiry
        IF NEW.not_after < NOW() THEN
            NEW.status := 'EXPIRED';
        ELSIF NEW.status != 'REVOKED' AND NEW.status != 'INVALID' THEN
            NEW.status := 'ACTIVE';
        END IF;
    ELSE
        -- For secrets (no not_after), always ACTIVE unless manually set
        IF NEW.status NOT IN ('REVOKED', 'INVALID') THEN
            NEW.status := 'ACTIVE';
        END IF;
        NEW.days_until_expiry := NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update certificate version status
CREATE TRIGGER update_certificate_version_status_trigger
    BEFORE INSERT OR UPDATE ON certificate_versions
    FOR EACH ROW
    EXECUTE FUNCTION update_certificate_version_status();

-- Function to get next version number
CREATE OR REPLACE FUNCTION get_next_certificate_version(cert_metadata_pid BIGINT)
RETURNS INTEGER AS $$
DECLARE
    next_version INTEGER;
BEGIN
    SELECT COALESCE(MAX(version), 0) + 1
    INTO next_version
    FROM certificate_versions
    WHERE certificate_metadata_pid = cert_metadata_pid;

    RETURN next_version;
END;
$$ LANGUAGE plpgsql;

-- View for latest certificate versions (for backward compatibility)
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
    m.custom_metadata,
    m.created_at,
    m.created_by,
    m.updated_at,
    m.updated_by
FROM certificate_metadata m
INNER JOIN LATERAL (
    SELECT *
    FROM certificate_versions
    WHERE certificate_metadata_pid = m.pid
    ORDER BY version DESC
    LIMIT 1
) v ON true;

-- View for expiring certificate versions (within 30 days)
CREATE OR REPLACE VIEW expiring_certificate_versions AS
SELECT
    m.id,
    m.name,
    m.group_id,
    g.name AS group_name,
    m.namespace,
    v.version,
    v.subject,
    v.not_after,
    v.days_until_expiry,
    v.status
FROM certificate_metadata m
INNER JOIN LATERAL (
    SELECT *
    FROM certificate_versions
    WHERE certificate_metadata_pid = m.pid
    ORDER BY version DESC
    LIMIT 1
) v ON true
JOIN certificate_groups g ON m.group_id = g.id
WHERE v.status = 'ACTIVE'
  AND v.not_after > NOW()
  AND v.not_after < NOW() + INTERVAL '30 days'
ORDER BY v.not_after ASC;

-- Comments for documentation
COMMENT ON TABLE certificate_metadata IS 'Certificate metadata - one record per certificate name, contains metadata shared across all versions';
COMMENT ON COLUMN certificate_metadata.pid IS 'Private ID - internal identifier used for foreign key relationships';
COMMENT ON COLUMN certificate_metadata.id IS 'Public UUID - unique identifier exposed via REST API';
COMMENT ON COLUMN certificate_metadata.name IS 'Unique certificate name';
COMMENT ON COLUMN certificate_metadata.custom_metadata IS 'User-defined key-value pairs shared across all versions';

COMMENT ON TABLE certificate_versions IS 'Certificate versions - one record per version, contains certificate content and parsed metadata';
COMMENT ON COLUMN certificate_versions.pid IS 'Private ID - internal identifier';
COMMENT ON COLUMN certificate_versions.id IS 'Public UUID - unique identifier for this specific version';
COMMENT ON COLUMN certificate_versions.certificate_metadata_pid IS 'Foreign key to certificate_metadata';
COMMENT ON COLUMN certificate_versions.version IS 'Version number (auto-incremented, starts at 1)';
COMMENT ON COLUMN certificate_versions.private_key_pem IS 'Private key encrypted with AES-256-GCM envelope encryption';

COMMENT ON VIEW certificates_latest IS 'View showing the latest version of each certificate (for backward compatibility)';
COMMENT ON VIEW expiring_certificate_versions IS 'View showing latest versions of certificates expiring within 30 days';

-- Note: Old 'certificates' table will be deprecated but kept for backward compatibility during migration
-- Applications should migrate to use certificate_metadata + certificate_versions
