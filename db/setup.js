const fs = require('fs');
const path = require('path');
const db = require('./connection');

async function run() {
  const schemaPath = path.join(__dirname, 'schema.sql');
  if (!fs.existsSync(schemaPath)) {
    console.error('schema.sql file not found!');
    process.exit(1);
  }

  const schemaSql = fs.readFileSync(schemaPath, 'utf8');

  // Initialize the database connection pool
  try {
    await db.initialize();
  } catch (err) {
    console.error('Failed to connect to Oracle database. Please make sure the service is running and credentials in .env are correct.');
    process.exit(1);
  }

  console.log('Connected to database. Starting schema execution...');

  const lines = schemaSql.split(/\r?\n/);
  let currentBlock = [];
  let inPlSql = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmed = line.trim();
    
    // Ignore lines that are comments or empty unless we are accumulating inside a block
    if (!inPlSql && (trimmed.startsWith('--') || trimmed.length === 0)) {
      continue;
    }

    // Detect entry into a PL/SQL block
    if (!inPlSql && /^(DECLARE|BEGIN|CREATE\s+(OR\s+REPLACE\s+)?TRIGGER)/i.test(trimmed)) {
      inPlSql = true;
    }

    if (inPlSql) {
      if (trimmed === '/') {
        // End of PL/SQL block, execute it
        const blockSql = currentBlock.join('\n').trim();
        if (blockSql) {
          console.log(`Executing PL/SQL block...`);
          try {
            await db.execute(blockSql);
            console.log('PL/SQL block executed successfully.');
          } catch (err) {
            console.error('Error executing PL/SQL block:', err.message);
            console.error('PL/SQL code:\n', blockSql);
          }
        }
        currentBlock = [];
        inPlSql = false;
      } else {
        currentBlock.push(line);
      }
    } else {
      // Regular SQL statement
      if (trimmed.endsWith(';')) {
        // Remove trailing semicolon for node-oracledb execution
        const lastLineCleaned = line.substring(0, line.lastIndexOf(';'));
        currentBlock.push(lastLineCleaned);
        const stmtSql = currentBlock.join('\n').trim();
        if (stmtSql) {
          console.log(`Executing SQL statement: ${stmtSql.split('\n')[0].substring(0, 60)}...`);
          try {
            await db.execute(stmtSql);
          } catch (err) {
            console.error('Error executing statement:', err.message);
            console.error('Statement SQL:\n', stmtSql);
          }
        }
        currentBlock = [];
      } else {
        currentBlock.push(line);
      }
    }
  }

  console.log('Database schema setup run completed.');
  await db.close();
}

run().catch(err => {
  console.error('Database setup script execution failed:', err);
  process.exit(1);
});
