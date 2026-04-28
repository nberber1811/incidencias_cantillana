const db = require('../config/db');
const fs = require('fs');
const path = require('path');

exports.getAllIncidencias = async (req, res) => {
  try {
    const query = `
      SELECT i.*, 
             DATE_FORMAT(i.fecha_creacion, '%Y-%m-%dT%H:%i:%sZ') as fecha_creacion,
             c.nombre as categoriaNombre, 
             e.nombre as estadoNombre,
             u.nombre as tecnicoNombre,
             creador.rol_id as rolCreadorId
      FROM incidencias i
      LEFT JOIN categorias c ON i.categoria_id = c.id
      LEFT JOIN estados e ON i.estado_id = e.id
      LEFT JOIN usuarios u ON i.usuarioTecnico_id = u.id
      LEFT JOIN usuarios creador ON i.usuario_id = creador.id
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
    res.status(500).json({ message: 'Error al obtener incidencias del usuario', error: error.message });
  }
};

exports.getIncidenciasByTechnician = async (req, res) => {
  const { tecnicoId } = req.params;
  try {
    const query = `
      SELECT i.*, 
             DATE_FORMAT(i.fecha_creacion, '%Y-%m-%dT%H:%i:%sZ') as fecha_creacion,
             c.nombre as categoriaNombre, 
             e.nombre as estadoNombre 
      FROM incidencias i
      LEFT JOIN categorias c ON i.categoria_id = c.id
      LEFT JOIN estados e ON i.estado_id = e.id
      WHERE i.usuarioTecnico_id = ?
      ORDER BY i.fecha_creacion DESC
    `;
    const [rows] = await db.query(query, [tecnicoId]);
    res.json(rows);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener incidencias del técnico', error: error.message });
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
  const { estado_id, usuario_id, comentario_tecnico } = req.body;

  try {
    // 1. Obtener estado anterior
    const [current] = await db.query('SELECT estado_id FROM incidencias WHERE id = ?', [id]);
    const estadoPrevio = current.length > 0 ? current[0].estado_id : null;

    // 2. Actualizar incidencia con comentario
    await db.query(
      'UPDATE incidencias SET estado_id = ?, comentario_tecnico = ? WHERE id = ?', 
      [estado_id, comentario_tecnico || null, id]
    );

    // 3. Registrar en historial
    await db.query(
      'INSERT INTO historial_estados (incidencia_id, estado_anterior, estado_nuevo, usuario_id) VALUES (?, ?, ?, ?)',
      [id, estadoPrevio, estado_id, usuario_id]
    );

    res.json({ message: 'Estado y comentario actualizados' });
  } catch (error) {
    res.status(500).json({ message: 'Error al actualizar el estado', error: error.message });
  }
};

exports.updateIncidencia = async (req, res) => {
  const { id } = req.params;
  const { titulo, descripcion, categoria_id, latitud, longitud, direccion, image } = req.body;

  try {
    // 1. Verificar si la incidencia existe y obtener imagen actual
    const [rows] = await db.query('SELECT estado_id, image FROM incidencias WHERE id = ?', [id]);
    
    if (rows.length === 0) {
      return res.status(404).json({ message: 'Incidencia no encontrada' });
    }

    if (rows[0].estado_id !== 1) {
      return res.status(403).json({ message: 'Solo se pueden editar incidencias en estado abierto' });
    }

    const oldImage = rows[0].image;

    // 2. Actualizar campos
    await db.query(
      'UPDATE incidencias SET titulo = ?, descripcion = ?, categoria_id = ?, latitud = ?, longitud = ?, direccion = ?, image = ? WHERE id = ?',
      [titulo, descripcion, categoria_id || null, latitud, longitud, direccion, image, id]
    );

    // 3. Si la imagen ha cambiado, borrar la antigua
    if (image && oldImage && image !== oldImage) {
      const oldImagePath = path.join(__dirname, '..', 'uploads', oldImage);
      if (fs.existsSync(oldImagePath)) {
        fs.unlinkSync(oldImagePath);
      }
    }

    res.json({ message: 'Incidencia actualizada con éxito' });
  } catch (error) {
    console.error('Error al actualizar incidencia:', error);
    res.status(500).json({ message: 'Error al actualizar la incidencia', error: error.message });
  }
};

exports.deleteIncidencia = async (req, res) => {
  const { id } = req.params;

  try {
    // 1. Verificar si la incidencia existe y obtener la imagen
    const [rows] = await db.query('SELECT estado_id, image FROM incidencias WHERE id = ?', [id]);
    
    if (rows.length === 0) {
      return res.status(404).json({ message: 'Incidencia no encontrada' });
    }

    if (rows[0].estado_id !== 1) {
      return res.status(403).json({ message: 'Solo se pueden borrar incidencias en estado abierto' });
    }

    const imageName = rows[0].image;

    // 2. Borrar incidencia de la DB
    await db.query('DELETE FROM incidencias WHERE id = ?', [id]);

    // 3. Borrar archivo físico si existe
    if (imageName) {
      const imagePath = path.join(__dirname, '..', 'uploads', imageName);
      if (fs.existsSync(imagePath)) {
        fs.unlinkSync(imagePath);
      }
    }

    res.json({ message: 'Incidencia borrada con éxito y archivo eliminado' });
  } catch (error) {
    console.error('Error al borrar incidencia:', error);
    res.status(500).json({ message: 'Error al borrar la incidencia', error: error.message });
  }
};

exports.getCategorias = async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM categorias ORDER BY nombre ASC');
    res.json(rows);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener categorías', error: error.message });
  }
};

exports.getEstados = async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM estados ORDER BY id ASC');
    res.json(rows);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener estados', error: error.message });
  }
};
