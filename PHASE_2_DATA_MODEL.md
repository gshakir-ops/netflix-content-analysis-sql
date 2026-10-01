# PHASE 2 — DATA MODEL DESIGN

## PostgreSQL Schema Design

### Relational Model Overview

The data model normalizes Netflix titles metadata into three interconnected tables:

```
titles (one) ──→ title_countries (many)
             ├─→ title_genres (many)
```

### Table Definitions

#### 1. `titles` (Main Table)

**Purpose:** Store cleaned Netflix title metadata with one row per unique show_id.

**Fields:**

```sql
CREATE TABLE titles (
    show_id        VARCHAR(10) PRIMARY KEY,
    type           VARCHAR(20) NOT NULL,
    title          VARCHAR(255) NOT NULL,
    director       TEXT,
    cast           TEXT,
    date_added     DATE,
    release_year   INTEGER NOT NULL,
    rating         VARCHAR(20),
    duration       VARCHAR(50),
    description    TEXT NOT NULL,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Rationale:**

- `show_id`: Netflix's internal identifier, guaranteed unique (verified in audit)
- `type`: ENUM-like values (Movie, TV Show)
- `title`: Full title text
- `director`: NULL-friendly (29.91% missing is normal)
- `cast`: Stored as comma-separated text (not normalized for portfolio simplicity)
- `date_added`: Cleaned and converted from text to DATE
- `release_year`: Integer, no NULL values in source
- `rating`: Content rating after cleaning (3 anomalies fixed)
- `duration`: Duration after cleaning (parsed from source)
- `description`: Full description text
- `created_at`: Audit timestamp

**Data Types:**

- VARCHAR(10) for show_id (format: s1 through s8807)
- VARCHAR(20) for type (Movie, TV Show) with NOT NULL
- VARCHAR(255) for title with NOT NULL (all titles present)
- TEXT for director and cast (allow NULL)
- DATE for date_added (allow NULL for 10 missing records)
- INTEGER for release_year with NOT NULL
- VARCHAR(20) for rating (allow NULL)
- VARCHAR(50) for duration (format varies: "90 min", "2 Seasons", etc.)
- TEXT for description with NOT NULL (all present)

---

#### 2. `title_countries` (Normalized Junction Table)

**Purpose:** Normalize multi-value country field. Many titles are co-productions.

**Fields:**

```sql
CREATE TABLE title_countries (
    country_id  SERIAL PRIMARY KEY,
    show_id     VARCHAR(10) NOT NULL REFERENCES titles(show_id) ON DELETE CASCADE,
    country     VARCHAR(100) NOT NULL
);

CREATE INDEX idx_title_countries_show_id ON title_countries(show_id);
CREATE UNIQUE INDEX idx_title_countries_unique ON title_countries(show_id, country);
```

**Rationale:**

- One row per title-country pair
- Example: "United States, Canada" becomes 2 rows
- FOREIGN KEY ensures referential integrity
- UNIQUE constraint prevents duplicate country entries per title
- Index on show_id for fast lookups

**Benefits:**

- Enables aggregation by country
- Allows filtering titles by production country
- Supports analysis of co-productions

---

#### 3. `title_genres` (Normalized Junction Table)

**Purpose:** Normalize multi-value genre field. Most titles have 2-3 genres.

**Fields:**

```sql
CREATE TABLE title_genres (
    genre_id   SERIAL PRIMARY KEY,
    show_id    VARCHAR(10) NOT NULL REFERENCES titles(show_id) ON DELETE CASCADE,
    genre      VARCHAR(100) NOT NULL
);

CREATE INDEX idx_title_genres_show_id ON title_genres(show_id);
CREATE UNIQUE INDEX idx_title_genres_unique ON title_genres(show_id, genre);
```

**Rationale:**

- One row per title-genre pair
- Example: "Dramas, International Movies, Romantic Movies" becomes 3 rows
- FOREIGN KEY ensures referential integrity
- UNIQUE constraint prevents duplicate genres per title
- Index on show_id for fast lookups

**Benefits:**

- Enables aggregation by genre
- Allows filtering titles by genre
- Supports cross-genre analysis (e.g., which genres appear together)
- Enables genre trend analysis

---

### Why NOT Normalize `cast`

**Rationale:** Cast normalization is unnecessary for this portfolio project.

**Reasons:**

1. **Complexity** — Most titles have 10-20+ cast members; normalization creates very large table
2. **Limited analytical value** — Portfolio questions don't require cast-level analysis
3. **Data quality issues** — Cast strings often list minor actors; incomplete casting lists
4. **Portfolio scope** — This is a Data Analyst project, not data engineering
5. **Maintainability** — Simpler model is more professional for a portfolio

**Decision:** Store cast as comma-separated text in titles table; document this limitation.

---

### Relationships and Constraints

```
titles
├─ PK: show_id
├─ FK (implicit): type IN ('Movie', 'TV Show')
├─ Check: release_year >= 1900 AND release_year <= 2021
└─ Check: duration IS NOT NULL OR type = 'TV Show'

title_countries
├─ PK: country_id
├─ FK: show_id → titles(show_id)
└─ UNIQUE(show_id, country)

title_genres
├─ PK: genre_id
├─ FK: show_id → titles(show_id)
└─ UNIQUE(show_id, genre)
```

---

### Query Pattern Examples

**Example 1: Find all Movies from United States**

```sql
SELECT t.*
FROM titles t
INNER JOIN title_countries tc ON t.show_id = tc.show_id
WHERE t.type = 'Movie'
  AND tc.country = 'United States';
```

**Example 2: Find titles in Drama genre**

```sql
SELECT t.*
FROM titles t
INNER JOIN title_genres tg ON t.show_id = tg.show_id
WHERE tg.genre = 'Dramas';
```

**Example 3: Genre distribution**

```sql
SELECT genre, COUNT(*) as title_count
FROM title_genres
GROUP BY genre
ORDER BY title_count DESC;
```

---

### Data Model Advantages

1. **Normalization** — Eliminates multi-value field redundancy
2. **Query flexibility** — Easy filtering, grouping, aggregation by country/genre
3. **Data integrity** — Foreign keys ensure no orphan records
4. **Scalability** — Can add new countries/genres without schema changes
5. **Analytical clarity** — Demonstrates proper relational design

### Data Model Trade-offs

1. **JOIN complexity** — Queries require joins (minimal for portfolio project)
2. **Import complexity** — Requires parsing multi-value fields during load
3. **Slight redundancy** — show_id repeated in normalized tables (standard design)

---

## Implementation Plan

### Step 1: Create tables
- Execute CREATE TABLE statements
- Create foreign keys
- Create indexes

### Step 2: Import and clean
- Load raw CSV
- Parse multi-value fields
- Fix the 3 rating anomalies
- Convert date_added to DATE type
- Handle NULL values

### Step 3: Validate
- Check referential integrity
- Validate record counts
- Verify normalization completeness

---

## Schema Validation Checklist

- [ ] titles table has 8,807 rows (matches source)
- [ ] No duplicate show_ids
- [ ] All NOT NULL constraints satisfied
- [ ] date_added properly converted
- [ ] rating anomalies fixed
- [ ] title_countries has no orphan records
- [ ] title_genres has no orphan records
- [ ] All countries from source appear in title_countries
- [ ] All genres from source appear in title_genres

---

## Next: PHASE 3 — Data Cleaning

The schema is ready. Phase 3 will execute the actual data import, cleaning, and transformation.
