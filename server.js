// ============================================================
// Whisperia: server.js
// Main Express application entry point
// ============================================================
const express = require('express');
const session = require('express-session');
const cors = require('cors');
const path = require('path');
const db = require('./config/database');

const app = express();
const PORT = process.env.PORT || 3000;

// ============================================================
// Middleware
// ============================================================
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Session configuration
app.use(session({
  secret: 'whisperia-secret-key-2024',
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: false,       // Set to true in production with HTTPS
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000  // 24 hours
  }
}));

// Serve static files from /public
app.use(express.static(path.join(__dirname, 'public')));

// ============================================================
// API Routes
// ============================================================
app.use('/api/auth', require('./routes/auth'));
app.use('/api/questions', require('./routes/questions'));
app.use('/api/answers', require('./routes/answers'));
app.use('/api/votes', require('./routes/votes'));
app.use('/api/bookmarks', require('./routes/bookmarks'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/users', require('./routes/users'));
app.use('/api/reports', require('./routes/reports'));
app.use('/api/tags', require('./routes/tags'));
app.use('/api/admin', require('./routes/admin'));

// ============================================================
// SPA Fallback — serve index.html for non-API routes
// ============================================================
app.get('*', (req, res) => {
  if (!req.path.startsWith('/api')) {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
  }
});

// ============================================================
// Start Server
// ============================================================
async function startup() {
  try {
    // Initialize Oracle connection pool
    await db.initialize();
    console.log('Database connection pool initialized.');

    app.listen(PORT, () => {
      console.log(`\n  ✦ Whisperia server running at http://localhost:${PORT}\n`);
    });
  } catch (err) {
    console.error('Failed to start server:', err);
    process.exit(1);
  }
}

// Graceful shutdown
async function shutdown() {
  console.log('\nShutting down...');
  try {
    await db.close();
  } catch (err) {
    console.error('Error during shutdown:', err);
  }
  process.exit(0);
}

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

startup();
