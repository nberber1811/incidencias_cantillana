const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
require('dotenv').config();
const path = require('path');
const fs = require('fs');

// Asegurar carpeta de subidas con manejo de error
try {
  const uploadsDir = path.join(__dirname, 'uploads');
  if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
    console.log('Carpeta uploads creada correctamente ✅');
  }
} catch (err) {
  console.error('CRÍTICO: No se pudo crear/acceder a la carpeta uploads:', err.message);
}

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Static files (for images)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
let db;
try {
  db = require('./config/db');
} catch (err) {
  console.error('ERROR CARGANDO BASE DE DATOS:', err.message);
}

const incidenciasRoutes = require('./routes/incidencias.routes');
const authRoutes = require('./routes/auth.routes');

// Endpoint de diagnóstico
app.get('/api/test-db', async (req, res) => {
  try {
    if (!db) throw new Error("Módulo de base de datos no cargado");
    const [rows] = await db.query('SELECT "Conexión MySQL OK" as status');
    res.json({ success: true, db: rows[0].status });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message, stack: err.stack });
  }
});

// Rutas
app.use('/api/incidencias', incidenciasRoutes);
app.use('/api/auth', authRoutes);

// Frontend SPA support
const frontendPath = path.join(__dirname, '..');
app.use(express.static(frontendPath));

// Catch-all para Flutter (SPA) compatible con Express 5
app.get('/*', (req, res) => {
  if (req.path.startsWith('/api') || req.path.startsWith('/uploads')) {
    return res.status(404).json({ error: 'Not found' });
  }
  res.sendFile(path.join(frontendPath, 'index.html'));
});

// Manejo de errores global para evitar caídas
app.use((err, req, res, next) => {
  console.error('ERROR NO MANEJADO:', err);
  res.status(500).json({ error: 'Internal Server Error', details: err.message });
});

// Start server
app.listen(PORT, () => {
  console.log(`Servidor Node.js activo en puerto ${PORT} 🚀`);
});
