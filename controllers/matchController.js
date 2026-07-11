const db = require('../db/connection');

// ---------------------------------------------------------------------------
//  GET /api/matches?tournament_id=
//  Match schedule from the denormalized v_match_details view.
// ---------------------------------------------------------------------------
exports.getSchedule = async (req, res) => {
  const { tournament_id } = req.query;

  try {
    const sql = tournament_id
      ? `SELECT * FROM v_match_details WHERE tournament_id = :tournament_id ORDER BY round, match_date`
      : `SELECT * FROM v_match_details ORDER BY tournament_id, round, match_date`;

    const result = await db.execute(sql, tournament_id ? { tournament_id } : {});
    res.status(200).json({ success: true, data: result.rows });
  } catch (err) {
    console.error('getSchedule error:', err.message);
    res.status(500).json({ success: false, message: 'Failed to fetch match schedule.' });
  }
};

// ---------------------------------------------------------------------------
//  GET /api/matches/:id
// ---------------------------------------------------------------------------
exports.getMatchById = async (req, res) => {
  const { id } = req.params;

  try {
    const result = await db.execute(
      `SELECT * FROM v_match_details WHERE match_id = :id`,
      { id }
    );

    if (!result.rows || result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Match not found.' });
    }

    res.status(200).json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('getMatchById error:', err.message);
    res.status(500).json({ success: false, message: 'Failed to fetch match.' });
  }
};

// ---------------------------------------------------------------------------
//  POST /api/matches  (Admin only)
//  Schedules a new match via the schedule_match procedure.
// ---------------------------------------------------------------------------
exports.scheduleMatch = async (req, res) => {
  const { tournament_id, round, team1_id, team2_id, match_date } = req.body;

  if (!tournament_id || !round || !team1_id || !team2_id || !match_date) {
    return res.status(400).json({ success: false, message: 'tournament_id, round, team1_id, team2_id, and match_date are required.' });
  }

  let conn;
  try {
    conn = await db.getConnection();
    await conn.execute(
      `BEGIN schedule_match(:p_tournament_id, :p_round_no, :p_team1_id, :p_team2_id, :p_match_date); END;`,
      {
        p_tournament_id: tournament_id,
        p_round_no: round,
        p_team1_id: team1_id,
        p_team2_id: team2_id,
        p_match_date: new Date(match_date)
      }
    );

    const created = await conn.execute(
      `SELECT * FROM v_match_details
        WHERE tournament_id = :tournament_id AND team_a_id = :team1_id AND team_b_id = :team2_id
        ORDER BY match_id DESC FETCH FIRST 1 ROWS ONLY`,
      { tournament_id, team1_id, team2_id },
      { outFormat: db.oracledb.OUT_FORMAT_OBJECT }
    );

    res.status(201).json({
      success: true,
      message: 'Match scheduled successfully.',
      data: created.rows[0]
    });
  } catch (err) {
    console.error('scheduleMatch error:', err.message);
    res.status(400).json({ success: false, message: err.message });
  } finally {
    if (conn) await conn.close();
  }
};

// ---------------------------------------------------------------------------
//  PUT /api/matches/:id/result  (Admin only)
//  Declares the winner of a match via the declare_winner procedure.
// ---------------------------------------------------------------------------
exports.declareWinner = async (req, res) => {
  const { id } = req.params;
  const { winner_team_id } = req.body;

  if (!winner_team_id) {
    return res.status(400).json({ success: false, message: 'winner_team_id is required.' });
  }

  let conn;
  try {
    conn = await db.getConnection();
    await conn.execute(
      `BEGIN declare_winner(:p_match_id, :p_winner_team_id); END;`,
      {
        p_match_id: id,
        p_winner_team_id: winner_team_id
      }
    );

    const updated = await conn.execute(
      `SELECT * FROM v_match_details WHERE match_id = :id`,
      { id },
      { outFormat: db.oracledb.OUT_FORMAT_OBJECT }
    );

    res.status(200).json({
      success: true,
      message: 'Match result recorded successfully.',
      data: updated.rows[0]
    });
  } catch (err) {
    console.error('declareWinner error:', err.message);
    res.status(400).json({ success: false, message: err.message });
  } finally {
    if (conn) await conn.close();
  }
};
