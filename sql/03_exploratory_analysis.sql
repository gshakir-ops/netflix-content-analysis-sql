-- PHASE 5: EXPLORATORY DATA ANALYSIS
-- Netflix Content Analytics - EDA Queries
--
-- These queries answer fundamental questions about the Netflix catalog
-- Run these to understand data patterns and distributions

-- ============================================================================
-- Q1: Content Type Distribution - Overall Catalog Composition
-- ============================================================================

SELECT 'Q1: Content Type Distribution' as question;

SELECT
    type,
    COUNT(*) as count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM titles), 2) as percentage
FROM titles
GROUP BY type
ORDER BY count DESC;

-- Expected: ~6,131 Movies (69.66%), ~2,676 TV Shows (30.34%)

-- ============================================================================
-- Q2: Most Common Content Ratings
-- ============================================================================

SELECT 'Q2: Most Common Content Ratings' as question;

SELECT
    COALESCE(rating, 'UNRATED') as rating,
    COUNT(*) as count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM titles), 2) as percentage,
    COUNT(CASE WHEN type = 'Movie' THEN 1 END) as movies,
    COUNT(CASE WHEN type = 'TV Show' THEN 1 END) as tv_shows
FROM titles
GROUP BY rating
ORDER BY count DESC;

-- ============================================================================
-- Q3: Most Common Genres
-- ============================================================================

SELECT 'Q3: Most Common Genres' as question;

SELECT
    genre,
    COUNT(*) as title_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(DISTINCT show_id) FROM title_genres), 2) as percentage
FROM title_genres
GROUP BY genre
ORDER BY title_count DESC;

-- ============================================================================
-- Q4: Top 15 Production Countries
-- ============================================================================

SELECT 'Q4: Top 15 Production Countries' as question;

SELECT
    country,
    COUNT(*) as title_count,
    COUNT(CASE WHEN type = 'Movie' THEN 1 END) as movies,
    COUNT(CASE WHEN type = 'TV Show' THEN 1 END) as tv_shows
FROM title_countries tc
JOIN titles t ON tc.show_id = t.show_id
GROUP BY country
ORDER BY title_count DESC
LIMIT 15;

-- ============================================================================
-- Q5: Movie Duration Distribution
-- ============================================================================

SELECT 'Q5: Movie Duration Distribution' as question;

SELECT
    CASE
        WHEN duration ~ '^\d+ min$' THEN (regexp_matches(duration, '(\d+)', 'g'))[1]::INTEGER
        ELSE NULL
    END as duration_minutes,
    COUNT(*) as count
FROM titles
WHERE type = 'Movie' AND duration ~ '^\d+ min$'
GROUP BY (regexp_matches(duration, '(\d+)', 'g'))[1]::INTEGER
ORDER BY duration_minutes;

-- Summary statistics for movie durations
SELECT
    'Movie Duration Statistics' as stat_name,
    AVG((regexp_matches(duration, '(\d+)', 'g'))[1]::INTEGER)::NUMERIC(6,2) as avg_minutes,
    MIN((regexp_matches(duration, '(\d+)', 'g'))[1]::INTEGER) as min_minutes,
    MAX((regexp_matches(duration, '(\d+)', 'g'))[1]::INTEGER) as max_minutes,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (regexp_matches(duration, '(\d+)', 'g'))[1]::INTEGER) as median_minutes
FROM titles
WHERE type = 'Movie' AND duration ~ '^\d+ min$';

-- ============================================================================
-- Q6: TV Show Season Distribution
-- ============================================================================

SELECT 'Q6: TV Show Season Distribution' as question;

SELECT
    CASE
        WHEN duration ~ '^\d+ Season' THEN (regexp_matches(duration, '(\d+)', 'g'))[1]::INTEGER
        ELSE NULL
    END as seasons,
    COUNT(*) as show_count
FROM titles
WHERE type = 'TV Show' AND duration ~ '^\d+ Season'
GROUP BY (regexp_matches(duration, '(\d+)', 'g'))[1]::INTEGER
ORDER BY seasons;

-- Summary statistics for TV show seasons
SELECT
    'TV Show Season Statistics' as stat_name,
    AVG((regexp_matches(duration, '(\d+)', 'g'))[1]::INTEGER)::NUMERIC(6,2) as avg_seasons,
    MIN((regexp_matches(duration, '(\d+)', 'g'))[1]::INTEGER) as min_seasons,
    MAX((regexp_matches(duration, '(\d+)', 'g'))[1]::INTEGER) as max_seasons,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (regexp_matches(duration, '(\d+)', 'g'))[1]::INTEGER) as median_seasons
FROM titles
WHERE type = 'TV Show' AND duration ~ '^\d+ Season';

-- ============================================================================
-- Q7: Content by Release Year (Distribution Over Time)
-- ============================================================================

SELECT 'Q7: Content by Release Year' as question;

SELECT
    release_year,
    COUNT(*) as total_titles,
    COUNT(CASE WHEN type = 'Movie' THEN 1 END) as movies,
    COUNT(CASE WHEN type = 'TV Show' THEN 1 END) as tv_shows
FROM titles
GROUP BY release_year
ORDER BY release_year DESC
LIMIT 30;

-- ============================================================================
-- Q8: Content Added to Netflix by Year (date_added Analysis)
-- ============================================================================

SELECT 'Q8: Content Added to Netflix by Year' as question;

SELECT
    EXTRACT(YEAR FROM date_added) as year_added,
    COUNT(*) as titles_added,
    COUNT(CASE WHEN type = 'Movie' THEN 1 END) as movies_added,
    COUNT(CASE WHEN type = 'TV Show' THEN 1 END) as tv_shows_added
FROM titles
WHERE date_added IS NOT NULL
GROUP BY EXTRACT(YEAR FROM date_added)
ORDER BY year_added DESC;

-- ============================================================================
-- Q9: Content Age at Addition (Release Year vs Date Added)
-- ============================================================================

SELECT 'Q9: Content Age Analysis (Release Year to Addition)' as question;

SELECT
    EXTRACT(YEAR FROM date_added) - release_year as years_after_release,
    COUNT(*) as title_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM titles WHERE date_added IS NOT NULL), 2) as percentage
FROM titles
WHERE date_added IS NOT NULL
GROUP BY EXTRACT(YEAR FROM date_added) - release_year
ORDER BY years_after_release DESC
LIMIT 20;

-- ============================================================================
-- Q10: Distribution of Titles with Missing Metadata
-- ============================================================================

SELECT 'Q10: Missing Metadata Summary' as question;

SELECT
    SUM(CASE WHEN director IS NULL THEN 1 ELSE 0 END) as missing_director,
    SUM(CASE WHEN cast IS NULL THEN 1 ELSE 0 END) as missing_cast,
    COUNT(DISTINCT tc.show_id) as titles_with_country,
    (SELECT COUNT(*) FROM titles) - COUNT(DISTINCT tc.show_id) as missing_country,
    SUM(CASE WHEN date_added IS NULL THEN 1 ELSE 0 END) as missing_date_added,
    SUM(CASE WHEN rating IS NULL THEN 1 ELSE 0 END) as missing_rating
FROM titles t
LEFT JOIN title_countries tc ON t.show_id = tc.show_id;

-- ============================================================================
-- Q11: Movie vs TV Show Comparison
-- ============================================================================

SELECT 'Q11: Movie vs TV Show Comparison' as question;

SELECT
    type,
    COUNT(*) as total,
    COUNT(DISTINCT CASE WHEN director IS NOT NULL THEN show_id END) as has_director,
    COUNT(DISTINCT CASE WHEN cast IS NOT NULL THEN show_id END) as has_cast,
    COUNT(DISTINCT CASE WHEN rating IS NOT NULL THEN show_id END) as has_rating,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN rating IS NOT NULL THEN show_id END) / COUNT(*), 2) as rating_coverage_percent
FROM titles
GROUP BY type;

-- ============================================================================
-- Q12: Top 20 Most Frequent Genres
-- ============================================================================

SELECT 'Q12: Top 20 Most Frequent Genres' as question;

SELECT
    genre,
    COUNT(*) as title_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(DISTINCT show_id) FROM title_genres), 2) as coverage_percent
FROM title_genres
GROUP BY genre
ORDER BY title_count DESC
LIMIT 20;

-- ============================================================================
-- Q13: Co-occurrence Analysis - Genres That Appear Together Most Frequently
-- ============================================================================

SELECT 'Q13: Genres Frequently Appearing Together' as question;

SELECT
    tg1.genre as genre_1,
    tg2.genre as genre_2,
    COUNT(*) as co_occurrence_count
FROM title_genres tg1
JOIN title_genres tg2 ON tg1.show_id = tg2.show_id AND tg1.genre_id < tg2.genre_id
GROUP BY tg1.genre, tg2.genre
ORDER BY co_occurrence_count DESC
LIMIT 15;

-- ============================================================================
-- Q14: Multi-Country Co-Productions
-- ============================================================================

SELECT 'Q14: Multi-Country Co-Productions' as question;

SELECT
    COUNT(*) as title_count,
    AVG(country_count) as avg_countries_per_title,
    MAX(country_count) as max_countries_in_single_title
FROM (
    SELECT show_id, COUNT(*) as country_count
    FROM title_countries
    GROUP BY show_id
) subq;

-- Show titles with most countries
SELECT
    t.show_id,
    t.title,
    COUNT(*) as country_count,
    STRING_AGG(tc.country, ', ' ORDER BY tc.country) as countries
FROM titles t
JOIN title_countries tc ON t.show_id = tc.show_id
GROUP BY t.show_id, t.title
ORDER BY country_count DESC, t.title
LIMIT 10;

-- ============================================================================
-- Q15: Rating Distribution by Content Type
-- ============================================================================

SELECT 'Q15: Rating Distribution by Content Type' as question;

SELECT
    type,
    COALESCE(rating, 'UNRATED') as rating,
    COUNT(*) as count
FROM titles
GROUP BY type, rating
ORDER BY type, count DESC;

-- ============================================================================
-- Q16: Sample of Each Content Type
-- ============================================================================

SELECT 'Q16: Sample Movie' as category, * FROM titles WHERE type = 'Movie' LIMIT 1;
SELECT 'Q16: Sample TV Show' as category, * FROM titles WHERE type = 'TV Show' LIMIT 1;

-- ============================================================================
-- EXPLORATORY ANALYSIS COMPLETE
-- ============================================================================
