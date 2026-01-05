-- Migration: Add public UUID to audit_logs table
-- This follows the pid/id pattern used by other tables (namespaces, certificate_groups, certificates)
-- The BIGSERIAL id becomes private (never exposed), and public_id (UUID) is exposed via API

-- Step 1: Add the public_id column with default UUID generation
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS public_id UUID UNIQUE DEFAULT uuid_generate_v4();

-- Step 2: Generate UUIDs for any existing records that don't have one
UPDATE audit_logs SET public_id = uuid_generate_v4() WHERE public_id IS NULL;

-- Step 3: Make the column NOT NULL after populating existing records
ALTER TABLE audit_logs ALTER COLUMN public_id SET NOT NULL;

-- Step 4: Create index for efficient lookups by public_id
CREATE INDEX IF NOT EXISTS idx_audit_logs_public_id ON audit_logs(public_id);

-- Step 5: Add documentation comments
COMMENT ON COLUMN audit_logs.id IS 'Private ID (pid) - internal BIGSERIAL identifier used for internal operations and ordering, never exposed externally via API';
COMMENT ON COLUMN audit_logs.public_id IS 'Public UUID - unique identifier exposed via REST/gRPC API, prevents enumeration attacks and ID prediction';
