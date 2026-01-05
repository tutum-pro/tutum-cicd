-- Tutum Platform Database Schema
-- PostgreSQL 15+

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Namespaces Table
CREATE TABLE IF NOT EXISTS namespaces (
    pid BIGSERIAL PRIMARY KEY,
    id UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL UNIQUE,
    confidentiality_level VARCHAR(20) NOT NULL DEFAULT 'NORMAL',
    description TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by VARCHAR(255),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_by VARCHAR(255),

    -- Constraints
    CONSTRAINT namespaces_name_check CHECK (char_length(name) > 0),
    CONSTRAINT namespaces_confidentiality_check CHECK (confidentiality_level IN ('NORMAL', 'PARANOIC'))
);

-- Indexes for namespaces
CREATE INDEX IF NOT EXISTS idx_namespaces_id ON namespaces(id);
CREATE INDEX IF NOT EXISTS idx_namespaces_name ON namespaces(name);
CREATE INDEX IF NOT EXISTS idx_namespaces_created_at ON namespaces(created_at DESC);

-- Certificate Groups Table
CREATE TABLE IF NOT EXISTS certificate_groups (
    pid BIGSERIAL PRIMARY KEY,
    id UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by VARCHAR(255),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_by VARCHAR(255),

    -- Constraints
    CONSTRAINT certificate_groups_name_check CHECK (char_length(name) > 0)
);

CREATE INDEX IF NOT EXISTS idx_certificate_groups_id ON certificate_groups(id);
CREATE INDEX IF NOT EXISTS idx_certificate_groups_name ON certificate_groups(name);
CREATE INDEX IF NOT EXISTS idx_certificate_groups_created_at ON certificate_groups(created_at DESC);

-- Certificates Table
CREATE TABLE IF NOT EXISTS certificates (
    pid BIGSERIAL PRIMARY KEY,
    id UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    group_pid BIGINT NOT NULL REFERENCES certificate_groups(pid) ON DELETE RESTRICT,
    namespace_pid BIGINT NOT NULL REFERENCES namespaces(pid) ON DELETE RESTRICT,
    CONSTRAINT certificates_name_group_namespace_unique UNIQUE (name, group_pid, namespace_pid),

    -- Legacy fields for backward compatibility (deprecated, use group_pid and namespace_pid)
    group_id UUID,
    namespace VARCHAR(255) NOT NULL DEFAULT 'default',

    -- Certificate data (PEM encoded)
    certificate_pem TEXT NOT NULL,
    private_key_pem TEXT NOT NULL,  -- ENCRYPTED
    ca_chain_pem TEXT,

    -- Parsed metadata
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

    -- Status
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    days_until_expiry INTEGER,

    -- Custom metadata
    custom_metadata JSONB DEFAULT '{}'::jsonb,

    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by VARCHAR(255),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_by VARCHAR(255),

    -- Constraints
    CONSTRAINT certificates_name_check CHECK (char_length(name) > 0),
    CONSTRAINT certificates_status_check CHECK (status IN ('ACTIVE', 'EXPIRED', 'REVOKED', 'INVALID'))
);

-- Indexes for certificates
CREATE INDEX IF NOT EXISTS idx_certificates_id ON certificates(id);
CREATE INDEX IF NOT EXISTS idx_certificates_name ON certificates(name);
CREATE INDEX IF NOT EXISTS idx_certificates_group_pid ON certificates(group_pid);
CREATE INDEX IF NOT EXISTS idx_certificates_namespace_pid ON certificates(namespace_pid);
CREATE INDEX IF NOT EXISTS idx_certificates_status ON certificates(status);
CREATE INDEX IF NOT EXISTS idx_certificates_not_after ON certificates(not_after);
CREATE INDEX IF NOT EXISTS idx_certificates_fingerprint ON certificates(fingerprint_sha256);
CREATE INDEX IF NOT EXISTS idx_certificates_created_at ON certificates(created_at DESC);

-- Legacy indexes for backward compatibility
CREATE INDEX IF NOT EXISTS idx_certificates_group_id ON certificates(group_id);
CREATE INDEX IF NOT EXISTS idx_certificates_namespace ON certificates(namespace);

-- GIN index for custom_metadata JSONB searches
CREATE INDEX IF NOT EXISTS idx_certificates_custom_metadata ON certificates USING GIN (custom_metadata);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_certificates_group_pid_status ON certificates(group_pid, status);
CREATE INDEX IF NOT EXISTS idx_certificates_namespace_pid_status ON certificates(namespace_pid, status);

-- Audit Log Table
CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL PRIMARY KEY,  -- Private ID (pid) - internal, never exposed
    public_id UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),  -- Public UUID - exposed via API
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    action VARCHAR(50) NOT NULL,  -- CREATE, UPDATE, DELETE, GET, LIST, MOUNT, UNMOUNT
    resource_type VARCHAR(50) NOT NULL,  -- CERTIFICATE, GROUP, NAMESPACE
    resource_id UUID,
    resource_name VARCHAR(255),
    user_id VARCHAR(255),
    user_agent VARCHAR(500),
    ip_address VARCHAR(45),
    details JSONB DEFAULT '{}'::jsonb,
    success BOOLEAN NOT NULL DEFAULT TRUE,
    error_message TEXT,

    -- Workload tracking (for certificate mount/unmount operations)
    workload_type VARCHAR(20),  -- k8s-deployment, k8s-statefulset, k8s-daemonset, docker-service
    workload_name VARCHAR(255),  -- Name of the workload
    workload_namespace VARCHAR(255),  -- K8s namespace (NULL for Docker)

    -- Certificate version tracking (for MOUNT operations)
    version_requested INTEGER DEFAULT 0,  -- 0=latest, >0=specific version

    -- Constraints
    CONSTRAINT audit_logs_action_check CHECK (action IN ('CREATE', 'UPDATE', 'DELETE', 'GET', 'LIST', 'INVALIDATE', 'MOUNT', 'UNMOUNT')),
    CONSTRAINT audit_logs_resource_type_check CHECK (resource_type IN ('CERTIFICATE', 'GROUP', 'NAMESPACE')),
    CONSTRAINT audit_logs_workload_type_check CHECK (workload_type IS NULL OR workload_type IN ('k8s-pod', 'k8s-deployment', 'k8s-statefulset', 'k8s-daemonset', 'docker-service'))
);

-- Indexes for audit logs
CREATE INDEX IF NOT EXISTS idx_audit_logs_public_id ON audit_logs(public_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource_type ON audit_logs(resource_type);
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource_id ON audit_logs(resource_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_workload ON audit_logs(workload_type, workload_name);
CREATE INDEX IF NOT EXISTS idx_audit_logs_mount_latest ON audit_logs(action, resource_name, version_requested) WHERE action = 'MOUNT' AND version_requested = 0;

-- Composite index for common audit queries
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource ON audit_logs(resource_type, resource_id, timestamp DESC);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for certificate_groups
DROP TRIGGER IF EXISTS update_certificate_groups_updated_at ON certificate_groups;
CREATE TRIGGER update_certificate_groups_updated_at
    BEFORE UPDATE ON certificate_groups
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for certificates
DROP TRIGGER IF EXISTS update_certificates_updated_at ON certificates;
CREATE TRIGGER update_certificates_updated_at
    BEFORE UPDATE ON certificates
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for namespaces
DROP TRIGGER IF EXISTS update_namespaces_updated_at ON namespaces;
CREATE TRIGGER update_namespaces_updated_at
    BEFORE UPDATE ON namespaces
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate days_until_expiry
CREATE OR REPLACE FUNCTION update_certificate_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate days until expiry
    NEW.days_until_expiry := EXTRACT(EPOCH FROM (NEW.not_after - NOW())) / 86400;

    -- Update status based on expiry
    IF NEW.not_after < NOW() THEN
        NEW.status := 'EXPIRED';
    ELSIF NEW.status != 'REVOKED' AND NEW.status != 'INVALID' THEN
        NEW.status := 'ACTIVE';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update certificate status
DROP TRIGGER IF EXISTS update_certificate_status_trigger ON certificates;
CREATE TRIGGER update_certificate_status_trigger
    BEFORE INSERT OR UPDATE ON certificates
    FOR EACH ROW
    EXECUTE FUNCTION update_certificate_status();

-- View for expiring certificates (within 30 days)
CREATE OR REPLACE VIEW expiring_certificates AS
SELECT
    c.id,
    c.name,
    c.group_id,
    g.name AS group_name,
    c.namespace,
    c.subject,
    c.not_after,
    c.days_until_expiry,
    c.status
FROM certificates c
JOIN certificate_groups g ON c.group_id = g.id
WHERE c.status = 'ACTIVE'
  AND c.not_after > NOW()
  AND c.not_after < NOW() + INTERVAL '30 days'
ORDER BY c.not_after ASC;

-- View for certificate statistics by group
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

-- Insert default namespace
INSERT INTO namespaces (name, description, confidentiality_level, created_by)
VALUES
    ('default', 'Default namespace', 'NORMAL', 'system')
ON CONFLICT (name) DO NOTHING;

-- Insert default group
INSERT INTO certificate_groups (id, name, description, created_by)
VALUES
    ('00000000-0000-0000-0000-000000000001', 'default', 'Default certificate group', 'system')
ON CONFLICT (name) DO NOTHING;

-- Comments for documentation
COMMENT ON TABLE namespaces IS 'Namespaces for organizing certificates with confidentiality levels';
COMMENT ON COLUMN namespaces.pid IS 'Private ID - internal identifier used for foreign key relationships, never exposed externally';
COMMENT ON COLUMN namespaces.id IS 'Public UUID - unique identifier exposed via REST API';
COMMENT ON COLUMN namespaces.confidentiality_level IS 'NORMAL: accessible via REST and gRPC, PARANOIC: accessible only via gRPC';

COMMENT ON TABLE certificate_groups IS 'Certificate groups for organizing certificates';
COMMENT ON COLUMN certificate_groups.pid IS 'Private ID - internal identifier used for foreign key relationships, never exposed externally';
COMMENT ON COLUMN certificate_groups.id IS 'Public UUID - unique identifier exposed via REST API';

COMMENT ON TABLE certificates IS 'X.509 certificates with encrypted private keys';
COMMENT ON COLUMN certificates.pid IS 'Private ID - internal identifier, never exposed externally';
COMMENT ON COLUMN certificates.id IS 'Public UUID - unique identifier exposed via REST API';
COMMENT ON COLUMN certificates.group_pid IS 'Foreign key to certificate_groups.pid';
COMMENT ON COLUMN certificates.namespace_pid IS 'Foreign key to namespaces.pid';
COMMENT ON COLUMN certificates.group_id IS 'DEPRECATED: Legacy UUID field, use group_pid instead';
COMMENT ON COLUMN certificates.namespace IS 'DEPRECATED: Legacy string field, use namespace_pid instead';
COMMENT ON COLUMN certificates.private_key_pem IS 'Private key encrypted with AES-256-GCM envelope encryption';
COMMENT ON COLUMN certificates.custom_metadata IS 'User-defined key-value pairs (JSONB)';

COMMENT ON TABLE audit_logs IS 'Audit trail for all certificate operations';
COMMENT ON COLUMN audit_logs.id IS 'Private ID (pid) - internal BIGSERIAL identifier used for ordering, never exposed externally via API';
COMMENT ON COLUMN audit_logs.public_id IS 'Public UUID - unique identifier exposed via REST/gRPC API, prevents enumeration attacks';
