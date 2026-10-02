# Netflix Content Analysis — PostgreSQL

**PostgreSQL 12+ | Data Cleaning | Relational Modeling | Exploratory Analysis | Advanced SQL**

A portfolio project focused on data quality, relational modeling, descriptive analysis, and analytical SQL on Netflix catalog metadata.

---

## Project Overview

This project analyzes a dataset of 8,807 Netflix titles (movies and TV shows) using PostgreSQL. The analysis demonstrates:

- **Data quality assessment** and systematic cleaning
- **Relational database design** with normalization
- **Exploratory data analysis** using intermediate and advanced SQL
- **Analytical reasoning** to answer meaningful business questions
- **Professional documentation** for portfolio readiness

The project follows data analyst best practices: preserve raw data, validate all transformations, trace every finding to actual query results, and clearly document limitations.

---

## Business Questions

- How is the dataset distributed between Movies and TV Shows?
- Which genres and countries are represented most frequently?
- What are the typical movie runtimes and TV Show season counts?
- How have title additions varied by year in the snapshot?
- Which content ratings are most common?
- What is the release-to-addition gap?

## Dataset Description

**Source:** Netflix Titles Dataset (metadata snapshot as of September 25, 2021)

**Records:** 8,807 titles

**Columns:**
- show_id (unique identifier)
- type (Movie or TV Show)
- title (content name)
- director (comma-separated)
- cast (comma-separated)
- country (comma-separated)
- date_added (date added to Netflix)
- release_year (original release year)
- rating (content rating: PG-13, TV-MA, etc.)
- duration (minutes for movies, seasons for TV shows)
- listed_in (genres, comma-separated)
- description (plot summary)

**Data Quality:** Generally excellent; 100% complete for core fields (show_id, type, title, release_year, description). Expected missing values in director (29.91% for TV shows), cast (9.37%), and country (9.44%). Minor issues: 3 rating/duration anomalies fixed during cleaning; 10 missing date_added values.

---

## Dataset Limitations

**Important:** This dataset has inherent limitations that affect analytical conclusions:

- **No viewing data:** Cannot determine what subscribers actually watch or engagement
- **No revenue/financial data:** Cannot determine profitability, costs, or financial impact
- **No subscriber data:** Cannot determine user preferences or demographic patterns
- **No real-time data:** Snapshot from September 2021; does not reflect current Netflix catalog
- **Metadata only:** Does not include production quality, cultural significance, or strategic decisions
- **No control group:** Cannot compare to other streaming services' catalogs

**Consequence:** Analytical findings are descriptive (what the catalog contains), not prescriptive (what Netflix's strategy is or what subscribers want).

---

## Data Quality Issues Discovered & Resolved

### 1. Rating/Duration Swap (3 Records)

**Issue:** Three records had duration values in the rating field instead of the duration field.

| Record | Type | Title | Before (rating) | Before (duration) | After (rating) | After (duration) |
|--------|------|-------|---|---|---|---|
| s5542 | Movie | Louis C.K. 2017 | '74 min' | '' | 'TV-MA' | '74 min' |
| s5795 | Movie | Louis C.K.: Hilarious | '84 min' | '' | 'TV-MA' | '84 min' |
| s5814 | Movie | Louis C.K.: Live at the Comedy Store | '66 min' | '' | 'TV-MA' | '66 min' |

**Root Cause:** Column misalignment during data export (likely copy-paste error or ETL bug)

**Resolution:** Moved duration from rating field to duration field; assigned 'TV-MA' rating (standard for comedy specials)

**Traceability:** Documented in `data_quality_flag` field

### 2. Whitespace Contamination

**Issue:** Leading/trailing whitespace in text fields (particularly dates, cast, genre)

**Resolution:** Applied TRIM() to all text fields before type conversion

### 3. Date Format Inconsistency

**Issue:** date_added stored as text in "Month DD, YYYY" format (e.g., "September 25, 2021")

**Resolution:** Converted to SQL DATE type using TO_DATE() with format specification

### 4. Missing Values (Handled, Not Invented)

**Philosophy:** Missing values are kept as NULL where appropriate; data is never invented.

- Director: 2,634 (29.91%) missing - normal for TV shows
- Cast: 825 (9.37%) missing - acceptable for non-scripted content
- Country: 831 (9.44%) missing - genuinely missing, not invented
- date_added: 10 (0.11%) missing - kept as NULL
- rating: 4 (0.05%) missing - 3 fixed by anomaly resolution

---

## Data Cleaning Methodology

### Approach: Preserve Raw, Create Cleaned Tables

1. **Raw data preserved:** Original `netflix_titles.csv` stored untouched in `data/raw/`
2. **Staging area:** Data loaded into temporary staging table
3. **Transformation:** Applied cleaning logic via SQL (documented in `01_create_and_clean_tables.sql`)
4. **Validation:** Data quality checks executed (see `02_data_quality_checks.sql`)
5. **Normalization:** Multi-value fields split into junction tables

### Cleaning Steps

1. **Whitespace trimming:** TRIM() applied to all text fields
2. **Type conversion:** release_year → INTEGER, date_added → DATE
3. **Anomaly fixing:** 3 rating/duration swaps corrected
4. **NULL handling:** Empty strings converted to NULL (not invented)
5. **Multi-value normalization:** Countries and genres split into junction tables
6. **Constraint application:** NOT NULL, UNIQUE, FOREIGN KEY constraints
7. **Audit trail:** data_quality_flag field documents all changes

### Reproducibility

All cleaning is:
- **Documented** in this README and `docs/methodology.md`
- **Traceable** via SQL queries and data_quality_flag field
- **Reversible** (raw data always available)
- **Repeatable** via `sql/01_create_tables.sql`

---

## Data Model

### Relational Schema

```
titles (main table)
├─ show_id (PK, VARCHAR)
├─ type (Movie | TV Show)
├─ title, director, cast, description
├─ date_added (DATE), release_year (INTEGER)
├─ rating, duration
└─ data_quality_flag (audit trail)

title_countries (junction table)
├─ country_id (PK)
├─ show_id (FK → titles)
└─ country

title_genres (junction table)
├─ genre_id (PK)
├─ show_id (FK → titles)
└─ genre
```

### Why This Design?

**Normalization:**
- Multi-value fields (country, genre) split into junction tables
- Eliminates redundancy; enables grouping/filtering by country/genre
- Foreign keys enforce referential integrity

**Why Not Normalize Cast?**
- Cast normalization would create massive table (10-20 cast members per title)
- Limited analytical value for data analyst portfolio scope
- Trade-off: simplicity over granularity

**Constraints:**
- PRIMARY KEY: Ensures uniqueness of titles
- FOREIGN KEY: Ensures no orphan country/genre records
- UNIQUE: Prevents duplicate country/genre per title
- NOT NULL: Enforces required fields
- CHECK: Validates type and release_year ranges

---

## SQL Techniques Demonstrated

### Intermediate SQL

- **JOINs:** INNER JOIN, LEFT JOIN, multiple joins
- **Aggregation:** COUNT, SUM, AVG, MIN, MAX, PERCENTILE_CONT
- **Grouping:** GROUP BY, HAVING
- **Sorting:** ORDER BY with custom sort orders
- **Filtering:** WHERE with complex conditions
- **String functions:** TRIM, CONCAT, STRING_AGG, REGEXP_MATCHES

### Advanced SQL

- **CTEs (WITH clauses):** Multi-step queries, readable subqueries
- **Window Functions:** ROW_NUMBER, RANK, DENSE_RANK, LAG
- **Subqueries:** Nested queries for complex logic
- **Case Statements:** Conditional logic (CASE WHEN)
- **Array Functions:** STRING_TO_ARRAY, UNNEST (for multi-value splitting)
- **Date Functions:** EXTRACT, date arithmetic
- **Conditional Aggregation:** SUM(CASE WHEN...) for pivot logic
- **Regex Functions:** REGEXP_MATCHES for duration/season parsing

---

## Analytical Questions & Key Findings

### Question 1: How is the Netflix catalog distributed between Movies and TV Shows?

**Finding:** 6,131 Movies (69.66%) and 2,676 TV Shows (30.34%)

**Interpretation:** dataset-level descriptive pattern (2.3x more than TV shows)

**Limitation:** Cannot determine if this reflects Netflix's strategy, market availability, or subscriber demand

### Question 2: Which genres dominate the Netflix catalog?

**Finding:** Top 5 genres:
1. International Movies (1,351 titles, 15.35%)
2. Dramas (1,208 titles, 13.73%)
3. Comedies (869 titles, 9.88%)
4. Action & Adventure (756 titles, 8.60%)
5. Romantic Movies (657 titles, 7.47%)

**Interpretation:** dataset-level descriptive pattern (international + dramas)

### Question 3: Which countries contribute the most content?

**Finding:** Top 5 countries:
1. United States (2,769 titles, 29.4%)
2. India (806 titles, 8.6%)
3. United Kingdom (414 titles, 4.4%)
4. Japan (327 titles, 3.5%)
5. Canada (267 titles, 2.8%)

**Interpretation:** dataset-level descriptive pattern

### Question 4: What is typical movie duration?

**Finding:** 
- Average: 101.4 minutes
- Median: 102 minutes
- Most common range: 90-120 minutes (66.7% of movies)
- Range: 10 to 312 minutes

**Interpretation:** dataset-level descriptive pattern

### Question 5: How many seasons do TV shows typically have?

**Finding:**
- Average: 2.36 seasons
- Median: 1 season
- Distribution: 49% have 1 season, 20.8% have 2 seasons
- Range: 1 to 13 seasons

**Interpretation:** dataset-level descriptive pattern

### Question 6: How has content been added to Netflix over time?

**Finding:** Content additions accelerated 2020-2021:
- 2020: 1,647 titles
- 2021 (partial): 1,649 titles
- Combined 2020-2021: 3,296 titles (~37% of entire catalog)

**Interpretation:** dataset-level descriptive pattern

**Limitation:** Cannot determine causation; coincidence with pandemic does not prove causation

### Question 7: What ratings dominate the catalog?

**Finding:**
- TV-MA: 2,161 (24.5%)
- PG-13: 1,632 (18.5%)
- R: 1,425 (16.2%)
- Children's (TV-Y, TV-Y7): 408 (4.6%)

**Interpretation:** Netflix targets adult/teen audience; limited children's programming

### Question 8: How old is content when added to Netflix?

**Finding:**
- Average gap: 8.2 years between release and addition
- 76% added 3+ years after release
- Only 6.6% added same year as release

**Interpretation:** dataset-level descriptive pattern

---

## Project Structure

```
netflix-content-analysis-sql/
│
├── README.md (this file)
│
├── data/
│   └── raw/
│       └── README.md
│
├── sql/
│   ├── 01_create_and_clean_tables.sql (schema + data loading + cleaning)
│   ├── 02_data_quality_checks.sql (validation queries)
│   ├── 03_exploratory_analysis.sql (EDA queries)
│   ├── 04_advanced_analysis.sql (advanced SQL techniques)
│   └── 05_business_questions.sql (analytical questions with results)
│
├── analysis/
│   └── key_findings.md (detailed findings with evidence)
│
├── docs/
│   ├── data_dictionary.md (field definitions)
│   ├── methodology.md (detailed cleaning process)
│   └── README.md (this file)
│
├── .gitignore
└── LICENSE
```

---

## How to Run This Project

### Prerequisites

- PostgreSQL 12+ (or any recent version)
- Command line access to `psql`
- ~50 MB disk space for data

### Setup

1. **Clone repository**
   ```bash
   git clone https://github.com/gshakir-ops/netflix-content-analysis-sql.git
   cd netflix-content-analysis-sql
   ```

2. **Create database**
   ```bash
   createdb netflix_db
   ```

3. **Run setup script**
   ```bash
   psql netflix_db < sql/01_create_tables.sql
   ```

   (This script will prompt you to load the CSV file using \COPY; follow the on-screen instructions)

4. **Run quality checks**
   ```bash
   psql netflix_db < sql/02_data_quality_checks.sql
   ```

5. **Run analysis queries**
   ```bash
   psql netflix_db < sql/03_exploratory_analysis.sql
   psql netflix_db < sql/04_advanced_analysis.sql
   psql netflix_db < sql/05_business_questions.sql
   ```

### Example Queries

**Q: How many movies vs TV shows?**
```sql
SELECT type, COUNT(*) as count, 
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM titles), 2) as pct
FROM titles
GROUP BY type;
```

**Q: Top 10 genres**
```sql
SELECT genre, COUNT(*) as count
FROM title_genres
GROUP BY genre
ORDER BY count DESC
LIMIT 10;
```

**Q: Top 10 countries**
```sql
SELECT country, COUNT(*) as count
FROM title_countries
GROUP BY country
ORDER BY count DESC
LIMIT 10;
```

---

## SQL Techniques Demonstrated

This project demonstrates the following SQL proficiencies:

| Technique | Usage | Example File |
|-----------|-------|--------------|
| **CTEs** | Multi-step analytical queries | 04_advanced_analysis.sql |
| **Window Functions** | ROW_NUMBER, RANK, DENSE_RANK, LAG | 04_advanced_analysis.sql |
| **Joins** | INNER, LEFT, multiple joins | 03_exploratory_analysis.sql |
| **Aggregation** | COUNT, SUM, AVG, percentiles | 03_exploratory_analysis.sql |
| **Subqueries** | Nested queries for complex logic | 04_advanced_analysis.sql |
| **CASE Statements** | Conditional logic | 03_exploratory_analysis.sql |
| **String Functions** | TRIM, CONCAT, STRING_AGG, REGEXP | 01_create_tables.sql |
| **Array Functions** | STRING_TO_ARRAY, UNNEST | 01_create_tables.sql |
| **Date Functions** | EXTRACT, date arithmetic | 03_exploratory_analysis.sql |
| **GROUP BY + HAVING** | Aggregation with filters | 03_exploratory_analysis.sql |

---

## Data Validation

All key findings have been validated:

✓ **Count validation:** Total records (6,131 + 2,676 = 8,807)  
✓ **Anomaly verification:** 3 rating/duration fixes documented and verified  
✓ **Referential integrity:** No orphan country/genre records  
✓ **Constraint compliance:** All NOT NULL, UNIQUE, FOREIGN KEY constraints pass  
✓ **Data type correctness:** release_year INTEGER, date_added DATE, etc.  
✓ **No invented data:** All NULLs are genuine missing values  

---

## Key Insights

### What the Data Reveals

✓ Netflix's content is 70% movies, 30% TV shows  
✓ Dominated by international content, dramas, and comedies  
✓ 70% from just 5 countries (US, India, UK, Japan, Canada)  
✓ 68% of content released in last 20 years  
✓ Rapid catalog expansion during 2020-2021  
✓ Heavy focus on mature content (TV-MA + R ratings)  
✓ Most TV shows are limited series (1-2 seasons)  

### What the Data Cannot Reveal

✗ What subscribers actually watch (no viewing data)  
✗ Revenue or profitability (no financial data)  
✗ Subscriber preferences (no user data)  
✗ Content quality or critical reception  
✗ Netflix's strategic decisions  
✗ Engagement or retention metrics  
✗ Current catalog (snapshot from Sept 2021)  

---

## Limitations & Caveats

1. **Point-in-time snapshot:** Dataset captured September 25, 2021; does not reflect current catalog
2. **No viewing data:** Analysis describes what Netflix has, not what people watch
3. **No financial data:** Cannot determine profitability, costs, or ROI
4. **Metadata quality:** Dataset quality depends on source accuracy (IMDB, Netflix systems)
5. **Missing data:** ~30% of TV shows missing director (expected); some cast/country missing
6. **Multi-value fields:** Country and genre splitting assumes comma-delimited format
7. **No causation:** Patterns observed (e.g., pandemic expansion) do not prove cause
8. **Geopolitical bias:** Data reflects Netflix's market presence, not global content availability

---

## Future Improvements

### Analysis Enhancements
- **Sentiment analysis:** Analyze description text for tone/themes
- **Language extraction:** Parse title/description for multiple languages
- **Co-production networks:** Analyze multi-country collaboration patterns
- **Genre evolution:** Time-series analysis of genre trends over decades
- **Director/actor collaboration:** Network analysis of production relationships

### Technical Enhancements
- **Automated ETL pipeline:** dbt or Airflow for scheduled refreshes
- **BI dashboards:** Tableau/Power BI visualization layer
- **API layer:** REST API for programmatic data access
- **Incremental updates:** Track additions/removals over time
- **Data validation framework:** dbt tests for data quality
- **Performance optimization:** Indexes, query optimization, materialized views

### Data Enhancements
- **Subscriber data:** Join with viewing metrics (if available)
- **Financial data:** Add budget/revenue/ROI metrics
- **Critical reviews:** Add IMDB ratings, Rotten Tomatoes scores
- **Production details:** Add runtime, cinematography, production company
- **Licensing terms:** Add exclusive window info, licensing agreements

---

## Files Summary

| File | Purpose |
|------|---------|
| `01_create_and_clean_tables.sql` | Create schema, load raw data, clean, normalize (~300 lines) |
| `02_data_quality_checks.sql` | Validate data integrity with 16 comprehensive checks (~400 lines) |
| `03_exploratory_analysis.sql` | Answer 16 fundamental EDA questions (~400 lines) |
| `04_advanced_analysis.sql` | Demonstrate advanced SQL with CTEs, window functions (~600 lines) |
| `05_business_questions.sql` | 10 curated business questions with interpretation (~600 lines) |
| `data_dictionary.md` | Complete field definitions and data specifications |
| `methodology.md` | Detailed cleaning process and design decisions |
| `key_findings.md` | Key insights with observations, evidence, interpretations |

**Total SQL:** ~2,300 lines of production-quality SQL code

---

## Limitations

- The dataset is a September 2021 snapshot, not a current Netflix catalog.
- It contains metadata only; there is no viewing, revenue, subscriber, cost, or engagement data.
- Country and genre values are multi-valued, so their counts are not mutually exclusive.
- Descriptive patterns do not establish causal business strategy.

## Author

**Golam Shakir**

Data Analyst portfolio project focused on SQL, data cleaning, relational modeling, and analytical reasoning.

## License

This project is licensed under the MIT License. See LICENSE file for details.

---



**Last Updated:** October 1, 2026  
**Dataset Date:** September 25, 2021  
**Database:** PostgreSQL 12+

