-- PHASE 3: DATA CLEANING & IMPORT
-- Netflix Content Analytics - Complete Data Cleaning and Loading Script
--
-- This script processes the raw netflix_titles.csv and creates cleaned tables
-- It handles all data quality issues identified in the audit
--
-- Execution order:
-- 1. Create staging table for raw data
-- 2. Import raw CSV
-- 3. Create cleaned main table
-- 4. Create normalized junction tables
-- 5. Validate data integrity

-- ============================================================================
-- STEP 1: CREATE STAGING TABLE FOR RAW CSV DATA
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
-- STEP 2: IMPORT RAW CSV (Run this in psql or via application)
-- ============================================================================

-- Command to execute in psql terminal:
-- \COPY netflix_raw_staging FROM 'E:\archive (1)\netflix_titles.csv' WITH (FORMAT csv, HEADER, DELIMITER ',', QUOTE '"', ESCAPE '"')

-- Alternatively, use COPY if the file is accessible to the database server:
-- COPY netflix_raw_staging FROM 'E:\archive (1)\netflix_titles.csv' WITH (FORMAT csv, HEADER, DELIMITER ',', QUOTE '"', ESCAPE '"')

-- ============================================================================
-- STEP 3: CREATE CLEANED TITLES TABLE
-- ============================================================================

DROP TABLE IF EXISTS titles CASCADE;

CREATE TABLE titles (
    show_id            VARCHAR(10) PRIMARY KEY,
    type               VARCHAR(20) NOT NULL CHECK (type IN ('Movie', 'TV Show')),
    title              VARCHAR(255) NOT NULL,
    director           TEXT,
    cast               TEXT,
    date_added         DATE,
    release_year       INTEGER NOT NULL CHECK (release_year >= 1900 AND release_year <= 2021),
    rating             VARCHAR(20),
    duration           VARCHAR(50),
    description        TEXT NOT NULL,
    data_quality_flag  TEXT,
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- STEP 4: INSERT CLEANED DATA INTO TITLES TABLE
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
    data_quality_flag
)
SELECT
    TRIM(raw.show_id)::VARCHAR(10) as show_id,
    TRIM(raw.type)::VARCHAR(20) as type,
    TRIM(raw.title)::VARCHAR(255) as title,

    -- Director: trim whitespace, NULL if empty
    NULLIF(TRIM(raw.director), '') as director,

    -- Cast: trim whitespace, NULL if empty
    NULLIF(TRIM(raw.cast), '') as cast,

    -- Date Added: convert to DATE with proper NULL handling
    CASE
        WHEN TRIM(raw.date_added) = '' THEN NULL
        ELSE TO_DATE(TRIM(raw.date_added), 'Month DD, YYYY')
    END as date_added,

    -- Release Year: convert to integer
    TRIM(raw.release_year)::INTEGER as release_year,

    -- Rating: fix the 3 known anomalies
    CASE
        -- Fix anomaly: s5542 has '74 min' in rating field
        WHEN TRIM(raw.show_id) = 's5542' THEN 'TV-MA'

        -- Fix anomaly: s5795 has '84 min' in rating field
        WHEN TRIM(raw.show_id) = 's5795' THEN 'TV-MA'

        -- Fix anomaly: s5814 has '66 min' in rating field
        WHEN TRIM(raw.show_id) = 's5814' THEN 'TV-MA'

        -- Handle other empty/invalid ratings
        WHEN TRIM(raw.rating) = '' OR TRIM(raw.rating) IN ('66 min', '74 min', '84 min') THEN NULL

        -- Normal case
        ELSE TRIM(raw.rating)
    END as rating,

    -- Duration: move anomaly values from rating field to duration field
    CASE
        -- Fix anomaly: s5542 should have '74 min' in duration
        WHEN TRIM(raw.show_id) = 's5542' THEN '74 min'

        -- Fix anomaly: s5795 should have '84 min' in duration
        WHEN TRIM(raw.show_id) = 's5795' THEN '84 min'

        -- Fix anomaly: s5814 should have '66 min' in duration
        WHEN TRIM(raw.show_id) = 's5814' THEN '66 min'

        -- Normal case: trim and use, or NULL if empty
        ELSE NULLIF(TRIM(raw.duration), '')
    END as duration,

    TRIM(raw.description) as description,

    -- Data quality flag for audit trail
    CASE
        WHEN TRIM(raw.show_id) IN ('s5542', 's5795', 's5814')
            THEN 'CLEANED: Duration moved from rating field'
        WHEN NULLIF(TRIM(raw.director), '') IS NULL AND TRIM(raw.type) = 'TV Show'
            THEN 'EXPECTED: TV show without director'
        WHEN NULLIF(TRIM(raw.director), '') IS NULL
            THEN 'NOTE: Missing director'
        ELSE NULL
    END as data_quality_flag

FROM netflix_raw_staging raw
ORDER BY raw.show_id;

-- ============================================================================
-- STEP 5: CREATE NORMALIZED COUNTRIES TABLE
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
-- STEP 6: POPULATE COUNTRIES TABLE (Split multi-value field)
-- ============================================================================

INSERT INTO title_countries (show_id, country)
SELECT
    raw.show_id,
    TRIM(country_value) as country
FROM (
    SELECT
        TRIM(show_id)::VARCHAR(10) as show_id,
        UNNEST(STRING_TO_ARRAY(country, ',')) as country_value
    FROM netflix_raw_staging
    WHERE TRIM(country) IS NOT NULL AND TRIM(country) != ''
) raw
WHERE TRIM(country_value) != ''
ORDER BY raw.show_id, country;

-- ============================================================================
-- STEP 7: CREATE NORMALIZED GENRES TABLE
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
-- STEP 8: POPULATE GENRES TABLE (Split multi-value field)
-- ============================================================================

INSERT INTO title_genres (show_id, genre)
SELECT
    raw.show_id,
    TRIM(genre_value) as genre
FROM (
    SELECT
        TRIM(show_id)::VARCHAR(10) as show_id,
        UNNEST(STRING_TO_ARRAY(listed_in, ',')) as genre_value
    FROM netflix_raw_staging
    WHERE TRIM(listed_in) IS NOT NULL AND TRIM(listed_in) != ''
) raw
WHERE TRIM(genre_value) != ''
ORDER BY raw.show_id, genre;

-- ============================================================================
-- STEP 9: DROP STAGING TABLE (Clean up)
-- ============================================================================

DROP TABLE netflix_raw_staging;

-- ============================================================================
-- VERIFICATION: Check that data was loaded correctly
-- ============================================================================

-- Count records in main table
SELECT COUNT(*) as titles_count FROM titles;

-- Count records in normalized tables
SELECT COUNT(*) as countries_count FROM title_countries;
SELECT COUNT(*) as genres_count FROM title_genres;

-- Show the 3 fixed anomalies
SELECT show_id, type, title, rating, duration
FROM titles
WHERE show_id IN ('s5542', 's5795', 's5814')
ORDER BY show_id;

-- Show sample of cleaned data
SELECT * FROM titles LIMIT 10;
