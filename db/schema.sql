-- eSports Tournament Management System Database Schema Setup Script
-- Compatible with Oracle XE 21c
-- Set echo on to trace execution

-- Clean up existing database objects in proper dependency order
DECLARE
  PROCEDURE drop_object(p_type VARCHAR2, p_name VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE 'DROP ' || p_type || ' ' || p_name;
  EXCEPTION
    WHEN OTHERS THEN
      -- Ignore if object does not exist (e.g., ORA-00942, ORA-02289)
      NULL;
  END;
BEGIN
  -- Drop Triggers
  drop_object('TRIGGER', 'USERS_BI_TRG');
  drop_object('TRIGGER', 'GAMES_BI_TRG');
  drop_object('TRIGGER', 'TOURNAMENTS_BI_TRG');
  drop_object('TRIGGER', 'TEAMS_BI_TRG');
  drop_object('TRIGGER', 'TEAM_MEMBERS_BI_TRG');
  drop_object('TRIGGER', 'MATCHES_BI_TRG');
  drop_object('TRIGGER', 'MATCH_TEAMS_BI_TRG');
  drop_object('TRIGGER', 'BRACKETS_BI_TRG');

  -- Drop Tables (with CASCADE CONSTRAINTS to clear relations)
  drop_object('TABLE', 'BRACKETS CASCADE CONSTRAINTS');
  drop_object('TABLE', 'MATCH_TEAMS CASCADE CONSTRAINTS');
  drop_object('TABLE', 'MATCHES CASCADE CONSTRAINTS');
  drop_object('TABLE', 'TEAM_MEMBERS CASCADE CONSTRAINTS');
  drop_object('TABLE', 'TEAMS CASCADE CONSTRAINTS');
  drop_object('TABLE', 'TOURNAMENTS CASCADE CONSTRAINTS');
  drop_object('TABLE', 'GAMES CASCADE CONSTRAINTS');
  drop_object('TABLE', 'USERS CASCADE CONSTRAINTS');

  -- Drop Sequences
  drop_object('SEQUENCE', 'USERS_SEQ');
  drop_object('SEQUENCE', 'GAMES_SEQ');
  drop_object('SEQUENCE', 'TOURNAMENTS_SEQ');
  drop_object('SEQUENCE', 'TEAMS_SEQ');
  drop_object('SEQUENCE', 'TEAM_MEMBERS_SEQ');
  drop_object('SEQUENCE', 'MATCHES_SEQ');
  drop_object('SEQUENCE', 'MATCH_TEAMS_SEQ');
  drop_object('SEQUENCE', 'BRACKETS_SEQ');
END;
/

--------------------------------------------------------
--  CREATE SEQUENCES FOR AUTO-INCREMENT KEYS
--------------------------------------------------------
CREATE SEQUENCE USERS_SEQ START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE GAMES_SEQ START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE TOURNAMENTS_SEQ START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE TEAMS_SEQ START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE TEAM_MEMBERS_SEQ START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE MATCHES_SEQ START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE MATCH_TEAMS_SEQ START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE BRACKETS_SEQ START WITH 1 INCREMENT BY 1 NOCACHE;

--------------------------------------------------------
--  CREATE TABLE: USERS
--------------------------------------------------------
CREATE TABLE USERS (
  user_id NUMBER NOT NULL,
  username VARCHAR2(50) NOT NULL,
  email VARCHAR2(100) NOT NULL,
  password VARCHAR2(255) NOT NULL,
  role VARCHAR2(20) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT users_pk PRIMARY KEY (user_id),
  CONSTRAINT users_email_uq UNIQUE (email),
  CONSTRAINT users_role_ck CHECK (role IN ('Player', 'Team Captain', 'Admin'))
);

--------------------------------------------------------
--  CREATE TABLE: GAMES
--------------------------------------------------------
CREATE TABLE GAMES (
  game_id NUMBER NOT NULL,
  name VARCHAR2(100) NOT NULL,
  genre VARCHAR2(50),
  platform VARCHAR2(50),
  CONSTRAINT games_pk PRIMARY KEY (game_id),
  CONSTRAINT games_name_uq UNIQUE (name)
);

--------------------------------------------------------
--  CREATE TABLE: TOURNAMENTS
--------------------------------------------------------
CREATE TABLE TOURNAMENTS (
  tournament_id NUMBER NOT NULL,
  name VARCHAR2(100) NOT NULL,
  game_id NUMBER NOT NULL,
  description VARCHAR2(1000),
  start_date DATE,
  end_date DATE,
  status VARCHAR2(20) NOT NULL,
  prize_pool VARCHAR2(50),
  max_teams NUMBER NOT NULL,
  CONSTRAINT tournaments_pk PRIMARY KEY (tournament_id),
  CONSTRAINT tournaments_game_fk FOREIGN KEY (game_id) REFERENCES GAMES(game_id) ON DELETE CASCADE,
  CONSTRAINT tournaments_status_ck CHECK (status IN ('Upcoming', 'Ongoing', 'Completed')),
  CONSTRAINT tournaments_max_teams_ck CHECK (max_teams > 0)
);

--------------------------------------------------------
--  CREATE TABLE: TEAMS
--------------------------------------------------------
CREATE TABLE TEAMS (
  team_id NUMBER NOT NULL,
  name VARCHAR2(100) NOT NULL,
  captain_id NUMBER,
  game_id NUMBER NOT NULL,
  tournament_id NUMBER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT teams_pk PRIMARY KEY (team_id),
  CONSTRAINT teams_name_uq UNIQUE (name),
  CONSTRAINT teams_captain_fk FOREIGN KEY (captain_id) REFERENCES USERS(user_id) ON DELETE SET NULL,
  CONSTRAINT teams_game_fk FOREIGN KEY (game_id) REFERENCES GAMES(game_id) ON DELETE CASCADE,
  CONSTRAINT teams_tournament_fk FOREIGN KEY (tournament_id) REFERENCES TOURNAMENTS(tournament_id) ON DELETE CASCADE
);

--------------------------------------------------------
--  CREATE TABLE: TEAM_MEMBERS
--------------------------------------------------------
CREATE TABLE TEAM_MEMBERS (
  member_id NUMBER NOT NULL,
  team_id NUMBER NOT NULL,
  user_id NUMBER NOT NULL,
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT team_members_pk PRIMARY KEY (member_id),
  CONSTRAINT team_members_team_fk FOREIGN KEY (team_id) REFERENCES TEAMS(team_id) ON DELETE CASCADE,
  CONSTRAINT team_members_user_fk FOREIGN KEY (user_id) REFERENCES USERS(user_id) ON DELETE CASCADE,
  CONSTRAINT team_members_uq UNIQUE (team_id, user_id)
);

--------------------------------------------------------
--  CREATE TABLE: MATCHES
--------------------------------------------------------
CREATE TABLE MATCHES (
  match_id NUMBER NOT NULL,
  tournament_id NUMBER NOT NULL,
  round VARCHAR2(50),
  match_date TIMESTAMP,
  winner_team_id NUMBER,
  status VARCHAR2(20) NOT NULL,
  CONSTRAINT matches_pk PRIMARY KEY (match_id),
  CONSTRAINT matches_tournament_fk FOREIGN KEY (tournament_id) REFERENCES TOURNAMENTS(tournament_id) ON DELETE CASCADE,
  CONSTRAINT matches_winner_fk FOREIGN KEY (winner_team_id) REFERENCES TEAMS(team_id) ON DELETE SET NULL,
  CONSTRAINT matches_status_ck CHECK (status IN ('Upcoming', 'Ongoing', 'Completed'))
);

--------------------------------------------------------
--  CREATE TABLE: MATCH_TEAMS
--------------------------------------------------------
CREATE TABLE MATCH_TEAMS (
  match_team_id NUMBER NOT NULL,
  match_id NUMBER NOT NULL,
  team_id NUMBER NOT NULL,
  score NUMBER,
  CONSTRAINT match_teams_pk PRIMARY KEY (match_team_id),
  CONSTRAINT match_teams_match_fk FOREIGN KEY (match_id) REFERENCES MATCHES(match_id) ON DELETE CASCADE,
  CONSTRAINT match_teams_team_fk FOREIGN KEY (team_id) REFERENCES TEAMS(team_id) ON DELETE CASCADE,
  CONSTRAINT match_teams_score_ck CHECK (score >= 0),
  CONSTRAINT match_teams_uq UNIQUE (match_id, team_id)
);

--------------------------------------------------------
--  CREATE TABLE: BRACKETS
--------------------------------------------------------
CREATE TABLE BRACKETS (
  bracket_id NUMBER NOT NULL,
  tournament_id NUMBER NOT NULL,
  name VARCHAR2(100),
  round_count NUMBER NOT NULL,
  CONSTRAINT brackets_pk PRIMARY KEY (bracket_id),
  CONSTRAINT brackets_tournament_fk FOREIGN KEY (tournament_id) REFERENCES TOURNAMENTS(tournament_id) ON DELETE CASCADE
);

--------------------------------------------------------
--  BEFORE INSERT TRIGGERS FOR AUTO-INCREMENT PKs
--------------------------------------------------------
CREATE OR REPLACE TRIGGER USERS_BI_TRG
BEFORE INSERT ON USERS
FOR EACH ROW
BEGIN
  IF :NEW.user_id IS NULL THEN
    SELECT USERS_SEQ.NEXTVAL INTO :NEW.user_id FROM DUAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER GAMES_BI_TRG
BEFORE INSERT ON GAMES
FOR EACH ROW
BEGIN
  IF :NEW.game_id IS NULL THEN
    SELECT GAMES_SEQ.NEXTVAL INTO :NEW.game_id FROM DUAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER TOURNAMENTS_BI_TRG
BEFORE INSERT ON TOURNAMENTS
FOR EACH ROW
BEGIN
  IF :NEW.tournament_id IS NULL THEN
    SELECT TOURNAMENTS_SEQ.NEXTVAL INTO :NEW.tournament_id FROM DUAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER TEAMS_BI_TRG
BEFORE INSERT ON TEAMS
FOR EACH ROW
BEGIN
  IF :NEW.team_id IS NULL THEN
    SELECT TEAMS_SEQ.NEXTVAL INTO :NEW.team_id FROM DUAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER TEAM_MEMBERS_BI_TRG
BEFORE INSERT ON TEAM_MEMBERS
FOR EACH ROW
BEGIN
  IF :NEW.member_id IS NULL THEN
    SELECT TEAM_MEMBERS_SEQ.NEXTVAL INTO :NEW.member_id FROM DUAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER MATCHES_BI_TRG
BEFORE INSERT ON MATCHES
FOR EACH ROW
BEGIN
  IF :NEW.match_id IS NULL THEN
    SELECT MATCHES_SEQ.NEXTVAL INTO :NEW.match_id FROM DUAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER MATCH_TEAMS_BI_TRG
BEFORE INSERT ON MATCH_TEAMS
FOR EACH ROW
BEGIN
  IF :NEW.match_team_id IS NULL THEN
    SELECT MATCH_TEAMS_SEQ.NEXTVAL INTO :NEW.match_team_id FROM DUAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER BRACKETS_BI_TRG
BEFORE INSERT ON BRACKETS
FOR EACH ROW
BEGIN
  IF :NEW.bracket_id IS NULL THEN
    SELECT BRACKETS_SEQ.NEXTVAL INTO :NEW.bracket_id FROM DUAL;
  END IF;
END;
/

--------------------------------------------------------
--  DATABASE COMMENTS FOR ALL TABLES & COLUMNS
--------------------------------------------------------
COMMENT ON TABLE USERS IS 'Stores account credentials, emails, and roles for players, captains, and admins.';
COMMENT ON COLUMN USERS.user_id IS 'Unique identifier for the user (Primary Key).';
COMMENT ON COLUMN USERS.username IS 'Display handle or gamertag of the user.';
COMMENT ON COLUMN USERS.email IS 'Email address of the user (must be unique).';
COMMENT ON COLUMN USERS.password IS 'Bcrypt hashed password of the user account.';
COMMENT ON COLUMN USERS.role IS 'Account classification (Player, Team Captain, Admin).';
COMMENT ON COLUMN USERS.created_at IS 'Timestamp of when the user account was registered.';

COMMENT ON TABLE GAMES IS 'Maintains list of competitive game titles supported by the tournament platform.';
COMMENT ON COLUMN GAMES.game_id IS 'Unique identifier for the game title (Primary Key).';
COMMENT ON COLUMN GAMES.name IS 'Name of the eSports title (e.g., CS2, Valorant).';
COMMENT ON COLUMN GAMES.genre IS 'Genre classification (e.g., FPS, Battle Royale, Sports).';
COMMENT ON COLUMN GAMES.platform IS 'Console or platform the game runs on (e.g., PC, Mobile).';

COMMENT ON TABLE TOURNAMENTS IS 'Stores competition details including status, dates, and max participant teams.';
COMMENT ON COLUMN TOURNAMENTS.tournament_id IS 'Unique identifier for the tournament (Primary Key).';
COMMENT ON COLUMN TOURNAMENTS.name IS 'Title of the tournament competition.';
COMMENT ON COLUMN TOURNAMENTS.game_id IS 'Reference to the game being played (Foreign Key).';
COMMENT ON COLUMN TOURNAMENTS.description IS 'Detailed information regarding tournament rules and schedule.';
COMMENT ON COLUMN TOURNAMENTS.start_date IS 'Scheduled start date of the tournament.';
COMMENT ON COLUMN TOURNAMENTS.end_date IS 'Scheduled end date of the tournament.';
COMMENT ON COLUMN TOURNAMENTS.status IS 'Current status of the tournament (Upcoming, Ongoing, Completed).';
COMMENT ON COLUMN TOURNAMENTS.prize_pool IS 'Total financial or reward prize pool.';
COMMENT ON COLUMN TOURNAMENTS.max_teams IS 'Maximum capacity of team entries allowed.';

COMMENT ON TABLE TEAMS IS 'Represents registered competition squads linked to a captain and game.';
COMMENT ON COLUMN TEAMS.team_id IS 'Unique identifier for the squad (Primary Key).';
COMMENT ON COLUMN TEAMS.name IS 'Official name of the eSports squad.';
COMMENT ON COLUMN TEAMS.captain_id IS 'Reference to the Team Captain user (Foreign Key).';
COMMENT ON COLUMN TEAMS.game_id IS 'Reference to the game the team competes in (Foreign Key).';
COMMENT ON COLUMN TEAMS.tournament_id IS 'Reference to the tournament the team is registered in (Foreign Key).';
COMMENT ON COLUMN TEAMS.created_at IS 'Timestamp of team profile creation.';

COMMENT ON TABLE TEAM_MEMBERS IS 'Roster mapping linking players to their registered squads.';
COMMENT ON COLUMN TEAM_MEMBERS.member_id IS 'Unique identifier for the roster entry (Primary Key).';
COMMENT ON COLUMN TEAM_MEMBERS.team_id IS 'Reference to the team (Foreign Key).';
COMMENT ON COLUMN TEAM_MEMBERS.user_id IS 'Reference to the player user (Foreign Key).';
COMMENT ON COLUMN TEAM_MEMBERS.joined_at IS 'Timestamp of when player joined the squad.';

COMMENT ON TABLE MATCHES IS 'Individual rounds and fixtures generated inside tournaments.';
COMMENT ON COLUMN MATCHES.match_id IS 'Unique identifier for the match fixture (Primary Key).';
COMMENT ON COLUMN MATCHES.tournament_id IS 'Reference to the parent tournament (Foreign Key).';
COMMENT ON COLUMN MATCHES.round IS 'Stage identifier (e.g., Round of 16, Quarter-Finals, Finals).';
COMMENT ON COLUMN MATCHES.match_date IS 'Scheduled date and time of the match.';
COMMENT ON COLUMN MATCHES.winner_team_id IS 'Reference to the team that won the match (Foreign Key).';
COMMENT ON COLUMN MATCHES.status IS 'Match progress indicator (Upcoming, Ongoing, Completed).';

COMMENT ON TABLE MATCH_TEAMS IS 'Junction table linking competing squads to fixtures and tracking scores.';
COMMENT ON COLUMN MATCH_TEAMS.match_team_id IS 'Unique identifier for match team entry (Primary Key).';
COMMENT ON COLUMN MATCH_TEAMS.match_id IS 'Reference to the match fixture (Foreign Key).';
COMMENT ON COLUMN MATCH_TEAMS.team_id IS 'Reference to the participating team (Foreign Key).';
COMMENT ON COLUMN MATCH_TEAMS.score IS 'Total points or rounds won by this team in this fixture.';

COMMENT ON TABLE BRACKETS IS 'Bracket management configuration details for tournament layouts.';
COMMENT ON COLUMN BRACKETS.bracket_id IS 'Unique identifier for the bracket (Primary Key).';
COMMENT ON COLUMN BRACKETS.tournament_id IS 'Reference to the tournament (Foreign Key).';
COMMENT ON COLUMN BRACKETS.name IS 'Name identifier of the bracket (e.g., Upper Bracket).';
COMMENT ON COLUMN BRACKETS.round_count IS 'Total number of rounds in this bracket.';
