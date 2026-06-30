// ============================================================
// Whisperia: middleware/admin.js
// Role-based admin authorization middleware
// ============================================================

/**
 * Middleware: Requires user to be an admin.
 * Must be used AFTER isAuthenticated middleware.
 */
function isAdmin(req, res, next) {
  if (req.session && req.session.user && req.session.user.role === 'admin') {
    return next();
  }
  return res.status(403).json({ error: 'Access denied. Admin privileges required.' });
}

module.exports = { isAdmin };
