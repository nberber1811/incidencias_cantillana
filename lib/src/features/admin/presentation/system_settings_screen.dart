import 'package:ayuntamiento_incidencias/src/features/admin/presentation/admin_controller.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/data/incidencia_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SystemSettingsScreen extends ConsumerStatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  ConsumerState<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends ConsumerState<SystemSettingsScreen> {
  final _categoryController = TextEditingController();
  final _roleController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _submitCategory() async {
    if (_categoryController.text.isEmpty) return;
    await ref.read(adminControllerProvider.notifier).createCategory(_categoryController.text);
    _categoryController.clear();
    ref.invalidate(categoriasProvider); // Refrescar lista
  }

  void _submitRole() async {
    if (_roleController.text.isEmpty) return;
    await ref.read(adminControllerProvider.notifier).createRole(_roleController.text);
    _roleController.clear();
    ref.invalidate(estadosProvider); // Refrescar lista
  }

  void _editCategory(int id, String currentName) async {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Categoría'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () async {
              await ref.read(adminControllerProvider.notifier).updateCategory(id, controller.text);
              ref.invalidate(categoriasProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Borrar "$name"?'),
        content: const Text('Esta acción no se puede deshacer y fallará si hay incidencias que usan esta categoría.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('BORRAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(adminControllerProvider.notifier).deleteCategory(id);
        ref.invalidate(categoriasProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  void _editRole(int id, String currentName) async {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Estado'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () async {
              await ref.read(adminControllerProvider.notifier).updateRole(id, controller.text);
              ref.invalidate(estadosProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  void _deleteRole(int id, String name) async {
    if (id <= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pueden borrar estados base del sistema')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Borrar "$name"?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('BORRAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(adminControllerProvider.notifier).deleteRole(id);
        ref.invalidate(estadosProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriasAsync = ref.watch(categoriasProvider);
    final estadosAsync = ref.watch(estadosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Sistema'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con diseño moderno
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                    ? [Colors.blueGrey[900]!, Colors.blueGrey[800]!]
                    : [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.admin_panel_settings, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Panel de Control Maestro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gestiona las categorías y estados de la plataforma',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Sección Categorías
            _buildSection(
              context,
              title: 'Gestión de Categorías',
              description: 'Añade nuevas áreas de actuación.',
              icon: Icons.category,
              color: Colors.orange,
              controller: _categoryController,
              onPressed: _submitCategory,
              buttonText: 'Añadir Categoría',
              hintText: 'Ej: Alumbrado Público...',
              items: categoriasAsync.when(
                data: (cats) => cats,
                loading: () => [],
                error: (_, __) => [],
              ),
              onEdit: (item) => _editCategory(item.id, item.nombre),
              onDelete: (item) => _deleteCategory(item.id, item.nombre),
            ),

            const SizedBox(height: 32),

            // Sección Roles/Estados
            _buildSection(
              context,
              title: 'Gestión de Estados',
              description: 'Define nuevos flujos de trabajo.',
              icon: Icons.rule,
              color: Colors.purple,
              controller: _roleController,
              onPressed: _submitRole,
              buttonText: 'Añadir Estado',
              hintText: 'Ej: Pendiente de materiales...',
              items: estadosAsync.when(
                data: (ests) => ests,
                loading: () => [],
                error: (_, __) => [],
              ),
              onEdit: (item) => _editRole(item.id, item.nombre),
              onDelete: (item) => _deleteRole(item.id, item.nombre),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required VoidCallback onPressed,
    required String buttonText,
    required String hintText,
    required List<dynamic> items,
    required Function(dynamic) onEdit,
    required Function(dynamic) onDelete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: hintText,
                      filled: true,
                      fillColor: isDark ? Colors.black26 : Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text('EXISTENTES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) => Chip(
                label: Text(item.nombre),
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                deleteIcon: const Icon(Icons.edit, size: 14),
                onDeleted: () => onEdit(item),
                avatar: GestureDetector(
                  onTap: () => onDelete(item),
                  child: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
