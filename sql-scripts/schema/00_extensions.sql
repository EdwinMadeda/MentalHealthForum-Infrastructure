-- =====================================================================
-- PART 1: EXTENSIONS
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS unaccent SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Create text search configurations (needed for global search)
CREATE TEXT SEARCH CONFIGURATION IF NOT EXISTS public.english_unaccent (COPY = english);
ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ALTER MAPPING FOR word, asciiword, hword, hword_part
        WITH public.unaccent, english_stem;

CREATE TEXT SEARCH CONFIGURATION IF NOT EXISTS public.simple_unaccent (COPY = simple);
ALTER TEXT SEARCH CONFIGURATION public.simple_unaccent
    ALTER MAPPING FOR word, asciiword, hword, hword_part
        WITH public.unaccent, simple;