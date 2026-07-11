const db = require('../db/connection');

// ---------------------------------------------------------------------------
//  GET /api/tournaments
//  List all tournaments from the aggregated v_tournament_summary view.
// ---------------------------------------------------------------------------
exports.getAllTournaments = async (req, res) => {
  try {
    const result = await db.execute(
      `SELECT * FROM v_tournament_summary`
    );
    res.status(200).json({ success: true, data: result.rows });
  } catch (err) {
    console.error('getAllTournaments error:', err.message);
    res.status(500).json({ success: false, message: 'Failed to fetch tournaments.' });
  }
};

// ---------------------------------------------------------------------------
//  GET /api/tournaments/:id
//  Tournament detail: summary row + registered teams + scheduled matches.
// ---------------------------------------------------------------------------
exports.getTournamentById = async (req, res) => {
  const { id } = req.params;

  try {
    const summary = await db.execute(
      `SELECT * FROM v_tournament_summary WHERE tournament_id = :id`,
      { id }
    );

    if (!summary.rows || summary.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Tournament not found.' });
    }

    const teams = await db.execute(
      `SELECT team_id, name, captain_id FROM TEAMS WHERE tournament_id = :id ORDER BY name`,
      { id }
    );

    const matches = await db.execute(
      `SELECT * FROM v_match_details WHERE tournament_id = :id ORDER BY round, match_date`,
      { id }
    );

    res.status(200).json({
      success: true,
      data: {
        tournament: summary.rows[0],
        teams: teams.rows,
        matches: matches.rows
      }
    });
  } catch (err) {
    console.error('getTournamentById error:', err.message);
    res.status(500).json({ success: false, message: 'Failed to fetch tournament detail.' });
  }
};

// ---------------------------------------------------------------------------
//  POST /api/tournaments  (Admin only)
//  Creates a new tournament.
// ---------------------------------------------------------------------------
exports.createTournament = async (req, res) => {
  const { name, game_id, description, start_date, end_date, prize_pool, max_teams } = req.body;

  if (!name || !game_id || !start_date || !end_date || !max_teams) {
    return res.status(400).json({ success: false, message: 'name, game_id, start_date, end_date, and max_teams are required.' });
  }

  try {
    const result = await db.executeWithCommit(
      `INSERT INTO TOURNAMENTS (name, game_id, description, start_date, end_date, status, prize_pool, max_teams)
       VALUES (:name, :game_id, :description, TO_DATE(:start_date, 'YYYY-MM-DD'), TO_DATE(:end_date, 'YYYY-MM-DD'), 'Upcoming', :prize_pool, :max_teams)
       RETURNING tournament_id INTO :tournament_id`,
      {
        name,
        game_id,
        description: description || null,
        start_date,
        end_date,
        prize_pool: prize_pool || null,
        max_teams,
        tournament_id: { dir: db.oracledb.BIND_OUT, type: db.oracledb.NUMBER }
      }
    );

    res.status(201).json({
      success: true,
      message: 'Tournament created successfully.',
      data: { tournament_id: result.outBinds.tournament_id[0] }
    });
  } catch (err) {
    console.error('createTournament error:', err.message);
    res.status(500).json({ success: false, message: 'Failed to create tournament.' });
  }
};

// ---------------------------------------------------------------------------
//  PUT /api/tournaments/:id  (Admin only)
// ---------------------------------------------------------------------------
exports.updateTournament = async (req, res) => {
  const { id } = req.params;
  const { name, description, start_date, end_date, status, prize_pool, max_teams } = req.body;

  try {
    const result = await db.executeWithCommit(
      `UPDATE TOURNAMENTS
          SET name        = NVL(:name, name),
              description = NVL(:description, description),
              start_date  = NVL(TO_DATE(:start_date, 'YYYY-MM-DD'), start_date),
              end_date    = NVL(TO_DATE(:end_date, 'YYYY-MM-DD'), end_date),
              status      = NVL(:status, status),
              prize_pool  = NVL(:prize_pool, prize_pool),
              max_teams   = NVL(:max_teams, max_teams)
        WHERE tournament_id = :id`,
      {
        id,
        name: name || null,
        description: description || null,
        start_date: start_date || null,
        end_date: end_date || null,
        status: status || null,
        prize_pool: prize_pool || null,
        max_teams: max_teams || null
      }
    );

    if (result.rowsAffected === 0) {
      return res.status(404).json({ success: false, message: 'Tournament not found.' });
    }

    res.status(200).json({ success: true, message: 'Tournament updated successfully.' });
  } catch (err) {
    console.error('updateTournament error:', err.message);
    res.status(500).json({ success: false, message: 'Failed to update tournament.' });
  }
};

// ---------------------------------------------------------------------------
//  DELETE /api/tournaments/:id  (Admin only)
// ---------------------------------------------------------------------------
exports.deleteTournament = async (req, res) => {
  const { id } = req.params;

  try {
    const result = await db.executeWithCommit(
      `DELETE FROM TOURNAMENTS WHERE tournament_id = :id`,
      { id }
    );

    if (result.rowsAffected === 0) {
      return res.status(404).json({ success: false, message: 'Tournament not found.' });
    }

    res.status(200).json({ success: true, message: 'Tournament deleted successfully.' });
  } catch (err) {
    console.error('deleteTournament error:', err.message);
    res.status(500).json({ success: false, message: 'Failed to delete tournament.' });
  }
};
