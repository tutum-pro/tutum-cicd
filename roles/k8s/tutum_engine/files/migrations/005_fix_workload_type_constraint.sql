-- Migration: 005_fix_workload_type_constraint
-- Description: Add k8s-pod to workload_type constraint
-- Author: System
-- Date: 2025-11-22
-- Note: CSI driver sends k8s-pod for standalone pods and k8s-deployment/statefulset/daemonset for managed workloads

BEGIN;

-- Drop old constraint
ALTER TABLE audit_logs DROP CONSTRAINT IF EXISTS audit_logs_workload_type_check;

-- Add new constraint with k8s-pod included
ALTER TABLE audit_logs ADD CONSTRAINT audit_logs_workload_type_check
    CHECK (workload_type IS NULL OR workload_type IN ('k8s-pod', 'k8s-deployment', 'k8s-statefulset', 'k8s-daemonset', 'docker-service'));

-- Update documentation comment
COMMENT ON COLUMN audit_logs.workload_type IS 'Type of workload: k8s-pod, k8s-deployment, k8s-statefulset, k8s-daemonset, docker-service';

COMMIT;
