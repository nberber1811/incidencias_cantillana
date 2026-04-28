import 'package:ayuntamiento_incidencias/src/features/auth/presentation/profile_screen.dart';
import 'dart:ui';
import 'package:ayuntamiento_incidencias/src/features/admin/presentation/admin_controller.dart';
import 'package:ayuntamiento_incidencias/src/features/admin/presentation/admin_incidencia_detail_screen.dart';
import 'package:ayuntamiento_incidencias/src/features/admin/presentation/user_management_screen.dart';
import 'package:ayuntamiento_incidencias/src/features/admin/presentation/system_settings_screen.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/presentation/auth_controller.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/data/incidencia_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/presentation/map_view_screen.dart';
import 'package:ayuntamiento_incidencias/src/shared/widgets/incidencia_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _selectedIndex = 0;
  int? _filterStatusId; 
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _AdminIncidenciasView(
            filterStatusId: _filterStatusId,
            dateRange: _dateRange,
            onFilterChanged: (id) => setState(() => _filterStatusId = id),
            onDateRangeChanged: (range) => setState(() => _dateRange = range),
          ),
          UserManagementScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Incidencias',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Usuarios',
          ),
        ],
      ),
    );
  }
}

class _AdminIncidenciasView extends ConsumerStatefulWidget {
  final int? filterStatusId;
  final DateTimeRange? dateRange;
  final Function(int?) onFilterChanged;
  final Function(DateTimeRange?) onDateRangeChanged;

  const _AdminIncidenciasView({
    required this.filterStatusId,
    required this.dateRange,
    required this.onFilterChanged,
    required this.onDateRangeChanged,
  });

  @override
  ConsumerState<_AdminIncidenciasView> createState() => _AdminIncidenciasViewState();
}

class _AdminIncidenciasViewState extends ConsumerState<_AdminIncidenciasView> {
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
    final allIncidenciasAsync = ref.watch(allIncidenciasStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar incidencias...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text('Panel de Gestión'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SizedBox(
            height: 60,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _FilterChip(label: 'Todas', isSelected: widget.filterStatusId == null, onSelected: () => widget.onFilterChanged(null)),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Abiertas', isSelected: widget.filterStatusId == 1, onSelected: () => widget.onFilterChanged(1), color: Colors.orange),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'En Proceso', isSelected: widget.filterStatusId == 2, onSelected: () => widget.onFilterChanged(2), color: Colors.blue),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Resueltas', isSelected: widget.filterStatusId == 3, onSelected: () => widget.onFilterChanged(3), color: Colors.green),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'No Resuelta', isSelected: widget.filterStatusId == 4, onSelected: () => widget.onFilterChanged(4), color: Colors.orange[800]),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Error', isSelected: widget.filterStatusId == 5, onSelected: () => widget.onFilterChanged(5), color: Colors.redAccent),
                    if (widget.dateRange != null) ...[
                      const SizedBox(width: 16),
                      InputChip(
                        avatar: const Icon(Icons.date_range, size: 14, color: Colors.white),
                        label: Text(
                          '${DateFormat('dd/MM').format(widget.dateRange!.start)} - ${DateFormat('dd/MM').format(widget.dateRange!.end)}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                        selected: true,
                        selectedColor: Colors.purple[400],
                        onPressed: () => widget.onDateRangeChanged(null),
                        onDeleted: () => widget.onDateRangeChanged(null),
                        deleteIconColor: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        leading: _isSearching
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.arrow_back),
              )
            : IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapViewScreen()),
                ),
                icon: const Icon(Icons.map_outlined),
                tooltip: 'Mapa global',
              ),
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
          if (widget.filterStatusId != null && widget.filterStatusId! >= 3)
            IconButton(
              onPressed: () => _showBulkDeleteDialog(context, ref, widget.filterStatusId!),
              icon: const Icon(Icons.cleaning_services_outlined, color: Colors.redAccent),
              tooltip: 'Limpiar historial de este estado',
            ),
          IconButton(
            onPressed: () => _selectDateRange(context),
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Filtrar por fecha',
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Mi Perfil',
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SystemSettingsScreen())),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuración del sistema',
          ),
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: allIncidenciasAsync.when(
        data: (incidencias) {
          var filtered = widget.filterStatusId == null 
            ? incidencias 
            : incidencias.where((i) => i.estadoId == widget.filterStatusId).toList();

          if (widget.dateRange != null) {
            filtered = filtered.where((i) {
              final date = i.fechaCreacion;
              return date.isAfter(widget.dateRange!.start.subtract(const Duration(days: 1))) && 
                     date.isBefore(widget.dateRange!.end.add(const Duration(days: 1)));
            }).toList();
          }

          // FILTRO DE BÚSQUEDA
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            filtered = filtered.where((i) => 
              i.titulo.toLowerCase().contains(query) || 
              i.descripcion.toLowerCase().contains(query) ||
              (i.categoriaNombre?.toLowerCase().contains(query) ?? false)
            ).toList();
          }

          if (filtered.isEmpty) {
            return const Center(child: Text('No hay incidencias con estos filtros'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              final isTablet = constraints.maxWidth > 600 && constraints.maxWidth <= 900;
              
              int crossAxisCount = 1;
              if (isDesktop) crossAxisCount = 3;
              else if (isTablet) crossAxisCount = 2;

              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: crossAxisCount > 1 
                    ? GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          mainAxisExtent: 320,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => _buildCard(context, filtered[index]),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => _buildCard(context, filtered[index]),
                      ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildCard(BuildContext context, incidencia) {
    return IncidenciaCard(
      incidencia: incidencia,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminIncidenciaDetailScreen(incidencia: incidencia),
          ),
        );
      },
    );
  }

  Future<void> _showBulkDeleteDialog(BuildContext context, WidgetRef ref, int estadoId) async {
    String estadoNombre = '';
    switch (estadoId) {
      case 3: estadoNombre = 'Resueltas'; break;
      case 4: estadoNombre = 'No Resueltas'; break;
      case 5: estadoNombre = 'Error / Inválida'; break;
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Limpiar $estadoNombre?'),
        content: Text('Se borrarán TODAS las incidencias marcadas como $estadoNombre. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(adminControllerProvider.notifier).deleteFinalIncidencias(estadoId: estadoId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Historial de $estadoNombre limpiado')),
                );
              }
            },
            child: const Text('BORRAR TODO', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: widget.dateRange,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: isDark 
            ? ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Colors.blueAccent,
                  onPrimary: Colors.white,
                  surface: Color(0xFF1E1E1E),
                  onSurface: Colors.white,
                ),
              )
            : ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Colors.blue,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      widget.onDateRangeChanged(picked);
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: TextStyle(
        color: isSelected ? Colors.white : (color ?? Colors.grey[700]),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      )),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: color ?? Colors.blueAccent,
      checkmarkColor: Colors.white,
      backgroundColor: Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
