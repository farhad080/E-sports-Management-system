const db = require('../db/connection');

// Mock data arrays for tournament list and schedules
const mockTournaments = [
  {
    id: 1,
    name: 'CS2 Championship Cup',
    game: 'CS2',
    startDate: '2026-07-25',
    endDate: '2026-07-30',
    status: 'Upcoming', // 'Upcoming', 'Ongoing', 'Completed'
    prizePool: '$10,000',
    teamsRegisteredCount: 16,
    maxTeams: 16
  },
  {
    id: 2,
    name: 'Valorant Radiant League',
    game: 'Valorant',
    startDate: '2026-06-20',
    endDate: '2026-07-05',
    status: 'Ongoing',
    prizePool: '$15,000',
    teamsRegisteredCount: 12,
    maxTeams: 16
  },
  {
    id: 3,
    name: 'PUBG Mobile Squad Showdown',
    game: 'PUBG Mobile',
    startDate: '2026-08-05',
    endDate: '2026-08-10',
    status: 'Upcoming',
    prizePool: '$5,000',
    teamsRegisteredCount: 10,
    maxTeams: 20
  },
  {
    id: 4,
    name: 'FIFA Arena Clash',
    game: 'FIFA 24',
    startDate: '2026-06-10',
    endDate: '2026-06-15',
    status: 'Completed',
    prizePool: '$2,500',
    teamsRegisteredCount: 32,
    maxTeams: 32
  }
];

const mockMatches = [
  {
    id: 101,
    tournamentName: 'CS2 Championship Cup',
    round: 'Quarter-Final 1',
    teamA: 'Cyber Knights',
    teamB: 'Ice Wolves',
    dateTime: '2026-07-25 18:00',
    result: 'Upcoming',
    game: 'CS2'
  },
  {
    id: 102,
    tournamentName: 'CS2 Championship Cup',
    round: 'Quarter-Final 2',
    teamA: 'Shadow Assassins',
    teamB: 'Lunar Vipers',
    dateTime: '2026-07-25 20:00',
    result: 'Upcoming',
    game: 'CS2'
  },
  {
    id: 103,
    tournamentName: 'Valorant Radiant League',
    round: 'Group Stage',
    teamA: 'Cyber Knights',
    teamB: 'Shadow Assassins',
    dateTime: '2026-06-29 18:00',
    result: 'Cyber Knights Won (13-9)',
    game: 'Valorant'
  },
  {
    id: 104,
    tournamentName: 'Valorant Radiant League',
    round: 'Group Stage',
    teamA: 'Lunar Vipers',
    teamB: 'Apex Predators',
    dateTime: '2026-06-29 20:00',
    result: 'Lunar Vipers Won (13-11)',
    game: 'Valorant'
  },
  {
    id: 105,
    tournamentName: 'FIFA Arena Clash',
    round: 'Grand Finals',
    teamA: 'MessiFan10',
    teamB: 'RonaldoCR7',
    dateTime: '2026-06-15 21:00',
    result: 'MessiFan10 Won (3-2)',
    game: 'FIFA 24'
  }
];

const mockTournamentDetail = {
  1: {
    id: 1,
    name: 'CS2 Championship Cup',
    game: 'CS2',
    description: 'The ultimate showdown for the best CS2 squads in the region. Fight for glory, rank, and a piece of the $10,000 prize pool.',
    startDate: '2026-07-25',
    endDate: '2026-07-30',
    status: 'Upcoming',
    prizePool: '$10,000',
    teamsRegistered: [
      { name: 'Cyber Knights', captain: 'Captain Phantom', registeredAt: '2026-06-15' },
      { name: 'Shadow Assassins', captain: 'ShadowBoss', registeredAt: '2026-06-16' },
      { name: 'Ice Wolves', captain: 'FrostByte', registeredAt: '2026-06-18' },
      { name: 'Lunar Vipers', captain: 'ViperKing', registeredAt: '2026-06-20' },
      { name: 'Frost Giants', captain: 'Glacier', registeredAt: '2026-06-21' }
    ],
    matches: [
      { round: 'Quarter-Finals', teamA: 'Cyber Knights', teamB: 'Ice Wolves', dateTime: '2026-07-25 18:00', result: 'Pending' },
      { round: 'Quarter-Finals', teamA: 'Shadow Assassins', teamB: 'Lunar Vipers', dateTime: '2026-07-25 20:00', result: 'Pending' },
      { round: 'Semi-Finals', teamA: 'TBD', teamB: 'TBD', dateTime: '2026-07-27 18:00', result: 'Pending' },
      { round: 'Grand Finals', teamA: 'TBD', teamB: 'TBD', dateTime: '2026-07-29 20:00', result: 'Pending' }
    ],
    brackets: {
      rounds: [
        {
          name: 'Quarter-Finals',
          matches: [
            { teamA: 'Cyber Knights', teamB: 'Ice Wolves', scoreA: null, scoreB: null },
            { teamA: 'Shadow Assassins', teamB: 'Lunar Vipers', scoreA: null, scoreB: null }
          ]
        },
        {
          name: 'Semi-Finals',
          matches: [
            { teamA: 'TBD', teamB: 'TBD', scoreA: null, scoreB: null }
          ]
        },
        {
          name: 'Grand Finals',
          matches: [
            { teamA: 'TBD', teamB: 'TBD', scoreA: null, scoreB: null }
          ]
        }
      ]
    }
  },
  2: {
    id: 2,
    name: 'Valorant Radiant League',
    game: 'Valorant',
    description: 'Steal the spotlight in the Radiant League. Engage in high-stakes tactical combat.',
    startDate: '2026-06-20',
    endDate: '2026-07-05',
    status: 'Ongoing',
    prizePool: '$15,000',
    teamsRegistered: [
      { name: 'Cyber Knights', captain: 'Captain Phantom', registeredAt: '2026-06-10' },
      { name: 'Shadow Assassins', captain: 'ShadowBoss', registeredAt: '2026-06-11' },
      { name: 'Apex Predators', captain: 'ApexLeader', registeredAt: '2026-06-12' },
      { name: 'Lunar Vipers', captain: 'ViperKing', registeredAt: '2026-06-14' }
    ],
    matches: [
      { round: 'Group Stage', teamA: 'Cyber Knights', teamB: 'Shadow Assassins', dateTime: '2026-06-29 18:00', result: 'Cyber Knights Won (13-9)' },
      { round: 'Group Stage', teamA: 'Lunar Vipers', teamB: 'Apex Predators', dateTime: '2026-06-29 20:00', result: 'Lunar Vipers Won (13-11)' }
    ],
    brackets: {
      rounds: [
        {
          name: 'Semi-Finals',
          matches: [
            { teamA: 'Cyber Knights', teamB: 'Lunar Vipers', scoreA: null, scoreB: null }
          ]
        },
        {
          name: 'Grand Finals',
          matches: [
            { teamA: 'TBD', teamB: 'TBD', scoreA: null, scoreB: null }
          ]
        }
      ]
    }
  },
  3: {
    id: 3,
    name: 'PUBG Mobile Squad Showdown',
    game: 'PUBG Mobile',
    description: 'Survival of the fittest on Erangel. 20 squads enter, only one will claim the dinner.',
    startDate: '2026-08-05',
    endDate: '2026-08-10',
    status: 'Upcoming',
    prizePool: '$5,000',
    teamsRegistered: [],
    matches: [],
    brackets: null
  },
  4: {
    id: 4,
    name: 'FIFA Arena Clash',
    game: 'FIFA 24',
    description: 'Compete in single-elimination matches to be crowned the ultimate FIFA champion.',
    startDate: '2026-06-10',
    endDate: '2026-06-15',
    status: 'Completed',
    prizePool: '$2,500',
    teamsRegistered: [
      { name: 'MessiFan10', captain: 'MessiFan10', registeredAt: '2026-06-01' },
      { name: 'RonaldoCR7', captain: 'RonaldoCR7', registeredAt: '2026-06-02' }
    ],
    matches: [
      { round: 'Grand Finals', teamA: 'MessiFan10', teamB: 'RonaldoCR7', dateTime: '2026-06-15 21:00', result: 'MessiFan10 Won (3-2)' }
    ],
    brackets: {
      rounds: [
        {
          name: 'Grand Finals',
          matches: [
            { teamA: 'MessiFan10', teamB: 'RonaldoCR7', scoreA: 3, scoreB: 2 }
          ]
        }
      ]
    }
  }
};

exports.getIndex = async (req, res, next) => {
  try {
    res.render('index', { 
      title: 'Dashboard | Nexus eSports',
      success_msg: req.session.success_msg || '',
      error_msg: req.session.error_msg || ''
    });
    req.session.success_msg = null;
    req.session.error_msg = null;
  } catch (err) {
    next(err);
  }
};

exports.getTournaments = (req, res) => {
  res.render('tournaments/list', { 
    title: 'Tournaments | Nexus eSports',
    tournaments: mockTournaments,
    user: req.session.user
  });
};

exports.getTournamentDetail = (req, res) => {
  const tournamentId = req.params.id;
  const tournament = mockTournamentDetail[tournamentId] || mockTournamentDetail[1];
  
  res.render('tournaments/detail', { 
    title: `${tournament.name} | Nexus eSports`,
    tournament: tournament,
    user: req.session.user
  });
};

exports.getTeams = (req, res) => {
  res.render('index', { title: 'Teams | Nexus eSports' });
};

exports.getMatches = (req, res) => {
  res.render('matches/schedule', { 
    title: 'Matches | Nexus eSports',
    matches: mockMatches,
    user: req.session.user
  });
};
