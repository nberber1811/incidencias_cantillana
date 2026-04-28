import 'package:ayuntamiento_incidencias/src/features/auth/presentation/auth_controller.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/data/auth_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/presentation/profile_screen.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/data/incidencia_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/technician/presentation/technician_incidencia_detail_screen.dart';
import 'package:ayuntamiento_incidencias/src/screens/new_incidencia_screen.dart';
import 'package:ayuntamiento_incidencias/src/screens/incidencia_detail_screen.dart';
import 'package:ayuntamiento_incidencias/src/shared/widgets/incidencia_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TechnicianHomeScreen extends ConsumerStatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  ConsumerState<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends ConsumerState<TechnicianHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final uid = user?.uid ?? '';

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _TechnicianTasksView(tecnicoId: uid),
          _TechnicianReportsView(userId: uid),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.build_circle_outlined),
            selectedIcon: Icon(Icons.build_circle),
            label: 'Mis Tareas',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Mis Reportes',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1 
        ? FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewIncidenciaScreen()),
            ),
            label: const Text('Reportar'),
            icon: const Icon(Icons.add_a_photo_outlined),
          )
        : null,
    );
  }
}

class _TechnicianTasksView extends ConsumerStatefulWidget {
  final String tecnicoId;
  const _TechnicianTasksView({required this.tecnicoId});

  @override
  ConsumerState<_TechnicianTasksView> createState() => _TechnicianTasksViewState();
}

class _TechnicianTasksViewState extends ConsumerState<_TechnicianTasksView> {
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
    final tasksAsync = ref.watch(technicianIncidenciasStreamProvider(widget.tecnicoId));

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar tareas...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text('Tareas Asignadas'),
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
            : null,
        actions: [
          if (!_isSearching)
            IconButton(
              onPressed: () => setState(() => _isSearching = true),
              icon: const Icon(Icons.search),
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
          ),
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) {
          var filtered = tasks;
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            filtered = tasks.where((t) => 
              t.titulo.toLowerCase().contains(query) || 
              t.descripcion.toLowerCase().contains(query)
            ).toList();
          }

          if (filtered.isEmpty) {
            return Center(child: Text(_isSearching ? 'No hay coincidencias' : 'No tienes tareas asignadas'));
          }
          
          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              final isTablet = constraints.maxWidth > 600 && constraints.maxWidth <= 900;
              int crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

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
                        itemBuilder: (context, index) => _buildCard(context, filtered[index], true),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => _buildCard(context, filtered[index], true),
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

  Widget _buildCard(BuildContext context, incidencia, bool isTask) {
    return IncidenciaCard(
      incidencia: incidencia,
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => isTask 
            ? TechnicianIncidenciaDetailScreen(incidencia: incidencia)
            : IncidenciaDetailScreen(incidencia: incidencia)
        )
      ),
    );
  }
}

class _TechnicianReportsView extends ConsumerStatefulWidget {
  final String userId;
  const _TechnicianReportsView({required this.userId});

  @override
  ConsumerState<_TechnicianReportsView> createState() => _TechnicianReportsViewState();
}

class _TechnicianReportsViewState extends ConsumerState<_TechnicianReportsView> {
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
    final reportsAsync = ref.watch(userIncidenciasStreamProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar mis reportes...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text('Mis Reportes'),
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
            : null,
        actions: [
          if (!_isSearching)
            IconButton(
              onPressed: () => setState(() => _isSearching = true),
              icon: const Icon(Icons.search),
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
          ),
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: reportsAsync.when(
        data: (reports) {
          var filtered = reports;
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            filtered = reports.where((r) => 
              r.titulo.toLowerCase().contains(query) || 
              r.descripcion.toLowerCase().contains(query)
            ).toList();
          }

          if (filtered.isEmpty) {
            return Center(child: Text(_isSearching ? 'No hay coincidencias' : 'No has creado ninguna incidencia'));
          }
          
          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              final isTablet = constraints.maxWidth > 600 && constraints.maxWidth <= 900;
              int crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

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
                        itemBuilder: (context, index) => _buildCard(context, filtered[index], false),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => _buildCard(context, filtered[index], false),
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

  Widget _buildCard(BuildContext context, incidencia, bool isTask) {
    return IncidenciaCard(
      incidencia: incidencia,
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => isTask 
            ? TechnicianIncidenciaDetailScreen(incidencia: incidencia)
            : IncidenciaDetailScreen(incidencia: incidencia)
        )
      ),
    );
  }
}
