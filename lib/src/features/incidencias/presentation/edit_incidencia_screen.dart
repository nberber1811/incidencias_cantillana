import 'dart:io';
import 'package:ayuntamiento_incidencias/src/features/incidencias/domain/incidencia.dart';
import 'package:ayuntamiento_incidencias/src/features/incidencias/presentation/incidencia_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class EditIncidenciaScreen extends ConsumerStatefulWidget {
  final Incidencia incidencia;
  const EditIncidenciaScreen({super.key, required this.incidencia});

  @override
  ConsumerState<EditIncidenciaScreen> createState() => _EditIncidenciaScreenState();
}

class _EditIncidenciaScreenState extends ConsumerState<EditIncidenciaScreen> {
  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  late TextEditingController _direccionController;
  late String _categoria;
  XFile? _newImage;
  Position? _currentPosition;
  bool _isLocating = false;
  late bool _useGps;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.incidencia.titulo);
    _descripcionController = TextEditingController(text: widget.incidencia.descripcion);
    _direccionController = TextEditingController(text: widget.incidencia.direccion);
    _categoria = widget.incidencia.categoriaNombre ?? 'Limpieza';
    _useGps = widget.incidencia.latitud != null;
    
    if (_useGps) {
      _currentPosition = Position(
        latitude: widget.incidencia.latitud!,
        longitude: widget.incidencia.longitud!,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
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
      setState(() => _newImage = pickedFile);
    }
  }

  Future<void> _submit() async {
    if (_tituloController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade un título')),
      );
      return;
    }
    if (_descripcionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, añade una descripción detallada')),
      );
      return;
    }
    if (_useGps && _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay una ubicación GPS válida. Púlsala de nuevo o usa dirección manual.')),
      );
      return;
    }
    if (!_useGps && _direccionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, indica la dirección manualmente')),
      );
      return;
    }

    await ref.read(incidenciaControllerProvider.notifier).editIncidencia(
      id: widget.incidencia.id,
      titulo: _tituloController.text,
      descripcion: _descripcionController.text,
      categoria: _categoria,
      imagen: _newImage,
      existingImageUrl: widget.incidencia.image,
      latitud: _useGps ? _currentPosition?.latitude : null,
      longitud: _useGps ? _currentPosition?.longitude : null,
      direccion: _direccionController.text.isNotEmpty ? _direccionController.text : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    const String baseUploadUrl = 'https://alumno23.fpcantillana.org/uploads/';
    final state = ref.watch(incidenciaControllerProvider);

    ref.listen<AsyncValue<void>>(
      incidenciaControllerProvider,
      (previous, next) {
        next.whenOrNull(
          data: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incidencia actualizada correctamente')),
            );
            Navigator.pop(context);
          },
          error: (e, st) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al actualizar: $e')),
            );
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Incidencia')),
      body: Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text("Editar información", 
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
                      child: _newImage == null && widget.incidencia.image == null
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
                              child: _newImage != null
                                ? (kIsWeb 
                                    ? Image.network(_newImage!.path, fit: BoxFit.cover)
                                    : Image.file(File(_newImage!.path), fit: BoxFit.cover))
                                : Image.network('$baseUploadUrl${widget.incidencia.image}', fit: BoxFit.cover),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Asunto o Título',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descripcionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción detallada',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: ['Limpieza', 'Alumbrado', 'Vía Pública', 'Mobiliario', 'Otros'].contains(_categoria) ? _categoria : 'Otros',
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: ['Limpieza', 'Alumbrado', 'Vía Pública', 'Mobiliario', 'Otros']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => _categoria = val!),
                  ),
                  const SizedBox(height: 24),
                  
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text("Ubicación", 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Usar GPS automático"),
                    value: _useGps,
                    onChanged: (val) {
                      setState(() => _useGps = val);
                      if (val && _currentPosition == null) {
                        _determinePosition();
                      }
                    },
                  ),
                  
                  if (_useGps)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _currentPosition != null ? Icons.location_on : Icons.location_off,
                        color: _currentPosition != null ? Colors.green : Colors.red,
                      ),
                      title: Text(_currentPosition != null 
                          ? "Ubicación fijada" 
                          : (_isLocating ? "Buscando ubicación..." : "No se pudo obtener la ubicación")),
                      trailing: TextButton(
                        onPressed: _determinePosition,
                        child: const Text("Actualizar"),
                      ),
                    )
                  else
                    TextField(
                      controller: _direccionController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección manual',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: state.isLoading ? null : _submit,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text("Guardar Cambios"),
                  )
                ],
              ),
            ),
          ),
          if (state.isLoading)
            const Center(child: CircularProgressIndicator()),
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
