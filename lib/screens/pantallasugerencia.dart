import 'package:flutter/material.dart';

class PantallaSugerida extends StatefulWidget {
  final Widget siguientePantalla;

  const PantallaSugerida({super.key, required this.siguientePantalla});

  @override
  State<PantallaSugerida> createState() => _PantallaSugeridaState();
}

class _PantallaSugeridaState extends State<PantallaSugerida> {
  bool esPantallaPequena(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return size.width < 600 || size.width < size.height; 
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!esPantallaPequena(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => widget.siguientePantalla),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!esPantallaPequena(context)) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.cyan)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.cyan,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.screen_rotation, size: 100, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'Este módulo se visualiza mejor en modo horizontal o en pantalla grande (TV). '
                'Gira tu dispositivo para una mejor experiencia.',
                style: TextStyle(color: Colors.white, fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.cyan,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => widget.siguientePantalla),
                  );
                },
                child: const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
