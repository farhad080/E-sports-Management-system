const bcrypt = require('bcryptjs');
const db = require('../db/connection');

// GET Login Page
exports.getLogin = (req, res) => {
  res.render('auth/login', { 
    title: 'Login | Nexus eSports'
  });
};

// GET Register Page
exports.getRegister = (req, res) => {
  res.render('auth/register', { 
    title: 'Register | Nexus eSports'
  });
};

// POST Login Handler
exports.postLogin = async (req, res) => {
  const { email, password, role } = req.body;

  // Basic Server-Side Validation
  if (!email || !password || !role) {
    req.session.error_msg = 'Please fill in all fields';
    return res.redirect('/login');
  }

  try {
    // Note: Here is where you execute your Oracle SQL statement to find user:
    // SELECT * FROM users WHERE email = :email AND role = :role
    // Example using the db connection pool helper:
    // const result = await db.execute('SELECT * FROM users WHERE email = :email AND role = :role', [email, role]);
    // const user = result.rows[0];
    
    // For demonstration, let's simulate authentication
    // Let's assume a default admin or player if the Oracle Database is not active yet
    if (email === 'admin@nexus.com' && password === 'admin123' && role === 'Admin') {
      req.session.user = { name: 'System Admin', email, role };
      req.session.success_msg = 'Successfully logged in as Administrator!';
      return res.redirect('/admin/dashboard');
    }
    
    // Set mock user details based on role for richer dashboard presentation
    let name = 'Player Elite';
    if (role === 'Team Captain') name = 'Captain Phantom';
    if (role === 'Player') name = 'ViperX';

    // Otherwise simulate standard login success for testing
    req.session.user = { name, email, role };
    req.session.success_msg = `Welcome back! Logged in as ${role}`;
    
    if (role === 'Admin') {
      return res.redirect('/admin/dashboard');
    }
    if (role === 'Team Captain') {
      return res.redirect('/captain/dashboard');
    }
    if (role === 'Player') {
      return res.redirect('/player/dashboard');
    }
    return res.redirect('/');
  } catch (err) {
    console.error(err);
    req.session.error_msg = 'An error occurred during authentication';
    res.redirect('/login');
  }
};

// POST Register Handler
exports.postRegister = async (req, res) => {
  const { name, email, role, password, confirmPassword } = req.body;

  // Server-Side Validation
  let errors = [];
  if (!name || !email || !role || !password || !confirmPassword) {
    errors.push('Please fill in all fields');
  }
  if (password !== confirmPassword) {
    errors.push('Passwords do not match');
  }
  if (password && password.length < 6) {
    errors.push('Password must be at least 6 characters');
  }

  if (errors.length > 0) {
    req.session.error_msg = errors.join(', ');
    return res.redirect('/register');
  }

  try {
    // Generate salt and hash the password using bcryptjs
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Note: Here is where you execute your Oracle SQL INSERT statement:
    // INSERT INTO users (name, email, role, password) VALUES (:name, :email, :role, :password)
    console.log(`[MOCK DB] User Registration details: Name: ${name}, Email: ${email}, Role: ${role}, Hashed Password: ${hashedPassword}`);
    
    req.session.success_msg = 'Registration successful! You can now log in.';
    res.redirect('/login');
  } catch (err) {
    console.error(err);
    req.session.error_msg = 'An error occurred during registration';
    res.redirect('/register');
  }
};

// GET Logout Handler
exports.logout = (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      console.error('Session destruction error:', err);
    }
    res.redirect('/');
  });
};
