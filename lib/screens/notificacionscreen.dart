import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../apiservice.dart';  

class Notificacion {
  final int id;
  final int proyectoId;
  final int userId;
  final int solicitadoPor;
  final String titulo;
  final String cuerpo;
  final String fecha;
  final bool leido;
  final String estado;
  final String solicitudId;
  final String tipoAccion;
  final String nombreSolicitante;
  final String? nombreProcesador;

  Notificacion({
    required this.id,
    required this.proyectoId,
    required this.userId,
    required this.solicitadoPor,
    required this.titulo,
    required this.cuerpo,
    required this.fecha,
    required this.leido,
    required this.estado,
    required this.solicitudId,
    required this.tipoAccion,
    required this.nombreSolicitante,
    this.nombreProcesador,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'],
      proyectoId: json['proyecto_id'],
      userId: json['user_id'],
      solicitadoPor: json['solicitado_por'],
      titulo: json['titulo'],
      cuerpo: json['cuerpo'],
      fecha: json['fecha'],
      leido: json['leido'] == 1,
      estado: json['estado'],
      solicitudId: json['solicitud_id'] ?? '',
      tipoAccion: json['tipo_accion'] ?? '',
      nombreSolicitante: json['nombre_solicitante'] ?? 'Desconocido',
      nombreProcesador: json['nombre_procesador'],
    );
  }
}

class HistorialNotificacionesScreen extends StatefulWidget {
  final int userId;

  const HistorialNotificacionesScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<HistorialNotificacionesScreen> createState() => _HistorialNotificacionesScreenState();
}

class _HistorialNotificacionesScreenState extends State<HistorialNotificacionesScreen> {
  late Future<List<Notificacion>> _futureNotificaciones;
  Set<int> notificacionesLeidas = {};


 
@override
void initState() {
  super.initState();
  _inicializarDatos();
}

Future<void> _inicializarDatos() async {
  await _cargarNotificacionesLeidas();
  await _cargarNotificaciones();       
}

Future<void> _cargarNotificaciones() async {
  _futureNotificaciones = ApiService.fetchNotificaciones(widget.userId);
  setState(() {});
}

Future<void> _cargarNotificacionesLeidas() async {
  final prefs = await SharedPreferences.getInstance();
  final leidas = prefs.getStringList('notificaciones_leidas_${widget.userId}') ?? [];
  setState(() {
    notificacionesLeidas = leidas.map(int.parse).toSet();
  });
}

void _marcarComoLeida(int id) async {
  if (!notificacionesLeidas.contains(id)) {
    setState(() {
      notificacionesLeidas.add(id);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'notificaciones_leidas_${widget.userId}',
      notificacionesLeidas.map((e) => e.toString()).toList(),
    );
  }
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
                  'Notificaciones',
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

    body: FutureBuilder<List<Notificacion>>(
      future: _futureNotificaciones,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay notificaciones'));
        }

        final notificaciones = snapshot.data!;

        return ListView.separated(
          itemCount: notificaciones.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final n = notificaciones[index];
            final estaLeida = notificacionesLeidas.contains(n.id);

            return GestureDetector(
              onTap: () {
                _marcarComoLeida(n.id);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getCardColor(n.estado),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            estaLeida ? Icons.mark_email_read : Icons.mark_email_unread,
                            color: estaLeida ? Colors.grey : Colors.blueAccent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              n.titulo,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _buildEstadoChip(n.estado),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        n.cuerpo,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Fecha: ${n.fecha}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Solicitado por: ${n.nombreSolicitante}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      if (n.estado != 'pendiente') ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Procesado por: ${n.nombreProcesador ?? "-"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                      if (n.estado.toLowerCase() == 'pendiente' && n.tipoAccion == 'eliminar_tarea') ...[
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                           OutlinedButton.icon(
  onPressed: () async {
    final exito = await ApiService.responderSolicitud(
      solicitudId: n.solicitudId,
      decision: 'aceptado',
    );
    if (!mounted) return;

    if (exito) {
      _marcarComoLeida(n.id);  
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(exito ? 'Solicitud aceptada' : 'Error al aceptar')),
    );
    setState(() {
      _futureNotificaciones = ApiService.fetchNotificaciones(widget.userId);
    });
  },
  icon: const Icon(Icons.thumb_up, color: Colors.green),
  label: const Text("Aceptar", style: TextStyle(color: Colors.green)),
  style: OutlinedButton.styleFrom(
    side: const BorderSide(color: Colors.green),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
),
const SizedBox(width: 8),
OutlinedButton.icon(
  onPressed: () async {
    final exito = await ApiService.responderSolicitud(
      solicitudId: n.solicitudId,
      decision: 'rechazado',
    );
    if (!mounted) return;

    if (exito) {
      _marcarComoLeida(n.id);  
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(exito ? 'Solicitud rechazada' : 'Error al rechazar')),
    );
    setState(() {
      _futureNotificaciones = ApiService.fetchNotificaciones(widget.userId);
    });
  },
  icon: const Icon(Icons.thumb_down, color: Colors.red),
  label: const Text("Rechazar", style: TextStyle(color: Colors.red)),
  style: OutlinedButton.styleFrom(
    side: const BorderSide(color: Colors.red),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
),

                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

  Widget _buildEstadoChip(String estado) {
    Color color;
    String texto;

    switch (estado.toLowerCase()) {
      case 'pendiente':
        color = Colors.orange;
        texto = 'Pendiente';
        break;
      case 'aceptado':
        color = Colors.green;
        texto = 'Aceptado';
        break;
      case 'rechazado':
        color = Colors.red;
        texto = 'Rechazado';
        break;
      default:
        color = Colors.grey;
        texto = estado;
    }

    return Chip(
      label: Text(texto, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  Color _getCardColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return const Color(0xFFFFF3E0); 
      case 'aceptado':
        return const Color(0xFFE8F5E9); 
      case 'rechazado':
        return const Color(0xFFFFEBEE); 
      default:
        return Colors.white;
    }
  }

  
}
