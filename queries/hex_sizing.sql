-- Hex sizing exploration (2025 season)
--
-- Decisions:
--   * Cell size: 3 ft. Smaller cells are mostly empty (2 ft median: 2 shots
--     per bin for a 591-attempt player). Larger cells blur zones: the
--     corner-3 strip is only ~3 ft wide.
--   * Grid anchored at the hoop (x_raw = 25, y_raw = 0), so one cell is
--     centered on the rim and the grid is mirror-symmetric.
--   * Small samples handled by shrinkage toward the league rate per cell,
--     with k = 10: (makes + k * league_pct) / (attempts + k).
--   * Heaves excluded: coordinate_y_raw > 41.75.

-- 1. Check the hoop-centered bins.
SELECT
  floor((coordinate_x_raw - 25 + 1.5) / 3) AS bin_x,
  floor((coordinate_y_raw + 1.5) / 3)      AS bin_y,
  count(*) AS attempts,
  count(*) FILTER (WHERE scoring_play) AS makes,
  makes * 1.0 / attempts AS fg_pct
FROM pbp25
WHERE shooting_play
  AND type_text NOT LIKE 'Free Throw%'
  AND coordinate_y_raw <= 41.75
GROUP BY bin_x, bin_y
ORDER BY attempts DESC
LIMIT 20;

-- 2. Save the league baseline per bin for 2025.
CREATE TABLE league_bins_2025 AS
SELECT
  floor((coordinate_x_raw - 25 + 1.5) / 3) AS bin_x,
  floor((coordinate_y_raw + 1.5) / 3)      AS bin_y,
  count(*) AS attempts,
  count(*) FILTER (WHERE scoring_play) AS makes,
  makes * 1.0 / attempts AS fg_pct
FROM pbp25
WHERE shooting_play
  AND type_text NOT LIKE 'Free Throw%'
  AND coordinate_y_raw <= 41.75
GROUP BY bin_x, bin_y;

-- 3. Skylar Diggins: raw vs. shrunk FG% per bin (k = 10).
WITH her AS (
  SELECT
    floor((coordinate_x_raw - 25 + 1.5) / 3) AS bin_x,
    floor((coordinate_y_raw + 1.5) / 3)      AS bin_y,
    count(*) AS attempts,
    count(*) FILTER (WHERE scoring_play) AS makes
  FROM pbp25
  WHERE shooting_play
    AND type_text NOT LIKE 'Free Throw%'
    AND coordinate_y_raw <= 41.75
    AND athlete_id_1 = 2491205
  GROUP BY bin_x, bin_y
)
SELECT
  h.bin_x,
  h.bin_y,
  h.attempts,
  h.makes,
  round(h.makes * 1.0 / h.attempts, 3)                    AS raw_pct,
  round(l.fg_pct, 3)                                      AS league_pct,
  round((h.makes + 10 * l.fg_pct) / (h.attempts + 10), 3) AS shrunk_pct
FROM her h
JOIN league_bins_2025 l USING (bin_x, bin_y)
ORDER BY h.attempts DESC;