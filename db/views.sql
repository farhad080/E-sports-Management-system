-- eSports Tournament Management System — Complex JOIN Views
-- Compatible with Oracle XE 21c

--------------------------------------------------------------------------------
-- 1. VIEW: V_TOURNAMENT_SUMMARY
-- Description: Aggregated overview of every tournament with its game title,
--              status, dates, prize pool, and the number of teams currently
--              registered.  Useful for admin dashboards and public listings.
--
-- Joins: TOURNAMENTS → GAMES (game details)
--        TOURNAMENTS → TEAMS (registration count)
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_tournament_summary AS
SELECT
    t.tournament_id,
    t.name                      AS tournament_name,
    g.name                      AS game_name,
    g.genre                     AS game_genre,
    g.platform                  AS game_platform,
    t.description,
    TO_CHAR(t.start_date, 'YYYY-MM-DD')  AS start_date,
    TO_CHAR(t.end_date,   'YYYY-MM-DD')  AS end_date,
    t.status                    AS tournament_status,
    t.prize_pool,
    t.max_teams,
    NVL(team_counts.registered_teams, 0)  AS registered_teams,
    t.max_teams - NVL(team_counts.registered_teams, 0)  AS available_slots,
    CASE
      WHEN NVL(team_counts.registered_teams, 0) >= t.max_teams THEN 'Full'
      WHEN t.status = 'Upcoming' THEN 'Open'
      ELSE 'Closed'
    END                         AS registration_status
FROM
    TOURNAMENTS t
    INNER JOIN GAMES g
        ON t.game_id = g.game_id
    LEFT JOIN (
        SELECT tournament_id,
               COUNT(*) AS registered_teams
          FROM TEAMS
         WHERE tournament_id IS NOT NULL
         GROUP BY tournament_id
    ) team_counts
        ON t.tournament_id = team_counts.tournament_id
ORDER BY
    CASE t.status
      WHEN 'Ongoing'   THEN 1
      WHEN 'Upcoming'  THEN 2
      WHEN 'Completed' THEN 3
      ELSE 4
    END,
    t.start_date;

COMMENT ON TABLE v_tournament_summary IS 'Aggregated tournament view with game details, team registration counts, and slot availability.';

--------------------------------------------------------------------------------
-- 2. VIEW: V_MATCH_DETAILS
-- Description: Fully denormalized view of every match, including tournament
--              context, both competing teams (with scores), and the winner.
--              Designed for match result pages and bracket rendering.
--
-- Joins: MATCHES       → TOURNAMENTS (tournament context)
--        MATCHES       → MATCH_TEAMS (participants & scores)  ×2 (team A / B)
--        MATCH_TEAMS   → TEAMS       (team names)             ×2
--        MATCHES       → TEAMS       (winner name)
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_match_details AS
SELECT
    m.match_id,
    -- Tournament info
    trn.tournament_id,
    trn.name                    AS tournament_name,
    trn.status                  AS tournament_status,
    -- Match info
    m.round,
    m.match_date,
    m.status                    AS match_status,
    -- Team A (first team by lowest match_team_id)
    ta.team_id                  AS team_a_id,
    ta_info.name                AS team_a_name,
    ta.score                    AS team_a_score,
    -- Team B (second team)
    tb.team_id                  AS team_b_id,
    tb_info.name                AS team_b_name,
    tb.score                    AS team_b_score,
    -- Winner
    m.winner_team_id,
    w_info.name                 AS winner_team_name
FROM
    MATCHES m
    -- Tournament details
    INNER JOIN TOURNAMENTS trn
        ON m.tournament_id = trn.tournament_id
    -- Team A: the participant with the LOWER match_team_id
    LEFT JOIN (
        SELECT mt.*,
               ROW_NUMBER() OVER (PARTITION BY mt.match_id ORDER BY mt.match_team_id ASC) AS rn
          FROM MATCH_TEAMS mt
    ) ta
        ON m.match_id = ta.match_id AND ta.rn = 1
    LEFT JOIN TEAMS ta_info
        ON ta.team_id = ta_info.team_id
    -- Team B: the participant with the HIGHER match_team_id
    LEFT JOIN (
        SELECT mt.*,
               ROW_NUMBER() OVER (PARTITION BY mt.match_id ORDER BY mt.match_team_id ASC) AS rn
          FROM MATCH_TEAMS mt
    ) tb
        ON m.match_id = tb.match_id AND tb.rn = 2
    LEFT JOIN TEAMS tb_info
        ON tb.team_id = tb_info.team_id
    -- Winner details
    LEFT JOIN TEAMS w_info
        ON m.winner_team_id = w_info.team_id
ORDER BY
    trn.tournament_id,
    m.round,
    m.match_date;

COMMENT ON TABLE v_match_details IS 'Fully denormalized match view with both competing teams, scores, tournament context, and winner details.';
