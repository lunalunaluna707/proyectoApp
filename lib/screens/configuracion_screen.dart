import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_bottom_nav.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notificacionscreen.dart';
import 'acercade.dart';
import 'perfilscreen.dart';
import 'package:http/http.dart' as http;

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> with WidgetsBindingObserver {
  bool _notificacionesActivas = true;
  bool _modoOscuro = false;
  bool _permisoSistema = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarPreferencias();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Cuando la app vuelve a primer plano, sincronizamos estado real de permisos
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    Future.delayed(const Duration(milliseconds: 500), () {
      _cargarPreferencias();
    });
  }
}

Future<void> _cargarPreferencias() async {
  final prefs = await SharedPreferences.getInstance();
  final permiso = await Permission.notification.status;

  bool permisoConcedido = permiso.isGranted;

  bool notificacionesGuardadas = prefs.getBool('notificaciones') ?? true;

  if (permisoConcedido && !notificacionesGuardadas) {
    await _guardarPreferencia('notificaciones', true);
    notificacionesGuardadas = true;
  }

  setState(() {
    _permisoSistema = permisoConcedido;
    _notificacionesActivas = permisoConcedido && notificacionesGuardadas;
    _modoOscuro = prefs.getBool('modo_oscuro') ?? false;
  });

  if (!permisoConcedido) {
    await _guardarPreferencia('notificaciones', false);
  }
}



  Future<void> _guardarPreferencia(String clave, bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(clave, valor);
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
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
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Configuración',
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

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Cuenta",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Perfil"),
            subtitle: const Text("Ver o editar información del perfil"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerfilUsuarioScreen()),
              );
            },
          ),
          const Divider(height: 32),

          const Text(
            "Preferencias",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text("Notificaciones"),
            subtitle: !_permisoSistema
                ? const Text(
                    "Actívalas desde ajustes del sistema",
                    style: TextStyle(color: Colors.red),
                  )
                : null,
            value: _notificacionesActivas,
            onChanged: (bool value) async {
              if (!value) {
                final opened = await openAppSettings();
                if (!opened) {
                  _mostrarSnackBar("No se pudo abrir la configuración del sistema.");
                }
                return;
              }

              final status = await Permission.notification.request();

              if (!status.isGranted) {
                _mostrarSnackBar(
                    'Debes activar las notificaciones desde Ajustes del sistema');
                setState(() {
                  _notificacionesActivas = false;
                  _permisoSistema = false;
                });
                return;
              }

              
              setState(() {
                _notificacionesActivas = true;
                _permisoSistema = true;
              });
              await _guardarPreferencia('notificaciones', true);
              await FirebaseMessaging.instance.subscribeToTopic('todos');
              _mostrarSnackBar('Notificaciones activadas');
            },
          ),

          const Divider(height: 8),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Ver notificaciones"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final userId = prefs.getInt('userId') ?? 0;

              if (userId == 0) {
                _mostrarSnackBar('No se encontró usuario válido');
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HistorialNotificacionesScreen(userId: userId),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("Acerca de"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AcercaDeScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Cerrar sesión"),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final userId = prefs.getInt('userId');
              final notificacionesActivas =
                  prefs.getBool('notificaciones') ?? true;

              if (notificacionesActivas) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Desactiva las notificaciones"),
                    content: const Text(
                        "Para cerrar sesión correctamente, primero debes desactivar las notificaciones."),
                    actions: [
                      TextButton(
                        child: const Text("OK"),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                );
                return;
              }

              if (userId != null) {
                try {
                  await FirebaseMessaging.instance.deleteToken();
                  await eliminarTokenFcmDelServidor(userId);
                } catch (e) {
                  debugPrint("❌ Error al eliminar token: $e");
                }

                await prefs.remove('userId');
                await prefs.remove('notificaciones');
              }

              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }

  Future<void> eliminarTokenFcmDelServidor(int userId) async {
    final uri = Uri.parse("https://6ca93b502fb2.ngrok-free.app/tokens-fcm/$userId");
    final response = await http.delete(uri);

    if (response.statusCode == 200) {
      debugPrint("✅ Token FCM eliminado del servidor");
    } else {
      debugPrint("⚠️ No se pudo eliminar token FCM del servidor");
    }
  }
}
