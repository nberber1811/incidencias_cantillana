const jwt = require('jsonwebtoken');

// Verifica que el usuario esté logueado (Token válido)
exports.verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(403).json({ message: 'No se proporcionó un token' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // Guardamos id y rol_id
    next();
  } catch (error) {
    return res.status(401).json({ message: 'Token inválido o expirado' });
  }
};

// Verifica que el usuario sea Administrador (rol_id = 3)
exports.isAdmin = (req, res, next) => {
  if (req.user && req.user.rol_id === 3) {
    next();
  } else {
    res.status(403).json({ message: 'Acceso denegado: Se requiere rol de Administrador' });
  }
};
