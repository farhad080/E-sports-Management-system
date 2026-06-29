const fs = require('fs');
const path = require('path');
const db = require('./connection');

async function run() {
  const procPath = path.join(__dirname, 'procedures.sql');
  if (!fs.existsSync(procPath)) {
    console.error('procedures.sql file not found!');
    process.exit(1);
  }

  const procSql = fs.readFileSync(procPath, 'utf8');

  // Initialize the database connection pool
  try {
    await db.initialize();
  } catch (err) {
    console.error('Failed to connect to Oracle database.');
    process.exit(1);
  }

  console.log('Connected to database. Compiling stored procedures & functions...');

  const lines = procSql.split(/\r?\n/);
  let currentBlock = [];
  let inPlSql = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmed = line.trim();
    
    // Ignore lines that are sqlplus config commands (like SET SERVEROUTPUT ON) or empty or comments
    if (!inPlSql && (trimmed.startsWith('--') || trimmed.length === 0 || trimmed.toLowerCase().startsWith('set '))) {
      continue;
    }

    // Detect PL/SQL block / trigger / procedure / function starts
    if (!inPlSql && /^(CREATE\s+(OR\s+REPLACE\s+)?(PROCEDURE|FUNCTION))/i.test(trimmed)) {
      inPlSql = true;
    }

    if (inPlSql) {
      if (trimmed === '/') {
        // End of PL/SQL block, execute it
        const blockSql = currentBlock.join('\n').trim();
        if (blockSql) {
          console.log(`Compiling block starting with: ${blockSql.split('\n')[0].substring(0, 60)}...`);
          try {
            await db.execute(blockSql);
            console.log('Compiled successfully.');
          } catch (err) {
            console.error('Compilation error:', err.message);
            console.error('Block SQL:\n', blockSql);
          }
        }
        currentBlock = [];
        inPlSql = false;
      } else {
        currentBlock.push(line);
      }
    } else {
      // Standard SQL statement
      if (trimmed.endsWith(';')) {
        const lastLineCleaned = line.substring(0, line.lastIndexOf(';'));
        currentBlock.push(lastLineCleaned);
        const stmtSql = currentBlock.join('\n').trim();
        if (stmtSql) {
          console.log(`Executing statement: ${stmtSql.substring(0, 60)}...`);
          try {
            await db.execute(stmtSql);
          } catch (err) {
            console.error('Execution error:', err.message);
          }
        }
        currentBlock = [];
      } else {
        currentBlock.push(line);
      }
    }
  }

  console.log('Stored procedures & functions compilation completed.');
  await db.close();
}

run().catch(err => {
  console.error('Compilation script execution failed:', err);
  process.exit(1);
});
