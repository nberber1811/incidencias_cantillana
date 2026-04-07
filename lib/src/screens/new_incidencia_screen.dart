import 'dart:io';
import 'package:ayuntamiento_incidencias/src/features/incidencias/presentation/incidencia_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class NewIncidenciaScreen extends ConsumerStatefulWidget {
  const NewIncidenciaScreen({super.key});

  @override
  ConsumerState<NewIncidenciaScreen> createState() => _NewIncidenciaScreenState();
}

class _NewIncidenciaScreenState extends ConsumerState<NewIncidenciaScreen> {
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  String _categoria = 'Limpieza';
  File? _image;
  Position? _currentPosition;
  bool _isLocating = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Servicios de ubicación desactivados';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Permisos denegados';
      }
      
      _currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint("Error obteniendo ubicación: $e");
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _submit() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes añadir una foto')),
      );
      return;
    }
    if (_tituloController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade un título')),
      );
      return;
    }

    await ref.read(incidenciaControllerProvider.notifier).submitIncidencia(
      title: _tituloController.text,
      description: _descripcionController.text,
      category: _categoria,
      image: _image,
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(incidenciaControllerProvider);

    ref.listen<AsyncValue<void>>(
      incidenciaControllerProvider,
      (previous, next) {
        next.whenOrNull(
          data: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incidencia enviada correctamente')),
            );
            Navigator.pop(context);
          },
          error: (e, st) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al enviar: $e')),
            );
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Incidencia')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text("¿Qué ha pasado?", 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              GestureDetector(
                onTap: () => _showPickerOptions(context),
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                  ),
                  child: _image == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 60, color: Colors.blueAccent),
                            SizedBox(height: 12),
                            Text("Toca para añadir una foto", 
                                 style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.file(_image!, fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Asunto o Título',
                  hintText: 'Ej: Bucle en acera, Farola rota...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción detallada',
                  hintText: 'Cuéntanos un poco más...',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categoria,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: ['Limpieza', 'Alumbrado', 'Vía Pública', 'Mobiliario', 'Otros']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _categoria = val!),
              ),
              const SizedBox(height: 16),
              
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _currentPosition != null ? Icons.location_on : Icons.location_off,
                  color: _currentPosition != null ? Colors.green : Colors.red,
                ),
                title: Text(_currentPosition != null 
                    ? "Ubicación detectada" 
                    : (_isLocating ? "Buscando ubicación..." : "No se pudo obtener la ubicación")),
                subtitle: const Text("Se enviarán las coordenadas automáticamente"),
                trailing: _isLocating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
              ),
              
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: state.isLoading ? null : _submit,
                icon: const Icon(Icons.send_rounded),
                label: const Text("Enviar a Revisión"),
              )
            ],
          ),
          if (state.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Subiendo incidencia..."),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Galería'),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Cámara'),
                  onTap: () {
                    _pickImage(ImageSource.camera);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}