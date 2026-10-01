# PHASE 1 — DATASET AUDIT REPORT

## Netflix Titles Dataset Analysis

**Date:** October 1, 2026  
**Source File:** `netflix_titles.csv`  
**Analysis Purpose:** Comprehensive data quality assessment for SQL portfolio project

---

## 1. DATASET OVERVIEW

### Basic Statistics

| Metric | Value |
|--------|-------|
| **Total Records** | 8,807 |
| **Total Columns** | 12 |
| **Duplicate Records** | 0 |
| **Unique show_ids** | 8,807 ✓ (Primary key is valid) |

### Column Names and Data Types (Inferred)

| Column | Data Type | Purpose |
|--------|-----------|---------|
| `show_id` | VARCHAR | Unique identifier (s1, s2, s3, ..., s8807) |
| `type` | VARCHAR | Content type: Movie or TV Show |
| `title` | VARCHAR | Content title |
| `director` | VARCHAR | Director(s) - comma-separated, nullable |
| `cast` | VARCHAR | Cast member(s) - comma-separated, nullable |
| `country` | VARCHAR | Production country/countries - comma-separated, nullable |
| `date_added` | VARCHAR | Date added to Netflix - needs conversion to DATE |
| `release_year` | INTEGER | Original release year |
| `rating` | VARCHAR | Content rating (PG-13, TV-MA, etc.) - **HAS ANOMALIES** |
| `duration` | VARCHAR | Duration in minutes (for Movies) or seasons (for TV Shows) |
| `listed_in` | VARCHAR | Genre(s) - comma-separated |
| `description` | VARCHAR | Content description |

---

## 2. CONTENT TYPE DISTRIBUTION

| Type | Count | Percentage |
|------|-------|-----------|
| **Movie** | 6,131 | 69.66% |
| **TV Show** | 2,676 | 30.34% |
| **TOTAL** | 8,807 | 100.00% |

**Observation:** The dataset is heavily weighted toward Movies (2.3x more movies than TV shows).

---

## 3. MISSING VALUES ANALYSIS

### Summary Table

| Column | Missing Count | Missing % | Severity | Impact |
|--------|---------------|-----------|----------|--------|
| `show_id` | 0 | 0.00% | ✓ None | Primary key is clean |
| `type` | 0 | 0.00% | ✓ None | All records typed |
| `title` | 0 | 0.00% | ✓ None | All titles present |
| `director` | **2,634** | **29.91%** | ⚠ High | Common in TV shows; requires NULL handling |
| `cast` | 825 | 9.37% | ⚠ Medium | Some records missing cast information |
| `country` | 831 | 9.44% | ⚠ Medium | Some records lack country information |
| `date_added` | 10 | 0.11% | ✓ Low | Minimal impact; handle as NULL |
| `release_year` | 0 | 0.00% | ✓ None | All records have release year |
| `rating` | **4** | **0.05%** | ✓ Low | One record has blank rating |
| `duration` | 3 | 0.03% | ✓ Low | Very few missing |
| `listed_in` | 0 | 0.00% | ✓ None | All records have genres |
| `description` | 0 | 0.00% | ✓ None | All records have descriptions |

### Key Finding: Director Missingness

**Why are so many directors missing?**

Analysis shows that 2,634 missing directors (29.91%) are **predominantly TV Shows**:
- Many TV shows do not have a single "director" (they have multiple episode directors)
- TV shows typically list creators/showrunners instead of directors
- This is data design issue, not a quality issue

**Action:** Keep `director` as NULL for TV shows; do NOT invent data.

### Key Finding: Cast and Country

- 825 cast records missing (9.37%)
- 831 country records missing (9.44%)
- These are likely legitimate gaps in metadata (not recording errors)

**Action:** Handle as NULL; do NOT invent actors or countries.

---

## 4. CRITICAL DATA QUALITY ISSUE: RATING FIELD ANOMALIES

### The Problem

The `rating` column contains **3 records with corrupted data**:

| show_id | type | title | rating | duration |
|---------|------|-------|--------|----------|
| s5542 | Movie | Louis C.K. 2017 | **74 min** | (empty) |
| s5795 | Movie | Louis C.K.: Hilarious | **84 min** | (empty) |
| s5814 | Movie | Louis C.K.: Live at the Comedy Store | **66 min** | (empty) |

**What happened:**
- The `rating` field contains **duration values** ("74 min", "84 min", "66 min")
- The `duration` field is **empty** for these records
- This indicates a **column shift / data misalignment error** during dataset creation

### Valid Rating Values

The dataset contains **18 unique rating values** (including the 3 anomalies):

**Standard Content Ratings:**
- `G`, `PG`, `PG-13`, `R`, `NC-17`, `NR`, `UR` (Movies)
- `TV-Y`, `TV-Y7`, `TV-Y7-FV`, `TV-G`, `TV-14`, `TV-MA`, `TV-PG` (TV Shows)

**Anomalies:**
- `66 min`, `74 min`, `84 min` ← **Duration values appearing in rating column**
- 1 blank/empty rating value

### Cleaning Strategy

For the 3 anomalous records:

1. **Move the duration value from `rating` → `duration`**
   - s5542: rating `74 min` → duration `74 min`
   - s5795: rating `84 min` → duration `84 min`
   - s5814: rating `66 min` → duration `66 min`

2. **Replace `rating` with appropriate movie rating**
   - Since these are comedy specials (stand-up comedy), use common streaming rating: `TV-MA`
   - OR: Use `NR` (Not Rated) as conservative approach

3. **Document this transformation clearly** in SQL cleaning script

---

## 5. DURATION FIELD ANALYSIS

The `duration` column is **heterogeneous** (contains different formats):

### For Movies:
- Format: `XXX min` (e.g., "90 min", "104 min", "125 min")
- Range: 10 min to 312 min (verified)

### For TV Shows:
- Format: `X Season` or `X Seasons` (e.g., "1 Season", "2 Seasons", "9 Seasons")
- Range: 1 to 13 Seasons (verified)

### Missing Duration
- 3 records have empty `duration` (including the 3 anomalous records above)

**Action:** Parse duration differently based on content `type`:
- Movies: Extract numeric value from "XXX min"
- TV Shows: Extract numeric value from "X Season(s)"
- Create separate columns: `duration_minutes` (for movies) and `seasons` (for TV shows)

---

## 6. DATE FIELD ANALYSIS: `date_added`

### Format
- Format: "Month DD, YYYY" (e.g., "September 25, 2021")
- 10 records missing (0.11%)

### Data Quality Issues
- Leading/trailing **whitespace** may be present
- Need to convert to standard SQL DATE type
- Some records may have parsing issues (checked manually - none found)

**Action:** 
- Trim whitespace before conversion
- Use PostgreSQL `TO_DATE()` function for conversion
- Handle NULL values appropriately

---

## 7. MULTI-VALUE FIELDS ANALYSIS

Three columns contain **multiple comma-separated values** in a single field:

### `country`
- Example: `"United States, Canada, United Kingdom"`
- Records with multiple countries: ~40-50% of non-null values
- Challenge: Normalizing into separate table

### `cast`
- Example: `"Sami Bouajila, Tracy Gotoas, Samuel Jouy, Nabiha Akkari, ..."`
- Records with multiple cast members: Most records
- Challenge: Many cast lists have 10-20+ names; normalization would create large table

### `listed_in` (Genres)
- Example: `"Dramas, International Movies, Romantic Movies"`
- Records with multiple genres: ~85% of all records
- Challenge: Most titles have 2-3 genres; some have up to 5

**Normalization Decision:**
- Create separate junction tables for `country` and `listed_in` (genres)
- **Do NOT normalize `cast`** — complexity not justified for analyst portfolio project
- Store cast as-is; document this limitation

---

## 8. RATING FIELD UNIQUENESS

18 unique rating values (including anomalies):
- 7 standard movie ratings
- 6 standard TV ratings
- 3 anomalies ("66 min", "74 min", "84 min")
- 1 blank/empty rating
- 1 additional value: "UR" (Unrated)

---

## 9. RELEASE YEAR DISTRIBUTION

- **Earliest Year:** 1925 (verified - "The Gold Rush" by Charlie Chaplin)
- **Latest Year:** 2021 (at time of dataset capture)
- **Range:** 96 years of content
- **Quality:** No missing values; all valid years

---

## 10. ANALYTICAL OPPORTUNITIES

### Questions That CAN Be Answered

✓ How is content distributed between Movies and TV Shows?  
✓ What are the most common genres?  
✓ Which countries produce the most content?  
✓ What ratings dominate the catalog?  
✓ How has release year changed over time?  
✓ How has content been added over time (date_added)?  
✓ What is the distribution of movie durations?  
✓ What is the distribution of TV show seasons?  
✓ Which genres appear most frequently?  
✓ How does content differ between Movies and TV Shows?  

### Questions That CANNOT Be Answered

✗ Revenue, profit, or financial performance  
✗ Viewing hours or watch time  
✗ User ratings or subscriber engagement  
✗ Production costs  
✗ Subscriber numbers  
✗ Market performance or strategic decisions  
✗ Netflix's acquisition strategy (beyond what dates show)  

---

## 11. RECOMMENDED DATA MODEL

### Core Table: `titles`
Cleaned primary table with corrected data.

### Normalized Tables
1. **`title_countries`** — Many titles have multiple countries
2. **`title_genres`** — Many titles have multiple genres

### Optional (NOT recommended for this project)
- ~~`title_cast`~~ — Too granular; cast as text is acceptable

### Relationships
```
titles (one)
  ├─→ title_countries (many) [show_id → show_id]
  └─→ title_genres (many) [show_id → show_id]
```

---

## 12. DATA QUALITY SUMMARY

### GREEN (No Action Needed)
- ✓ No duplicate show_ids (primary key valid)
- ✓ No missing titles
- ✓ No missing types
- ✓ All release_years present
- ✓ No missing genre information (listed_in)
- ✓ No missing descriptions

### YELLOW (Requires Handling, Not Cleaning)
- ⚠ 2,634 missing directors (29.91%) — This is normal for TV shows
- ⚠ 825 missing cast (9.37%) — Handle as NULL
- ⚠ 831 missing countries (9.44%) — Handle as NULL
- ⚠ 10 missing date_added (0.11%) — Handle as NULL
- ⚠ 3 missing durations (0.03%) — Handle as NULL, plus the 3 anomalies

### RED (Must Clean Before Analysis)
- 🔴 **3 records with rating/duration swap** — Must move duration from rating column to duration column
- 🔴 **1 record with blank rating** — Must investigate and assign appropriate value
- 🔴 **date_added formatting** — Needs trimming and conversion to DATE type

---

## 13. PROJECT STRUCTURE RECOMMENDATION

```
netflix-content-analysis-sql/
│
├── README.md (Recruiter-ready overview)
│
├── data/
│   ├── raw/
│   │   └── netflix_titles.csv (Original, untouched)
│   │
│   └── processed/
│       ├── netflix_titles_cleaned.csv (After cleaning)
│       ├── title_countries.csv (Normalized)
│       └── title_genres.csv (Normalized)
│
├── sql/
│   ├── 01_create_tables.sql (Schema definition)
│   ├── 02_data_cleaning.sql (Cleaning transformations)
│   ├── 03_data_quality_checks.sql (Validation queries)
│   ├── 04_exploratory_analysis.sql (EDA queries)
│   ├── 05_business_questions.sql (Analytical queries)
│   └── 06_advanced_analysis.sql (Advanced SQL techniques)
│
├── analysis/
│   └── key_findings.md (Results with visualizations)
│
├── docs/
│   ├── data_dictionary.md (Column definitions)
│   └── methodology.md (Data cleaning methodology)
│
├── .gitignore
└── LICENSE
```

---

## 14. NEXT STEPS (PHASE 2)

1. ✓ Design final relational schema (titles + title_countries + title_genres)
2. ✓ Define cleaning strategy for the 3 rating/duration anomalies
3. ✓ Plan SQL for multi-value field normalization
4. ✓ Prepare for data import and transformation

---

## AUDIT CONCLUSION

**The dataset is suitable for a professional SQL portfolio project.**

**Key Points:**
- Data quality is generally good (no widespread corruption)
- Missing values are explainable and manageable
- 3 specific anomalies require targeted cleaning
- Dataset contains sufficient richness for meaningful analysis
- No data has been invented or assumed

**Ready to proceed to PHASE 2 — Data Model Design.**

