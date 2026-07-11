const oracledb = require('oracledb');
require('dotenv').config();

// Enable thick mode if Oracle Instant Client is available, otherwise use thin mode
try {
  oracledb.initOracleClient();
  console.log('Oracle Client: Thick mode enabled.');
} catch (err) {
  console.log('Oracle Client: Using default Thin mode (node-oracledb 6+).');
}

// Set default output format for all queries
oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
oracledb.autoCommit = false;

let pool;

/**
 * Initialize the Oracle connection pool.
 * Pool settings are sourced from environment variables.
 */
async function initialize() {
  try {
    pool = await oracledb.createPool({
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      connectString: process.env.DB_CONNECT_STRING, // e.g., "localhost:1521/XE" or "localhost:1521/FREE"
      poolMin: 2,
      poolMax: 10,
      poolIncrement: 1,
      poolTimeout: 60
    });
    console.log('Oracle Database connection pool initialized successfully.');
  } catch (err) {
    console.error('Failed to initialize Oracle Database connection pool:', err.message);
    throw err;
  }
}

/**
 * Close the connection pool gracefully.
 */
async function close() {
  if (pool) {
    try {
      await pool.close(10); // 10 second drain timeout
      console.log('Oracle Database connection pool closed.');
    } catch (err) {
      console.error('Error closing Oracle Database connection pool:', err.message);
    }
  }
}

/**
 * Execute a SQL statement using the connection pool.
 * @param {string} sql - The SQL query or PL/SQL block to execute.
 * @param {Object|Array} binds - Bind variables (positional array or named object).
 * @param {Object} opts - Additional options (autoCommit, outFormat, etc.).
 * @returns {Promise<Object>} - The result object from oracledb.
 */
async function execute(sql, binds = {}, opts = {}) {
  let conn;
  opts.outFormat = opts.outFormat || oracledb.OUT_FORMAT_OBJECT;
  opts.autoCommit = opts.autoCommit !== undefined ? opts.autoCommit : false;

  try {
    conn = await oracledb.getConnection();
    const result = await conn.execute(sql, binds, opts);
    return result;
  } catch (err) {
    console.error('Database query execution error:', err.message);
    throw err;
  } finally {
    if (conn) {
      try {
        await conn.close();
      } catch (err) {
        console.error('Error closing connection:', err.message);
      }
    }
  }
}

/**
 * Execute a SQL statement with auto-commit enabled.
 * Convenience wrapper for INSERT/UPDATE/DELETE operations.
 * @param {string} sql - The SQL statement to execute.
 * @param {Object|Array} binds - Bind variables.
 * @returns {Promise<Object>} - The result object from oracledb.
 */
async function executeWithCommit(sql, binds = {}) {
  return execute(sql, binds, { autoCommit: true });
}

/**
 * Get a raw connection from the pool for multi-statement transactions.
 * Caller is responsible for committing/rolling back and closing the connection.
 * @returns {Promise<oracledb.Connection>}
 */
async function getConnection() {
  return oracledb.getConnection();
}

module.exports = {
  initialize,
  close,
  execute,
  executeWithCommit,
  getConnection,
  oracledb
};
