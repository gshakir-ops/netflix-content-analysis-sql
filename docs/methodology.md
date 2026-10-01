# Data Cleaning Methodology
# Netflix Content Analytics - Detailed Documentation of Cleaning Process

## Overview

This document describes the systematic approach to cleaning and transforming the raw Netflix titles dataset into analysis-ready tables.

## Raw Data Source

**File:** `netflix_titles.csv`
**Records:** 8,807 titles
**Columns:** 12 fields
**Status:** Original file preserved untouched in `data/raw/`

## Data Quality Audit Results

### Pre-Cleaning Issues Identified

1. **Rating/Duration Anomalies (3 records)**
   - Duration values appeared in rating field instead of duration field
   - Records: s5542, s5795, s5814
   - Values: "74 min", "84 min", "66 min" in rating field; empty duration field

2. **Whitespace Contamination**
   - Leading/trailing whitespace in text fields
   - Particularly problematic in date_added, director, cast, country, genre fields

3. **Date Format Inconsistency**
   - Raw format: "Month DD, YYYY" (e.g., "September 25, 2021")
   - Needs conversion to SQL DATE type

4. **Multi-Value Fields**
   - Country: Comma-separated (e.g., "United States, Canada")
   - Genre (listed_in): Comma-separated (e.g., "Dramas, Comedies")
   - Cast: Comma-separated (not normalized for portfolio scope)
   - Director: Comma-separated in rare cases

5. **Missing Values**
   - Director: 2,634 (29.91%) - normal for TV shows
   - Cast: 825 (9.37%)
   - Country: 831 (9.44%)
   - Date Added: 10 (0.11%)
   - Rating: 4 (0.05%) - including 3 anomalies
   - Duration: 3 (0.03%) - including 3 anomalies

## Cleaning Process

### Step 1: Data Type Standardization

**Input:** Raw CSV (all fields imported as text/VARCHAR)

**Transformations:**
- release_year: VARCHAR → INTEGER
- date_added: VARCHAR("Month DD, YYYY") → DATE
- rating: VARCHAR → VARCHAR (validated for allowed values)
- duration: VARCHAR (validated format by type)

**SQL Implementation:**
```sql
TRIM(raw.release_year)::INTEGER as release_year
TO_DATE(TRIM(raw.date_added), 'Month DD, YYYY') as date_added
```

### Step 2: Whitespace Trimming

**Issue:** Leading/trailing spaces in text fields

**Solution:** Applied TRIM() function to all text fields

**Affected Fields:**
- show_id, type, title, director, cast
- country, date_added, rating, duration, listed_in, description

**SQL Implementation:**
```sql
TRIM(raw.show_id) as show_id
TRIM(raw.director) as director
-- Applied consistently across all text fields
```

### Step 3: NULL Handling

**Philosophy:** Keep genuinely missing values as NULL; do not invent data

**Rules Applied:**
- Empty strings ('') converted to NULL using NULLIF()
- NULLs preserved for director, cast, country (explainable missingness)
- NULLs preserved for date_added (10 records)

**SQL Implementation:**
```sql
NULLIF(TRIM(raw.director), '') as director
CASE 
    WHEN TRIM(raw.date_added) = '' THEN NULL
    ELSE TO_DATE(TRIM(raw.date_added), 'Month DD, YYYY')
END as date_added
```

### Step 4: Fix Rating/Duration Anomalies

**Problem:** Three records had duration values in the rating field

**Records Affected:**
1. s5542 | Movie | "Louis C.K. 2017" | rating='74 min' | duration=''
2. s5795 | Movie | "Louis C.K.: Hilarious" | rating='84 min' | duration=''
3. s5814 | Movie | "Louis C.K.: Live at the Comedy Store" | rating='66 min' | duration=''

**Investigation:** These are stand-up comedy specials; '74 min', '84 min', '66 min' are legitimate durations

**Solution:** 
1. Move duration value from rating field to duration field
2. Assign appropriate rating: 'TV-MA' (standard for comedy specials)

**Before → After:**

| ID | Field | Before | After |
|----|-------|--------|-------|
| s5542 | rating | '74 min' | 'TV-MA' |
| s5542 | duration | '' | '74 min' |
| s5795 | rating | '84 min' | 'TV-MA' |
| s5795 | duration | '' | '84 min' |
| s5814 | rating | '66 min' | 'TV-MA' |
| s5814 | duration | '' | '66 min' |

**SQL Implementation:**
```sql
CASE 
    WHEN TRIM(raw.show_id) = 's5542' THEN 'TV-MA'
    WHEN TRIM(raw.show_id) = 's5795' THEN 'TV-MA'
    WHEN TRIM(raw.show_id) = 's5814' THEN 'TV-MA'
    WHEN TRIM(raw.rating) = '' OR TRIM(raw.rating) IN ('66 min', '74 min', '84 min') THEN NULL
    ELSE TRIM(raw.rating)
END as rating,

CASE 
    WHEN TRIM(raw.show_id) = 's5542' THEN '74 min'
    WHEN TRIM(raw.show_id) = 's5795' THEN '84 min'
    WHEN TRIM(raw.show_id) = 's5814' THEN '66 min'
    ELSE NULLIF(TRIM(raw.duration), '')
END as duration
```

**Audit Trail:** data_quality_flag field documents this fix

### Step 5: Multi-Value Field Normalization

#### 5a. Countries Normalization

**Input:** Comma-separated countries in single field
```
Example: "United States, Canada, United Kingdom"
```

**Process:**
1. Split comma-separated values using STRING_TO_ARRAY()
2. UNNEST to create individual rows
3. Trim each value
4. Insert into title_countries junction table

**SQL Implementation:**
```sql
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
```

**Result:** ~9,380 country entries created from 7,976 titles with country data

#### 5b. Genres Normalization

**Input:** Comma-separated genres in single field
```
Example: "Dramas, International Movies, Comedies"
```

**Process:**
1. Split comma-separated values using STRING_TO_ARRAY()
2. UNNEST to create individual rows
3. Trim each value
4. Insert into title_genres junction table

**SQL Implementation:**
```sql
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
```

**Result:** ~13,160 genre entries created (all 8,807 titles have genres)

#### 5c. Cast (Not Normalized)

**Decision:** Keep cast as comma-separated text in titles table

**Rationale:**
- Portfolio scope: normalization not necessary
- Most titles have 10-20+ cast members (large table)
- Limited analytical value for data analyst portfolio
- Simplicity over complexity

**Handling:** Trimmed but not split

### Step 6: Data Validation & Constraint Application

**Constraints Added:**

1. **Primary Key:**
   - show_id: UNIQUE, NOT NULL
   - No duplicates found (all 8,807 show_ids unique)

2. **NOT NULL Constraints:**
   - type: NOT NULL (100% complete)
   - title: NOT NULL (100% complete)
   - release_year: NOT NULL (100% complete)
   - description: NOT NULL (100% complete)

3. **CHECK Constraints:**
   - type IN ('Movie', 'TV Show') - verified
   - release_year >= 1900 AND release_year <= 2021 - verified

4. **Foreign Keys:**
   - title_countries.show_id → titles.show_id (ON DELETE CASCADE)
   - title_genres.show_id → titles.show_id (ON DELETE CASCADE)
   - No orphan records allowed

5. **Uniqueness Constraints (Junction Tables):**
   - title_countries: UNIQUE(show_id, country) - prevents duplicate country per title
   - title_genres: UNIQUE(show_id, genre) - prevents duplicate genre per title

### Step 7: Audit Trail

**Field Added:** data_quality_flag (TEXT, nullable)

**Purpose:** Documents which records were cleaned and why

**Examples:**
- "FIXED: Duration moved from rating field" (for s5542, s5795, s5814)
- "EXPECTED: TV show without director" (for TV shows missing director)
- "NOTE: Missing director" (for movies missing director)
- NULL (for records with no quality issues)

**Usage:** Enables traceability; helps validate cleaning process

## Cleaning Summary

### Records Processed
- Total records: 8,807
- Records with cleaning applied: 3 (rating/duration swap)
- Records with NULLs preserved: ~4,500+ (normal missing values)
- Records with no changes: ~4,300

### Transformations Applied

| Transformation | Count | Status |
|---|---|---|
| Whitespace trimmed | 8,807 | 100% |
| release_year converted to INTEGER | 8,807 | 100% |
| date_added converted to DATE | 8,797 | 99.9% (10 NULL) |
| rating/duration anomalies fixed | 3 | Fixed |
| Countries normalized | 7,976 | 90.6% |
| Genres normalized | 8,807 | 100% |
| NULLs preserved (not invented) | 4,500+ | Verified |

### Data Quality Checks Performed

✓ No duplicate show_ids  
✓ All required fields NOT NULL (100% of records)  
✓ Type values valid (only 'Movie' or 'TV Show')  
✓ Release year in valid range (1925-2021)  
✓ Date_added successfully converted to DATE  
✓ Rating anomalies fixed  
✓ Duration anomalies fixed  
✓ Multi-value fields normalized  
✓ Referential integrity verified (no orphan records)  
✓ No duplicate country/genre pairs per title  

## Output Tables

### titles (Main Table)
- **Records:** 8,807
- **Fields:** show_id, type, title, director, cast, date_added, release_year, rating, duration, description, data_quality_flag, created_at
- **Indexing:** Primary key on show_id
- **Size:** ~15-20 MB (depends on description field length)

### title_countries (Junction Table)
- **Records:** ~9,380
- **Fields:** country_id (PK), show_id (FK), country
- **Indexing:** PK on country_id, FK on show_id, UNIQUE on (show_id, country)
- **Size:** ~200-300 KB

### title_genres (Junction Table)
- **Records:** ~13,160
- **Fields:** genre_id (PK), show_id (FK), genre
- **Indexing:** PK on genre_id, FK on show_id, UNIQUE on (show_id, genre)
- **Size:** ~300-400 KB

## Reproducibility

All cleaning steps are:
1. **Documented** in this methodology file
2. **Traceable** via data_quality_flag field
3. **Reversible** (original raw data untouched)
4. **Repeatable** via SQL scripts in sql/01_create_tables.sql

To replicate:
```bash
psql netflix_db < sql/01_create_tables.sql
```

## Limitations & Assumptions

### Limitations
- Cannot validate accuracy of director/cast names
- Cannot validate country correctness
- Cannot validate genre assignments
- Genre splitting assumes comma as delimiter (verified in data audit)
- Country splitting assumes comma as delimiter (verified in data audit)

### Assumptions
- "Month DD, YYYY" format is consistent for date_added (verified)
- Whitespace issues are leading/trailing only (not internal)
- Duration format for movies is "XXX min"; for TV shows is "X Season(s)"
- Multi-value fields use comma as delimiter with optional spaces
- TV-MA is appropriate rating for comedy specials (industry standard)

## Quality Assurance

All cleaned data has been validated via:
1. **Count validation:** Total records match source (8,807)
2. **Anomaly verification:** 3 fixes documented and verified
3. **Constraint testing:** All CHECK, UNIQUE, FK constraints pass
4. **Referential integrity:** No orphan records
5. **Sample review:** Manual review of cleaned anomalies

## Next Steps for Analysis

Cleaned data is now ready for:
- Exploratory Data Analysis (EDA)
- Statistical analysis
- Business intelligence queries
- Visualization and reporting

All SQL scripts assume cleaned data is loaded into titles, title_countries, and title_genres tables.

