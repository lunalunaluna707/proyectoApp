import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login.dart';
import '../screens/project_screen.dart'; // Pantalla principal tras login

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controllerIn;
  late AnimationController _controllerOut;

  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;

  late Animation<double> _fadeOut;
  late Animation<Offset> _slideUpOut;

  bool _exiting = false;

  @override
  void initState() {
    super.initState();

    _controllerIn = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeIn = CurvedAnimation(parent: _controllerIn, curve: Curves.easeIn);
    _scaleIn = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controllerIn, curve: Curves.easeOut),
    );

    _controllerOut = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controllerOut, curve: Curves.easeIn),
    );

    _slideUpOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.3),
    ).animate(CurvedAnimation(parent: _controllerOut, curve: Curves.easeInOut));

    _controllerIn.forward();

    Timer(const Duration(seconds: 4), () async {
      setState(() => _exiting = true);
      await _controllerOut.forward();
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        final userId = prefs.getInt('userId');

        if (token != null && userId != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ProjectScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controllerIn.dispose();
    _controllerOut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final logoSize = screenWidth * 0.3; // Escala el logo al 30% del ancho
    final titleFontSize = screenWidth * 0.08; // Escala el título
    final subtitleFontSize = screenWidth * 0.045; // Escala el subtítulo

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5F7FA), Color(0xFFE8ECF1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _exiting ? _controllerOut : _controllerIn,
              builder: (context, child) {
                if (!_exiting) {
                  return Opacity(
                    opacity: _fadeIn.value,
                    child: Transform.scale(
                      scale: _scaleIn.value,
                      child: child,
                    ),
                  );
                } else {
                  return Opacity(
                    opacity: _fadeOut.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideUpOut.value.dy * screenHeight * 0.3),
                      child: child,
                    ),
                  );
                }
              },
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(
                      tag: 'logo',
                      child: Image.asset(
                        'assets/icono_koalgenda.png',
                        width: logoSize.clamp(100.0, 300.0), // Limita el tamaño para TV/celular
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      'Koalgenda',
                      style: TextStyle(
                        fontSize: titleFontSize.clamp(28.0, 48.0),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50),
                        fontFamily: 'Montserrat',
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    AnimatedOpacity(
                      duration: const Duration(seconds: 2),
                      opacity: _exiting ? 0 : 1,
                      child: Text(
                        'Organiza. Colabora. Avanza.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: subtitleFontSize.clamp(14.0, 24.0),
                          color: const Color(0xFF34495E),
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
