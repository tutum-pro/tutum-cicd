-- Migration: 007_add_pod_restart_config_to_namespaces
-- Description: Add pod restart configuration to namespaces table for opt-out control

BEGIN;

-- Add pod_restart_enabled flag (default: true)
ALTER TABLE namespaces
    ADD COLUMN IF NOT EXISTS pod_restart_enabled BOOLEAN DEFAULT true;

COMMENT ON COLUMN namespaces.pod_restart_enabled IS
    'Enable/disable automatic pod restart on certificate updates for this namespace (default: true)';

-- Index for faster lookups when checking restart permission
CREATE INDEX IF NOT EXISTS idx_namespaces_pod_restart_enabled
    ON namespaces(pod_restart_enabled)
    WHERE pod_restart_enabled = false;

COMMIT;
