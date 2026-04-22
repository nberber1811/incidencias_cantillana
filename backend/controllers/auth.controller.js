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
      'INSERT INTO usuarios (email, password, nombre, telefono, rol_id, verificado) VALUES (?, ?, ?, ?, ?, ?)',
      [email, hashedPassword, nombre || 'Usuario Nuevo', telefono || null, 1, 1] // verificado = 1 por defecto ahora
    );

    res.status(201).json({ 
      user: {
        uid: result.insertId.toString(),
        email,
        nombre: nombre || 'Usuario Nuevo',
        telefono: telefono || null,
        rol_id: 1
      },
      message: 'Usuario registrado con éxito' 
    });
  } catch (error) {
    console.error('ERROR CRÍTICO EN REGISTRO:', error);
    
    // Loguear a un archivo
    const fs = require('fs');
    const logMessage = `[${new Date().toISOString()}] REGISTRO ERROR: ${error.message}\nStack: ${error.stack}\n\n`;
    fs.appendFileSync('registro_errors.log', logMessage);

    res.status(500).json({ 
      success: false, 
      message: `Error en el servidor: ${error.message}`, // Ahora incluimos el detalle real del error
      error_detalle: error.message,
      code: error.code
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

exports.updateProfile = async (req, res) => {
  const { uid } = req.params;
  const { nombre, telefono } = req.body;

  try {
    // 1. Actualizar usuario
    await db.query(
      'UPDATE usuarios SET nombre = ?, telefono = ? WHERE id = ?',
      [nombre, telefono, uid]
    );

    // 2. Obtener el usuario actualizado para devolverlo
    const [rows] = await db.query('SELECT id, email, nombre, telefono, rol_id FROM usuarios WHERE id = ?', [uid]);
    
    if (rows.length === 0) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    const userRow = rows[0];
    const user = {
      uid: userRow.id.toString(),
      email: userRow.email,
      nombre: userRow.nombre,
      telefono: userRow.telefono,
      rol_id: userRow.rol_id
    };

    res.json({ user, message: 'Perfil actualizado con éxito' });
  } catch (error) {
    console.error('Error al actualizar perfil:', error);
    res.status(500).json({ message: 'Error al actualizar el perfil', error: error.message });
  }
};
