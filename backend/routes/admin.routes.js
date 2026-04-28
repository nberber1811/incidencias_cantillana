const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const { verifyToken, isAdmin } = require('../middleware/auth.middleware');

// Todas las rutas aquí requieren Token y ser Admin
router.use(verifyToken);
router.use(isAdmin);

router.get('/users', adminController.getAllUsers);
router.put('/users/:uid/role', adminController.updateUserRole);
router.get('/technicians', adminController.getTechnicians);
router.put('/incidencias/:id/assign', adminController.assignTechnician);
router.delete('/incidencias/finalizadas', adminController.deleteFinalIncidencias);

// Gestión de Categorías
router.post('/categories', adminController.createCategory);
router.put('/categories/:id', adminController.updateCategory);
router.delete('/categories/:id', adminController.deleteCategory);

// Gestión de Roles/Estados
router.post('/roles', adminController.createRole);
router.put('/roles/:id', adminController.updateRole);
router.delete('/roles/:id', adminController.deleteRole);

module.exports = router;
