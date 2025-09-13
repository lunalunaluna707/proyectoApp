import 'package:flutter/material.dart';

class AcercaDeScreen extends StatelessWidget {
  const AcercaDeScreen({Key? key}) : super(key: key);

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
                    'Acerca de',
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
     
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Versión: 1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Koalgenda es una aplicación diseñada para  la gestión integral de proyectos, '
              'permitiendo a equipos organizar tareas, asignar responsabilidades, establecer plazos y '
              'el progreso de manera sencilla y eficiente.',
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 20),
            Text(
              'Características principales:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('• Planificación y seguimiento de proyectos.', style: TextStyle(fontSize: 15)),
            Text('• Gestión de tareas y asignación de responsables.', style: TextStyle(fontSize: 15)),
            Text('• Notificaciones y recordatorios automáticos.', style: TextStyle(fontSize: 15)),
            Text('• Reportes de avance', style: TextStyle(fontSize: 15)),
            SizedBox(height: 20),
            Text(
              'Desarrollado por:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('Equipo Koalgenda', style: TextStyle(fontSize: 15)),
            SizedBox(height: 20),
            Text(
              'Licencia:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('© 2025 Koalgenda. Todos los derechos reservados.', style: TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
