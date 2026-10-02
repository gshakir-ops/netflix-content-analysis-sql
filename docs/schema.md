# Database Schema

## Model

```text
titles
 ├── title_countries
 └── title_genres

show_id: 1 → many country rows
show_id: 1 → many genre rows
```

## Why normalize?

The source stores country and genre values as comma-separated text. Separate relationship tables make grouping, filtering, counting, and co-occurrence analysis more reliable.

## Tables

### titles
Core title metadata and cleaning audit information. Primary key: `show_id`.

### title_countries
One row per title-country relationship. Primary key: `country_id`; foreign key: `show_id`; unique `(show_id, country)`.

### title_genres
One row per title-genre relationship. Primary key: `genre_id`; foreign key: `show_id`; unique `(show_id, genre)`.

## Cast decision

`cast` remains a comma-separated text field because cast-level analysis is outside the project scope. Adding another many-to-many table would increase complexity without supporting the core questions.
