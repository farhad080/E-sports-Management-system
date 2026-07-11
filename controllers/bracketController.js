const db = require('../db/connection');

// ---------------------------------------------------------------------------
//  POST /api/brackets/:tournamentId/generate  (Admin only)
//  Regenerates bracket metadata via the generate_brackets procedure.
// ---------------------------------------------------------------------------
exports.generateBrackets = async (req, res) => {
  const { tournamentId } = req.params;

  let conn;
  try {
    conn = await db.getConnection();
    await conn.execute(
      `BEGIN generate_brackets(:p_tournament_id); END;`,
      { p_tournament_id: tournamentId }
    );

    const bracket = await conn.execute(
      `SELECT bracket_id, tournament_id, name, round_count FROM BRACKETS WHERE tournament_id = :tournamentId`,
      { tournamentId },
      { outFormat: db.oracledb.OUT_FORMAT_OBJECT }
    );

    res.status(200).json({
      success: true,
      message: 'Bracket generated successfully.',
      data: bracket.rows[0]
    });
  } catch (err) {
    console.error('generateBrackets error:', err.message);
    res.status(400).json({ success: false, message: err.message });
  } finally {
    if (conn) await conn.close();
  }
};

// ---------------------------------------------------------------------------
//  GET /api/brackets/:tournamentId
//  Fetches bracket metadata plus all matches for the tournament, grouped by
//  round so the frontend can render a bracket tree.
// ---------------------------------------------------------------------------
exports.getBracket = async (req, res) => {
  const { tournamentId } = req.params;

  try {
    const bracket = await db.execute(
      `SELECT bracket_id, tournament_id, name, round_count FROM BRACKETS WHERE tournament_id = :tournamentId`,
      { tournamentId }
    );

    if (!bracket.rows || bracket.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'No bracket has been generated for this tournament yet.' });
    }

    const matches = await db.execute(
      `SELECT * FROM v_match_details WHERE tournament_id = :tournamentId ORDER BY round, match_date`,
      { tournamentId }
    );

    const rounds = {};
    for (const match of matches.rows) {
      const roundName = match.ROUND;
      if (!rounds[roundName]) rounds[roundName] = [];
      rounds[roundName].push(match);
    }

    res.status(200).json({
      success: true,
      data: {
        bracket: bracket.rows[0],
        rounds: Object.entries(rounds).map(([name, roundMatches]) => ({ name, matches: roundMatches }))
      }
    });
  } catch (err) {
    console.error('getBracket error:', err.message);
    res.status(500).json({ success: false, message: 'Failed to fetch bracket data.' });
  }
};
