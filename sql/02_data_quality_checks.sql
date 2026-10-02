-- PHASE 4: DATA QUALITY CHECKS
-- Netflix Content Analytics - Data Validation Queries
--
-- These queries validate the integrity of cleaned data
-- Run after data loading to ensure quality

-- ============================================================================
-- CHECK 1: VERIFY PRIMARY KEY UNIQUENESS
-- ============================================================================

-- show_id should be unique and present
SELECT 'PRIMARY KEY: show_id uniqueness' as check_name,
       CASE
           WHEN COUNT(*) = COUNT(DISTINCT show_id) THEN 'PASS'
           ELSE 'FAIL'
       END as result,
       COUNT(*) as total_records,
       COUNT(DISTINCT show_id) as unique_show_ids
FROM titles;

-- ============================================================================
-- CHECK 2: VERIFY NO NULL IN REQUIRED FIELDS
-- ============================================================================

SELECT 'NOT NULL: show_id' as check_name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as result,
       COUNT(*) as null_count
FROM titles WHERE show_id IS NULL;

SELECT 'NOT NULL: type' as check_name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as result,
       COUNT(*) as null_count
FROM titles WHERE type IS NULL;

SELECT 'NOT NULL: title' as check_name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as result,
       COUNT(*) as null_count
FROM titles WHERE title IS NULL;

SELECT 'NOT NULL: release_year' as check_name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as result,
       COUNT(*) as null_count
FROM titles WHERE release_year IS NULL;

SELECT 'NOT NULL: description' as check_name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as result,
       COUNT(*) as null_count
FROM titles WHERE description IS NULL;

-- ============================================================================
-- CHECK 3: VERIFY TYPE VALUES
-- ============================================================================

SELECT 'CHECK: Valid type values' as check_name,
       CASE
           WHEN COUNT(DISTINCT type) = 2 AND SUM(CASE WHEN type IN ('Movie', 'TV Show') THEN 1 ELSE 0 END) = COUNT(*)
           THEN 'PASS'
           ELSE 'FAIL'
       END as result,
       COUNT(DISTINCT type) as distinct_types
FROM titles;

SELECT type as value, COUNT(*) as count FROM titles GROUP BY type ORDER BY count DESC;

-- ============================================================================
-- CHECK 4: VERIFY RATING ANOMALIES WERE FIXED
-- ============================================================================

SELECT 'ANOMALY REVIEW: s5542, s5795, s5814' as check_name,
       CASE
           WHEN COUNT(*) = 3 AND COUNT(*) FILTER (WHERE rating IS NULL) = 3 AND COUNT(*) FILTER (WHERE duration IN ('74 min','84 min','66 min')) = 3
           THEN 'PASS'
           ELSE 'FAIL'
       END as result
FROM titles
WHERE show_id IN ('s5542', 's5795', 's5814');

SELECT show_id, type, title, rating, duration
FROM titles
WHERE show_id IN ('s5542', 's5795', 's5814')
ORDER BY show_id;

-- ============================================================================
-- CHECK 5: VERIFY DURATION VALUES WERE MOVED
-- ============================================================================

SELECT 'ANOMALY FIX: Duration values in correct field' as check_name,
       CASE
           WHEN SUM(CASE WHEN duration IN ('74 min', '84 min', '66 min') THEN 1 ELSE 0 END) = 3
           THEN 'PASS'
           ELSE 'FAIL'
       END as result,
       SUM(CASE WHEN duration IN ('74 min', '84 min', '66 min') THEN 1 ELSE 0 END) as anomaly_durations_found
FROM titles;

-- ============================================================================
-- CHECK 6: VERIFY NO DURATION VALUES IN RATING FIELD
-- ============================================================================

SELECT 'CHECK: No duration values in rating field' as check_name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as result,
       COUNT(*) as invalid_ratings
FROM titles
WHERE rating LIKE '%min%';

-- ============================================================================
-- CHECK 7: VERIFY RELEASE YEAR RANGE
-- ============================================================================

SELECT 'CHECK: Release year range' as check_name,
       CASE
           WHEN MIN(release_year) >= 1900 AND MAX(release_year) <= 2021
           THEN 'PASS'
           ELSE 'FAIL'
       END as result,
       MIN(release_year) as min_year,
       MAX(release_year) as max_year
FROM titles;

-- ============================================================================
-- CHECK 8: VERIFY DATE_ADDED CONVERSION
-- ============================================================================

SELECT 'CHECK: date_added type and range' as check_name,
       CASE
           WHEN COUNT(*) > 0 AND MIN(date_added) >= '2021-01-01' AND MAX(date_added) <= '2021-12-31'
           THEN 'PASS'
           ELSE 'FAIL'
       END as result,
       COUNT(*) as non_null_dates,
       MIN(date_added) as min_date,
       MAX(date_added) as max_date
FROM titles
WHERE date_added IS NOT NULL;

-- ============================================================================
-- CHECK 9: VERIFY MISSING VALUES (EXPECTED NULL VALUES)
-- ============================================================================

SELECT 'MISSING VALUES: director' as check_name,
       COUNT(*) as missing_count,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM titles), 2) as missing_percent
FROM titles WHERE director IS NULL;

SELECT 'MISSING VALUES: cast' as check_name,
       COUNT(*) as missing_count,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM titles), 2) as missing_percent
FROM titles WHERE cast IS NULL;

SELECT 'MISSING VALUES: date_added' as check_name,
       COUNT(*) as missing_count,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM titles), 2) as missing_percent
FROM titles WHERE date_added IS NULL;

SELECT 'MISSING VALUES: rating' as check_name,
       COUNT(*) as missing_count,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM titles), 2) as missing_percent
FROM titles WHERE rating IS NULL;

-- ============================================================================
-- CHECK 10: VERIFY NORMALIZED TABLES - REFERENTIAL INTEGRITY
-- ============================================================================

SELECT 'REFERENTIAL INTEGRITY: Orphan countries' as check_name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as result,
       COUNT(*) as orphan_count
FROM title_countries
WHERE show_id NOT IN (SELECT show_id FROM titles);

SELECT 'REFERENTIAL INTEGRITY: Orphan genres' as check_name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as result,
       COUNT(*) as orphan_count
FROM title_genres
WHERE show_id NOT IN (SELECT show_id FROM titles);

-- ============================================================================
-- CHECK 11: VERIFY NORMALIZED TABLES - NO DUPLICATES
-- ============================================================================

SELECT 'UNIQUENESS: Duplicate countries' as check_name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as result,
       COUNT(*) as duplicate_count
FROM (
    SELECT show_id, country, COUNT(*) as cnt
    FROM title_countries
    GROUP BY show_id, country
    HAVING COUNT(*) > 1
) x;

SELECT 'UNIQUENESS: Duplicate genres' as check_name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as result,
       COUNT(*) as duplicate_count
FROM (
    SELECT show_id, genre, COUNT(*) as cnt
    FROM title_genres
    GROUP BY show_id, genre
    HAVING COUNT(*) > 1
) x;

-- ============================================================================
-- CHECK 12: VERIFY TOTAL RECORD COUNTS
-- ============================================================================

SELECT 'RECORD COUNT: Total titles' as check_name,
       COUNT(*) as count
FROM titles;

SELECT 'RECORD COUNT: Total countries' as check_name,
       COUNT(*) as count
FROM title_countries;

SELECT 'RECORD COUNT: Total genres' as check_name,
       COUNT(*) as count
FROM title_genres;

-- ============================================================================
-- CHECK 13: VERIFY CONTENT TYPE DISTRIBUTION
-- ============================================================================

SELECT type, COUNT(*) as count,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM titles), 2) as percent
FROM titles
GROUP BY type
ORDER BY count DESC;

-- ============================================================================
-- CHECK 14: VERIFY RATING VALUE VALIDITY
-- ============================================================================

SELECT rating, COUNT(*) as count
FROM titles
WHERE rating IS NOT NULL
GROUP BY rating
ORDER BY count DESC;

-- Verify only valid ratings exist (no 'min' values)
SELECT 'CHECK: No invalid rating formats' as check_name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as result,
       COUNT(*) as invalid_count
FROM titles
WHERE rating IS NOT NULL AND (rating LIKE '%min%' OR rating LIKE '%season%' OR CHAR_LENGTH(rating) > 20);

-- ============================================================================
-- CHECK 15: VERIFY DURATION FORMAT BY TYPE
-- ============================================================================

SELECT 'DURATION: Movie format check' as check_name,
       CASE
           WHEN COUNT(*) > 0 AND SUM(CASE WHEN duration LIKE '%min' OR duration IS NULL THEN 1 ELSE 0 END) = COUNT(*)
           THEN 'PASS'
           ELSE 'FAIL'
       END as result,
       COUNT(*) as movie_count
FROM titles
WHERE type = 'Movie';

SELECT 'DURATION: TV Show format check' as check_name,
       CASE
           WHEN COUNT(*) > 0 AND SUM(CASE WHEN duration LIKE '%Season%' OR duration IS NULL THEN 1 ELSE 0 END) = COUNT(*)
           THEN 'PASS'
           ELSE 'FAIL'
       END as result,
       COUNT(*) as tv_show_count
FROM titles
WHERE type = 'TV Show';

-- ============================================================================
-- CHECK 16: SUMMARY VALIDATION REPORT
-- ============================================================================

SELECT 'SUMMARY: Total records in titles table' as check_name, COUNT(*) as result FROM titles
UNION ALL
SELECT 'SUMMARY: Movies in catalog' as check_name, COUNT(*) as result FROM titles WHERE type = 'Movie'
UNION ALL
SELECT 'SUMMARY: TV Shows in catalog' as check_name, COUNT(*) as result FROM titles WHERE type = 'TV Show'
UNION ALL
SELECT 'SUMMARY: Records with NULL director' as check_name, COUNT(*) as result FROM titles WHERE director IS NULL
UNION ALL
SELECT 'SUMMARY: Records with NULL cast' as check_name, COUNT(*) as result FROM titles WHERE cast IS NULL
UNION ALL
SELECT 'SUMMARY: Records with NULL date_added' as check_name, COUNT(*) as result FROM titles WHERE date_added IS NULL
UNION ALL
SELECT 'SUMMARY: Records with NULL rating' as check_name, COUNT(*) as result FROM titles WHERE rating IS NULL
UNION ALL
SELECT 'SUMMARY: Records with NULL duration' as check_name, COUNT(*) as result FROM titles WHERE duration IS NULL
ORDER BY result DESC;
