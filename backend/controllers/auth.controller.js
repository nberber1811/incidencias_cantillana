const db = require('../config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const fetch = require('node-fetch');
const crypto = require('crypto');
const { OAuth2Client } = require('google-auth-library');
const mailer = require('../config/mailer');
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
    const hashedPassword = await bcrypt.hash(password, 10);
    const verificationToken = crypto.randomBytes(32).toString('hex');

    const [result] = await db.query(
      'INSERT INTO usuarios (nombre, email, password, telefono, verification_token, rol_id, verificado) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [nombre || 'Usuario Nuevo', email, hashedPassword, telefono || null, verificationToken, 1, 0]
    );

    // Enviar email de verificación
    try {
      await mailer.sendVerificationEmail(email, verificationToken);
    } catch (error) {
      console.error('Error enviando email:', error);
      // No bloqueamos el registro si falla el email, pero sería ideal avisar
    }

    res.status(201).json({ 
      message: 'Usuario registrado con éxito. Por favor, verifica tu correo.',
      user: {
        email,
        nombre: nombre || 'Usuario Nuevo',
        telefono: telefono || null,
        rol_id: 1
      }
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

    // Verificar si está verificado
    if (!userRow.verificado) {
      return res.status(403).json({ message: 'Por favor, verifica tu correo electrónico antes de iniciar sesión.' });
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

exports.verifyEmail = async (req, res) => {
  const { token } = req.params;

  try {
    const [rows] = await db.query('SELECT id FROM usuarios WHERE verification_token = ?', [token]);
    if (rows.length === 0) {
      return res.status(400).send('<h1>Enlace inválido o expirado</h1>');
    }

    await db.query('UPDATE usuarios SET verificado = 1, verification_token = NULL WHERE id = ?', [rows[0].id]);
    
    res.send('<h1>¡Correo verificado con éxito!</h1><p>Ya puedes iniciar sesión en la aplicación.</p>');
  } catch (error) {
    res.status(500).send('<h1>Error al verificar el correo</h1>');
  }
};

exports.forgotPassword = async (req, res) => {
  const { email } = req.body;

  try {
    const [rows] = await db.query('SELECT id FROM usuarios WHERE email = ?', [email]);
    if (rows.length === 0) {
      // Por seguridad, no decimos si el email existe o no, pero aquí mandamos éxito
      return res.json({ message: 'Si el correo existe, recibirás un enlace para restablecer tu contraseña.' });
    }

    const resetToken = Math.floor(100000 + Math.random() * 900000).toString(); // Código de 6 dígitos
    const expires = new Date(Date.now() + 3600000); // 1 hora

    await db.query(
      'UPDATE usuarios SET reset_token = ?, reset_token_expires = ? WHERE id = ?',
      [resetToken, expires, rows[0].id]
    );

    await mailer.sendResetPasswordEmail(email, resetToken);

    res.json({ message: 'Si el correo existe, recibirás un enlace para restablecer tu contraseña.' });
  } catch (error) {
    console.error('Error en forgotPassword:', error);
    res.status(500).json({ message: 'Error al procesar la solicitud' });
  }
};

exports.resetPassword = async (req, res) => {
  const { token, newPassword } = req.body;

  try {
    const [rows] = await db.query(
      'SELECT id FROM usuarios WHERE reset_token = ? AND reset_token_expires > NOW()',
      [token]
    );

    if (rows.length === 0) {
      return res.status(400).json({ message: 'El enlace ha expirado o es inválido' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await db.query(
      'UPDATE usuarios SET password = ?, reset_token = NULL, reset_token_expires = NULL WHERE id = ?',
      [hashedPassword, rows[0].id]
    );

    res.json({ message: 'Contraseña actualizada con éxito' });
  } catch (error) {
    console.error('Error en resetPassword:', error);
    res.status(500).json({ message: 'Error al actualizar la contraseña' });
  }
};
