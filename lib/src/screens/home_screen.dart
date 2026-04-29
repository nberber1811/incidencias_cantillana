import 'package:ayuntamiento_incidencias/src/features/auth/presentation/auth_controller.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/data/auth_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/auth/presentation/profile_screen.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/data/incidencia_repository.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/presentation/map_view_screen.dart';
import 'package:ayuntamiento_incidencias/src/screens/incidencia_detail_screen.dart';
import 'package:ayuntamiento_incidencias/src/screens/new_incidencia_screen.dart';
import 'package:ayuntamiento_incidencias/src/shared/widgets/incidencia_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
    final user = ref.watch(authStateProvider);
    final uid = user?.uid ?? '';
    final incidenciasAsync = ref.watch(userIncidenciasStreamProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar mis incidencias...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text('Mis Incidencias'),
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
            : (user?.rolId == 1 
              ? null 
              : IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MapViewScreen()),
                  ),
                  icon: const Icon(Icons.map_outlined),
                  tooltip: 'Ver mapa',
                )),
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
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
      body: incidenciasAsync.when(
        data: (incidencias) {
          var filtered = incidencias;
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            filtered = incidencias.where((i) => 
              i.titulo.toLowerCase().contains(query) || 
              i.descripcion.toLowerCase().contains(query)
            ).toList();
          }

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSearching ? Icons.search_off : Icons.assignment_turned_in_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSearching ? 'No se encontraron coincidencias' : 'No hay incidencias reportadas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
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
                          mainAxisExtent: 380,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewIncidenciaScreen()),
          );
        },
        label: const Text('Nueva Incidencia'),
        icon: const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }

  Widget _buildCard(BuildContext context, incidencia) {
    return IncidenciaCard(
      incidencia: incidencia,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IncidenciaDetailScreen(incidencia: incidencia),
        ),
      ),
    );
  }
}