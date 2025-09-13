import 'package:flutter/material.dart';
import '../apiservice.dart';



class AsignarUsuarioScreen extends StatefulWidget {
  @override
  _AsignarUsuarioScreenState createState() => _AsignarUsuarioScreenState();
}

class _AsignarUsuarioScreenState extends State<AsignarUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> proyectos = [];
  List<Map<String, dynamic>> usuarios = [];

  int? proyectoSeleccionadoId;
  int? usuarioSeleccionadoId;
  String? rolSeleccionado;

  final TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> cargarDatos() async {
    try {
      final listaProyectos = await ApiService.obtenerProyectos();
      final listaUsuarios = await ApiService.obtenerUsuarios();
      setState(() {
        proyectos = listaProyectos;
        usuarios = listaUsuarios;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando datos: $e')),
      );
    }
  }

  Future<void> asignarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    
    final usuarioEncontrado = usuarios.firstWhere(
      (u) => u['email'].toString().toLowerCase() == emailController.text.trim().toLowerCase(),
      orElse: () => {},
    );

    if (usuarioEncontrado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se encontró un usuario con ese correo')),
      );
      return;
    }

    usuarioSeleccionadoId = usuarioEncontrado['usuario_id'];

    try {
      final success = await ApiService.asignarUsuarioAProyecto(
        proyectoId: proyectoSeleccionadoId!,
        usuarioId: usuarioSeleccionadoId!,
        rol: rolSeleccionado!,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuario asignado al proyecto')),
        );
        setState(() {
          proyectoSeleccionadoId = null;
          usuarioSeleccionadoId = null;
          rolSeleccionado = null;
          emailController.clear();
        });
        _formKey.currentState!.reset();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.cyan[700]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.cyan.shade700, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  Expanded(
                    child: Text(
                      'Asignar usuario al proyecto',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(1, 1),
                            blurRadius: 4,
                          ),
                        ],
                        letterSpacing: 1.1,
                      ),
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
              DropdownButtonFormField<int>(
  value: proyectoSeleccionadoId,
  decoration: _inputDecoration(
    label: 'Selecciona un Proyecto',
    icon: Icons.work_outline,
  ),
  items: proyectos.map((proyecto) {
    return DropdownMenuItem<int>(
      value: proyecto['proyecto_id'],
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6, 
        child: Text(
          proyecto['nombre'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis, 
        ),
      ),
    );
  }).toList(),
  onChanged: (value) => setState(() => proyectoSeleccionadoId = value),
  validator: (value) =>
      value == null ? 'Por favor selecciona un proyecto' : null,
),
              SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                decoration: _inputDecoration(
                  label: 'Correo electrónico del usuario',
                  icon: Icons.email_outlined,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un correo electrónico';
                  }
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: rolSeleccionado,
                decoration: _inputDecoration(
                  label: 'Rol en el Proyecto',
                  icon: Icons.security,
                ),
                items: ['Administrador', 'Miembro'].map((rol) {
                  return DropdownMenuItem<String>(
                    value: rol,
                    child: Text(rol),
                  );
                }).toList(),
                onChanged: (value) => setState(() => rolSeleccionado = value),
                validator: (value) =>
                    value == null ? 'Por favor selecciona un rol' : null,
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                icon: Icon(Icons.person_add, color: Colors.white),
                label: Text('Asignar Usuario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: asignarUsuario,
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.grey[100],
    );
  }
}
