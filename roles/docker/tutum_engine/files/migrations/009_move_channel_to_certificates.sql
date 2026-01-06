-- Migration: 009_move_channel_to_certificates
-- Description: Move distribution channel from namespace to certificate level
-- This allows filtering certificates by channel during access

BEGIN;

-- ============================================================================
-- Add channel_pid to certificates table
-- ============================================================================
ALTER TABLE certificates
    ADD COLUMN IF NOT EXISTS channel_pid BIGINT REFERENCES distribution_channels(pid) ON DELETE SET NULL;

-- Index for efficient channel filtering
CREATE INDEX IF NOT EXISTS idx_certificates_channel_pid ON certificates(channel_pid);

COMMENT ON COLUMN certificates.channel_pid IS 'Distribution channel for this certificate (NULL = default channel)';

-- ============================================================================
-- Migrate existing certificates to default channel
-- ============================================================================
UPDATE certificates
SET channel_pid = (SELECT pid FROM distribution_channels WHERE name = 'default')
WHERE channel_pid IS NULL;

-- ============================================================================
-- Remove channel_pid from namespaces (channel is now on certificate)
-- ============================================================================
-- First drop the index
DROP INDEX IF EXISTS idx_namespaces_channel_pid;

-- Then drop the column
ALTER TABLE namespaces
    DROP COLUMN IF EXISTS channel_pid;

COMMIT;
