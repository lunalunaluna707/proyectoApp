import 'package:flutter/material.dart';
import 'dart:convert';
import '../apiservice.dart'; // Ajusta la ruta si es necesaria
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
// Ajusta la ruta si es necesaria

class RegistrarTareaScreen extends StatefulWidget {
  const RegistrarTareaScreen({super.key});

  @override
  State<RegistrarTareaScreen> createState() => _RegistrarTareaScreenState();
}

class _RegistrarTareaScreenState extends State<RegistrarTareaScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _proyectoSeleccionadoId;
  List<Map<String, dynamic>> proyectos = [];
  bool _cargandoProyectos = true;

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();
  final TextEditingController _porcentajeController = TextEditingController();

  String _estadoSeleccionado = 'pendiente';
  final List<String> _estados = ['pendiente', 'en progreso', 'completado'];

  @override
  void initState() {
    super.initState();
    _cargarProyectos();
  }

  Future<void> _cargarProyectos() async {
    try {
      final lista = await ApiService.obtenerProyectos();
      setState(() {
        proyectos = List<Map<String, dynamic>>.from(lista);
        _cargandoProyectos = false;
      });
    } catch (e) {
      setState(() {
        _cargandoProyectos = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar proyectos: $e')),
      );
    }
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.cyan[700]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.cyan.shade700, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  Future<void> _registrarTarea() async {
    if (!_formKey.currentState!.validate()) return;

    if (_proyectoSeleccionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un proyecto')),
      );
      return;
    }

    final exito = await ApiService.registrarTarea(
      proyectoId: _proyectoSeleccionadoId!,
      titulo: _tituloController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      fechaInicio: _fechaInicioController.text.trim(),
      fechaFin: _fechaFinController.text.trim(),
      porcentajeProgreso: int.tryParse(_porcentajeController.text.trim()) ?? 0,
      estado: _estadoSeleccionado,
    );

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Tarea registrada')),
      );

      // Limpiar formulario y campos
      _formKey.currentState!.reset();
      _tituloController.clear();
      _descripcionController.clear();
      _fechaInicioController.clear();
      _fechaFinController.clear();
      _porcentajeController.clear();
      setState(() {
        _estadoSeleccionado = 'pendiente';
        _proyectoSeleccionadoId = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Error: No se pudo registrar')),
      );
    }
  }

  String _getFechaActual() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Tarea'),
        backgroundColor: Colors.cyan[700],
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/proyectos');
            },
            child: Text(
              _getFechaActual(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _cargandoProyectos
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<int>(
                      value: _proyectoSeleccionadoId,
                      decoration: _inputDecoration(label: 'Selecciona un Proyecto', icon: Icons.work),
                      items: proyectos.map((proyecto) {
                        return DropdownMenuItem<int>(
                          value: proyecto['proyecto_id'],
                          child: Text(proyecto['nombre']),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _proyectoSeleccionadoId = value),
                      validator: (value) => value == null ? 'Selecciona un proyecto' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _tituloController,
                      decoration: _inputDecoration(label: 'Título', icon: Icons.title),
                      validator: (value) => value == null || value.isEmpty ? 'Ingresa el título' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descripcionController,
                      decoration: _inputDecoration(label: 'Descripción', icon: Icons.description),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _fechaInicioController,
                      decoration: _inputDecoration(label: 'Fecha de Inicio (YYYY-MM-DD)', icon: Icons.date_range),
                      validator: (value) => value == null || value.isEmpty ? 'Ingresa la fecha de inicio' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _fechaFinController,
                      decoration: _inputDecoration(label: 'Fecha de Fin (YYYY-MM-DD)', icon: Icons.event),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _porcentajeController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(label: 'Porcentaje de Progreso', icon: Icons.percent),
                      validator: (value) {
                        final num = int.tryParse(value ?? '');
                        if (num == null || num < 0 || num > 100) return 'Debe estar entre 0 y 100';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _estadoSeleccionado,
                      decoration: _inputDecoration(label: 'Estado', icon: Icons.flag),
                      items: _estados.map((estado) {
                        return DropdownMenuItem<String>(
                          value: estado,
                          child: Text(estado.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _estadoSeleccionado = value ?? 'pendiente'),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _registrarTarea,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        'Guardar Tarea',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
