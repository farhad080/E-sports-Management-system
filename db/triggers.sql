-- eSports Tournament Management System — Business Logic Triggers
-- Compatible with Oracle XE 21c

--------------------------------------------------------------------------------
-- 1. TRIGGER: TRG_PREVENT_DUPLICATE_TEAM
-- Description: Fires BEFORE INSERT on TEAMS to block the same team name from
--              being registered in the same tournament more than once.
--              The built-in UNIQUE constraint on TEAMS.name enforces global
--              uniqueness, but this trigger specifically prevents a team
--              (identified by captain_id + tournament_id combination) from
--              registering multiple entries under different names in the same
--              tournament.
-- Error Code:  -20050
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_prevent_duplicate_team
BEFORE INSERT ON TEAMS
FOR EACH ROW
DECLARE
  v_count NUMBER;
BEGIN
  -- Only validate when a tournament_id is supplied (team is being registered)
  IF :NEW.tournament_id IS NOT NULL THEN

    -- Check 1: Same captain already has a team in this tournament
    SELECT COUNT(*)
      INTO v_count
      FROM TEAMS
     WHERE captain_id     = :NEW.captain_id
       AND tournament_id  = :NEW.tournament_id;

    IF v_count > 0 THEN
      RAISE_APPLICATION_ERROR(
        -20050,
        'Duplicate Registration Denied: Captain ID ' || :NEW.captain_id ||
        ' already has a team registered in Tournament ID ' || :NEW.tournament_id || '.'
      );
    END IF;

    -- Check 2: A team with the exact same name is already in this tournament
    SELECT COUNT(*)
      INTO v_count
      FROM TEAMS
     WHERE UPPER(name)    = UPPER(:NEW.name)
       AND tournament_id  = :NEW.tournament_id;

    IF v_count > 0 THEN
      RAISE_APPLICATION_ERROR(
        -20051,
        'Duplicate Registration Denied: A team named "' || :NEW.name ||
        '" is already registered in Tournament ID ' || :NEW.tournament_id || '.'
      );
    END IF;

  END IF;
END;
/

--------------------------------------------------------------------------------
-- 2. TRIGGER: TRG_AUTO_CLOSE_TOURNAMENT
-- Description: Fires AFTER UPDATE on MATCHES.  Whenever a match is marked
--              'Completed' (winner declared), the trigger checks whether ALL
--              matches belonging to the same tournament now have a winner.
--              If so, it automatically sets the tournament status to 'Completed'.
-- Error Code:  N/A — purely automated status transition.
-- Note:        This trigger uses an autonomous transaction so it can issue its
--              own COMMIT without interfering with the calling DML statement.
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_auto_close_tournament
AFTER UPDATE OF status ON MATCHES
FOR EACH ROW
WHEN (NEW.status = 'Completed')
DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;

  v_total_matches     NUMBER;
  v_completed_matches NUMBER;
  v_current_status    VARCHAR2(20);
BEGIN
  -- 1. Fetch the current tournament status to avoid redundant updates
  BEGIN
    SELECT status
      INTO v_current_status
      FROM TOURNAMENTS
     WHERE tournament_id = :NEW.tournament_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- Tournament deleted in the meantime; silently exit
      RETURN;
  END;

  -- If already completed, nothing to do
  IF v_current_status = 'Completed' THEN
    RETURN;
  END IF;

  -- 2. Count total and completed matches for this tournament
  SELECT COUNT(*),
         COUNT(winner_team_id)
    INTO v_total_matches,
         v_completed_matches
    FROM MATCHES
   WHERE tournament_id = :NEW.tournament_id;

  -- 3. If every match has a winner, close the tournament
  IF v_total_matches > 0 AND v_total_matches = v_completed_matches THEN
    UPDATE TOURNAMENTS
       SET status = 'Completed'
     WHERE tournament_id = :NEW.tournament_id;

    DBMS_OUTPUT.PUT_LINE(
      'Tournament ID ' || :NEW.tournament_id ||
      ' automatically set to Completed — all ' || v_total_matches || ' matches resolved.'
    );
  END IF;

  COMMIT;
END;
/
