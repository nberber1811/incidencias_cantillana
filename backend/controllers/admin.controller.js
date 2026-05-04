const db = require('../config/db');

// Listar todos los usuarios (solo para admins)
exports.getAllUsers = async (req, res) => {
  try {
    const [users] = await db.query(
      'SELECT id, nombre, email, telefono, rol_id, verificado, bloqueado, createdAt FROM usuarios ORDER BY createdAt DESC'
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
    
    // 0. Obtener estado anterior
    const [current] = await db.query('SELECT estado_id FROM incidencias WHERE id = ?', [id]);
    const estadoPrevio = current.length > 0 ? current[0].estado_id : null;

    // 1. Actualizar incidencia
    const estadoNuevo = finalTecnicoId ? 2 : 1;
    await db.query(
      'UPDATE incidencias SET usuarioTecnico_id = ?, estado_id = ? WHERE id = ?',
      [finalTecnicoId, estadoNuevo, id]
    );

    // 2. Registrar en historial solo si el estado realmente cambia
    if (estadoPrevio !== estadoNuevo) {
      await db.query(
        'INSERT INTO historial_estados (incidencia_id, estado_anterior, estado_nuevo, usuario_id) VALUES (?, ?, ?, ?)',
        [id, estadoPrevio, estadoNuevo, req.user.id]
      );
    }

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
      // Borrar historial primero
      await db.query('DELETE FROM historial_estados WHERE incidencia_id IN (SELECT id FROM incidencias WHERE estado_id = ? AND estado_id IN (3, 4, 5))', [estadoId]);
      await db.query('DELETE FROM incidencias WHERE estado_id = ? AND estado_id IN (3, 4, 5)', [estadoId]);
      res.json({ message: `Incidencias del estado ${estadoId} eliminadas correctamente` });
    } else {
      // Borrar historial primero
      await db.query('DELETE FROM historial_estados WHERE incidencia_id IN (SELECT id FROM incidencias WHERE estado_id IN (3, 4, 5))');
      await db.query('DELETE FROM incidencias WHERE estado_id IN (3, 4, 5)');
      res.json({ message: 'Historial de incidencias finalizadas limpiado correctamente' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Error al limpiar historial', error: error.message });
  }
};

// Crear nueva categoría
exports.createCategory = async (req, res) => {
  const { nombre, descripcion } = req.body;
  try {
    if (!nombre) return res.status(400).json({ message: 'El nombre es obligatorio' });
    const [result] = await db.query('INSERT INTO categorias (nombre, descripcion) VALUES (?, ?)', [nombre, descripcion || null]);
    res.status(201).json({ id: result.insertId, message: 'Categoría creada con éxito' });
  } catch (error) {
    res.status(500).json({ message: 'Error al crear categoría', error: error.message });
  }
};

// Actualizar categoría
exports.updateCategory = async (req, res) => {
  const { id } = req.params;
  const { nombre, descripcion } = req.body;
  try {
    await db.query('UPDATE categorias SET nombre = ?, descripcion = ? WHERE id = ?', [nombre, descripcion || null, id]);
    res.json({ message: 'Categoría actualizada con éxito' });
  } catch (error) {
    res.status(500).json({ message: 'Error al actualizar categoría', error: error.message });
  }
};

// Borrar categoría
exports.deleteCategory = async (req, res) => {
  const { id } = req.params;
  try {
    const [usage] = await db.query('SELECT COUNT(*) as count FROM incidencias WHERE categoria_id = ?', [id]);
    if (usage[0].count > 0) {
      // Actualizar incidencias para que dejen de usar esta categoría (pasar a null / Sin categoría)
      await db.query('UPDATE incidencias SET categoria_id = NULL WHERE categoria_id = ?', [id]);
    }
    await db.query('DELETE FROM categorias WHERE id = ?', [id]);
    res.json({ message: 'Categoría eliminada con éxito' });
  } catch (error) {
    res.status(500).json({ message: 'Error al eliminar categoría', error: error.message });
  }
};

// Crear nuevo rol/estado
exports.createRole = async (req, res) => {
  const { nombre, descripcion } = req.body;
  try {
    if (!nombre) return res.status(400).json({ message: 'El nombre es obligatorio' });
    const [result] = await db.query('INSERT INTO estados (nombre, descripcion) VALUES (?, ?)', [nombre, descripcion || null]);
    res.status(201).json({ id: result.insertId, message: 'Rol/Estado creado con éxito' });
  } catch (error) {
    res.status(500).json({ message: 'Error al crear rol', error: error.message });
  }
};

// Actualizar rol/estado
exports.updateRole = async (req, res) => {
  const { id } = req.params;
  const { nombre, descripcion } = req.body;
  try {
    await db.query('UPDATE estados SET nombre = ?, descripcion = ? WHERE id = ?', [nombre, descripcion || null, id]);
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

// Bloquear/Desbloquear usuario (Solo Admin)
exports.toggleBlockUser = async (req, res) => {
  const { uid } = req.params;
  const { bloqueado } = req.body;

  try {
    await db.query('UPDATE usuarios SET bloqueado = ? WHERE id = ?', [bloqueado ? 1 : 0, uid]);
    res.json({ message: bloqueado ? 'Usuario bloqueado correctamente' : 'Usuario desbloqueado correctamente' });
  } catch (error) {
    res.status(500).json({ message: 'Error al cambiar estado de bloqueo', error: error.message });
  }
};

// Borrar usuario (Solo Admin)
exports.deleteUser = async (req, res) => {
  const { uid } = req.params;

  try {
    // 1. Verificar si tiene incidencias
    const [incidencias] = await db.query('SELECT COUNT(*) as count FROM incidencias WHERE usuario_id = ? OR usuarioTecnico_id = ?', [uid, uid]);
    
    if (incidencias[0].count > 0) {
      return res.status(400).json({ 
        message: 'No se puede eliminar el usuario porque tiene incidencias asociadas. Prueba a bloquearlo en su lugar.' 
      });
    }

    await db.query('DELETE FROM usuarios WHERE id = ?', [uid]);
    res.json({ message: 'Usuario eliminado con éxito' });
  } catch (error) {
    res.status(500).json({ message: 'Error al eliminar usuario', error: error.message });
  }
};

