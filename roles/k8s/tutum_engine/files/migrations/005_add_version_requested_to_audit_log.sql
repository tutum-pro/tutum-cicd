-- Migration: 005_add_version_requested_to_audit_log
-- Description: Add version_requested field to track if pod mounts latest or specific version
-- Author: System
-- Date: 2025-11-21

BEGIN;

-- Add version_requested column (0 = latest, >0 = specific version)
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS version_requested INTEGER DEFAULT 0;

-- Add comment for documentation
COMMENT ON COLUMN audit_logs.version_requested IS 'Certificate version requested during MOUNT: 0=latest, >0=specific version';

-- Create index for queries finding pods mounting latest versions
CREATE INDEX IF NOT EXISTS idx_audit_logs_mount_latest ON audit_logs(action, resource_name, version_requested)
    WHERE action = 'MOUNT' AND version_requested = 0;

COMMIT;
