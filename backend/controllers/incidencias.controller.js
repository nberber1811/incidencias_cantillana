const db = require('../config/db');

exports.getAllIncidencias = async (req, res) => {
  try {
    const query = `
      SELECT i.*, 
             DATE_FORMAT(i.fecha_creacion, '%Y-%m-%dT%H:%i:%sZ') as fecha_creacion,
             c.nombre as categoriaNombre, 
             e.nombre as estadoNombre 
      FROM incidencias i
      LEFT JOIN categorias c ON i.categoria_id = c.id
      LEFT JOIN estados e ON i.estado_id = e.id
      ORDER BY i.fecha_creacion DESC
    `;
    const [rows] = await db.query(query);
    res.json(rows);
  } catch (error) {
    console.error('Error getAllIncidencias:', error);
    res.status(500).json({ message: 'Error al obtener incidencias', error: error.message });
  }
};

exports.getIncidenciasByUser = async (req, res) => {
  const { userId } = req.params;
  try {
    const query = `
      SELECT i.*, 
             DATE_FORMAT(i.fecha_creacion, '%Y-%m-%dT%H:%i:%sZ') as fecha_creacion,
             c.nombre as categoriaNombre, 
             e.nombre as estadoNombre 
      FROM incidencias i
      LEFT JOIN categorias c ON i.categoria_id = c.id
      LEFT JOIN estados e ON i.estado_id = e.id
      WHERE i.usuario_id = ?
      ORDER BY i.fecha_creacion DESC
    `;
    const [rows] = await db.query(query, [userId]);
    res.json(rows);
  } catch (error) {
    console.error('Error getIncidenciasByUser:', error);
    res.status(500).json({ message: 'Error al obtener incidencias del usuario', error: error.message });
  }
};

exports.uploadOnly = async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: 'No se ha subido ninguna imagen' });
  }
  // Devolvemos solo el nombre del archivo, la app construye la URL
  res.json({ url: req.file.filename });
};

exports.createIncidencia = async (req, res) => {
  const { usuario_id, titulo, descripcion, categoria_id, latitud, longitud, direccion, image } = req.body;

  try {
    const [result] = await db.query(
      'INSERT INTO incidencias (usuario_id, titulo, descripcion, categoria_id, latitud, longitud, direccion, image, estado_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [usuario_id, titulo, descripcion, categoria_id || null, latitud, longitud, direccion, image, 1] // 1 = abierta
    );
    res.status(201).json({ id: result.insertId, message: 'Incidencia creada con éxito' });
  } catch (error) {
    console.error('Error al crear incidencia:', error);
    res.status(500).json({ message: 'Error al crear la incidencia', error: error.message });
  }
};

exports.updateStatus = async (req, res) => {
  const { id } = req.params;
  const { estado_id, usuario_id } = req.body;

  try {
    // 1. Obtener estado anterior para el historial
    const [current] = await db.query('SELECT estado_id FROM incidencias WHERE id = ?', [id]);
    const estadoPrevio = current.length > 0 ? current[0].estado_id : null;

    // 2. Actualizar incidencia
    await db.query('UPDATE incidencias SET estado_id = ? WHERE id = ?', [estado_id, id]);

    // 3. Registrar en historial
    await db.query(
      'INSERT INTO historial_estados (incidencia_id, estado_anterior, estado_nuevo, usuario_id) VALUES (?, ?, ?, ?)',
      [id, estadoPrevio, estado_id, usuario_id]
    );

    res.json({ message: 'Estado actualizado e historial registrado' });
  } catch (error) {
    res.status(500).json({ message: 'Error al actualizar el estado', error });
  }
};
