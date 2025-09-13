import 'dart:convert';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../main.dart'; 
import 'config.dart';

class Notificaciones {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _baseUrl = Config.baseUrl;
  static const String _endpointNotificarAdmin = '$_baseUrl/send-notification-all';
  static const String _endpointRegistrarToken = '$_baseUrl/register-token';

  static final StreamController<RemoteMessage> _onMessageStreamController = StreamController.broadcast();
  static Stream<RemoteMessage> get onMessageStream => _onMessageStreamController.stream;

  static Future<void> inicializarFirebase() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
    await _configurarNotificacionesLocales();
    await _solicitarPermisos();
    _escucharMensajes();
  }

  static Future<void> _configurarNotificacionesLocales() async {
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: initSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    const AndroidNotificationChannel canal = AndroidNotificationChannel(
      'channel_id',
      'Canal de notificaciones',
      description: 'Canal para notificaciones de reportes.',
      importance: Importance.max,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(canal);
  }

  static Future<void> _solicitarPermisos() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('Authorization status: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permiso concedido');
    } else {
      print('❌ Permiso denegado');
    }
  }

  static Future<void> mostrarNotificacion(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel_id',
      'Canal de notificaciones',
      channelDescription: 'Canal para notificaciones de reportes.',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
    );
  }

  static Future<void> _backgroundMessageHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('📥 Mensaje en segundo plano: ${message.messageId}');
  }

  static void _escucharMensajes() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Mensaje en foreground: ${message.messageId}');
      if (message.notification != null) {
        final snackBar = SnackBar(
          content: Text('${message.notification!.title ?? ''}: ${message.notification!.body ?? ''}'),
          duration: Duration(seconds: 4),
        );
        scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
      }
    });

    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('🔄 Token FCM actualizado: $newToken');
    });
  }

  static Future<String?> obtenerToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      print("🔑 Token FCM obtenido: $token");
      return token;
    } catch (e) {
      print('❌ Error obteniendo token FCM: $e');
      return null;
    }
  }

  static Future<bool> enviarNotificacionDesdeFlutter({
    required String token,
    required String titulo,
    required String cuerpo,
  }) async {
    final url = Uri.parse(_endpointNotificarAdmin);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': titulo,
          'body': cuerpo,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Notificación enviada correctamente");
        return true;
      } else {
        print("❌ Error al enviar notificación: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error de red: $e");
      return false;
    }
  }

  static Future<void> registrarTokenEnServidorid(
      int idEmpleado, String token, String privilegio) async {
    final url = Uri.parse(_endpointRegistrarToken);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': idEmpleado,
          'token': token,
          'privilegios': privilegio,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Token registrado correctamente');
      } else {
        print('❌ Error al registrar token: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('❌ Excepción al registrar token: $e');
    }
  }

  static Future<bool> notificarAdminProyecto({
    required int proyectoId,
    required String titulo,
    required String cuerpo,
    required String jwtToken,
  }) async {
    final url = Uri.parse('$_baseUrl/notificar-admin-proyecto/$proyectoId');
    final fcmToken = await FirebaseMessaging.instance.getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'title': titulo,
          'body': cuerpo,
          'fcm_token': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Notificación enviada al administrador del proyecto");
        return true;
      } else {
        print("❌ Error al enviar notificación: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error de red al enviar notificación: $e");
      return false;
    }
  }

  static Future<bool> solicitarEliminacionTarea({
    required int tareaId,
    required String jwtToken,
  }) async {
    final url = Uri.parse('$_baseUrl/solicitar-eliminacion-tarea/$tareaId');
    final fcmToken = await FirebaseMessaging.instance.getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
        }),
      );

      final responseJson = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print("✅ Solicitud enviada con éxito.");
        return true;
      } else if (response.statusCode == 207) {
        print("⚠️ Solicitud enviada, pero algunas notificaciones fallaron.");
        print("Detalles del error: ${responseJson['errores']}");
        return true;
      } else {
        print("❌ Error del servidor: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Error de red al solicitar eliminación: $e");
      return false;
    }
  }

  static Future<bool> responderSolicitud({
    required String solicitudId,
    required String decision,
    required String jwtToken,
  }) async {
    final url = Uri.parse('$_baseUrl/responder-solicitud/$solicitudId');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'decision': decision,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Solicitud respondida: $decision");
        return true;
      } else {
        print("❌ Error al responder solicitud: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error de red al responder solicitud: $e");
      return false;
    }
  }
}
