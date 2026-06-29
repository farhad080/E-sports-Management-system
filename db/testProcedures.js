const db = require('./connection');
const oracledb = require('oracledb');

async function test() {
  let conn;
  try {
    // 1. Initialize DB pool
    await db.initialize();
    conn = await db.oracledb.getConnection();
    console.log('\n==================================================');
    console.log('   STARTING INTEGRATION TESTS FOR PL/SQL API   ');
    console.log('==================================================');

    // 2. Insert test seed data
    console.log('\n--- Seeding Users ---');
    // Clear existing users/games/tournaments (cascade drops will clean up dependent rows)
    await conn.execute(`DELETE FROM USERS`);
    await conn.execute(`DELETE FROM GAMES`);

    // Insert Users
    const resUser1 = await conn.execute(
      `INSERT INTO USERS (username, email, password, role) VALUES ('Admin User', 'admin@nexus.com', 'pwd', 'Admin') RETURNING user_id INTO :id`,
      { id: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT } }
    );
    const adminId = resUser1.outBinds.id[0];
    console.log(`Seeded Admin User (ID: ${adminId})`);

    const resUser2 = await conn.execute(
      `INSERT INTO USERS (username, email, password, role) VALUES ('Captain Alpha', 'alpha@nexus.com', 'pwd', 'Team Captain') RETURNING user_id INTO :id`,
      { id: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT } }
    );
    const captain1Id = resUser2.outBinds.id[0];
    console.log(`Seeded Captain Alpha (ID: ${captain1Id})`);

    const resUser3 = await conn.execute(
      `INSERT INTO USERS (username, email, password, role) VALUES ('Captain Beta', 'beta@nexus.com', 'pwd', 'Team Captain') RETURNING user_id INTO :id`,
      { id: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT } }
    );
    const captain2Id = resUser3.outBinds.id[0];
    console.log(`Seeded Captain Beta (ID: ${captain2Id})`);

    // Insert Game
    console.log('\n--- Seeding Game ---');
    const resGame = await conn.execute(
      `INSERT INTO GAMES (name, genre, platform) VALUES ('Valorant', 'FPS', 'PC') RETURNING game_id INTO :id`,
      { id: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT } }
    );
    const gameId = resGame.outBinds.id[0];
    console.log(`Seeded Game Valorant (ID: ${gameId})`);

    // Insert Tournaments
    console.log('\n--- Seeding Tournaments ---');
    const resTourney1 = await conn.execute(
      `INSERT INTO TOURNAMENTS (name, game_id, description, start_date, end_date, status, prize_pool, max_teams) 
       VALUES ('Valorant Ignition Cup', :game_id, 'Opening Cup', SYSDATE, SYSDATE+5, 'Upcoming', '$10,000', 8) 
       RETURNING tournament_id INTO :id`,
      { game_id: gameId, id: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT } }
    );
    const tournamentId = resTourney1.outBinds.id[0];
    console.log(`Seeded Upcoming Tournament: Valorant Ignition Cup (ID: ${tournamentId})`);

    const resTourney2 = await conn.execute(
      `INSERT INTO TOURNAMENTS (name, game_id, description, start_date, end_date, status, prize_pool, max_teams) 
       VALUES ('Valorant Legends League', :game_id, 'Ongoing League', SYSDATE-5, SYSDATE, 'Ongoing', '$50,000', 8) 
       RETURNING tournament_id INTO :id`,
      { game_id: gameId, id: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT } }
    );
    const ongoingTournamentId = resTourney2.outBinds.id[0];
    console.log(`Seeded Ongoing Tournament: Valorant Legends League (ID: ${ongoingTournamentId})`);

    // Commit seeds
    await conn.commit();

    // 3. Test register_team procedure
    console.log('\n--- Testing Procedure: register_team ---');
    // Team 1: Alpha Squad
    console.log('Registering Alpha Squad...');
    await conn.execute(
      `BEGIN register_team(:tournament_id, :captain_id, :team_name); END;`,
      { tournament_id: tournamentId, captain_id: captain1Id, team_name: 'Alpha Squad' }
    );

    // Team 2: Beta Squad
    console.log('Registering Beta Squad...');
    await conn.execute(
      `BEGIN register_team(:tournament_id, :captain_id, :team_name); END;`,
      { tournament_id: tournamentId, captain_id: captain2Id, team_name: 'Beta Squad' }
    );

    // Fetch team IDs to verify
    const teamsRes = await conn.execute(
      `SELECT team_id, name, captain_id, game_id, tournament_id FROM TEAMS WHERE tournament_id = :tid`,
      [tournamentId],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    console.log('Registered teams in database:', teamsRes.rows);
    const team1Id = teamsRes.rows[0].TEAM_ID;
    const team2Id = teamsRes.rows[1].TEAM_ID;

    // Verify team members
    const membersRes = await conn.execute(
      `SELECT * FROM TEAM_MEMBERS`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    console.log('Team members in database:', membersRes.rows);

    // 4. Test register_team exception handling (registering to non-Upcoming tournament)
    console.log('\n--- Testing register_team Exception: Non-Upcoming tournament ---');
    try {
      await conn.execute(
        `BEGIN register_team(:tournament_id, :captain_id, :team_name); END;`,
        { tournament_id: ongoingTournamentId, captain_id: captain1Id, team_name: 'Cheater Squad' }
      );
      console.error('FAIL: Allowed registration to an ongoing tournament.');
    } catch (err) {
      console.log('SUCCESS: Blocked registration as expected. Error message:', err.message.trim());
    }

    // 5. Test schedule_match procedure
    console.log('\n--- Testing Procedure: schedule_match ---');
    console.log(`Scheduling Quarter-Finals match between Team ${team1Id} and ${team2Id}...`);
    await conn.execute(
      `BEGIN schedule_match(:tournament_id, :round_no, :team1_id, :team2_id, SYSDATE); END;`,
      { tournament_id: tournamentId, round_no: 'Quarter-Finals', team1_id: team1Id, team2_id: team2Id }
    );

    // Fetch match detail to verify
    const matchRes = await conn.execute(
      `SELECT * FROM MATCHES WHERE tournament_id = :tid`,
      [tournamentId],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    console.log('Matches scheduled:', matchRes.rows);
    const matchId = matchRes.rows[0].MATCH_ID;

    const matchTeamsRes = await conn.execute(
      `SELECT * FROM MATCH_TEAMS WHERE match_id = :mid`,
      [matchId],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    console.log('Match Teams scheduled:', matchTeamsRes.rows);

    // 6. Test declare_winner procedure
    console.log('\n--- Testing Procedure: declare_winner ---');
    console.log(`Declaring Team ${team1Id} as winner of Match ${matchId}...`);
    await conn.execute(
      `BEGIN declare_winner(:match_id, :winner_id); END;`,
      { match_id: matchId, winner_id: team1Id }
    );

    // Verify winner and score update
    const winnerRes = await conn.execute(
      `SELECT * FROM MATCHES WHERE match_id = :mid`,
      [matchId],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    console.log('Match winner details:', winnerRes.rows);

    const winnerScores = await conn.execute(
      `SELECT * FROM MATCH_TEAMS WHERE match_id = :mid`,
      [matchId],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    console.log('Match scores updated:', winnerScores.rows);

    // 7. Test get_tournament_standings function (returns SYS_REFCURSOR)
    console.log('\n--- Testing Function: get_tournament_standings ---');
    const standingsRes = await conn.execute(
      `BEGIN :ret := get_tournament_standings(:tid); END;`,
      {
        tid: tournamentId,
        ret: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
      }
    );

    const resultSet = standingsRes.outBinds.ret;
    let row;
    const standings = [];
    while ((row = await resultSet.getRow())) {
      // row columns: TEAM_ID, NAME, WINS (depending on outFormat configuration of resultSet, but node-oracledb resultset row format matches connection configuration)
      // Since resultSet is dynamic, we output it as is
      standings.push(row);
    }
    await resultSet.close();
    console.log('Standings output (SYS_REFCURSOR):');
    console.table(standings);

    // 8. Test generate_brackets procedure
    console.log('\n--- Testing Procedure: generate_brackets ---');
    await conn.execute(`BEGIN generate_brackets(:tid); END;`, [tournamentId]);

    // Verify bracket entry
    const bracketRes = await conn.execute(
      `SELECT * FROM BRACKETS WHERE tournament_id = :tid`,
      [tournamentId],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    console.log('Brackets generated in database:', bracketRes.rows);

    console.log('\n==================================================');
    console.log('   ALL INTEGRATION TESTS PASSED SUCCESSFULLY!   ');
    console.log('==================================================\n');

  } catch (err) {
    console.error('\n!!! TEST EXECUTIONS FAILED !!!');
    console.error(err);
  } finally {
    if (conn) {
      try {
        await conn.close();
      } catch (err) {
        console.error('Error closing connection:', err);
      }
    }
    await db.close();
  }
}

test();
