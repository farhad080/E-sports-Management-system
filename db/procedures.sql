-- eSports Tournament Management System Stored Procedures & Functions
-- Compatible with Oracle XE 21c

SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- 1. PROCEDURE: REGISTER_TEAM
-- Description: Registers a new team for a tournament, validating tournament
--              existence and open registration status. Inserts the captain as 
--              the first member of the team.
-- Parameters:
--   p_tournament_id: The ID of the tournament to register for.
--   p_captain_id:    The user ID of the team captain.
--   p_team_name:     The name of the new team.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE register_team (
  p_tournament_id IN NUMBER,
  p_captain_id    IN NUMBER,
  p_team_name     IN VARCHAR2
) IS
  v_game_id           NUMBER;
  v_status            VARCHAR2(20);
  v_captain_exists    NUMBER;
  v_team_id           NUMBER;
  v_registered_count  NUMBER;
  v_max_teams         NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Starting register_team for tournament ' || p_tournament_id || ' and captain ' || p_captain_id);

  -- 1. Validate tournament existence and fetch details
  BEGIN
    SELECT game_id, status, max_teams 
    INTO v_game_id, v_status, v_max_teams 
    FROM TOURNAMENTS 
    WHERE tournament_id = p_tournament_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20001, 'Registration Failed: Tournament ID ' || p_tournament_id || ' does not exist.');
  END;

  -- 2. Validate tournament status is open for registration ('Upcoming')
  IF v_status != 'Upcoming' THEN
    RAISE_APPLICATION_ERROR(-20002, 'Registration Failed: Tournament status is ' || v_status || '. Registration is only open for Upcoming tournaments.');
  END If;

  -- 3. Check team limit
  SELECT COUNT(*) INTO v_registered_count FROM TEAMS WHERE tournament_id = p_tournament_id;
  IF v_registered_count >= v_max_teams THEN
    RAISE_APPLICATION_ERROR(-20003, 'Registration Failed: Tournament is already full (Max capacity: ' || v_max_teams || ' teams).');
  END IF;

  -- 4. Validate captain existence and role
  BEGIN
    SELECT COUNT(*) INTO v_captain_exists FROM USERS WHERE user_id = p_captain_id;
    IF v_captain_exists = 0 THEN
      RAISE_APPLICATION_ERROR(-20004, 'Registration Failed: Captain User ID ' || p_captain_id || ' does not exist.');
    END IF;
  END;

  -- 5. Insert new team
  INSERT INTO TEAMS (name, captain_id, game_id, tournament_id)
  VALUES (p_team_name, p_captain_id, v_game_id, p_tournament_id)
  RETURNING team_id INTO v_team_id;

  -- 6. Insert captain into TEAM_MEMBERS
  INSERT INTO TEAM_MEMBERS (team_id, user_id)
  VALUES (v_team_id, p_captain_id);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Team registered successfully. Team ID: ' || v_team_id || ', Team Name: ' || p_team_name);

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Error in register_team: ' || SQLERRM);
    RAISE;
END;
/

--------------------------------------------------------------------------------
-- 2. PROCEDURE: SCHEDULE_MATCH
-- Description: Creates a new match within a tournament and links the two
--              participating teams.
-- Parameters:
--   p_tournament_id: Parent tournament ID.
--   p_round_no:      The round description (e.g., Quarter-Finals, Semi-Finals).
--   p_team1_id:      The ID of the first team.
--   p_team2_id:      The ID of the second team.
--   p_match_date:    Scheduled date/time of the match.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE schedule_match (
  p_tournament_id IN NUMBER,
  p_round_no      IN VARCHAR2,
  p_team1_id      IN NUMBER,
  p_team2_id      IN NUMBER,
  p_match_date    IN TIMESTAMP
) IS
  v_tournament_exists NUMBER;
  v_team1_exists      NUMBER;
  v_team2_exists      NUMBER;
  v_match_id          NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Starting schedule_match for round: ' || p_round_no);

  -- 1. Validate tournament
  SELECT COUNT(*) INTO v_tournament_exists FROM TOURNAMENTS WHERE tournament_id = p_tournament_id;
  IF v_tournament_exists = 0 THEN
    RAISE_APPLICATION_ERROR(-20005, 'Scheduling Failed: Tournament ID ' || p_tournament_id || ' does not exist.');
  END IF;

  -- 2. Validate teams
  SELECT COUNT(*) INTO v_team1_exists FROM TEAMS WHERE team_id = p_team1_id;
  SELECT COUNT(*) INTO v_team2_exists FROM TEAMS WHERE team_id = p_team2_id;
  
  IF v_team1_exists = 0 OR v_team2_exists = 0 THEN
    RAISE_APPLICATION_ERROR(-20006, 'Scheduling Failed: One or both team IDs (' || p_team1_id || ', ' || p_team2_id || ') do not exist.');
  END IF;

  -- 3. Insert MATCHES entry
  INSERT INTO MATCHES (tournament_id, round, match_date, status)
  VALUES (p_tournament_id, p_round_no, p_match_date, 'Upcoming')
  RETURNING match_id INTO v_match_id;

  -- 4. Insert MATCH_TEAMS entries (scores start at 0)
  INSERT INTO MATCH_TEAMS (match_id, team_id, score) VALUES (v_match_id, p_team1_id, 0);
  INSERT INTO MATCH_TEAMS (match_id, team_id, score) VALUES (v_match_id, p_team2_id, 0);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Match scheduled successfully. Match ID: ' || v_match_id);

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Error in schedule_match: ' || SQLERRM);
    RAISE;
END;
/

--------------------------------------------------------------------------------
-- 3. PROCEDURE: DECLARE_WINNER
-- Description: Declares the winner of a match, updates scores for the team
--              records, and marks the match status as Completed.
-- Parameters:
--   p_match_id:       The match ID.
--   p_winner_team_id: The ID of the winning team.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE declare_winner (
  p_match_id       IN NUMBER,
  p_winner_team_id IN NUMBER
) IS
  v_match_exists       NUMBER;
  v_team_in_match      NUMBER;
  v_current_status     VARCHAR2(20);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Starting declare_winner for Match ' || p_match_id || ', Winner Team ' || p_winner_team_id);

  -- 1. Validate match existence
  BEGIN
    SELECT status INTO v_current_status FROM MATCHES WHERE match_id = p_match_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20007, 'Declare Winner Failed: Match ID ' || p_match_id || ' does not exist.');
  END;

  -- 2. Validate that the winning team participated in the match
  SELECT COUNT(*) INTO v_team_in_match 
  FROM MATCH_TEAMS 
  WHERE match_id = p_match_id AND team_id = p_winner_team_id;

  IF v_team_in_match = 0 THEN
    RAISE_APPLICATION_ERROR(-20008, 'Declare Winner Failed: Team ID ' || p_winner_team_id || ' did not participate in Match ID ' || p_match_id);
  END IF;

  -- 3. Update MATCHES winner and status
  UPDATE MATCHES
  SET winner_team_id = p_winner_team_id,
      status = 'Completed'
  WHERE match_id = p_match_id;

  -- 4. Set a high score for the winner (e.g. 13 points) and low score for the loser (e.g. 5 points)
  -- This provides mock-like realistic scores for UI representation
  UPDATE MATCH_TEAMS
  SET score = 13
  WHERE match_id = p_match_id AND team_id = p_winner_team_id;

  UPDATE MATCH_TEAMS
  SET score = 5
  WHERE match_id = p_match_id AND team_id != p_winner_team_id;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Winner declared successfully. Match ' || p_match_id || ' updated.');

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Error in declare_winner: ' || SQLERRM);
    RAISE;
END;
/

--------------------------------------------------------------------------------
-- 4. FUNCTION: GET_TOURNAMENT_STANDINGS
-- Description: Returns a refcursor containing the registered teams ranked by
--              their total match wins in the specified tournament.
-- Parameters:
--   p_tournament_id: The tournament to calculate standings for.
-- Returns:
--   SYS_REFCURSOR: Cursor with columns (team_id, name, wins).
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_tournament_standings (
  p_tournament_id IN NUMBER
) RETURN SYS_REFCURSOR IS
  v_cursor            SYS_REFCURSOR;
  v_tournament_exists NUMBER;
BEGIN
  -- 1. Validate tournament
  SELECT COUNT(*) INTO v_tournament_exists FROM TOURNAMENTS WHERE tournament_id = p_tournament_id;
  IF v_tournament_exists = 0 THEN
    RAISE_APPLICATION_ERROR(-20009, 'Get Standings Failed: Tournament ID ' || p_tournament_id || ' does not exist.');
  END IF;

  -- 2. Open standings cursor
  OPEN v_cursor FOR
    SELECT t.team_id, 
           t.name, 
           COUNT(m.match_id) AS wins
    FROM TEAMS t
    LEFT JOIN MATCHES m ON t.team_id = m.winner_team_id 
                        AND m.tournament_id = p_tournament_id 
                        AND m.status = 'Completed'
    WHERE t.tournament_id = p_tournament_id
    GROUP BY t.team_id, t.name
    ORDER BY wins DESC;

  RETURN v_cursor;
END;
/

--------------------------------------------------------------------------------
-- 5. PROCEDURE: GENERATE_BRACKETS
-- Description: Counts distinct rounds scheduled in MATCHES for a tournament
--              and registers/updates the BRACKETS metadata table.
-- Parameters:
--   p_tournament_id: The ID of the tournament.
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE generate_brackets (
  p_tournament_id IN NUMBER
) IS
  v_tournament_exists NUMBER;
  v_round_count       NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Starting generate_brackets for tournament: ' || p_tournament_id);

  -- 1. Validate tournament
  SELECT COUNT(*) INTO v_tournament_exists FROM TOURNAMENTS WHERE tournament_id = p_tournament_id;
  IF v_tournament_exists = 0 THEN
    RAISE_APPLICATION_ERROR(-20010, 'Generate Brackets Failed: Tournament ID ' || p_tournament_id || ' does not exist.');
  END IF;

  -- 2. Count distinct rounds currently scheduled
  SELECT COUNT(DISTINCT round) INTO v_round_count 
  FROM MATCHES 
  WHERE tournament_id = p_tournament_id;

  -- 3. Upsert into BRACKETS
  MERGE INTO BRACKETS b
  USING (
    SELECT p_tournament_id AS tournament_id, 
           'Main Stage Bracket' AS name, 
           NVL(v_round_count, 0) AS round_count
    FROM DUAL
  ) src
  ON (b.tournament_id = src.tournament_id)
  WHEN MATCHED THEN
    UPDATE SET b.round_count = src.round_count
  WHEN NOT MATCHED THEN
    INSERT (tournament_id, name, round_count)
    VALUES (src.tournament_id, src.name, src.round_count);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Bracket updated. Tournament ID: ' || p_tournament_id || ', Round count: ' || v_round_count);

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Error in generate_brackets: ' || SQLERRM);
    RAISE;
END;
/
