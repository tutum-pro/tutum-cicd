-- Migration: 008_add_distribution_channels
-- Description: Add distribution channels and channel tokens for certificate access control

BEGIN;

-- ============================================================================
-- Distribution Channels Table
-- ============================================================================
CREATE TABLE IF NOT EXISTS distribution_channels (
    pid BIGSERIAL PRIMARY KEY,
    id UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    requires_auth BOOLEAN NOT NULL DEFAULT true,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by VARCHAR(255),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_by VARCHAR(255),

    CONSTRAINT distribution_channels_name_check CHECK (char_length(name) > 0)
);

-- Indexes for distribution_channels
CREATE INDEX IF NOT EXISTS idx_distribution_channels_id ON distribution_channels(id);
CREATE INDEX IF NOT EXISTS idx_distribution_channels_name ON distribution_channels(name);
CREATE INDEX IF NOT EXISTS idx_distribution_channels_created_at ON distribution_channels(created_at DESC);

-- Trigger for updated_at
DROP TRIGGER IF EXISTS update_distribution_channels_updated_at ON distribution_channels;
CREATE TRIGGER update_distribution_channels_updated_at
    BEFORE UPDATE ON distribution_channels
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE distribution_channels IS 'Distribution channels for controlling certificate access';
COMMENT ON COLUMN distribution_channels.pid IS 'Private ID - internal identifier, never exposed externally';
COMMENT ON COLUMN distribution_channels.id IS 'Public UUID - unique identifier exposed via REST API';
COMMENT ON COLUMN distribution_channels.requires_auth IS 'If true, authentication token is required to access certificates in namespaces using this channel';

-- ============================================================================
-- Channel Tokens Table
-- ============================================================================
CREATE TABLE IF NOT EXISTS channel_tokens (
    pid BIGSERIAL PRIMARY KEY,
    id UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    channel_pid BIGINT NOT NULL REFERENCES distribution_channels(pid) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    token_hash VARCHAR(128) NOT NULL,
    token_encrypted TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    not_before TIMESTAMP WITH TIME ZONE NOT NULL,
    not_after TIMESTAMP WITH TIME ZONE NOT NULL,
    last_used_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by VARCHAR(255),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_by VARCHAR(255),
    revoked_at TIMESTAMP WITH TIME ZONE,
    revoked_by VARCHAR(255),

    CONSTRAINT channel_tokens_name_channel_unique UNIQUE (name, channel_pid),
    CONSTRAINT channel_tokens_status_check CHECK (status IN ('PENDING', 'ACTIVE', 'EXPIRED', 'REVOKED')),
    CONSTRAINT channel_tokens_validity_check CHECK (not_after > not_before)
);

-- Indexes for channel_tokens
CREATE INDEX IF NOT EXISTS idx_channel_tokens_id ON channel_tokens(id);
CREATE INDEX IF NOT EXISTS idx_channel_tokens_channel_pid ON channel_tokens(channel_pid);
CREATE INDEX IF NOT EXISTS idx_channel_tokens_status ON channel_tokens(status);
CREATE INDEX IF NOT EXISTS idx_channel_tokens_not_before ON channel_tokens(not_before);
CREATE INDEX IF NOT EXISTS idx_channel_tokens_not_after ON channel_tokens(not_after);
CREATE INDEX IF NOT EXISTS idx_channel_tokens_hash ON channel_tokens(token_hash);

-- Composite index for validity checking
CREATE INDEX IF NOT EXISTS idx_channel_tokens_validity ON channel_tokens(status, not_before, not_after)
    WHERE status != 'REVOKED';

-- Trigger for updated_at
DROP TRIGGER IF EXISTS update_channel_tokens_updated_at ON channel_tokens;
CREATE TRIGGER update_channel_tokens_updated_at
    BEFORE UPDATE ON channel_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE channel_tokens IS 'Authentication tokens for distribution channels';
COMMENT ON COLUMN channel_tokens.pid IS 'Private ID - internal identifier, never exposed externally';
COMMENT ON COLUMN channel_tokens.id IS 'Public UUID - unique identifier exposed via REST API';
COMMENT ON COLUMN channel_tokens.token_hash IS 'SHA-256 hash of the token for verification';
COMMENT ON COLUMN channel_tokens.token_encrypted IS 'AES-256-GCM encrypted token payload';
COMMENT ON COLUMN channel_tokens.status IS 'PENDING (not yet valid), ACTIVE (valid), EXPIRED (past validity), REVOKED (manually revoked)';
COMMENT ON COLUMN channel_tokens.not_before IS 'Token validity start time';
COMMENT ON COLUMN channel_tokens.not_after IS 'Token validity end time';

-- ============================================================================
-- Modify Namespaces Table
-- ============================================================================
ALTER TABLE namespaces
    ADD COLUMN IF NOT EXISTS channel_pid BIGINT REFERENCES distribution_channels(pid) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_namespaces_channel_pid ON namespaces(channel_pid);

COMMENT ON COLUMN namespaces.channel_pid IS 'Distribution channel for this namespace (NULL = default channel)';

-- ============================================================================
-- Bootstrap: Default Channel (no authentication required)
-- ============================================================================
INSERT INTO distribution_channels (id, name, description, requires_auth, created_by)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'default',
    'Default distribution channel (no authentication required)',
    false,
    'system'
)
ON CONFLICT (name) DO NOTHING;

-- Assign all existing namespaces to default channel
UPDATE namespaces
SET channel_pid = (SELECT pid FROM distribution_channels WHERE name = 'default')
WHERE channel_pid IS NULL;

-- ============================================================================
-- Update audit_logs action constraint to include new actions
-- ============================================================================
ALTER TABLE audit_logs
    DROP CONSTRAINT IF EXISTS audit_logs_action_check;

ALTER TABLE audit_logs
    ADD CONSTRAINT audit_logs_action_check CHECK (
        action IN (
            'CREATE', 'UPDATE', 'DELETE', 'GET', 'LIST',
            'INVALIDATE', 'MOUNT', 'UNMOUNT',
            'ACTIVATE', 'DEACTIVATE', 'EXPIRE', 'REVOKE'
        )
    );

-- Update resource_type constraint
ALTER TABLE audit_logs
    DROP CONSTRAINT IF EXISTS audit_logs_resource_type_check;

ALTER TABLE audit_logs
    ADD CONSTRAINT audit_logs_resource_type_check CHECK (
        resource_type IN ('CERTIFICATE', 'GROUP', 'NAMESPACE', 'CHANNEL', 'TOKEN')
    );

COMMIT;
