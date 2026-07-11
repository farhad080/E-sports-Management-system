const bcrypt = require('bcryptjs');
const db = require('../db/connection');

// ---------------------------------------------------------------------------
//  GET — Render Login Page
// ---------------------------------------------------------------------------
exports.getLogin = (req, res) => {
  res.render('auth/login', {
    title: 'Login | Nexus eSports'
  });
};

// ---------------------------------------------------------------------------
//  GET — Render Register Page
// ---------------------------------------------------------------------------
exports.getRegister = (req, res) => {
  res.render('auth/register', {
    title: 'Register | Nexus eSports'
  });
};

// ---------------------------------------------------------------------------
//  POST — Login Handler
//  Verifies credentials against the USERS table using bcryptjs.
//  On success, stores user_id, username, email, and role in express-session,
//  then redirects to the appropriate role-based dashboard.
// ---------------------------------------------------------------------------
exports.postLogin = async (req, res) => {
  const { email, password, role } = req.body;

  // Server-Side Validation
  if (!email || !password || !role) {
    req.session.error_msg = 'Please fill in all fields.';
    return res.redirect('/login');
  }

  try {
    // Query USERS table for matching email and role
    const result = await db.execute(
      `SELECT user_id, username, email, password, role
         FROM USERS
        WHERE LOWER(email) = LOWER(:email)
          AND role = :role`,
      { email, role }
    );

    if (!result.rows || result.rows.length === 0) {
      req.session.error_msg = 'Invalid email, role, or password.';
      return res.redirect('/login');
    }

    const user = result.rows[0];

    // Compare submitted password with stored bcrypt hash
    const isMatch = await bcrypt.compare(password, user.PASSWORD);

    if (!isMatch) {
      req.session.error_msg = 'Invalid email, role, or password.';
      return res.redirect('/login');
    }

    // Build session — store only what the app needs
    req.session.user = {
      user_id:  user.USER_ID,
      name:     user.USERNAME,
      email:    user.EMAIL,
      role:     user.ROLE
    };

    req.session.success_msg = `Welcome back, ${user.USERNAME}! Logged in as ${user.ROLE}.`;

    // Role-based redirect
    switch (user.ROLE) {
      case 'Admin':
        return res.redirect('/admin/dashboard');
      case 'Team Captain':
        return res.redirect('/captain/dashboard');
      case 'Player':
        return res.redirect('/player/dashboard');
      default:
        return res.redirect('/');
    }
  } catch (err) {
    console.error('Login error:', err.message);
    req.session.error_msg = 'An error occurred during authentication. Please try again.';
    return res.redirect('/login');
  }
};

// ---------------------------------------------------------------------------
//  POST — Register Handler
//  Hashes the password with bcryptjs (10 salt rounds), inserts a new row into
//  the USERS table using named binds and the USERS_SEQ sequence for the PK.
// ---------------------------------------------------------------------------
exports.postRegister = async (req, res) => {
  const { name, email, role, password, confirmPassword } = req.body;

  // Server-Side Validation
  let errors = [];

  if (!name || !email || !role || !password || !confirmPassword) {
    errors.push('Please fill in all fields.');
  }
  if (password !== confirmPassword) {
    errors.push('Passwords do not match.');
  }
  if (password && password.length < 6) {
    errors.push('Password must be at least 6 characters.');
  }
  if (role && !['Player', 'Team Captain'].includes(role)) {
    errors.push('Invalid role selected.');
  }

  if (errors.length > 0) {
    req.session.error_msg = errors.join(' ');
    return res.redirect('/register');
  }

  try {
    // Check if the email is already registered
    const existingUser = await db.execute(
      `SELECT user_id FROM USERS WHERE LOWER(email) = LOWER(:email)`,
      { email }
    );

    if (existingUser.rows && existingUser.rows.length > 0) {
      req.session.error_msg = 'An account with that email already exists.';
      return res.redirect('/register');
    }

    // Hash password with bcryptjs (10 salt rounds)
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Insert new user into USERS table
    await db.executeWithCommit(
      `INSERT INTO USERS (user_id, username, email, password, role)
       VALUES (USERS_SEQ.NEXTVAL, :username, :email, :password, :role)`,
      {
        username: name,
        email:    email,
        password: hashedPassword,
        role:     role
      }
    );

    req.session.success_msg = 'Registration successful! You can now log in.';
    return res.redirect('/login');
  } catch (err) {
    console.error('Registration error:', err.message);

    // Handle Oracle unique constraint violation (duplicate email)
    if (err.errorNum === 1) {
      req.session.error_msg = 'An account with that email already exists.';
    } else {
      req.session.error_msg = 'An error occurred during registration. Please try again.';
    }
    return res.redirect('/register');
  }
};

// ---------------------------------------------------------------------------
//  GET — Logout Handler
//  Destroys the express-session and redirects to the home page.
// ---------------------------------------------------------------------------
exports.logout = (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      console.error('Session destruction error:', err.message);
    }
    res.redirect('/');
  });
};
