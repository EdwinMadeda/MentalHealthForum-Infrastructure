-- =====================================================================
-- MASTER RUNNER - Execute in this order
-- =====================================================================

\echo '========================================'
\echo 'DEPLOYING MENTAL HEALTH FORUM SCHEMA'
\echo '========================================'

\i 00_extensions.sql
\i 01_enums.sql
\i 02_tables.sql
\i 03_circular_fks.sql
\i 04_indexes.sql
\i 05_functions.sql
\i 06_triggers.sql
\i 07_views.sql
\i 08_seed_data.sql

\echo '========================================'
\echo 'SCHEMA DEPLOYMENT COMPLETE!'
\echo '========================================'

-- ---------------------------------------------------------------------
-- Optional validation summary
-- ---------------------------------------------------------------------
DO $$
DECLARE
table_count INTEGER;
    enum_count INTEGER;
    function_count INTEGER;
    trigger_count INTEGER;
    view_count INTEGER;
BEGIN
SELECT COUNT(*) INTO table_count
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

SELECT COUNT(*) INTO enum_count
FROM pg_type t
         JOIN pg_namespace n ON n.oid = t.typnamespace
WHERE n.nspname = 'public' AND t.typtype = 'e';

SELECT COUNT(*) INTO function_count
FROM information_schema.routines
WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';

SELECT COUNT(*) INTO trigger_count
FROM information_schema.triggers
WHERE trigger_schema = 'public';

SELECT COUNT(*) INTO view_count
FROM information_schema.views
WHERE table_schema = 'public';

RAISE NOTICE '========================================';
    RAISE NOTICE 'SCHEMA VALIDATION COMPLETE! ✅';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tables:   %', table_count;
    RAISE NOTICE 'Enums:    %', enum_count;
    RAISE NOTICE 'Functions: %', function_count;
    RAISE NOTICE 'Triggers: %', trigger_count;
    RAISE NOTICE 'Views:    %', view_count;
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Database schema is ready for use! 🚀';
END $$;

