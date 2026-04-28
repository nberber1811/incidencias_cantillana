const db = require('../config/db');

// Listar todos los usuarios (solo para admins)
exports.getAllUsers = async (req, res) => {
  try {
    const [users] = await db.query(
      'SELECT id, nombre, email, telefono, rol_id, verificado, createdAt FROM usuarios ORDER BY createdAt DESC'
    );
    res.json(users);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener usuarios', error: error.message });
  }
};

// Cambiar el rol de un usuario
exports.updateUserRole = async (req, res) => {
  const { uid } = req.params;
  const { rol_id } = req.body;

  try {
    await db.query('UPDATE usuarios SET rol_id = ? WHERE id = ?', [rol_id, uid]);
    res.json({ message: 'Rol actualizado correctamente' });
  } catch (error) {
    res.status(500).json({ message: 'Error al actualizar el rol', error: error.message });
  }
};

exports.assignTechnician = async (req, res) => {
  const { id } = req.params; // Viene de la URL /incidencias/:id/assign
  const { tecnicoId } = req.body;
  try {
    const finalTecnicoId = (tecnicoId === null || tecnicoId === '') ? null : tecnicoId;
    
    // 1. Actualizar incidencia
    await db.query(
      'UPDATE incidencias SET usuarioTecnico_id = ?, estado_id = ? WHERE id = ?',
      [finalTecnicoId, finalTecnicoId ? 2 : 1, id]
    );

    // 2. Registrar en historial
    await db.query(
      'INSERT INTO historial_estados (incidencia_id, estado_nuevo, usuario_id) VALUES (?, ?, ?)',
      [id, finalTecnicoId ? 2 : 1, req.user.id]
    );

    res.json({ message: 'Asignación actualizada correctamente' });
  } catch (error) {
    res.status(500).json({ message: 'Error al actualizar asignación', error: error.message });
  }
};

exports.getTechnicians = async (req, res) => {
  try {
    const [technicians] = await db.query(
      'SELECT id, nombre FROM usuarios WHERE rol_id = 2'
    );
    res.json(technicians);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener técnicos', error: error.message });
  }
};

// Borrar incidencias por estado (solo para estados finales 3, 4, 5)
exports.deleteFinalIncidencias = async (req, res) => {
  const { estadoId } = req.query;
  
  try {
    if (estadoId) {
      await db.query('DELETE FROM incidencias WHERE estado_id = ? AND estado_id IN (3, 4, 5)', [estadoId]);
      res.json({ message: `Incidencias del estado ${estadoId} eliminadas correctamente` });
    } else {
      await db.query('DELETE FROM incidencias WHERE estado_id IN (3, 4, 5)');
      res.json({ message: 'Historial de incidencias finalizadas limpiado correctamente' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Error al limpiar historial', error: error.message });
  }
};

// Crear nueva categoría
exports.createCategory = async (req, res) => {
  const { nombre } = req.body;
  try {
    if (!nombre) return res.status(400).json({ message: 'El nombre es obligatorio' });
    const [result] = await db.query('INSERT INTO categorias (nombre) VALUES (?)', [nombre]);
    res.status(201).json({ id: result.insertId, message: 'Categoría creada con éxito' });
  } catch (error) {
    res.status(500).json({ message: 'Error al crear categoría', error: error.message });
  }
};

// Actualizar categoría
exports.updateCategory = async (req, res) => {
  const { id } = req.params;
  const { nombre } = req.body;
  try {
    await db.query('UPDATE categorias SET nombre = ? WHERE id = ?', [nombre, id]);
    res.json({ message: 'Categoría actualizada con éxito' });
  } catch (error) {
    res.status(500).json({ message: 'Error al actualizar categoría', error: error.message });
  }
};

// Borrar categoría
exports.deleteCategory = async (req, res) => {
  const { id } = req.params;
  try {
    // Verificar si hay incidencias usando esta categoría
    const [usage] = await db.query('SELECT COUNT(*) as count FROM incidencias WHERE categoria_id = ?', [id]);
    if (usage[0].count > 0) {
      return res.status(400).json({ message: 'No se puede borrar una categoría que tiene incidencias asociadas' });
    }
    await db.query('DELETE FROM categorias WHERE id = ?', [id]);
    res.json({ message: 'Categoría eliminada con éxito' });
  } catch (error) {
    res.status(500).json({ message: 'Error al eliminar categoría', error: error.message });
  }
};

// Crear nuevo rol/estado
exports.createRole = async (req, res) => {
  const { nombre } = req.body;
  try {
    if (!nombre) return res.status(400).json({ message: 'El nombre es obligatorio' });
    const [result] = await db.query('INSERT INTO estados (nombre) VALUES (?)', [nombre]);
    res.status(201).json({ id: result.insertId, message: 'Rol/Estado creado con éxito' });
  } catch (error) {
    res.status(500).json({ message: 'Error al crear rol', error: error.message });
  }
};

// Actualizar rol/estado
exports.updateRole = async (req, res) => {
  const { id } = req.params;
  const { nombre } = req.body;
  try {
    await db.query('UPDATE estados SET nombre = ? WHERE id = ?', [nombre, id]);
    res.json({ message: 'Rol/Estado actualizado con éxito' });
  } catch (error) {
    res.status(500).json({ message: 'Error al actualizar rol', error: error.message });
  }
};

// Borrar rol/estado
exports.deleteRole = async (req, res) => {
  const { id } = req.params;
  try {
    // No permitir borrar estados base (Abierta, En Proceso, Resuelta, etc. del 1 al 5)
    if (parseInt(id) <= 5) {
      return res.status(400).json({ message: 'No se pueden eliminar los estados base del sistema' });
    }
    const [usage] = await db.query('SELECT COUNT(*) as count FROM incidencias WHERE estado_id = ?', [id]);
    if (usage[0].count > 0) {
      return res.status(400).json({ message: 'No se puede borrar un estado que tiene incidencias asociadas' });
    }
    await db.query('DELETE FROM estados WHERE id = ?', [id]);
    res.json({ message: 'Rol/Estado eliminado con éxito' });
  } catch (error) {
    res.status(500).json({ message: 'Error al eliminar rol', error: error.message });
  }
};
