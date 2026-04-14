const express = require('express');
const router = express.Router();
const controller = require('../controllers/incidencias.controller');
const multer = require('multer');
const path = require('path');

// Multer Config
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});
const upload = multer({ storage: storage });

// Definición de rutas
router.get('/', controller.getAllIncidencias);
router.get('/user/:userId', controller.getIncidenciasByUser);
router.post('/upload', upload.single('image'), controller.uploadOnly);
router.post('/', controller.createIncidencia);
router.patch('/:id/status', controller.updateStatus);

module.exports = router;
