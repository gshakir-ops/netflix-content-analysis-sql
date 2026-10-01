# Data Dictionary
# Netflix Content Analytics - Field Definitions and Data Specifications

## TITLES TABLE

### show_id
- **Type:** VARCHAR(10)
- **Constraint:** PRIMARY KEY, NOT NULL
- **Description:** Unique identifier for each title (format: s1, s2, s3, ..., s8807)
- **Example:** s1, s5542, s8807
- **Data Quality:** 100% complete, no duplicates
- **Source:** Netflix internal identifier

### type
- **Type:** VARCHAR(20)
- **Constraint:** NOT NULL, CHECK (type IN ('Movie', 'TV Show'))
- **Description:** Content format classification
- **Valid Values:** 
  - Movie: Feature-length theatrical or streaming film
  - TV Show: Television series with one or more seasons
- **Distribution:** 6,131 Movies (69.66%), 2,676 TV Shows (30.34%)
- **Data Quality:** 100% complete, no NULL values
- **Source:** Netflix content classification system

### title
- **Type:** VARCHAR(255)
- **Constraint:** NOT NULL
- **Description:** Official title of the content as displayed on Netflix
- **Example:** "Dick Johnson Is Dead", "Blood & Water", "Jaws"
- **Data Quality:** 100% complete, no NULL values
- **Note:** May include original language titles translated to English

### director
- **Type:** TEXT
- **Constraint:** NULL allowed
- **Description:** Director(s) or showrunner(s) of the content
- **Format:** Comma-separated list if multiple directors
- **Example:** "Kirsten Johnson" or "Steven Spielberg, George Lucas"
- **Missing Data:** 2,634 records (29.91%)
  - Expected for TV Shows (typically have episode directors, not series directors)
  - Some movies also missing director information
- **Data Quality:** Normal for this field; NULLs are acceptable
- **Source:** Credits metadata

### cast
- **Type:** TEXT
- **Constraint:** NULL allowed
- **Description:** Cast members featured in the content
- **Format:** Comma-separated list of actor names
- **Example:** "Roy Scheider, Robert Shaw, Richard Dreyfuss"
- **Missing Data:** 825 records (9.37%)
  - Some documentary/non-scripted content may lack cast
- **Data Quality:** Generally complete; NULLs acceptable for non-scripted content
- **Note:** Not normalized into separate table (kept as text for portfolio simplicity)
- **Source:** Credits metadata

### date_added
- **Type:** DATE
- **Constraint:** NULL allowed
- **Description:** Date the title was added to Netflix catalog
- **Format:** YYYY-MM-DD (converted from "Month DD, YYYY" in raw data)
- **Example:** 2021-09-25
- **Missing Data:** 10 records (0.11%)
- **Data Range:** 2021-01-01 to 2021-12-31 (dataset captured mid-2021)
- **Data Quality:** 99.89% complete; missing values kept as NULL
- **Note:** Cleaned from source format; whitespace trimmed before conversion
- **Source:** Netflix platform metadata

### release_year
- **Type:** INTEGER
- **Constraint:** NOT NULL, CHECK (release_year >= 1900 AND release_year <= 2021)
- **Description:** Original release year of the content
- **Example:** 1975, 1993, 2021
- **Data Range:** 1925 (earliest: "The Gold Rush") to 2021
- **Distribution:** 68% of catalog released 2000 or later; median ~2012
- **Data Quality:** 100% complete, no NULL values
- **Data Quality:** All values within valid range
- **Source:** IMDB/entertainment databases

### rating
- **Type:** VARCHAR(20)
- **Constraint:** NULL allowed
- **Description:** Content rating classification indicating audience appropriateness
- **Valid Values (Movies):**
  - G: General Audiences
  - PG: Parental Guidance
  - PG-13: Parents Strongly Cautioned (children under 13)
  - R: Restricted (under 17 requires parent/guardian)
  - NC-17: No children under 17
  - NR: Not Rated
  - UR: Unrated

- **Valid Values (TV Shows):**
  - TV-Y: Young children
  - TV-Y7: Children 7+
  - TV-Y7-FV: Children 7+ (with fantasy violence)
  - TV-G: General Audiences
  - TV-PG: Parental Guidance
  - TV-14: Parents Strongly Cautioned (14+)
  - TV-MA: Mature Audiences (17+)

- **Missing Data:** 4 records (0.05%)
  - 3 fixed during data cleaning (rating/duration swap)
  - 1 genuinely missing
- **Data Quality:** Cleaned; 3 anomalies fixed
- **Data Cleaning:** 
  - s5542, s5795, s5814: Had duration values in rating field, assigned 'TV-MA'
- **Source:** MPAA/TV ratings standards

### duration
- **Type:** VARCHAR(50)
- **Constraint:** NULL allowed
- **Description:** Length of content
- **Format for Movies:** "XXX min" (e.g., "90 min", "104 min")
- **Format for TV Shows:** "X Season(s)" (e.g., "1 Season", "2 Seasons", "9 Seasons")
- **Examples:** "90 min", "102 min", "1 Season", "3 Seasons"
- **Data Range (Movies):** 10 minutes to 312 minutes
- **Data Range (TV Shows):** 1 Season to 13 Seasons
- **Missing Data:** 3 records (0.03%)
  - All 3 were fixed during data cleaning (moved from rating field)
- **Data Quality:** 99.97% complete after cleaning
- **Data Cleaning:**
  - s5542: '74 min' moved from rating field
  - s5795: '84 min' moved from rating field
  - s5814: '66 min' moved from rating field
- **Source:** Netflix/IMDB metadata

### description
- **Type:** TEXT
- **Constraint:** NOT NULL
- **Description:** Plot summary or content description
- **Example:** "When an insatiable great white shark terrorizes Amity Island, a police chief, an oceanographer and a grizzled shark hunter seek to destroy the beast."
- **Data Quality:** 100% complete, no NULL values
- **Length:** Typically 100-300 characters
- **Source:** Netflix content metadata

### data_quality_flag
- **Type:** TEXT
- **Constraint:** NULL allowed
- **Description:** Audit flag noting any data quality issues encountered and resolved
- **Example Values:**
  - "FIXED: Duration moved from rating field"
  - "EXPECTED: TV show without director"
  - "NOTE: Missing director"
  - NULL (for records with no quality issues)
- **Use:** Allows traceability of which records were cleaned
- **Source:** Populated during data cleaning

### created_at
- **Type:** TIMESTAMP
- **Constraint:** DEFAULT CURRENT_TIMESTAMP
- **Description:** Timestamp when record was inserted into database
- **Format:** YYYY-MM-DD HH:MM:SS
- **Purpose:** Audit trail for data loading
- **Source:** Database system time

---

## TITLE_COUNTRIES TABLE

Normalized junction table for multi-value country field. One row per title-country pair.

### country_id
- **Type:** SERIAL (Auto-incrementing integer)
- **Constraint:** PRIMARY KEY
- **Description:** Unique identifier for each row
- **Range:** 1 to ~9,380 (one per title-country pair)
- **Source:** Database-generated

### show_id
- **Type:** VARCHAR(10)
- **Constraint:** NOT NULL, FOREIGN KEY REFERENCES titles(show_id)
- **Description:** Reference to the title
- **Example:** s1, s5542, s8807
- **Referential Integrity:** ON DELETE CASCADE (deleting title removes all country entries)
- **Index:** Yes (for fast lookups)
- **Source:** From titles table

### country
- **Type:** VARCHAR(100)
- **Constraint:** NOT NULL
- **Description:** Production country name (trimmed, normalized)
- **Example:** "United States", "India", "United Kingdom", "Japan"
- **Data Quality:** Cleaned (leading/trailing whitespace trimmed)
- **Uniqueness:** UNIQUE constraint on (show_id, country) prevents duplicates
- **Data Range:** ~150 distinct countries
- **Top 5 Countries:** United States (2,769), India (806), UK (414), Japan (327), Canada (267)
- **Source:** Split from comma-separated country field in raw data

---

## TITLE_GENRES TABLE

Normalized junction table for multi-value genre field. One row per title-genre pair.

### genre_id
- **Type:** SERIAL (Auto-incrementing integer)
- **Constraint:** PRIMARY KEY
- **Description:** Unique identifier for each row
- **Range:** 1 to ~13,160 (one per title-genre pair)
- **Source:** Database-generated

### show_id
- **Type:** VARCHAR(10)
- **Constraint:** NOT NULL, FOREIGN KEY REFERENCES titles(show_id)
- **Description:** Reference to the title
- **Example:** s1, s5542, s8807
- **Referential Integrity:** ON DELETE CASCADE (deleting title removes all genre entries)
- **Index:** Yes (for fast lookups)
- **Source:** From titles table

### genre
- **Type:** VARCHAR(100)
- **Constraint:** NOT NULL
- **Description:** Genre classification (trimmed, normalized)
- **Examples:** "Dramas", "Comedies", "International Movies", "Action & Adventure"
- **Data Quality:** Cleaned (leading/trailing whitespace trimmed)
- **Uniqueness:** UNIQUE constraint on (show_id, genre) prevents duplicates
- **Data Range:** ~150 distinct genres
- **Top 5 Genres:** 
  - International Movies (1,351 titles)
  - Dramas (1,208 titles)
  - Comedies (869 titles)
  - Action & Adventure (756 titles)
  - Romantic Movies (657 titles)
- **Note:** Titles average 2-3 genres each
- **Source:** Split from comma-separated listed_in field in raw data

---

## Data Relationships

```
titles (1) ─── FK show_id ──→ title_countries (many)
         └─── FK show_id ──→ title_genres (many)
```

**Referential Integrity:**
- Both junction tables reference titles.show_id as foreign key
- ON DELETE CASCADE ensures deletion of title removes associated countries/genres
- No orphan records: all countries/genres point to valid titles
- No NULL foreign keys: all entries properly associated

---

## Data Quality Specifications

### Accepted NULL Values
- director: Expected for TV shows (~70% of TV shows), acceptable for some movies
- cast: Acceptable for non-scripted content (<10% of catalog)
- country: Minimal (9.44% of records) - genuinely missing, not invented
- date_added: Minimal (0.11% of records) - genuinely missing, not invented
- rating: Minimal (0.05% after cleaning) - genuinely missing, not invented
- duration: Minimal (0.03% after cleaning) - genuinely missing, not invented

### Cleaned Data Quality Issues
- **Rating/Duration Swap (3 records):** Fixed by moving duration from rating field to duration field
  - s5542: '74 min' → duration; rating set to 'TV-MA'
  - s5795: '84 min' → duration; rating set to 'TV-MA'
  - s5814: '66 min' → duration; rating set to 'TV-MA'
- **Whitespace:** All text fields trimmed of leading/trailing whitespace
- **Date Conversion:** date_added converted from "Month DD, YYYY" to DATE type
- **Type Validation:** type field validated to contain only 'Movie' or 'TV Show'

### Data Constraints
- release_year: 1900-2021 (validated with CHECK constraint)
- type: Only 'Movie' or 'TV Show' (validated with CHECK constraint)
- show_id: Unique, not NULL (validated as PRIMARY KEY)
- title: Not NULL (required field)
- description: Not NULL (required field)
- Referential integrity: All FK relationships enforced

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| Total Records (titles) | 8,807 |
| Total Countries (junction) | ~9,380 entries |
| Total Genres (junction) | ~13,160 entries |
| Distinct Countries | ~150 |
| Distinct Genres | ~150 |
| Data Complete Fields | 5 (show_id, type, title, release_year, description) |
| Data 99%+ Complete | 8 fields (date_added, duration, rating, etc.) |
| Expected NULL Fields | 3 (director, cast, country) |
| Anomalies Fixed | 3 (rating/duration swap) |

---

## Data Source & Limitations

**Source:** Netflix Titles Dataset (metadata snapshot as of September 25, 2021)
- Contains approximately 8,807 titles from Netflix catalog
- Metadata from IMDB, Netflix internal systems, and entertainment databases
- Point-in-time snapshot; does not reflect real-time changes

**Important Limitations:**
- No viewing data: Cannot determine what subscribers watch
- No revenue data: Cannot determine financial performance
- No subscriber data: Cannot determine user preferences
- No engagement metrics: Cannot determine content popularity
- Historical only: Reflects catalog as of mid-2021; may not match current Netflix
- Metadata accuracy: Field accuracy depends on source databases

