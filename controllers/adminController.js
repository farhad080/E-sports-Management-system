const db = require('../db/connection');

exports.getDashboard = async (req, res, next) => {
  try {
    // Mock statistical data for initial high-fidelity presentation
    const stats = {
      totalTournaments: 12,
      activeMatches: 4,
      registeredTeams: 32,
      totalPlayers: 156
    };

    // Render the admin dashboard with layout: false since we use a custom sidebar-layout
    res.render('admin/dashboard', {
      title: 'Admin Dashboard | Nexus eSports',
      stats,
      user: req.session.user || { name: 'System Admin', email: 'admin@nexus.com', role: 'Admin' },
      success_msg: req.session.success_msg || '',
      error_msg: req.session.error_msg || '',
      layout: false // bypass the main layout.ejs
    });

    // Clear flash messages after displaying
    req.session.success_msg = null;
    req.session.error_msg = null;
  } catch (err) {
    next(err);
  }
};
