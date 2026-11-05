# Data findings: ESPN WNBA play-by-play

Seasons checked: 2012 and 2025.

## 1. Shot attempts and results

shooting_play marks attempts; scoring_play marks makes. Exclude free throws with type_text NOT LIKE 'Free Throw%'. In 2012, don't trust type_text or score_value for 2 vs. 3.

2025: no contradictions between flags. 2012: 486 made 3s typed as ordinary jump shots; 16 non-shots (turnovers, fouls, 'Not Available') flagged as shooting plays.

## 2. Coordinate system

Two pairs of the same data, in feet. Raw: hoop-centered half court, hoop at x_raw = 25, y_raw = 0. Processed: full court from center, hoops at x = ±41.75.

41.75 = 47 ft (half of 94) − 5.25 ft hoop offset. Mapping test: y_mismatch = 0 in both seasons; x_mismatch only on heaves.
## 3. Coordinate quality

Every field-goal attempt has coordinates: 29,330 in 2012 and 42,193 in 2025,
with no nulls and no placeholder values. About 0.2% are heaves from beyond
half court, which need a rule in the ETL.

## 4. Game date and player ID

game_date (date type) and athlete_id_1 (stable across seasons).	

6 players appear in both seasons; all IDs match. Still to confirm: an ID survives a team change.

## Implications for the ETL

### Schema changes between seasons

Map columns per season, or start at a season with a consistent shape.

### Older Data is Messier

Validate rows on load and log failures per season.

### Labels are unreliable for 2 vs 3

Classify 2 vs. 3 by location against each season's 3-point line (moved back after 2012).

### Raw Coordinate pair

Use the raw pair for shot maps; no flipping needed. Add a rule for heaves (coordinate_y_raw > ~41.75).

## Method

-FG attempts = shooting_play AND type_text NOT LIKE 'Free Throw%'.				
-Sentinel check: top-10 most frequent coordinate pairs showed no placeholder values in either season.				
-x mismatch = rows where 41.75 − |coordinate_x| differs from coordinate_y_raw by > 0.5 ft; all inspected rows were 44–57 ft heaves.				
-y mismatch = rows where |coordinate_y| differs from |coordinate_x_raw − 25| by > 0.5 ft.				
-Source: my DuckDB queries against sportsdataverse release files, 2026-11-05. sportsdataverse espn_wnba_pbp release, CC BY 4.0.				