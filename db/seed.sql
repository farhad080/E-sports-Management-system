-- eSports Tournament Management System — Seed Data
-- Compatible with Oracle XE 21c
-- Prerequisites: Run schema.sql, procedures.sql, triggers.sql, views.sql, indexes.sql first.
-- Assumes fresh sequences starting at 1 (schema.sql resets them).

SET SERVEROUTPUT ON;
SET DEFINE OFF;

--------------------------------------------------------
--  SEED: USERS (13 rows)
--  1 Admin  |  3 Team Captains  |  9 Players
--  Password: bcrypt placeholder hash for 'Password123!'
--------------------------------------------------------
INSERT INTO USERS (user_id, username, email, password, role)
VALUES (USERS_SEQ.NEXTVAL, 'nexus_admin', 'admin@nexusesports.gg',
        '$2b$10$xV8dK3rZqJ5mN1pL0wYhUeRtAsFgHjKlQzXcVbNm9oIuYtRwEqDpS', 'Admin');

INSERT INTO USERS (user_id, username, email, password, role)
VALUES (USERS_SEQ.NEXTVAL, 'captain_phoenix', 'phoenix.lead@nexusesports.gg',
        '$2b$10$xV8dK3rZqJ5mN1pL0wYhUeRtAsFgHjKlQzXcVbNm9oIuYtRwEqDpS', 'Team Captain');

INSERT INTO USERS (user_id, username, email, password, role)
VALUES (USERS_SEQ.NEXTVAL, 'captain_shadow', 'shadow.lead@nexusesports.gg',
        '$2b$10$xV8dK3rZqJ5mN1pL0wYhUeRtAsFgHjKlQzXcVbNm9oIuYtRwEqDpS', 'Team Captain');

INSERT INTO USERS (user_id, username, email, password, role)
VALUES (USERS_SEQ.NEXTVAL, 'captain_storm', 'storm.lead@nexusesports.gg',
        '$2b$10$xV8dK3rZqJ5mN1pL0wYhUeRtAsFgHjKlQzXcVbNm9oIuYtRwEqDpS', 'Team Captain');

INSERT INTO USERS (user_id, username, email, password, role)
VALUES (USERS_SEQ.NEXTVAL, 'xDragonSlayer', 'dragon.slayer@gmail.com',
        '$2b$10$xV8dK3rZqJ5mN1pL0wYhUeRtAsFgHjKlQzXcVbNm9oIuYtRwEqDpS', 'Player');

INSERT INTO USERS (user_id, username, email, password, role)
VALUES (USERS_SEQ.NEXTVAL, 'NightHawk_99', 'nighthawk99@gmail.com',
        '$2b$10$xV8dK3rZqJ5mN1pL0wYhUeRtAsFgHjKlQzXcVbNm9oIuYtRwEqDpS', 'Player');

INSERT INTO USERS (user_id, username, email, password, role)
VALUES (USERS_SEQ.NEXTVAL, 'CyberWolf', 'cyberwolf.pro@gmail.com',
        '$2b$10$xV8dK3rZqJ5mN1pL0wYhUeRtAsFgHjKlQzXcVbNm9oIuYtRwEqDpS', 'Player');

INSERT INTO USERS (user_id, username, email, password, role)
VALUES (USERS_SEQ.NEXTVAL, 'BlazeMaster', 'blazemaster@outlook.com',
        '$2b$10$xV8dK3rZqJ5mN1pL0wYhUeRtAsFgHjKlQzXcVbNm9oIuYtRwEqDpS', 'Player');

INSERT INTO USERS (user_id, username, email, password, role)
VALUES (USERS_SEQ.NEXTVAL, 'SilentStrike', 'silent.strike@yahoo.com',
        '$2b$10$xV8dK3rZqJ5mN1pL0wYhUeRtAsFgHjKlQzXcVbNm9oIuYtRwEqDpS', 'Player');

INSERT INTO USERS (user_id, username, email, password, role)
VALUES (USERS_SEQ.NEXTVAL, 'VenomX', 'venomx.gg@gmail.com',
        '$2b$10$xV8dK3rZqJ5mN1pL0wYhUeRtAsFgHjKlQzXcVbNm9oIuYtRwEqDpS', 'Player');

INSERT INTO USERS (user_id, username, email, password, role)
VALUES (USERS_SEQ.NEXTVAL, 'ThunderBolt', 'thunderbolt@outlook.com',
        '$2b$10$xV8dK3rZqJ5mN1pL0wYhUeRtAsFgHjKlQzXcVbNm9oIuYtRwEqDpS', 'Player');

INSERT INTO USERS (user_id, username, email, password, role)
VALUES (USERS_SEQ.NEXTVAL, 'IceBreaker', 'icebreaker.fps@gmail.com',
        '$2b$10$xV8dK3rZqJ5mN1pL0wYhUeRtAsFgHjKlQzXcVbNm9oIuYtRwEqDpS', 'Player');

INSERT INTO USERS (user_id, username, email, password, role)
VALUES (USERS_SEQ.NEXTVAL, 'ShadowFury', 'shadowfury.x@gmail.com',
        '$2b$10$xV8dK3rZqJ5mN1pL0wYhUeRtAsFgHjKlQzXcVbNm9oIuYtRwEqDpS', 'Player');

-- User IDs assigned: 1=Admin, 2-4=Captains, 5-13=Players

--------------------------------------------------------
--  SEED: GAMES (5 rows)
--------------------------------------------------------
INSERT INTO GAMES (game_id, name, genre, platform)
VALUES (GAMES_SEQ.NEXTVAL, 'Valorant', 'FPS', 'PC');

INSERT INTO GAMES (game_id, name, genre, platform)
VALUES (GAMES_SEQ.NEXTVAL, 'PUBG', 'Battle Royale', 'PC, Mobile');

INSERT INTO GAMES (game_id, name, genre, platform)
VALUES (GAMES_SEQ.NEXTVAL, 'Free Fire', 'Battle Royale', 'Mobile');

INSERT INTO GAMES (game_id, name, genre, platform)
VALUES (GAMES_SEQ.NEXTVAL, 'FIFA', 'Sports', 'PC, Console');

INSERT INTO GAMES (game_id, name, genre, platform)
VALUES (GAMES_SEQ.NEXTVAL, 'CS2', 'FPS', 'PC');

-- Game IDs assigned: 1=Valorant, 2=PUBG, 3=Free Fire, 4=FIFA, 5=CS2

--------------------------------------------------------
--  SEED: TOURNAMENTS (3 rows)
--  Tournament 1: Upcoming (Valorant)
--  Tournament 2: Ongoing  (PUBG)
--  Tournament 3: Completed (CS2)
--------------------------------------------------------
INSERT INTO TOURNAMENTS (tournament_id, name, game_id, description, start_date, end_date, status, prize_pool, max_teams)
VALUES (TOURNAMENTS_SEQ.NEXTVAL, 'Valorant Champions Cup 2026', 1,
        'The premier Valorant tournament of the year featuring top teams from across the region competing for glory and a massive prize pool.',
        TO_DATE('2026-08-15', 'YYYY-MM-DD'), TO_DATE('2026-08-25', 'YYYY-MM-DD'),
        'Upcoming', '$50,000', 8);

INSERT INTO TOURNAMENTS (tournament_id, name, game_id, description, start_date, end_date, status, prize_pool, max_teams)
VALUES (TOURNAMENTS_SEQ.NEXTVAL, 'PUBG Global Invitational', 2,
        'An intense battle royale showdown where elite squads fight for survival and the championship title across multiple maps.',
        TO_DATE('2026-06-20', 'YYYY-MM-DD'), TO_DATE('2026-07-15', 'YYYY-MM-DD'),
        'Ongoing', '$30,000', 6);

INSERT INTO TOURNAMENTS (tournament_id, name, game_id, description, start_date, end_date, status, prize_pool, max_teams)
VALUES (TOURNAMENTS_SEQ.NEXTVAL, 'CS2 Major Championship', 5,
        'The concluded CS2 Major featuring world-class Counter-Strike competition. Natus Vincere claimed the championship after a thrilling Grand Final.',
        TO_DATE('2026-05-01', 'YYYY-MM-DD'), TO_DATE('2026-05-20', 'YYYY-MM-DD'),
        'Completed', '$100,000', 8);

-- Tournament IDs: 1=Valorant Upcoming, 2=PUBG Ongoing, 3=CS2 Completed

--------------------------------------------------------
--  SEED: TEAMS (8 rows)
--  Tournament 1 (Upcoming):  2 teams  — captains 2, 3
--  Tournament 2 (Ongoing):   2 teams  — captains 4, 2
--  Tournament 3 (Completed): 4 teams  — captains 3, 4, 2, 5
--  Each captain appears at most ONCE per tournament (satisfies trg_prevent_duplicate_team)
--------------------------------------------------------
-- Tournament 1 teams (Valorant)
INSERT INTO TEAMS (team_id, name, captain_id, game_id, tournament_id)
VALUES (TEAMS_SEQ.NEXTVAL, 'Phoenix Rising', 2, 1, 1);

INSERT INTO TEAMS (team_id, name, captain_id, game_id, tournament_id)
VALUES (TEAMS_SEQ.NEXTVAL, 'Shadow Sentinels', 3, 1, 1);

-- Tournament 2 teams (PUBG)
INSERT INTO TEAMS (team_id, name, captain_id, game_id, tournament_id)
VALUES (TEAMS_SEQ.NEXTVAL, 'Storm Predators', 4, 2, 2);

INSERT INTO TEAMS (team_id, name, captain_id, game_id, tournament_id)
VALUES (TEAMS_SEQ.NEXTVAL, 'Apex Warzone', 2, 2, 2);

-- Tournament 3 teams (CS2 — Completed)
INSERT INTO TEAMS (team_id, name, captain_id, game_id, tournament_id)
VALUES (TEAMS_SEQ.NEXTVAL, 'Natus Vincere', 3, 5, 3);

INSERT INTO TEAMS (team_id, name, captain_id, game_id, tournament_id)
VALUES (TEAMS_SEQ.NEXTVAL, 'FaZe Clan', 4, 5, 3);

INSERT INTO TEAMS (team_id, name, captain_id, game_id, tournament_id)
VALUES (TEAMS_SEQ.NEXTVAL, 'Cloud9 Elite', 2, 5, 3);

INSERT INTO TEAMS (team_id, name, captain_id, game_id, tournament_id)
VALUES (TEAMS_SEQ.NEXTVAL, 'Team Vitality', 5, 5, 3);

-- Team IDs: 1=Phoenix Rising, 2=Shadow Sentinels, 3=Storm Predators,
--           4=Apex Warzone, 5=Natus Vincere, 6=FaZe Clan,
--           7=Cloud9 Elite, 8=Team Vitality

--------------------------------------------------------
--  SEED: TEAM_MEMBERS (24 rows — 3 per team)
--  Each row: captain + 2 players
--  Constraint: UNIQUE(team_id, user_id) — no duplicates within same team
--------------------------------------------------------
-- Team 1: Phoenix Rising (captain=2)
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 1, 2);
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 1, 5);
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 1, 6);

-- Team 2: Shadow Sentinels (captain=3)
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 2, 3);
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 2, 7);
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 2, 8);

-- Team 3: Storm Predators (captain=4)
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 3, 4);
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 3, 9);
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 3, 10);

-- Team 4: Apex Warzone (captain=2)
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 4, 2);
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 4, 11);
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 4, 12);

-- Team 5: Natus Vincere (captain=3)
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 5, 3);
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 5, 5);
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 5, 13);

-- Team 6: FaZe Clan (captain=4)
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 6, 4);
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 6, 6);
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 6, 7);

-- Team 7: Cloud9 Elite (captain=2)
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 7, 2);
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 7, 8);
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 7, 9);

-- Team 8: Team Vitality (captain=5)
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 8, 5);
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 8, 10);
INSERT INTO TEAM_MEMBERS (member_id, team_id, user_id) VALUES (TEAM_MEMBERS_SEQ.NEXTVAL, 8, 11);

--------------------------------------------------------
--  SEED: MATCHES (7 rows — all for Tournament 3: CS2 Major)
--  Format: Group Stage round-robin (6 matches) + Grand Final (1 match)
--  All matches Completed with winners declared
--
--  Group Stage Results:
--    NaVi (5):    3 wins  — beat FaZe, Cloud9, Vitality
--    Cloud9 (7):  2 wins  — beat FaZe, Vitality
--    FaZe (6):    1 win   — beat Vitality
--    Vitality (8): 0 wins
--
--  Grand Final: NaVi vs Cloud9 → NaVi wins (Champions!)
--------------------------------------------------------
-- Group Stage — Round 1
INSERT INTO MATCHES (match_id, tournament_id, round, match_date, winner_team_id, status)
VALUES (MATCHES_SEQ.NEXTVAL, 3, 'Group Stage', TIMESTAMP '2026-05-02 14:00:00', 5, 'Completed');

INSERT INTO MATCHES (match_id, tournament_id, round, match_date, winner_team_id, status)
VALUES (MATCHES_SEQ.NEXTVAL, 3, 'Group Stage', TIMESTAMP '2026-05-03 16:00:00', 7, 'Completed');

-- Group Stage — Round 2
INSERT INTO MATCHES (match_id, tournament_id, round, match_date, winner_team_id, status)
VALUES (MATCHES_SEQ.NEXTVAL, 3, 'Group Stage', TIMESTAMP '2026-05-06 14:00:00', 5, 'Completed');

INSERT INTO MATCHES (match_id, tournament_id, round, match_date, winner_team_id, status)
VALUES (MATCHES_SEQ.NEXTVAL, 3, 'Group Stage', TIMESTAMP '2026-05-07 16:00:00', 6, 'Completed');

-- Group Stage — Round 3
INSERT INTO MATCHES (match_id, tournament_id, round, match_date, winner_team_id, status)
VALUES (MATCHES_SEQ.NEXTVAL, 3, 'Group Stage', TIMESTAMP '2026-05-10 14:00:00', 5, 'Completed');

INSERT INTO MATCHES (match_id, tournament_id, round, match_date, winner_team_id, status)
VALUES (MATCHES_SEQ.NEXTVAL, 3, 'Group Stage', TIMESTAMP '2026-05-11 16:00:00', 7, 'Completed');

-- Grand Final
INSERT INTO MATCHES (match_id, tournament_id, round, match_date, winner_team_id, status)
VALUES (MATCHES_SEQ.NEXTVAL, 3, 'Grand Final', TIMESTAMP '2026-05-18 18:00:00', 5, 'Completed');

-- Match IDs: 1-6=Group Stage, 7=Grand Final

--------------------------------------------------------
--  SEED: MATCH_TEAMS (14 rows — 2 per match)
--  Realistic CS2 round scores (first to 13/16)
--------------------------------------------------------
-- Match 1: NaVi (5) 13 vs FaZe (6) 8
INSERT INTO MATCH_TEAMS (match_team_id, match_id, team_id, score) VALUES (MATCH_TEAMS_SEQ.NEXTVAL, 1, 5, 13);
INSERT INTO MATCH_TEAMS (match_team_id, match_id, team_id, score) VALUES (MATCH_TEAMS_SEQ.NEXTVAL, 1, 6, 8);

-- Match 2: Cloud9 (7) 13 vs Vitality (8) 10
INSERT INTO MATCH_TEAMS (match_team_id, match_id, team_id, score) VALUES (MATCH_TEAMS_SEQ.NEXTVAL, 2, 7, 13);
INSERT INTO MATCH_TEAMS (match_team_id, match_id, team_id, score) VALUES (MATCH_TEAMS_SEQ.NEXTVAL, 2, 8, 10);

-- Match 3: NaVi (5) 16 vs Cloud9 (7) 14  (overtime thriller!)
INSERT INTO MATCH_TEAMS (match_team_id, match_id, team_id, score) VALUES (MATCH_TEAMS_SEQ.NEXTVAL, 3, 5, 16);
INSERT INTO MATCH_TEAMS (match_team_id, match_id, team_id, score) VALUES (MATCH_TEAMS_SEQ.NEXTVAL, 3, 7, 14);

-- Match 4: FaZe (6) 13 vs Vitality (8) 7
INSERT INTO MATCH_TEAMS (match_team_id, match_id, team_id, score) VALUES (MATCH_TEAMS_SEQ.NEXTVAL, 4, 6, 13);
INSERT INTO MATCH_TEAMS (match_team_id, match_id, team_id, score) VALUES (MATCH_TEAMS_SEQ.NEXTVAL, 4, 8, 7);

-- Match 5: NaVi (5) 13 vs Vitality (8) 5
INSERT INTO MATCH_TEAMS (match_team_id, match_id, team_id, score) VALUES (MATCH_TEAMS_SEQ.NEXTVAL, 5, 5, 13);
INSERT INTO MATCH_TEAMS (match_team_id, match_id, team_id, score) VALUES (MATCH_TEAMS_SEQ.NEXTVAL, 5, 8, 5);

-- Match 6: Cloud9 (7) 13 vs FaZe (6) 9
INSERT INTO MATCH_TEAMS (match_team_id, match_id, team_id, score) VALUES (MATCH_TEAMS_SEQ.NEXTVAL, 6, 7, 13);
INSERT INTO MATCH_TEAMS (match_team_id, match_id, team_id, score) VALUES (MATCH_TEAMS_SEQ.NEXTVAL, 6, 6, 9);

-- Match 7 Grand Final: NaVi (5) 16 vs Cloud9 (7) 12
INSERT INTO MATCH_TEAMS (match_team_id, match_id, team_id, score) VALUES (MATCH_TEAMS_SEQ.NEXTVAL, 7, 5, 16);
INSERT INTO MATCH_TEAMS (match_team_id, match_id, team_id, score) VALUES (MATCH_TEAMS_SEQ.NEXTVAL, 7, 7, 12);

--------------------------------------------------------
--  SEED: BRACKETS (1 row — Completed tournament)
--  2 rounds: Group Stage + Grand Final
--------------------------------------------------------
INSERT INTO BRACKETS (bracket_id, tournament_id, name, round_count)
VALUES (BRACKETS_SEQ.NEXTVAL, 3, 'Main Stage Bracket', 2);

--------------------------------------------------------
--  COMMIT & VERIFICATION
--------------------------------------------------------
COMMIT;

DBMS_OUTPUT.PUT_LINE('=== Seed Data Loaded Successfully ===');
DBMS_OUTPUT.PUT_LINE('Users:        ' || (SELECT COUNT(*) FROM USERS));
DBMS_OUTPUT.PUT_LINE('Games:        ' || (SELECT COUNT(*) FROM GAMES));
DBMS_OUTPUT.PUT_LINE('Tournaments:  ' || (SELECT COUNT(*) FROM TOURNAMENTS));
DBMS_OUTPUT.PUT_LINE('Teams:        ' || (SELECT COUNT(*) FROM TEAMS));
DBMS_OUTPUT.PUT_LINE('Team Members: ' || (SELECT COUNT(*) FROM TEAM_MEMBERS));
DBMS_OUTPUT.PUT_LINE('Matches:      ' || (SELECT COUNT(*) FROM MATCHES));
DBMS_OUTPUT.PUT_LINE('Match Teams:  ' || (SELECT COUNT(*) FROM MATCH_TEAMS));
DBMS_OUTPUT.PUT_LINE('Brackets:     ' || (SELECT COUNT(*) FROM BRACKETS));
/
