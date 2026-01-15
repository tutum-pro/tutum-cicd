-- Migration: 006_populate_group_names
-- Purpose: Ensure all certificate_groups have meaningful names populated
-- For groups created with UUID or empty names, generate descriptive names

BEGIN;

-- Update groups that have UUID-like names (pattern: 8-4-4-4-12 hex characters)
-- Replace with auto-generated names like "group-<first-8-chars>"
UPDATE certificate_groups
SET name = 'group-' || SUBSTRING(id::text, 1, 8),
    updated_at = NOW(),
    updated_by = 'migration-006'
WHERE name ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  AND name != '00000000-0000-0000-0000-000000000001'; -- Don't update default group

-- Log what was updated
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % certificate_groups with UUID names to descriptive names', updated_count;
END $$;

-- Update the default system group if it exists with UUID name
UPDATE certificate_groups
SET name = 'system-default',
    description = COALESCE(description, 'System default group'),
    updated_at = NOW(),
    updated_by = 'migration-006'
WHERE id = '00000000-0000-0000-0000-000000000000'
  AND name ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

COMMIT;
