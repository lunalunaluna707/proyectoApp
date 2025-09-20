import 'package:flutter/material.dart';
import '../screens/project_screen.dart';
import '../screens/configuracion_screen.dart';
import '../screens/tareasscreen.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget destination;
    switch (index) {
      case 0:
        destination = const ProjectScreen();
        break;
      case 1:
        destination = const TareasScreen();
        break;
      case 2:
        destination = const ConfiguracionScreen();
        break;
      default:
        return;
    }

    Navigator.of(context).pushReplacement(_crearTransicionAnimada(destination));
  }

  
  PageRouteBuilder _crearTransicionAnimada(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // de derecha a izquierda
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      backgroundColor: Colors.cyan[700],
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.folder),
          label: 'Proyectos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.task),
          label: 'Tareas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Configuración',
        ),
      ],
    );
  }
}
