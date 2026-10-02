-- PHASE 3: DATA CLEANING
-- Netflix Content Analytics - SQL Data Cleaning Script
--
-- This script handles:
-- 1. Leading/trailing whitespace trimming
-- 2. date_added conversion from text to DATE type
-- 3. Missing value handling (NULL where appropriate)
-- 4. Rating anomalies (3 records with duration in rating field)
-- 5. Duration parsing validation
-- 6. Multi-value field parsing for normalization
--
-- IMPORTANT: This script assumes raw data has been loaded into a staging table.
-- The raw netflix_titles.csv should NEVER be modified directly.

-- ============================================================================
-- STEP 1: CREATE STAGING TABLE (temporary working space)
-- ============================================================================

DROP TABLE IF EXISTS netflix_raw_staging CASCADE;

CREATE TABLE netflix_raw_staging (
    show_id       VARCHAR(10),
    type          VARCHAR(50),
    title         VARCHAR(500),
    director      TEXT,
    cast          TEXT,
    country       TEXT,
    date_added    TEXT,
    release_year  VARCHAR(10),
    rating        VARCHAR(100),
    duration      VARCHAR(100),
    listed_in     TEXT,
    description   TEXT
);

-- ============================================================================
-- STEP 2: IMPORT RAW DATA FROM CSV
-- ============================================================================

-- Load the source CSV from the repository root using the psql client.
\copy netflix_raw_staging FROM 'data/raw/netflix_titles.csv' WITH (FORMAT csv, HEADER, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '')

-- ============================================================================
-- STEP 3: CREATE CLEANED MAIN TABLE
-- ============================================================================

DROP TABLE IF EXISTS titles CASCADE;

CREATE TABLE titles (
    show_id        VARCHAR(10) PRIMARY KEY,
    type           VARCHAR(20) NOT NULL CHECK (type IN ('Movie', 'TV Show')),
    title          VARCHAR(255) NOT NULL,
    director       TEXT,
    cast           TEXT,
    date_added     DATE,
    release_year   INTEGER NOT NULL CHECK (release_year >= 1900 AND release_year <= 2021),
    rating         VARCHAR(20),
    duration       VARCHAR(50),
    description    TEXT NOT NULL,
    data_quality_note TEXT,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- STEP 4: IDENTIFY AND DOCUMENT RATING ANOMALIES
-- ============================================================================

-- Before cleaning, identify the 3 records with rating/duration swap
-- These are the records we need to fix:
-- s5542 | Movie | Louis C.K. 2017 | rating='74 min' | duration=''
-- s5795 | Movie | Louis C.K.: Hilarious | rating='84 min' | duration=''
-- s5814 | Movie | Louis C.K.: Live at the Comedy Store | rating='66 min' | duration=''

-- ============================================================================
-- STEP 5: INSERT CLEANED DATA INTO TITLES TABLE
-- ============================================================================

INSERT INTO titles (
    show_id,
    type,
    title,
    director,
    cast,
    date_added,
    release_year,
    rating,
    duration,
    description,
    data_quality_note
)
SELECT
    TRIM(raw.show_id)::VARCHAR(10) as show_id,
    TRIM(raw.type)::VARCHAR(20) as type,
    TRIM(raw.title)::VARCHAR(255) as title,

    -- Director: trim whitespace, convert empty strings to NULL
    CASE
        WHEN TRIM(raw.director) = '' THEN NULL
        ELSE TRIM(raw.director)
    END as director,

    -- Cast: trim whitespace, convert empty strings to NULL
    CASE
        WHEN TRIM(raw.cast) = '' THEN NULL
        ELSE TRIM(raw.cast)
    END as cast,

    -- Date Added: trim, convert to DATE
    -- Handle the 10 records with missing dates
    CASE
        WHEN TRIM(raw.date_added) = '' THEN NULL
        ELSE TO_DATE(TRIM(raw.date_added), 'Month DD, YYYY')
    END as date_added,

    -- Release Year: convert to integer
    CASE
        WHEN TRIM(raw.release_year) = '' THEN NULL
        ELSE TRIM(raw.release_year)::INTEGER
    END as release_year,

    -- Rating: handle the 3 anomalies and blank rating
    CASE
        -- Anomaly 1: s5542 has '74 min' in rating field
        WHEN TRIM(raw.show_id) = 's5542' THEN NULL

        -- Anomaly 2: s5795 has '84 min' in rating field
        WHEN TRIM(raw.show_id) = 's5795' THEN NULL

        -- Anomaly 3: s5814 has '66 min' in rating field
        WHEN TRIM(raw.show_id) = 's5814' THEN NULL

        -- Handle blank ratings
        WHEN TRIM(raw.rating) = '' OR TRIM(raw.rating) IN ('66 min', '74 min', '84 min') THEN NULL

        -- Normal case: trim and keep rating
        ELSE TRIM(raw.rating)
    END as rating,

    -- Duration: handle anomalies by extracting from rating field when needed
    CASE
        -- Anomaly 1: s5542 has '74 min' in rating field
        WHEN TRIM(raw.show_id) = 's5542' THEN '74 min'

        -- Anomaly 2: s5795 has '84 min' in rating field
        WHEN TRIM(raw.show_id) = 's5795' THEN '84 min'

        -- Anomaly 3: s5814 has '66 min' in rating field
        WHEN TRIM(raw.show_id) = 's5814' THEN '66 min'

        -- Normal case: trim and keep duration
        WHEN TRIM(raw.duration) = '' THEN NULL
        ELSE TRIM(raw.duration)
    END as duration,

    TRIM(raw.description) as description,

    -- Note data quality issues
    CASE
        WHEN TRIM(raw.show_id) IN ('s5542', 's5795', 's5814') THEN 'FIXED: Rating/Duration swap - duration moved from rating field'
        WHEN TRIM(raw.director) = '' THEN 'Missing director (typical for TV shows)'
        WHEN TRIM(raw.cast) = '' THEN 'Missing cast information'
        WHEN TRIM(raw.country) = '' THEN 'Missing country information'
        WHEN TRIM(raw.date_added) = '' THEN 'Missing date_added'
        WHEN TRIM(raw.rating) = '' THEN 'Missing rating'
        ELSE NULL
    END as data_quality_note

FROM netflix_raw_staging raw
ORDER BY raw.show_id;

-- ============================================================================
-- STEP 6: CREATE NORMALIZED TABLES FOR COUNTRIES
-- ============================================================================

DROP TABLE IF EXISTS title_countries CASCADE;

CREATE TABLE title_countries (
    country_id  SERIAL PRIMARY KEY,
    show_id     VARCHAR(10) NOT NULL REFERENCES titles(show_id) ON DELETE CASCADE,
    country     VARCHAR(100) NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_title_countries_show_id ON title_countries(show_id);
CREATE UNIQUE INDEX idx_title_countries_unique ON title_countries(show_id, country);

-- ============================================================================
-- STEP 7: CREATE NORMALIZED TABLES FOR GENRES
-- ============================================================================

DROP TABLE IF EXISTS title_genres CASCADE;

CREATE TABLE title_genres (
    genre_id   SERIAL PRIMARY KEY,
    show_id    VARCHAR(10) NOT NULL REFERENCES titles(show_id) ON DELETE CASCADE,
    genre      VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_title_genres_show_id ON title_genres(show_id);
CREATE UNIQUE INDEX idx_title_genres_unique ON title_genres(show_id, genre);

-- ============================================================================
-- STEP 8: NORMALIZE COUNTRIES (Multi-value field splitting)
-- ============================================================================

INSERT INTO title_countries (show_id, country)
SELECT
    raw.show_id,
    TRIM(country_value) as country
FROM (
    SELECT
        TRIM(show_id)::VARCHAR(10) as show_id,
        -- Split comma-separated countries into individual rows
        UNNEST(STRING_TO_ARRAY(country, ',')) as country_value
    FROM netflix_raw_staging
    WHERE TRIM(country) IS NOT NULL AND TRIM(country) != ''
) raw
WHERE TRIM(country_value) != ''
ORDER BY raw.show_id, country;

-- ============================================================================
-- STEP 9: NORMALIZE GENRES (Multi-value field splitting)
-- ============================================================================

INSERT INTO title_genres (show_id, genre)
SELECT
    raw.show_id,
    TRIM(genre_value) as genre
FROM (
    SELECT
        TRIM(show_id)::VARCHAR(10) as show_id,
        -- Split comma-separated genres into individual rows
        UNNEST(STRING_TO_ARRAY(listed_in, ',')) as genre_value
    FROM netflix_raw_staging
    WHERE TRIM(listed_in) IS NOT NULL AND TRIM(listed_in) != ''
) raw
WHERE TRIM(genre_value) != ''
ORDER BY raw.show_id, genre;

-- ============================================================================
-- STEP 10: SUMMARY OF CLEANING OPERATIONS
-- ============================================================================

-- Summary of what was cleaned:
-- 1. Trimmed leading/trailing whitespace from ALL fields
-- 2. Converted 10 empty date_added values to NULL (kept as missing, not invented)
-- 3. Fixed 3 rating/duration anomalies:
--    - s5542: '74 min' moved from rating → duration
--    - s5795: '84 min' moved from rating → duration
--    - s5814: '66 min' moved from rating → duration
--    - The original ratings remain NULL because the source does not establish them
-- 4. Converted release_year to INTEGER type
-- 5. Converted date_added to DATE type using 'Month DD, YYYY' format
-- 6. Normalized country field: split by comma, one row per country
-- 7. Normalized genre field (listed_in): split by comma, one row per genre
-- 8. Kept director, cast, country as NULL where missing (did not invent data)
-- 9. Kept description and title as-is (100% complete in source)
-- 10. Added data_quality_note for audit trail

-- ============================================================================
-- VERIFICATION QUERIES (Run these to validate cleaning)
-- ============================================================================

-- Verify total row count matches source (8,807)
SELECT 'Titles count' as check_name, COUNT(*) as result FROM titles;

-- Verify no duplicate show_ids
SELECT 'Duplicate show_ids' as check_name, COUNT(*) as result
FROM (SELECT show_id, COUNT(*) FROM titles GROUP BY show_id HAVING COUNT(*) > 1) x;

-- Verify type values are correct
SELECT 'Type values' as check_name, COUNT(DISTINCT type) as result FROM titles;

-- Verify no NULL titles
SELECT 'NULL titles' as check_name, COUNT(*) as result FROM titles WHERE title IS NULL;

-- Verify rating anomalies were fixed
SELECT 'Fixed ratings (s5542, s5795, s5814)' as check_name,
       STRING_AGG(CONCAT(show_id, '=', rating), ', ') as result
FROM titles WHERE show_id IN ('s5542', 's5795', 's5814');

-- Verify duration anomalies were fixed
SELECT 'Fixed durations (s5542, s5795, s5814)' as check_name,
       STRING_AGG(CONCAT(show_id, '=', duration), ', ') as result
FROM titles WHERE show_id IN ('s5542', 's5795', 's5814');

-- Verify date_added conversion
SELECT 'date_added type check' as check_name, COUNT(*) as null_count FROM titles WHERE date_added IS NULL;
SELECT 'date_added min' as check_name, MIN(date_added)::TEXT as result FROM titles WHERE date_added IS NOT NULL;
SELECT 'date_added max' as check_name, MAX(date_added)::TEXT as result FROM titles WHERE date_added IS NOT NULL;

-- Verify countries were normalized
SELECT 'Total country entries' as check_name, COUNT(*) as result FROM title_countries;

-- Verify genres were normalized
SELECT 'Total genre entries' as check_name, COUNT(*) as result FROM title_genres;

-- Verify referential integrity
SELECT 'Orphan countries' as check_name, COUNT(*) as result FROM title_countries
WHERE show_id NOT IN (SELECT show_id FROM titles);

SELECT 'Orphan genres' as check_name, COUNT(*) as result FROM title_genres
WHERE show_id NOT IN (SELECT show_id FROM titles);
