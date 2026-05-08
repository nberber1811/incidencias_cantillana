
import 'package:ayuntamiento_incidencias/src/features/auth/data/auth_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/presentation/auth_controller.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/presentation/profile_screen.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/data/incidencia_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/historial_item.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/incidencia.dart';
import 'package:ayuntamiento_incidencias/src/features/admin/presentation/admin_incidencia_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historialAsync = ref.watch(historialStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar en historial...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text('Historial de Cambios'),
        leading: _isSearching
            ? IconButton(
                onPressed: () => setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                }),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        actions: [
          if (!_isSearching)
            IconButton(
              onPressed: () => setState(() => _isSearching = true),
              icon: const Icon(Icons.search),
              tooltip: 'Buscar',
            ),
          if (_isSearching && _searchQuery.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              icon: const Icon(Icons.clear),
            ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Mi Perfil',
          ),
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: historialAsync.when(
        data: (items) {
          var filtered = items;
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            filtered = items.where((i) => 
              (i.incidenciaTitulo?.toLowerCase().contains(query) ?? false) || 
              (i.usuarioNombre?.toLowerCase().contains(query) ?? false) ||
              (i.estadoNuevoNombre?.toLowerCase().contains(query) ?? false)
            ).toList();
          }

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty ? 'No hay registros en el historial' : 'No se encontraron coincidencias',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const Divider(height: 32),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return _HistoryListItem(item: item, isDark: isDark);
                },
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _HistoryListItem extends ConsumerWidget {
  final HistorialItem item;
  final bool isDark;
  const _HistoryListItem({required this.item, required this.isDark});

  Color _getStatusColor(String? status) {
    final s = status?.toLowerCase() ?? '';
    if (s.contains('abierta')) return Colors.orange;
    if (s.contains('proceso')) return Colors.blue;
    if (s.contains('resuelta') && !s.contains('no')) return Colors.green;
    if (s.contains('no resuelta')) return Colors.orange[800]!;
    if (s.contains('error') || s.contains('inválida')) return Colors.redAccent;
    return Colors.grey;
  }

  void _navigateToIncidencia(BuildContext context, WidgetRef ref) {
    if (item.incidenciaId == null) return;
    
    // Obtenemos la lista completa de incidencias para encontrar el objeto Incidencia real
    final allIncidencias = ref.read(allIncidenciasStreamProvider).value;
    if (allIncidencias == null) return;

    try {
      final incidencia = allIncidencias.firstWhere(
        (i) => i.id == item.incidenciaId.toString()
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminIncidenciaDetailScreen(incidencia: incidencia),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo encontrar el detalle de esta incidencia (puede que haya sido borrada)')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _navigateToIncidencia(context, ref),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history, size: 22, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.incidenciaTitulo ?? 'Incidencia desconocida',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm:ss').format(item.fechaCambio),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  _StatusMiniBadge(
                    label: item.estadoAnteriorNombre ?? 'NUEVA',
                    color: _getStatusColor(item.estadoAnteriorNombre),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.grey),
                  ),
                  _StatusMiniBadge(
                    label: item.estadoNuevoNombre ?? 'SIN CAMBIO',
                    color: _getStatusColor(item.estadoNuevoNombre),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('MODIFICADO POR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                      Text(
                        item.usuarioNombre ?? 'Sistema',
                        style: TextStyle(
                          fontWeight: FontWeight.w600, 
                          fontSize: 13,
                          color: isDark ? Colors.blue[200] : Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusMiniBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusMiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
