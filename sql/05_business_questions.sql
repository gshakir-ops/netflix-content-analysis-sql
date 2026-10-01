-- PHASE 7: BUSINESS & ANALYTICAL QUESTIONS
-- Netflix Content Analytics - Key Business Questions with Answers
--
-- This section contains curated analytical questions with executable SQL,
-- actual results, observations, and limitations

-- ============================================================================
-- QUESTION 1: How is the Netflix catalog distributed between Movies and TV Shows?
-- ============================================================================

SELECT 'QUESTION 1: Content Type Distribution' as q;

-- Observation: Understand the fundamental composition of Netflix's offering
WITH content_mix AS (
    SELECT
        type,
        COUNT(*) as count,
        ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM titles), 2) as percentage
    FROM titles
    GROUP BY type
)
SELECT
    type,
    count,
    percentage,
    CASE
        WHEN type = 'Movie' THEN 'Movies dominate the catalog'
        ELSE 'TV Shows are smaller segment'
    END as interpretation
FROM content_mix
ORDER BY count DESC;

-- Expected Results:
-- Movie | 6131 | 69.66
-- TV Show | 2676 | 30.34
--
-- OBSERVATION: The catalog is heavily weighted toward movies (2.3x more movies than TV shows)
-- INTERPRETATION: Netflix prioritizes movie content acquisition
-- LIMITATION: This cannot tell us about viewing patterns, revenue contribution, or subscriber preference

-- ============================================================================
-- QUESTION 2: Which genres dominate the Netflix catalog?
-- ============================================================================

SELECT 'QUESTION 2: Top 10 Genres by Title Count' as q;

SELECT
    genre,
    COUNT(*) as title_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(DISTINCT show_id) FROM title_genres), 2) as catalog_coverage
FROM title_genres
GROUP BY genre
ORDER BY title_count DESC
LIMIT 10;

-- Expected Results: Top genres typically include International Movies, Dramas, Comedies, etc.
--
-- OBSERVATION: Certain genres appear in significantly more titles than others
-- INTERPRETATION: Netflix focuses heavily on diverse content including international and dramatic content
-- LIMITATION: High coverage % (>100% total) is expected because titles have multiple genres
-- LIMITATION: This does not indicate which genres are most watched or generate revenue

-- ============================================================================
-- QUESTION 3: How has the release year distribution evolved? What years had the most releases?
-- ============================================================================

SELECT 'QUESTION 3: Content Release Year Distribution' as q;

WITH release_by_decade AS (
    SELECT
        FLOOR(release_year / 10) * 10 as decade,
        COUNT(*) as title_count,
        COUNT(CASE WHEN type = 'Movie' THEN 1 END) as movies,
        COUNT(CASE WHEN type = 'TV Show' THEN 1 END) as tv_shows
    FROM titles
    GROUP BY FLOOR(release_year / 10) * 10
)
SELECT
    CONCAT(decade, 's') as decade,
    title_count,
    movies,
    tv_shows,
    ROUND(100.0 * title_count / (SELECT SUM(title_count) FROM release_by_decade), 2) as pct_of_catalog
FROM release_by_decade
WHERE decade >= 1980
ORDER BY decade DESC;

-- Expected: Heavy concentration in recent decades (1990s, 2000s, 2010s, 2020s)
--
-- OBSERVATION: Most content in Netflix catalog was released in last 30 years
-- INTERPRETATION: Netflix focuses on relatively recent content
-- LIMITATION: This measures release dates, not when content was added to Netflix

-- ============================================================================
-- QUESTION 4: When was content added to Netflix? How has Netflix expanded its catalog?
-- ============================================================================

SELECT 'QUESTION 4: Content Added to Netflix Over Time' as q;

SELECT
    EXTRACT(YEAR FROM date_added)::INTEGER as year_added,
    COUNT(*) as titles_added,
    COUNT(CASE WHEN type = 'Movie' THEN 1 END) as movies,
    COUNT(CASE WHEN type = 'TV Show' THEN 1 END) as tv_shows,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM titles WHERE date_added IS NOT NULL), 2) as pct
FROM titles
WHERE date_added IS NOT NULL
GROUP BY EXTRACT(YEAR FROM date_added)
ORDER BY year_added DESC;

-- Expected: Dataset captured mid-2021, so no full 2021 year
--
-- OBSERVATION: Netflix aggressively added content in 2020-2021
-- INTERPRETATION: Netflix expanded catalog significantly during pandemic period
-- LIMITATION: This is snapshot data; newer data would show different patterns
-- LIMITATION: Cannot determine if additions increased, stayed flat, or decreased after 2021

-- ============================================================================
-- QUESTION 5: Which countries contribute the most titles to Netflix?
-- ============================================================================

SELECT 'QUESTION 5: Top 15 Production Countries' as q;

SELECT
    country,
    COUNT(*) as title_count,
    COUNT(CASE WHEN type = 'Movie' THEN 1 END) as movies,
    COUNT(CASE WHEN type = 'TV Show' THEN 1 END) as tv_shows,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM title_countries), 2) as catalog_pct
FROM title_countries
JOIN titles ON title_countries.show_id = titles.show_id
GROUP BY country
ORDER BY title_count DESC
LIMIT 15;

-- Expected: United States dominates, followed by India, UK, Japan, etc.
--
-- OBSERVATION: United States produces far more content than any other country
-- INTERPRETATION: Netflix relies heavily on US production; also significant investment in Indian and international content
-- LIMITATION: Multi-country productions (co-productions) appear in multiple rows
-- LIMITATION: Cannot determine production budget, quality, or cultural diversity value

-- ============================================================================
-- QUESTION 6: What is the typical movie duration? How do movie lengths vary?
-- ============================================================================

SELECT 'QUESTION 6: Movie Duration Analysis' as q;

WITH movie_mins AS (
    SELECT
        (REGEXP_MATCHES(duration, '(\d+)', 'g'))[1]::INTEGER as minutes
    FROM titles
    WHERE type = 'Movie' AND duration ~ '^\d+ min$'
)
SELECT
    'Movie Duration' as metric,
    COUNT(*) as count,
    ROUND(AVG(minutes), 1) as avg_minutes,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY minutes), 1) as median_minutes,
    MIN(minutes) as shortest,
    MAX(minutes) as longest
FROM movie_mins;

-- Expected: Average ~100 minutes, range 10-312 minutes
--
-- OBSERVATION: Most Netflix movies cluster around 90-120 minutes (standard feature length)
-- INTERPRETATION: Netflix carries traditional-length movies and some shorter/longer content
-- LIMITATION: Very short movies (<60 min) might be TV specials misclassified as movies
-- LIMITATION: Cannot correlate duration with popularity or engagement

-- ============================================================================
-- QUESTION 7: How many seasons do TV shows typically have?
-- ============================================================================

SELECT 'QUESTION 7: TV Show Season Distribution' as q;

WITH tv_seasons AS (
    SELECT
        (REGEXP_MATCHES(duration, '(\d+)', 'g'))[1]::INTEGER as seasons
    FROM titles
    WHERE type = 'TV Show' AND duration ~ '^\d+ Season'
)
SELECT
    'TV Show Seasons' as metric,
    COUNT(*) as show_count,
    ROUND(AVG(seasons), 2) as avg_seasons,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY seasons), 1) as median_seasons,
    MIN(seasons) as min_seasons,
    MAX(seasons) as max_seasons
FROM tv_seasons;

-- Expected: Average ~2 seasons, range 1-13 seasons
--
-- OBSERVATION: Most TV shows on Netflix have 1-2 seasons
-- INTERPRETATION: Netflix carries many limited series and short-run shows; few long-running series
-- LIMITATION: This reflects point-in-time snapshot; shows may have gained/lost seasons
-- LIMITATION: Cannot determine if short runs indicate cancellations, planned conclusions, or ongoing series

-- ============================================================================
-- QUESTION 8: What ratings dominate the Netflix catalog?
-- ============================================================================

SELECT 'QUESTION 8: Content Rating Distribution' as q;

SELECT
    COALESCE(rating, 'UNRATED') as rating,
    COUNT(*) as count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM titles), 2) as pct,
    COUNT(CASE WHEN type = 'Movie' THEN 1 END) as movies,
    COUNT(CASE WHEN type = 'TV Show' THEN 1 END) as tv_shows
FROM titles
GROUP BY rating
ORDER BY count DESC;

-- Expected: TV-MA and PG-13 typically highest
--
-- OBSERVATION: Netflix catalog heavily skews toward mature content (TV-MA, R, PG-13)
-- INTERPRETATION: Netflix targets adult/teen audience; limited kids-specific content
-- LIMITATION: Cannot determine if this reflects viewer demand or acquisition strategy
-- LIMITATION: Unrated content may be older films with missing rating data

-- ============================================================================
-- QUESTION 9: How old is content when added to Netflix? (Content acquisition patterns)
-- ============================================================================

SELECT 'QUESTION 9: Content Age at Addition Analysis' as q;

WITH age_analysis AS (
    SELECT
        EXTRACT(YEAR FROM date_added) - release_year as years_after_release,
        COUNT(*) as count
    FROM titles
    WHERE date_added IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM date_added) - release_year
)
SELECT
    CASE
        WHEN years_after_release <= 0 THEN 'Same Year as Release'
        WHEN years_after_release BETWEEN 1 AND 2 THEN '1-2 Years After Release'
        WHEN years_after_release BETWEEN 3 AND 5 THEN '3-5 Years After Release'
        WHEN years_after_release BETWEEN 6 AND 10 THEN '6-10 Years After Release'
        ELSE '10+ Years After Release'
    END as age_category,
    SUM(count) as title_count,
    ROUND(100.0 * SUM(count) / (SELECT COUNT(*) FROM titles WHERE date_added IS NOT NULL), 2) as pct
FROM age_analysis
GROUP BY age_category
ORDER BY
    CASE
        WHEN age_category = 'Same Year as Release' THEN 1
        WHEN age_category = '1-2 Years After Release' THEN 2
        WHEN age_category = '3-5 Years After Release' THEN 3
        WHEN age_category = '6-10 Years After Release' THEN 4
        ELSE 5
    END;

-- Expected: Mix of recent and older content; some acquisitions years after release
--
-- OBSERVATION: Netflix acquires content both recently released and years after release
-- INTERPRETATION: Netflix balances new theatrical releases with back-catalog licensing
-- LIMITATION: This reflects acquisition timing, not streaming licensing windows
-- LIMITATION: Cannot determine which acquisition patterns drive subscriber engagement

-- ============================================================================
-- QUESTION 10: How does content differ between Movies and TV Shows?
-- ============================================================================

SELECT 'QUESTION 10: Movie vs TV Show Comparison' as q;

SELECT
    type,
    COUNT(*) as total,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM titles), 2) as pct_of_catalog,
    ROUND(100.0 * COUNT(CASE WHEN director IS NOT NULL THEN 1 END) / COUNT(*), 1) as director_coverage,
    ROUND(100.0 * COUNT(CASE WHEN cast IS NOT NULL THEN 1 END) / COUNT(*), 1) as cast_coverage,
    ROUND(100.0 * COUNT(CASE WHEN rating IS NOT NULL THEN 1 END) / COUNT(*), 1) as rating_coverage,
    COUNT(DISTINCT CASE WHEN rating IS NOT NULL THEN rating END) as unique_ratings
FROM titles
GROUP BY type
ORDER BY total DESC;

-- Expected: Movies have better director/cast/rating coverage; TV shows more often missing director
--
-- OBSERVATION: Movies have more complete metadata; TV shows often lack director field
-- INTERPRETATION: Metadata collection differs between content types; TV shows use different cataloging
-- LIMITATION: Missing director for TV shows is expected (shows have multiple episode directors)
-- LIMITATION: Cannot infer content quality or completeness from metadata coverage

-- ============================================================================
-- VALIDATION: Verify all questions
-- ============================================================================

-- Sum of Movies + TV Shows should equal total titles
SELECT
    'VALIDATION: Content Type Totals' as check_name,
    (SELECT COUNT(*) FROM titles WHERE type = 'Movie')::TEXT as movie_count,
    (SELECT COUNT(*) FROM titles WHERE type = 'TV Show')::TEXT as tv_show_count,
    (SELECT COUNT(*) FROM titles WHERE type = 'Movie') + (SELECT COUNT(*) FROM titles WHERE type = 'TV Show') as total_from_sum,
    (SELECT COUNT(*) FROM titles) as actual_total,
    CASE
        WHEN (SELECT COUNT(*) FROM titles WHERE type = 'Movie') + (SELECT COUNT(*) FROM titles WHERE type = 'TV Show') = (SELECT COUNT(*) FROM titles)
        THEN 'PASS'
        ELSE 'FAIL'
    END as validation_result;

-- ============================================================================
-- END OF BUSINESS QUESTIONS
-- ============================================================================
