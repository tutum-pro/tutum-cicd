-- Migration: 004_add_workload_to_audit_log
-- Description: Add workload information fields to audit_logs table for tracking K8s/Docker workloads
-- Author: System
-- Date: 2025-11-20

BEGIN;

-- Add workload_type column (k8s or docker)
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS workload_type VARCHAR(20);

-- Add workload_name column (Deployment/StatefulSet/DaemonSet name for K8s, service name for Docker)
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS workload_name VARCHAR(255);

-- Add workload_namespace column (for K8s namespace, NULL for Docker)
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS workload_namespace VARCHAR(255);

-- Add constraint for workload_type
ALTER TABLE audit_logs DROP CONSTRAINT IF EXISTS audit_logs_workload_type_check;
ALTER TABLE audit_logs ADD CONSTRAINT audit_logs_workload_type_check
    CHECK (workload_type IS NULL OR workload_type IN ('k8s-deployment', 'k8s-statefulset', 'k8s-daemonset', 'docker-service'));

-- Create index for workload queries
CREATE INDEX IF NOT EXISTS idx_audit_logs_workload ON audit_logs(workload_type, workload_name);

-- Update action constraint to include MOUNT and UNMOUNT
ALTER TABLE audit_logs DROP CONSTRAINT IF EXISTS audit_logs_action_check;
ALTER TABLE audit_logs ADD CONSTRAINT audit_logs_action_check
    CHECK (action IN ('CREATE', 'UPDATE', 'DELETE', 'GET', 'LIST', 'INVALIDATE', 'MOUNT', 'UNMOUNT'));

COMMIT;

-- Comments for documentation
COMMENT ON COLUMN audit_logs.workload_type IS 'Type of workload: k8s-deployment, k8s-statefulset, k8s-daemonset, docker-service';
COMMENT ON COLUMN audit_logs.workload_name IS 'Name of the workload that mounted/unmounted the certificate';
COMMENT ON COLUMN audit_logs.workload_namespace IS 'Kubernetes namespace of the workload (NULL for Docker)';
