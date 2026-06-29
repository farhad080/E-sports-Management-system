const db = require('../db/connection');

// GET Team Captain Dashboard
exports.getCaptainDashboard = async (req, res, next) => {
  try {
    // Mock statistical data for high-fidelity Captain dashboard presentation
    const stats = {
      teamName: 'Cyber Knights',
      gameCategory: 'CS2',
      playersCount: 5,
      wins: 14,
      losses: 3,
      roster: [
        { name: 'Captain Phantom', email: 'phantom@nexus.com', inGameRole: 'IGL (In-Game Leader)', status: 'Active' },
        { name: 'ViperX', email: 'viperx@nexus.com', inGameRole: 'Entry Fragger', status: 'Active' },
        { name: 'LiquidLoki', email: 'loki@nexus.com', inGameRole: 'Lurker', status: 'Active' },
        { name: 'BoltStrike', email: 'bolt@nexus.com', inGameRole: 'Support', status: 'Offline' },
        { name: 'ApexSniper', email: 'sniper@nexus.com', inGameRole: 'Sniper / AWP', status: 'Active' }
      ]
    };

    res.render('captain/dashboard', {
      title: 'Team Captain Dashboard | Nexus eSports',
      stats,
      user: req.session.user || { name: 'Captain Phantom', email: 'captain@nexus.com', role: 'Team Captain' },
      success_msg: req.session.success_msg || '',
      error_msg: req.session.error_msg || ''
    });

    // Clear flash messages
    req.session.success_msg = null;
    req.session.error_msg = null;
  } catch (err) {
    next(err);
  }
};

// GET Player Dashboard
exports.getPlayerDashboard = async (req, res, next) => {
  try {
    // Mock statistical data for high-fidelity Player dashboard presentation
    const stats = {
      level: 42,
      kdRatio: '1.45',
      winRate: 72,
      matchesPlayed: 124,
      tournamentsWon: 3
    };

    res.render('player/dashboard', {
      title: 'Player Dashboard | Nexus eSports',
      stats,
      user: req.session.user || { name: 'ViperX', email: 'player@nexus.com', role: 'Player' },
      success_msg: req.session.success_msg || '',
      error_msg: req.session.error_msg || ''
    });

    // Clear flash messages
    req.session.success_msg = null;
    req.session.error_msg = null;
  } catch (err) {
    next(err);
  }
};
