const mysql = require('mysql2');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Prueba de conexión inmediata con log a archivo
pool.getConnection((err, connection) => {
  const fs = require('fs');
  if (err) {
    fs.appendFileSync('db_error.log', `${new Date().toISOString()} - ERROR CONEXIÓN DB: ${err.message}\n`);
    console.error('Error de conexión a la base de datos:', err);
  } else {
    fs.appendFileSync('db_error.log', `${new Date().toISOString()} - Conexión DB OK ✅\n`);
    connection.release();
  }
});

module.exports = pool.promise();
