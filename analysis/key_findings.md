# Key Findings

This document summarizes descriptive results from the Netflix titles dataset.

## 1. Content type
**Result:** 6,131 Movies (69.66%) and 2,676 TV Shows (30.34%).

**Interpretation:** Movies represent the larger share of titles in the supplied dataset.

**Limitation:** This describes dataset composition and does not establish Netflix's overall strategy.

## 2. Genre representation
**Result:** International Movies (1,351), Dramas (1,208), Comedies (869), Action & Adventure (756), and Romantic Movies (657) have the highest title counts.

**Interpretation:** These are the most frequently represented normalized genre values.

**Limitation:** Titles can belong to multiple genres.

## 3. Country representation
**Result:** United States (2,769), India (806), United Kingdom (414), Japan (327), and Canada (267) have the highest associated title counts.

**Interpretation:** These countries have the highest counts in the normalized country metadata.

**Limitation:** Country values are non-exclusive and do not measure production budgets or investment.

## 4. Movie duration
**Result:** Average 101.4 minutes; median 102 minutes; 66.7% between 90 and 120 minutes.

**Interpretation:** Movie runtimes are concentrated around common feature-length ranges.

**Limitation:** No viewing or engagement data is available.

## 5. TV Show seasons
**Result:** Average 2.36 seasons; median 1; 49% have one season and 20.8% have two.

**Interpretation:** One- and two-season shows make up a large share of the TV Show rows.

**Limitation:** The snapshot does not identify whether a series was completed, cancelled, or still active.

## 6. Titles added
**Result:** 1,647 titles have a 2020 date_added year and 1,649 have a 2021 year.

**Interpretation:** The source contains many additions in these years.

**Limitation:** 2021 is partial, and the data does not establish why additions changed.

## 7. Ratings
**Result:** TV-MA (2,161), PG-13 (1,632), and R (1,425) are among the most common ratings.

**Interpretation:** These categories are strongly represented in the metadata.

**Limitation:** Rating counts do not measure audience size or preference.

## 8. Release-to-addition gap
**Result:** Average gap approximately 8.2 years; about 76% added at least three years after release; about 6.6% added in the same year.

**Interpretation:** The dataset contains both recent releases and older catalog additions.

**Limitation:** The gap does not establish licensing terms, acquisition strategy, or business intent.

## Data Quality Note

Three records contain runtime values in the rating field: s5542 (74 min), s5795 (84 min), and s5814 (66 min). The cleaning process moves these values into duration. Their ratings remain NULL because the source does not independently establish the missing ratings.
