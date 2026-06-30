// ============================================================
// Whisperia: config/database.js
// Oracle Database Connection Pool Configuration
// ============================================================
const oracledb = require('oracledb');

// Use OUT_FORMAT_OBJECT so rows come back as {COLUMN: value}
oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
// Auto-commit for simple queries (procedures handle their own)
oracledb.autoCommit = true;

const dbConfig = {
  user: 'set your username',
  password: 'set your password',
  connectString: 'localhost:1521/XEPDB1',
  poolMin: 2,
  poolMax: 10,
  poolIncrement: 1
};

/**
 * Initialize the Oracle connection pool.
 * Called once at application startup.
 */
async function initialize() {
  try {
    await oracledb.createPool(dbConfig);
    console.log('Oracle connection pool created successfully.');
  } catch (err) {
    console.error('Error creating Oracle pool:', err);
    throw err;
  }
}

/**
 * Close the Oracle connection pool.
 * Called on graceful shutdown.
 */
async function close() {
  try {
    await oracledb.getPool().close(10);
    console.log('Oracle connection pool closed.');
  } catch (err) {
    console.error('Error closing Oracle pool:', err);
  }
}

/**
 * Get a connection from the pool.
 * Always release connections in a finally block!
 */
async function getConnection() {
  return await oracledb.getConnection();
}

module.exports = { initialize, close, getConnection };
