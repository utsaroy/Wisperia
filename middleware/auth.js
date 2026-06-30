// ============================================================
// Whisperia: middleware/auth.js
// Session-based authentication middleware
// ============================================================

/**
 * Middleware: Requires user to be logged in.
 * Checks req.session.user exists.
 */
function isAuthenticated(req, res, next) {
  if (req.session && req.session.user) {
    return next();
  }
  return res.status(401).json({ error: 'Authentication required. Please log in.' });
}

/**
 * Middleware: Optionally attaches user info if logged in.
 * Does NOT block unauthenticated requests.
 */
function optionalAuth(req, res, next) {
  // User info is available via req.session.user if logged in
  return next();
}

module.exports = { isAuthenticated, optionalAuth };
