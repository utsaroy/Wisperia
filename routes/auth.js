// ============================================================
// Whisperia: routes/auth.js
// Authentication routes: register, login, logout, me
// ============================================================
const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');
const db = require('../config/database');
const oracledb = require('oracledb');

// POST /api/register
router.post('/register', [
  body('username').trim().isLength({ min: 3, max: 50 }).withMessage('Username must be 3-50 characters'),
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  let connection;
  try {
    connection = await db.getConnection();
    const { username, email, password } = req.body;

    // Check if username or email already exists
    const existing = await connection.execute(
      `SELECT UserID FROM Users WHERE Username = :username OR Email = :email`,
      { username, email }
    );
    if (existing.rows.length > 0) {
      return res.status(409).json({ error: 'Username or email already exists' });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // Insert new user using sequence
    const result = await connection.execute(
      `INSERT INTO Users (UserID, Username, Email, PasswordHash, Role, JoinDate)
       VALUES (user_seq.NEXTVAL, :username, :email, :passwordHash, 'user', SYSDATE)
       RETURNING UserID INTO :userId`,
      {
        username,
        email,
        passwordHash,
        userId: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
      }
    );

    const userId = result.outBinds.userId[0];

    // Set session
    req.session.user = { id: userId, username, email, role: 'user' };

    res.status(201).json({
      message: 'Registration successful',
      user: { id: userId, username, email, role: 'user' }
    });

  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ error: 'Registration failed' });
  } finally {
    if (connection) await connection.close();
  }
});

// POST /api/login
router.post('/login', [
  body('username').trim().notEmpty().withMessage('Username required'),
  body('password').notEmpty().withMessage('Password required')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  let connection;
  try {
    connection = await db.getConnection();
    const { username, password } = req.body;

    const result = await connection.execute(
      `SELECT UserID, Username, Email, PasswordHash, Role FROM Users WHERE Username = :username`,
      { username }
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    const user = result.rows[0];
    const isMatch = await bcrypt.compare(password, user.PASSWORDHASH);

    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    // Set session
    req.session.user = {
      id: user.USERID,
      username: user.USERNAME,
      email: user.EMAIL,
      role: user.ROLE
    };

    res.json({
      message: 'Login successful',
      user: { id: user.USERID, username: user.USERNAME, email: user.EMAIL, role: user.ROLE }
    });

  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Login failed' });
  } finally {
    if (connection) await connection.close();
  }
});

// POST /api/logout
router.post('/logout', (req, res) => {
  req.session.destroy(err => {
    if (err) {
      return res.status(500).json({ error: 'Logout failed' });
    }
    res.json({ message: 'Logged out successfully' });
  });
});

// GET /api/me - Get current user
router.get('/me', (req, res) => {
  if (req.session && req.session.user) {
    return res.json({ user: req.session.user });
  }
  res.status(401).json({ user: null });
});

module.exports = router;
