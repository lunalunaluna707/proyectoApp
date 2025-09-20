import 'package:flutter/material.dart';
import '../apiservice.dart'; 

class RegistroUsuarioScreen extends StatefulWidget {
  @override
  _RegistroUsuarioScreenState createState() => _RegistroUsuarioScreenState();
}

class _RegistroUsuarioScreenState extends State<RegistroUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  void _registrarUsuario() async {
    if (_formKey.currentState!.validate()) {
      final nombre = _nombreController.text.trim();
      final email = _emailController.text.trim();
      final telefono = _telefonoController.text.trim();
      final contrasena = _contrasenaController.text.trim();

      try {
        final result = await ApiService.registrarUsuario(
          nombre: nombre,
          email: email,
          telefono: telefono,
          contrasena: contrasena,
        );

        final status = result['status'];
        final data = result['body'];

        if (status == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${data['message']}')),
          );
          _formKey.currentState!.reset();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('⚠️ ${data['message'] ?? "Error al registrar"}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e')),
        );
      }
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
        colors: [Color(0xff00bcd4), Color(0xff00838f)], // cyan degradado
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
            const Text(
              'Registrarte',
              style: TextStyle(
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
              TextFormField(
                controller: _nombreController,
                decoration: _inputDecoration(label: 'Ingresa tu nombre completo', icon: Icons.person),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingresa tu nombre' : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration(label: 'Ingresa tu correo electrónico', icon: Icons.email),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || !value.contains('@') ? 'Correo no válido' : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _telefonoController,
                decoration: _inputDecoration(label: 'Ingresa tu teléfono', icon: Icons.phone),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || value.length < 10 ? 'Teléfono no válido' : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _contrasenaController,
                decoration: _inputDecoration(label: 'Ingresa tu contraseña', icon: Icons.lock),
                obscureText: true,
                validator: (value) =>
                    value == null || value.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                icon: Icon(Icons.person_add, color: Colors.white),
                label: Text('Registrar Usuario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _registrarUsuario,
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.grey[100],
    );
  }
}
