const db = require('../db/connection');

exports.getIndex = async (req, res, next) => {
  try {
    // Render the homepage with custom title and mock/database data
    res.render('index', { 
      title: 'Dashboard | Nexus eSports',
      success_msg: req.session.success_msg || '',
      error_msg: req.session.error_msg || ''
    });
    // Clear flash messages after displaying
    req.session.success_msg = null;
    req.session.error_msg = null;
  } catch (err) {
    next(err);
  }
};

exports.getTournaments = (req, res) => {
  res.render('index', { title: 'Tournaments | Nexus eSports' });
};

exports.getTeams = (req, res) => {
  res.render('index', { title: 'Teams | Nexus eSports' });
};

exports.getMatches = (req, res) => {
  res.render('index', { title: 'Matches | Nexus eSports' });
};
