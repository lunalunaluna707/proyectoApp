import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'servicionotificaciones/notification_sender.dart'; // tu clase Notificaciones

import 'login.dart';
import 'screens/project_screen.dart';
import 'splash/splash_screen.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 [Background] Mensaje recibido: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const KoalgendaApp());
}

class KoalgendaApp extends StatefulWidget {
  const KoalgendaApp({super.key});

  @override
  State<KoalgendaApp> createState() => _KoalgendaAppState();
}

class _KoalgendaAppState extends State<KoalgendaApp> {
  @override
  void initState() {
    super.initState();

    // Inicializa Firebase y configura la escucha y snackbars
    Notificaciones.inicializarFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koalgenda',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey, // clave global para SnackBars
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/proyectos': (context) => const ProjectScreen(),
      },
    );
  }
}
