-- eSports Tournament Management System — Performance Indexes
-- Compatible with Oracle XE 21c
--
-- Strategy:
--   1. Index every Foreign Key column to speed up JOINs and CASCADE operations.
--   2. Index frequently queried columns (email, status, tournament_id).
--   3. Composite indexes for common multi-column query patterns.
--
-- Note: Primary Key and UNIQUE constraints already create implicit indexes,
--       so we skip those columns (e.g., user_id PK, email UQ, game_name UQ).

--------------------------------------------------------------------------------
-- Helper: Drop-if-exists wrapper to make the script re-runnable
--------------------------------------------------------------------------------
DECLARE
  PROCEDURE drop_idx(p_name VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX ' || p_name;
  EXCEPTION
    WHEN OTHERS THEN NULL;   -- ORA-01418: index does not exist
  END;
BEGIN
  -- TOURNAMENTS FK & query indexes
  drop_idx('IDX_TOURNAMENTS_GAME_ID');
  drop_idx('IDX_TOURNAMENTS_STATUS');
  drop_idx('IDX_TOURNAMENTS_START_DATE');

  -- TEAMS FK & query indexes
  drop_idx('IDX_TEAMS_CAPTAIN_ID');
  drop_idx('IDX_TEAMS_GAME_ID');
  drop_idx('IDX_TEAMS_TOURNAMENT_ID');

  -- TEAM_MEMBERS FK indexes
  drop_idx('IDX_TEAM_MEMBERS_TEAM_ID');
  drop_idx('IDX_TEAM_MEMBERS_USER_ID');

  -- MATCHES FK & query indexes
  drop_idx('IDX_MATCHES_TOURNAMENT_ID');
  drop_idx('IDX_MATCHES_WINNER_TEAM_ID');
  drop_idx('IDX_MATCHES_STATUS');
  drop_idx('IDX_MATCHES_TOURN_STATUS');

  -- MATCH_TEAMS FK indexes
  drop_idx('IDX_MATCH_TEAMS_MATCH_ID');
  drop_idx('IDX_MATCH_TEAMS_TEAM_ID');

  -- BRACKETS FK indexes
  drop_idx('IDX_BRACKETS_TOURNAMENT_ID');

  -- USERS query indexes
  drop_idx('IDX_USERS_ROLE');
  drop_idx('IDX_USERS_EMAIL');
END;
/

--------------------------------------------------------------------------------
-- USERS indexes
--------------------------------------------------------------------------------
-- email is already UNIQUE, but we add a functional index on UPPER(email)
-- for case-insensitive login lookups
CREATE INDEX idx_users_email
    ON USERS (UPPER(email));

-- Role-based filtering (Admin panel, dashboards)
CREATE INDEX idx_users_role
    ON USERS (role);

--------------------------------------------------------------------------------
-- TOURNAMENTS indexes
--------------------------------------------------------------------------------
-- FK: game_id
CREATE INDEX idx_tournaments_game_id
    ON TOURNAMENTS (game_id);

-- Frequently filtered by status in dashboards and listings
CREATE INDEX idx_tournaments_status
    ON TOURNAMENTS (status);

-- Sorted/filtered by start date in upcoming tournament queries
CREATE INDEX idx_tournaments_start_date
    ON TOURNAMENTS (start_date);

--------------------------------------------------------------------------------
-- TEAMS indexes
--------------------------------------------------------------------------------
-- FK: captain_id
CREATE INDEX idx_teams_captain_id
    ON TEAMS (captain_id);

-- FK: game_id
CREATE INDEX idx_teams_game_id
    ON TEAMS (game_id);

-- FK: tournament_id — heavily used in registration counts & standings
CREATE INDEX idx_teams_tournament_id
    ON TEAMS (tournament_id);

--------------------------------------------------------------------------------
-- TEAM_MEMBERS indexes
--------------------------------------------------------------------------------
-- FK: team_id
CREATE INDEX idx_team_members_team_id
    ON TEAM_MEMBERS (team_id);

-- FK: user_id
CREATE INDEX idx_team_members_user_id
    ON TEAM_MEMBERS (user_id);

--------------------------------------------------------------------------------
-- MATCHES indexes
--------------------------------------------------------------------------------
-- FK: tournament_id — used in bracket generation and standings
CREATE INDEX idx_matches_tournament_id
    ON MATCHES (tournament_id);

-- FK: winner_team_id
CREATE INDEX idx_matches_winner_team_id
    ON MATCHES (winner_team_id);

-- Status filter for active / upcoming match queries
CREATE INDEX idx_matches_status
    ON MATCHES (status);

-- Composite: auto-close trigger and standings both query by (tournament_id, status)
CREATE INDEX idx_matches_tourn_status
    ON MATCHES (tournament_id, status);

--------------------------------------------------------------------------------
-- MATCH_TEAMS indexes
--------------------------------------------------------------------------------
-- FK: match_id
CREATE INDEX idx_match_teams_match_id
    ON MATCH_TEAMS (match_id);

-- FK: team_id
CREATE INDEX idx_match_teams_team_id
    ON MATCH_TEAMS (team_id);

--------------------------------------------------------------------------------
-- BRACKETS indexes
--------------------------------------------------------------------------------
-- FK: tournament_id
CREATE INDEX idx_brackets_tournament_id
    ON BRACKETS (tournament_id);
