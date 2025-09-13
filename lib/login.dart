import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../apiservice.dart';
import 'screens/registratescreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

 Future<void> iniciarSesion() async {
  final fcmToken = await FirebaseMessaging.instance.getToken();

  try {
    final data = await ApiService.login(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      fcmToken: fcmToken ?? '',
    );

    if (!mounted) return;
    print('Respuesta del login: $data');

    if (data['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setInt('userId', data['userId']);
      await prefs.setString('usuario_id', data['userId'].toString());
      await prefs.setString('nombre', data['nombre'] ?? '');
      await prefs.setString('email', data['email'] ?? '');
      await prefs.setString('telefono', data['telefono'] ?? '');
      await prefs.setString('contraseña', data['contraseña'] ?? '');
      print('Token FCM: $fcmToken');
      print('Token de sesión: ${data['token']}');
      print('ID de usuario: ${data['userId']}');
      Navigator.pushReplacementNamed(context, '/proyectos');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Error al iniciar sesión')),
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Fallo de conexión")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    const yellowCustom = Color(0xFFFFDE59);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/icono3.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '¡Bienvenido a Koalgenda!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyan,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Inicia sesión para continuar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              const Text(
                'Ingresa tu correo electronico',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                focusNode: emailFocus,
                decoration: InputDecoration(
                  hintText: 'ejemplo@gmail.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: const Icon(Icons.mail_outline, color: yellowCustom),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(passwordFocus);
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Ingresa tu contraseña',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                focusNode: passwordFocus,
                decoration: InputDecoration(
                  hintText: '6 a 8 caracteres',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: const Icon(Icons.lock, color: yellowCustom),
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: iniciarSesion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Iniciar sesión',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegistroUsuarioScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.cyan),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Registrarse',
                    style: TextStyle(fontSize: 18, color: Colors.cyan),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<String?> obtenerToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

}
