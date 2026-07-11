const db = require('../db/connection');

// ---------------------------------------------------------------------------
//  GET /api/teams?tournament_id=
//  List teams, optionally filtered by tournament.
// ---------------------------------------------------------------------------
exports.getAllTeams = async (req, res) => {
  const { tournament_id } = req.query;

  try {
    const sql = tournament_id
      ? `SELECT team_id, name, captain_id, game_id, tournament_id FROM TEAMS WHERE tournament_id = :tournament_id ORDER BY name`
      : `SELECT team_id, name, captain_id, game_id, tournament_id FROM TEAMS ORDER BY name`;

    const result = await db.execute(sql, tournament_id ? { tournament_id } : {});
    res.status(200).json({ success: true, data: result.rows });
  } catch (err) {
    console.error('getAllTeams error:', err.message);
    res.status(500).json({ success: false, message: 'Failed to fetch teams.' });
  }
};

// ---------------------------------------------------------------------------
//  GET /api/teams/:id
//  Team detail including its roster.
// ---------------------------------------------------------------------------
exports.getTeamById = async (req, res) => {
  const { id } = req.params;

  try {
    const team = await db.execute(
      `SELECT team_id, name, captain_id, game_id, tournament_id FROM TEAMS WHERE team_id = :id`,
      { id }
    );

    if (!team.rows || team.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Team not found.' });
    }

    const roster = await db.execute(
      `SELECT u.user_id, u.username, u.email, u.role
         FROM TEAM_MEMBERS tm
         JOIN USERS u ON tm.user_id = u.user_id
        WHERE tm.team_id = :id
        ORDER BY tm.joined_at`,
      { id }
    );

    res.status(200).json({
      success: true,
      data: { team: team.rows[0], roster: roster.rows }
    });
  } catch (err) {
    console.error('getTeamById error:', err.message);
    res.status(500).json({ success: false, message: 'Failed to fetch team detail.' });
  }
};

// ---------------------------------------------------------------------------
//  POST /api/teams  (Team Captain only)
//  Registers a new team for a tournament via the register_team procedure.
//  The captain is always the currently logged-in Team Captain.
// ---------------------------------------------------------------------------
exports.registerTeam = async (req, res) => {
  const { tournament_id, team_name } = req.body;
  const captain_id = req.session.user.user_id;

  if (!tournament_id || !team_name) {
    return res.status(400).json({ success: false, message: 'tournament_id and team_name are required.' });
  }

  let conn;
  try {
    conn = await db.getConnection();
    await conn.execute(
      `BEGIN register_team(:p_tournament_id, :p_captain_id, :p_team_name); END;`,
      {
        p_tournament_id: tournament_id,
        p_captain_id: captain_id,
        p_team_name: team_name
      }
    );

    const created = await conn.execute(
      `SELECT team_id, name, captain_id, tournament_id FROM TEAMS WHERE tournament_id = :tournament_id AND captain_id = :captain_id`,
      { tournament_id, captain_id },
      { outFormat: db.oracledb.OUT_FORMAT_OBJECT }
    );

    res.status(201).json({
      success: true,
      message: 'Team registered successfully.',
      data: created.rows[0]
    });
  } catch (err) {
    console.error('registerTeam error:', err.message);
    res.status(400).json({ success: false, message: err.message });
  } finally {
    if (conn) await conn.close();
  }
};

// ---------------------------------------------------------------------------
//  POST /api/teams/:id/players  (Team Captain of that team, or Admin)
//  Adds a player to the team's roster.
// ---------------------------------------------------------------------------
exports.addPlayerToTeam = async (req, res) => {
  const { id } = req.params;
  const { user_id } = req.body;
  const sessionUser = req.session.user;

  if (!user_id) {
    return res.status(400).json({ success: false, message: 'user_id is required.' });
  }

  try {
    const team = await db.execute(
      `SELECT team_id, captain_id FROM TEAMS WHERE team_id = :id`,
      { id }
    );

    if (!team.rows || team.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Team not found.' });
    }

    const isOwner = team.rows[0].CAPTAIN_ID === sessionUser.user_id;
    if (sessionUser.role !== 'Admin' && !isOwner) {
      return res.status(403).json({ success: false, message: 'Only the team captain or an admin can add players to this team.' });
    }

    const player = await db.execute(
      `SELECT user_id, role FROM USERS WHERE user_id = :user_id`,
      { user_id }
    );

    if (!player.rows || player.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Player not found.' });
    }

    await db.executeWithCommit(
      `INSERT INTO TEAM_MEMBERS (team_id, user_id) VALUES (:id, :user_id)`,
      { id, user_id }
    );

    res.status(201).json({ success: true, message: 'Player added to team successfully.' });
  } catch (err) {
    console.error('addPlayerToTeam error:', err.message);
    if (err.errorNum === 1) {
      return res.status(409).json({ success: false, message: 'Player is already a member of this team.' });
    }
    res.status(500).json({ success: false, message: 'Failed to add player to team.' });
  }
};

// ---------------------------------------------------------------------------
//  DELETE /api/teams/:id/players/:userId  (Team Captain of that team, or Admin)
// ---------------------------------------------------------------------------
exports.removePlayerFromTeam = async (req, res) => {
  const { id, userId } = req.params;
  const sessionUser = req.session.user;

  try {
    const team = await db.execute(
      `SELECT team_id, captain_id FROM TEAMS WHERE team_id = :id`,
      { id }
    );

    if (!team.rows || team.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Team not found.' });
    }

    const isOwner = team.rows[0].CAPTAIN_ID === sessionUser.user_id;
    if (sessionUser.role !== 'Admin' && !isOwner) {
      return res.status(403).json({ success: false, message: 'Only the team captain or an admin can remove players from this team.' });
    }

    const result = await db.executeWithCommit(
      `DELETE FROM TEAM_MEMBERS WHERE team_id = :id AND user_id = :userId`,
      { id, userId }
    );

    if (result.rowsAffected === 0) {
      return res.status(404).json({ success: false, message: 'Player is not a member of this team.' });
    }

    res.status(200).json({ success: true, message: 'Player removed from team successfully.' });
  } catch (err) {
    console.error('removePlayerFromTeam error:', err.message);
    res.status(500).json({ success: false, message: 'Failed to remove player from team.' });
  }
};

// ---------------------------------------------------------------------------
//  DELETE /api/teams/:id  (Admin only)
// ---------------------------------------------------------------------------
exports.deleteTeam = async (req, res) => {
  const { id } = req.params;

  try {
    const result = await db.executeWithCommit(
      `DELETE FROM TEAMS WHERE team_id = :id`,
      { id }
    );

    if (result.rowsAffected === 0) {
      return res.status(404).json({ success: false, message: 'Team not found.' });
    }

    res.status(200).json({ success: true, message: 'Team deleted successfully.' });
  } catch (err) {
    console.error('deleteTeam error:', err.message);
    res.status(500).json({ success: false, message: 'Failed to delete team.' });
  }
};
