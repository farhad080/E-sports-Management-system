const oracledb = require('oracledb');
require('dotenv').config();

// Enable thin mode if not already configured (supported natively in node-oracledb 6+)
try {
  oracledb.initOracleClient();
} catch (err) {
  // Client already initialized or using default thin mode
}

let pool;

async function initialize() {
  try {
    pool = await oracledb.createPool({
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      connectString: process.env.DB_CONNECT_STRING, // e.g., "localhost:1521/FREE" or "localhost:1521/XEPDB1"
      poolMin: 2,
      poolMax: 10,
      poolIncrement: 1,
      poolTimeout: 60
    });
    console.log('Oracle Database connection pool initialized successfully.');
  } catch (err) {
    console.error('Failed to initialize Oracle Database connection pool:', err);
    throw err;
  }
}

async function close() {
  if (pool) {
    try {
      await pool.close();
      console.log('Oracle Database connection pool closed.');
    } catch (err) {
      console.error('Error closing Oracle Database connection pool:', err);
    }
  }
}

async function execute(sql, binds = [], opts = {}) {
  let conn;
  opts.outFormat = opts.outFormat || oracledb.OUT_FORMAT_OBJECT;
  opts.autoCommit = opts.autoCommit || false;

  try {
    conn = await oracledb.getConnection();
    const result = await conn.execute(sql, binds, opts);
    return result;
  } catch (err) {
    console.error('Database query execution error:', err);
    throw err;
  } finally {
    if (conn) {
      try {
        await conn.close();
      } catch (err) {
        console.error('Error closing connection:', err);
      }
    }
  }
}

module.exports = {
  initialize,
  close,
  execute,
  oracledb
};
