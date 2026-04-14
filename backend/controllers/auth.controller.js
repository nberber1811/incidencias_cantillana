const db = require('../config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

exports.register = async (req, res) => {
  const { email, password, nombre, telefono } = req.body;

  try {
    // Verificar si el usuario ya existe
    const [existing] = await db.query('SELECT id FROM usuarios WHERE email = ?', [email]);
    if (existing.length > 0) {
      return res.status(400).json({ message: 'El correo ya está registrado' });
    }

    // Encriptar contraseña
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Insertar usuario (rol_id = 1: ciudadano)
    const [result] = await db.query(
      'INSERT INTO usuarios (email, password, nombre, telefono, rol_id) VALUES (?, ?, ?, ?, ?)',
      [email, hashedPassword, nombre || 'Usuario Nuevo', telefono || null, 1]
    );

    const user = {
      uid: result.insertId.toString(),
      email,
      nombre: nombre || 'Usuario Nuevo',
      telefono: telefono || null,
      rol_id: 1
    };

    // Generar Token para auto-login tras registro
    const token = jwt.sign({ id: user.uid }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRE
    });

    res.status(201).json({ user, token, message: 'Usuario registrado con éxito' });
  } catch (error) {
    console.error('ERROR CRÍTICO EN REGISTRO:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error en el servidor', 
      error_detalle: error.message,
      error_full: error
    });
  }
};

exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    const [rows] = await db.query('SELECT * FROM usuarios WHERE email = ?', [email]);
    if (rows.length === 0) {
      return res.status(401).json({ message: 'Credenciales inválidas' });
    }

    const userRow = rows[0];

    // Verificar contraseña
    const isMatch = await bcrypt.compare(password, userRow.password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Credenciales inválidas' });
    }

    // Generar Token (incluyendo el rol numérico)
    const token = jwt.sign({ id: userRow.id, rol_id: userRow.rol_id }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRE
    });

    const user = {
      uid: userRow.id.toString(),
      email: userRow.email,
      nombre: userRow.nombre,
      telefono: userRow.telefono,
      rol_id: userRow.rol_id
    };

    res.json({ user, token });
  } catch (error) {
    console.error('Error detallado en login:', error);
    res.status(500).json({ message: 'Error en el login', error: error.message });
  }
};
