# Data findings: ESPN WNBA play-by-play

Seasons checked: 2012 and 2025.

## 1\. Shot attempts and results

shooting\_play marks attempts; scoring\_play marks makes. Exclude free throws with type\_text NOT LIKE 'Free Throw%'. In 2012, don't trust type\_text or score\_value for 2 vs. 3.

2025: no contradictions between flags. 2012: 486 made 3s typed as ordinary jump shots; 16 non-shots (turnovers, fouls, 'Not Available') flagged as shooting plays.

## 2\. Coordinate system

Two pairs of the same data, in feet. Raw: hoop-centered half court, hoop at x\_raw = 25, y\_raw = 0. Processed: full court from center, hoops at x = ±41.75.

41.75 = 47 ft (half of 94) − 5.25 ft hoop offset. Mapping test: y\_mismatch = 0 in both seasons; x\_mismatch only on heaves.

## 3\. Coordinate quality

Every field-goal attempt has coordinates: 29,330 in 2012 and 42,193 in 2025,
with no nulls and no placeholder values. About 0.2% are heaves from beyond
half court, which need a rule in the ETL.

## 4\. Game date and player ID

game\_date (date type) and athlete\_id\_1 (stable across seasons).

6 players appear in both seasons; all IDs match. Still to confirm: an ID survives a team change.

## Implications for the ETL

### Schema changes between seasons

Map columns per season, or start at a season with a consistent shape.

### Older Data is Messier

Validate rows on load and log failures per season.

### Labels are unreliable for 2 vs 3

Classify 2 vs. 3 by location against each season's 3-point line (moved back after 2012).

### Raw Coordinate pair

Use the raw pair for shot maps; no flipping needed. Add a rule for heaves (coordinate\_y\_raw > \~41.75).

## Method

* FG attempts = shooting\_play AND type\_text NOT LIKE 'Free Throw%'.
* Sentinel check: top-10 most frequent coordinate pairs showed no placeholder values in either season.
* x mismatch = rows where 41.75 − |coordinate\_x| differs from coordinate\_y\_raw by > 0.5 ft; all inspected rows were 44–57 ft heaves.
* y mismatch = rows where |coordinate\_y| differs from |coordinate\_x\_raw − 25| by > 0.5 ft.
* Source: my DuckDB queries against sportsdataverse release files, 2026-11-05. sportsdataverse espn\_wnba\_pbp release, CC BY 4.0.



\## Hex sizing (2025)



Tested square bins of 2, 3, and 5 ft on Skylar Diggins (591 field-goal attempts):



| Bin size | Bins used | Median shots per bin | Busiest bin |

|---|---|---|---|

| 2 ft | 189 | 2 | 24 |

| 3 ft | 117 | 3 | 55 |

| 5 ft | 54 | 7 | 94 |



\- \*\*Chose 3 ft.\*\* Even at 5 ft the median bin holds only 7 shots, so no size

&#x20; fixes small samples alone. 5 ft is also too coarse: the corner-3 strip is

&#x20; only about 3 ft wide, and the league data shows corner 3s (37–38%) beat

&#x20; above-the-break 3s (30–35%).

\- \*\*Anchored the grid at the hoop.\*\* Unanchored bins left the hoop off-center,

&#x20; so the bins on either side of the rim got uneven counts.

\- \*\*Shrinkage toward the league rate per bin, k = 10.\*\* A 1-for-1 bin drops

&#x20; from 100% to about 35%, while real patterns survive: Diggins shot 14 of 40

&#x20; just left of the rim (35% raw, 38% shrunk) against a league rate of 51%.

\- \*\*Open question:\*\* the bottom row of bins is half empty, since almost no

&#x20; shots come from behind the hoop. Decide when laying out the hex grid.



Queries: `queries/hex\_sizing.sql`.

