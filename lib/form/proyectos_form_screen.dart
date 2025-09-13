import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../apiservice.dart';
import '../form/form_tarea.dart';

class ProyectoForm extends StatefulWidget {
  final Map<String, dynamic>? proyecto; 

  const ProyectoForm({super.key, this.proyecto});


  @override
  State<ProyectoForm> createState() => _ProyectoFormState();
}

class _ProyectoFormState extends State<ProyectoForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nombreController;
  late TextEditingController descripcionController;
  late TextEditingController fechaInicioController;
  late TextEditingController fechaFinController;
  late TextEditingController porcentajeController;

  @override
  void initState() {
    super.initState();

    nombreController = TextEditingController(text: widget.proyecto?['nombre'] ?? '');
    descripcionController = TextEditingController(text: widget.proyecto?['descripcion'] ?? '');
    fechaInicioController = TextEditingController(
      text: formatearFecha(widget.proyecto?['fecha_inicio']),
    );
    fechaFinController = TextEditingController(
      text: formatearFecha(widget.proyecto?['fecha_fin']),
    );
    porcentajeController = TextEditingController(
      text: (widget.proyecto?['porcentaje_progreso'] ?? '').toString(),
    );
  }

  Future<void> guardarProyecto() async {
    final isEditing = widget.proyecto != null;
    final id = widget.proyecto?['proyecto_id'];

    try {
      final exito = await ApiService.guardarProyecto(
        id: id,
        nombre: nombreController.text,
        descripcion: descripcionController.text,
        fechaInicio: fechaInicioController.text,
        fechaFin: fechaFinController.text,
        porcentaje: int.tryParse(porcentajeController.text) ?? 0,
      );

      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? "Proyecto actualizado" : "Proyecto creado con éxito"),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? "Error al actualizar proyecto" : "Error al crear proyecto"),
          ),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fallo de conexión")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.proyecto != null;

    return Scaffold(
   appBar: PreferredSize(
  preferredSize: const Size.fromHeight(100),
  child: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xff00bcd4), Color(0xff00838f)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black38,
          offset: Offset(0, 3),
          blurRadius: 8,
        ),
      ],
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              isEditing ? "Editar Proyecto" : "Registrar Proyecto",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    offset: Offset(1, 1),
                    blurRadius: 4,
                  ),
                ],
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildInputField(
                controller: nombreController,
                label: "Añadir nombre del proyecto",
                icon: Icons.title,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              _buildInputField(
                controller: descripcionController,
                label: "Descripción del proyecto",
                icon: Icons.description,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              _buildInputField(
                controller: fechaInicioController,
                label: "Fecha Inicio del proyecto (YYYY-MM-DD)",
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: () => _selectDate(context, fechaInicioController),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              _buildInputField(
                controller: fechaFinController,
                label: "Fecha Final del proyecto (opcional)",
                icon: Icons.calendar_month,
                readOnly: true,
                onTap: () => _selectDate(context, fechaFinController),
              ),
              const SizedBox(height: 12),
              _buildInputField(
                controller: porcentajeController,
                label: "Porcentaje Progreso del proyecto (calculado automáticamente)",
                icon: Icons.percent,
                readOnly: true,  
                validator: null, 
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    guardarProyecto();
                  }
                },
                 icon: Icon(Icons.person_add, color: Colors.white),
                label: Text(isEditing ? "Actualizar Proyecto" : "Guardar Proyecto"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white, 
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16,
                  color: Colors.white,),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color.fromARGB(255, 255, 255, 255),
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.cyan[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.cyan.shade700),
          borderRadius: BorderRadius.circular(12),
        ),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.text.isNotEmpty
          ? DateTime.parse(controller.text)
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  String formatearFecha(dynamic fechaOriginal) {
    if (fechaOriginal == null) return '';
    try {
      DateTime fecha = DateTime.tryParse(fechaOriginal) ??
          HttpDate.parse(fechaOriginal);
      return "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }
}
