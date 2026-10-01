-- PHASE 6: ADVANCED ANALYSIS
-- Netflix Content Analytics - Advanced SQL Techniques
--
-- This script demonstrates intermediate and advanced SQL techniques:
-- - CTEs (Common Table Expressions)
-- - Window Functions (ROW_NUMBER, RANK, DENSE_RANK)
-- - CASE statements
-- - Subqueries
-- - Multiple JOINs
-- - HAVING clauses
-- - Date functions

-- ============================================================================
-- Q1: Rank Genres by Frequency with Row Number
-- ============================================================================

SELECT 'Q1: Genre Ranking with Window Functions' as question;

WITH genre_counts AS (
    SELECT
        genre,
        COUNT(*) as title_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) as rank_rn,
        RANK() OVER (ORDER BY COUNT(*) DESC) as rank_rank,
        DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) as rank_dense
    FROM title_genres
    GROUP BY genre
)
SELECT
    rank_rn,
    genre,
    title_count
FROM genre_counts
WHERE rank_rn <= 20
ORDER BY rank_rn;

-- ============================================================================
-- Q2: Top Movies and TV Shows by Release Year with Ranking
-- ============================================================================

SELECT 'Q2: Top Content by Release Year (Last 10 Years)' as question;

WITH content_by_year AS (
    SELECT
        release_year,
        type,
        COUNT(*) as count,
        ROW_NUMBER() OVER (PARTITION BY release_year ORDER BY COUNT(*) DESC) as rank_in_year
    FROM titles
    WHERE release_year >= 2011
    GROUP BY release_year, type
)
SELECT
    release_year,
    type,
    count
FROM content_by_year
WHERE rank_in_year = 1
ORDER BY release_year DESC;

-- ============================================================================
-- Q3: Content Addition Trends Over Time with YoY Growth
-- ============================================================================

SELECT 'Q3: Year-over-Year Addition Trends' as question;

WITH yearly_additions AS (
    SELECT
        EXTRACT(YEAR FROM date_added)::INTEGER as year_added,
        COUNT(*) as titles_added,
        LAG(COUNT(*)) OVER (ORDER BY EXTRACT(YEAR FROM date_added)) as prev_year_count
    FROM titles
    WHERE date_added IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM date_added)
)
SELECT
    year_added,
    titles_added,
    prev_year_count,
    CASE
        WHEN prev_year_count IS NOT NULL
        THEN ROUND(100.0 * (titles_added - prev_year_count) / prev_year_count, 2)
        ELSE NULL
    END as yoy_growth_percent
FROM yearly_additions
ORDER BY year_added DESC;

-- ============================================================================
-- Q4: Genres with Highest Growth in Recent Years (2019-2021)
-- ============================================================================

SELECT 'Q4: Genre Growth Analysis (2019-2021)' as question;

WITH genre_by_year AS (
    SELECT
        EXTRACT(YEAR FROM t.date_added)::INTEGER as year_added,
        tg.genre,
        COUNT(*) as count
    FROM titles t
    JOIN title_genres tg ON t.show_id = tg.show_id
    WHERE EXTRACT(YEAR FROM t.date_added) IN (2019, 2020, 2021)
    GROUP BY EXTRACT(YEAR FROM t.date_added), tg.genre
),
genre_pivot AS (
    SELECT
        genre,
        SUM(CASE WHEN year_added = 2019 THEN count ELSE 0 END) as y2019,
        SUM(CASE WHEN year_added = 2020 THEN count ELSE 0 END) as y2020,
        SUM(CASE WHEN year_added = 2021 THEN count ELSE 0 END) as y2021
    FROM genre_by_year
    GROUP BY genre
)
SELECT
    genre,
    y2019,
    y2020,
    y2021,
    ROUND(100.0 * (y2021 - y2019) / y2019, 2) as pct_change_2019_to_2021
FROM genre_pivot
WHERE y2019 > 0 AND y2020 > 0 AND y2021 > 0
ORDER BY pct_change_2019_to_2021 DESC
LIMIT 15;

-- ============================================================================
-- Q5: Content Added vs Released - How Fresh is the Catalog?
-- ============================================================================

SELECT 'Q5: Content Recency Analysis' as question;

WITH recency_analysis AS (
    SELECT
        EXTRACT(YEAR FROM date_added) - release_year as years_after_release,
        COUNT(*) as title_count,
        SUM(CASE WHEN type = 'Movie' THEN 1 ELSE 0 END) as movies,
        SUM(CASE WHEN type = 'TV Show' THEN 1 ELSE 0 END) as tv_shows
    FROM titles
    WHERE date_added IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM date_added) - release_year
)
SELECT
    CASE
        WHEN years_after_release <= 0 THEN 'Same Year'
        WHEN years_after_release = 1 THEN '1 Year After'
        WHEN years_after_release BETWEEN 2 AND 5 THEN '2-5 Years After'
        WHEN years_after_release BETWEEN 6 AND 10 THEN '6-10 Years After'
        ELSE '10+ Years After'
    END as recency_category,
    SUM(title_count) as total_titles,
    SUM(movies) as total_movies,
    SUM(tv_shows) as total_tv_shows,
    ROUND(100.0 * SUM(title_count) / (SELECT COUNT(*) FROM titles WHERE date_added IS NOT NULL), 2) as percentage
FROM recency_analysis
GROUP BY recency_category
ORDER BY
    CASE
        WHEN recency_category = 'Same Year' THEN 1
        WHEN recency_category = '1 Year After' THEN 2
        WHEN recency_category = '2-5 Years After' THEN 3
        WHEN recency_category = '6-10 Years After' THEN 4
        ELSE 5
    END;

-- ============================================================================
-- Q6: Countries Contributing Most Content - with Movie/TV Mix
-- ============================================================================

SELECT 'Q6: Top 15 Countries - Content Mix Analysis' as question;

WITH country_content AS (
    SELECT
        tc.country,
        t.type,
        COUNT(*) as count,
        ROW_NUMBER() OVER (PARTITION BY tc.country ORDER BY COUNT(*) DESC) as rank_in_country
    FROM title_countries tc
    JOIN titles t ON tc.show_id = t.show_id
    GROUP BY tc.country, t.type
),
country_totals AS (
    SELECT
        country,
        SUM(count) as total_count,
        SUM(CASE WHEN type = 'Movie' THEN count ELSE 0 END) as movies,
        SUM(CASE WHEN type = 'TV Show' THEN count ELSE 0 END) as tv_shows
    FROM country_content
    GROUP BY country
)
SELECT
    country,
    total_count,
    movies,
    tv_shows,
    ROUND(100.0 * movies / total_count, 1) as movie_percentage,
    ROUND(100.0 * tv_shows / total_count, 1) as tv_show_percentage
FROM country_totals
ORDER BY total_count DESC
LIMIT 15;

-- ============================================================================
-- Q7: Prolific Directors - Directors with Most Titles
-- ============================================================================

SELECT 'Q7: Most Prolific Directors' as question;

WITH director_list AS (
    SELECT
        TRIM(director_name) as director,
        COUNT(*) as title_count,
        COUNT(DISTINCT type) as type_variety,
        STRING_AGG(DISTINCT type, ', ') as types,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) as rank
    FROM (
        SELECT
            TRIM(UNNEST(STRING_TO_ARRAY(director, ','))) as director_name,
            type
        FROM titles
        WHERE director IS NOT NULL
    ) x
    GROUP BY TRIM(director_name)
    HAVING COUNT(*) >= 3
)
SELECT
    rank,
    director,
    title_count,
    types
FROM director_list
WHERE rank <= 20
ORDER BY rank;

-- ============================================================================
-- Q8: Movies Duration Segments - How Long are Netflix Movies?
-- ============================================================================

SELECT 'Q8: Movie Duration Segments' as question;

WITH movie_durations AS (
    SELECT
        (REGEXP_MATCHES(duration, '(\d+)', 'g'))[1]::INTEGER as duration_minutes
    FROM titles
    WHERE type = 'Movie' AND duration ~ '^\d+ min$'
)
SELECT
    CASE
        WHEN duration_minutes < 60 THEN 'Short (< 60 min)'
        WHEN duration_minutes BETWEEN 60 AND 90 THEN 'Standard (60-90 min)'
        WHEN duration_minutes BETWEEN 91 AND 120 THEN 'Long (91-120 min)'
        WHEN duration_minutes BETWEEN 121 AND 150 THEN 'Extended (121-150 min)'
        ELSE 'Epic (150+ min)'
    END as duration_category,
    COUNT(*) as movie_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM movie_durations), 2) as percentage,
    ROUND(AVG(duration_minutes), 1) as avg_duration,
    MIN(duration_minutes) as min_duration,
    MAX(duration_minutes) as max_duration
FROM movie_durations
GROUP BY duration_category
ORDER BY
    CASE
        WHEN duration_category = 'Short (< 60 min)' THEN 1
        WHEN duration_category = 'Standard (60-90 min)' THEN 2
        WHEN duration_category = 'Long (91-120 min)' THEN 3
        WHEN duration_category = 'Extended (121-150 min)' THEN 4
        ELSE 5
    END;

-- ============================================================================
-- Q9: TV Shows - Season Distribution with Percentiles
-- ============================================================================

SELECT 'Q9: TV Show Season Distribution Analysis' as question;

WITH tv_seasons AS (
    SELECT
        (REGEXP_MATCHES(duration, '(\d+)', 'g'))[1]::INTEGER as season_count
    FROM titles
    WHERE type = 'TV Show' AND duration ~ '^\d+ Season'
)
SELECT
    'TV Show Seasons' as metric,
    COUNT(*) as show_count,
    ROUND(AVG(season_count), 2) as avg_seasons,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY season_count) as q1_seasons,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY season_count) as median_seasons,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY season_count) as q3_seasons,
    MIN(season_count) as min_seasons,
    MAX(season_count) as max_seasons
FROM tv_seasons;

-- ============================================================================
-- Q10: Rating Distribution Comparison - Movies vs TV Shows
-- ============================================================================

SELECT 'Q10: Rating Distribution by Content Type' as question;

WITH rating_dist AS (
    SELECT
        type,
        COALESCE(rating, 'UNRATED') as rating,
        COUNT(*) as count,
        SUM(COUNT(*)) OVER (PARTITION BY type) as type_total
    FROM titles
    GROUP BY type, rating
)
SELECT
    type,
    rating,
    count,
    ROUND(100.0 * count / type_total, 2) as percentage_of_type
FROM rating_dist
ORDER BY type, count DESC;

-- ============================================================================
-- Q11: Multi-Genre Titles - How Many Genres per Title?
-- ============================================================================

SELECT 'Q11: Genre Count Distribution' as question;

WITH genre_counts_per_title AS (
    SELECT
        t.show_id,
        COUNT(*) as genre_count
    FROM title_genres tg
    JOIN titles t ON tg.show_id = t.show_id
    GROUP BY t.show_id
)
SELECT
    CASE
        WHEN genre_count = 1 THEN 'Single Genre'
        WHEN genre_count = 2 THEN 'Two Genres'
        WHEN genre_count = 3 THEN 'Three Genres'
        ELSE '4+ Genres'
    END as genre_category,
    COUNT(*) as title_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM genre_counts_per_title), 2) as percentage
FROM genre_counts_per_title
GROUP BY genre_category
ORDER BY
    CASE
        WHEN genre_category = 'Single Genre' THEN 1
        WHEN genre_category = 'Two Genres' THEN 2
        WHEN genre_category = 'Three Genres' THEN 3
        ELSE 4
    END;

-- ============================================================================
-- Q12: Most Common Genre Pairs (Top 15)
-- ============================================================================

SELECT 'Q12: Most Common Genre Combinations' as question;

SELECT
    tg1.genre as genre_1,
    tg2.genre as genre_2,
    COUNT(*) as co_occurrences,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(DISTINCT show_id) FROM title_genres), 2) as coverage_percent
FROM title_genres tg1
JOIN title_genres tg2 ON tg1.show_id = tg2.show_id AND tg1.genre_id < tg2.genre_id
GROUP BY tg1.genre, tg2.genre
ORDER BY co_occurrences DESC
LIMIT 15;

-- ============================================================================
-- Q13: Content Released Each Decade
-- ============================================================================

SELECT 'Q13: Content Distribution by Decade' as question;

WITH decade_content AS (
    SELECT
        (FLOOR(release_year / 10) * 10)::INTEGER as decade,
        COUNT(*) as title_count,
        COUNT(CASE WHEN type = 'Movie' THEN 1 END) as movies,
        COUNT(CASE WHEN type = 'TV Show' THEN 1 END) as tv_shows
    FROM titles
    GROUP BY decade
)
SELECT
    CONCAT(decade, 's') as decade,
    title_count,
    movies,
    tv_shows,
    ROUND(100.0 * title_count / (SELECT SUM(title_count) FROM decade_content), 2) as percentage
FROM decade_content
WHERE decade >= 1920
ORDER BY decade DESC;

-- ============================================================================
-- ADVANCED ANALYSIS COMPLETE
-- ============================================================================
