const db = require('../config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const fetch = require('node-fetch');
const { OAuth2Client } = require('google-auth-library');
const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

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

    // Verificar si está bloqueado
    if (userRow.bloqueado) {
      return res.status(403).json({ message: 'Tu cuenta ha sido bloqueada. Contacta con el administrador.' });
    }

    // Generar Token (incluyendo el rol numérico)
    if (!process.env.JWT_SECRET) {
      console.error('CRÍTICO: No se ha definido JWT_SECRET en las variables de entorno');
      return res.status(500).json({ message: 'Error de configuración en el servidor (JWT)' });
    }

    const token = jwt.sign({ id: userRow.id, rol_id: userRow.rol_id }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRE || '30d'
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

exports.googleLogin = async (req, res) => {
  const { idToken, accessToken } = req.body;

  try {
    let email, name;

    if (idToken) {
      // Caso 1: Tenemos idToken (Móvil)
      const ticket = await client.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID
      });
      const payload = ticket.getPayload();
      email = payload.email;
      name = payload.name;
    } else if (accessToken) {
      // Caso 2: Tenemos accessToken (Web)
      const response = await fetch(`https://www.googleapis.com/oauth2/v3/userinfo?access_token=${accessToken}`);
      const data = await response.json();
      if (!data.email) throw new Error('No se pudo obtener el email del accessToken');
      email = data.email;
      name = data.name;
    } else {
      return res.status(400).json({ message: 'No se proporcionó ningún token' });
    }

    // 1. Buscar si el usuario existe por email
    let [rows] = await db.query('SELECT * FROM usuarios WHERE email = ?', [email]);
    let userRow;

    if (rows.length === 0) {
      // 2. Si no existe, crearlo (sin contraseña o con una aleatoria ya que usa Google)
      const [result] = await db.query(
        'INSERT INTO usuarios (email, password, nombre, rol_id, verificado) VALUES (?, ?, ?, ?, ?)',
        [email, 'GOOGLE_AUTH_NO_PASSWORD', name, 1, 1]
      );
      
      const [newRows] = await db.query('SELECT * FROM usuarios WHERE id = ?', [result.insertId]);
      userRow = newRows[0];
    } else {
      userRow = rows[0];
    }

    // 3. Generar JWT
    const token = jwt.sign({ id: userRow.id, rol_id: userRow.rol_id }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRE || '30d'
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
    console.error('Error en Google Login:', error);
    res.status(401).json({ message: 'Token de Google inválido', error: error.message });
  }
};
