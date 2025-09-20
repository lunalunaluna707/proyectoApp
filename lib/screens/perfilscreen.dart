import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../apiservice.dart'; 

class PerfilUsuarioScreen extends StatefulWidget {
  const PerfilUsuarioScreen({super.key});

  @override
  State<PerfilUsuarioScreen> createState() => _PerfilUsuarioScreenState();
}

class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();

  Map<String, String> usuario = {
    'usuario_id': '',
    'nombre': '',
    'email': '',
    'telefono': '',
    'contraseña': '',
  };

  late TextEditingController nombreController;
  late TextEditingController emailController;
  late TextEditingController telefonoController;
  late TextEditingController contrasenaController;

  bool loading = true;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      usuario = {
        'usuario_id': prefs.getString('usuario_id') ?? '',
        'nombre': prefs.getString('nombre') ?? '',
        'email': prefs.getString('email') ?? '',
        'telefono': prefs.getString('telefono') ?? '',
        'contraseña': prefs.getString('contraseña') ?? '',
      };
      nombreController = TextEditingController(text: usuario['nombre']);
      emailController = TextEditingController(text: usuario['email']);
      telefonoController = TextEditingController(text: usuario['telefono']);
      contrasenaController = TextEditingController(text: usuario['contraseña']);
      loading = false;
    });
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      guardando = true;
    });

    final response = await ApiService.editarUsuario(
      usuarioId: int.parse(usuario['usuario_id']!),
      nombre: nombreController.text.trim(),
      email: emailController.text.trim(),
      telefono: telefonoController.text.trim(),
      contrasena: contrasenaController.text.trim(),
    );

    setState(() {
      guardando = false;
    });

    if (response['status'] == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nombre', nombreController.text.trim());
      await prefs.setString('email', emailController.text.trim());
      await prefs.setString('telefono', telefonoController.text.trim());
      await prefs.setString('contraseña', contrasenaController.text.trim());

      setState(() {
        usuario['nombre'] = nombreController.text.trim();
        usuario['email'] = emailController.text.trim();
        usuario['telefono'] = telefonoController.text.trim();
        usuario['contraseña'] = contrasenaController.text.trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos actualizados correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response['body']['message'] ?? 'No se pudo actualizar'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final primaryColor = Colors.cyan[700]!;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, Colors.cyan.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                offset: Offset(0, 3),
                blurRadius: 8,
              ),
            ],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
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
                  const SizedBox(width: 20),
                  const Text(
                    'Perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          offset: Offset(1, 1),
                          blurRadius: 5,
                        ),
                      ],
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: primaryColor,
                child: Text(
                  _getIniciales(nombreController.text),
                  style: const TextStyle(
                    fontSize: 44,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 5, color: Colors.black38)],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                shadowColor: primaryColor.withOpacity(0.4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      _buildInputField(
                        controller: nombreController,
                        label: 'Nombre completo',
                        icon: Icons.person,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        controller: emailController,
                        label: 'Correo electrónico',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'El email es obligatorio';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return 'Email no válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        controller: telefonoController,
                        label: 'Teléfono',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'El teléfono es obligatorio' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        controller: contrasenaController,
                        label: 'Contraseña',
                        icon: Icons.lock,
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'La contraseña es obligatoria';
                          if (v.trim().length < 6) return 'Debe tener al menos 6 caracteres';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    onPressed: guardando ? null : _guardarCambios,
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: primaryColor,
      elevation: 6,
    ),
    child: guardando
        ? const CircularProgressIndicator(color: Colors.white)
        : const Text(
            'Guardar Cambios',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
  ),
),

              const SizedBox(height: 30),
              Text(
                'ID de usuario: ${usuario['usuario_id']}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.cyan[700]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.cyan[700]!, width: 2),
        ),
      ),
    );
  }

  String _getIniciales(String nombre) {
    final limpio = nombre.trim();
    if (limpio.isEmpty) return '?';

    final partes = limpio.split(RegExp(r'\s+'));
    if (partes.length == 1) return partes[0][0].toUpperCase();
    return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
  }
}
