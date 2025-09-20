import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:koalgenda/form/form_tarea.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../apiservice.dart';
import '../main.dart';
import 'package:fl_chart/fl_chart.dart';

import 'grupo_proyecto.dart';
import '../servicionotificaciones/notification_sender.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'detallles_tarea.dart';
import 'tarea-proyecto-detalles.dart';
import 'carrusel.dart';

class DetallesProyectoScreen extends StatefulWidget {
  final int proyectoId;

  const DetallesProyectoScreen({super.key, required this.proyectoId});

  @override
  State<DetallesProyectoScreen> createState() => _DetallesProyectoScreenState();
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _DetallesProyectoScreenState extends State<DetallesProyectoScreen> {
  Map<String, dynamic>? proyecto;
  List<dynamic> tareas = [];
  List<dynamic> tareasFiltradas = [];
  bool loading = true;
  final TextEditingController _searchController = TextEditingController();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    cargarDatos();
    _searchController.addListener(_filtrarTareas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
Future<int?> _getUsuarioId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('userId');
}

  void _filtrarTareas() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      tareasFiltradas = tareas.where((t) => (t['titulo'] ?? '').toLowerCase().contains(query)).toList();
    });
  }

  Future<void> cargarDatos() async {
    setState(() => loading = true);
    try {
      final proyectoData = await ApiService.fetchProyecto(widget.proyectoId);
      final tareasData = await ApiService.fetchTareas(widget.proyectoId);

      if (proyectoData != null) {
        setState(() {
          proyecto = proyectoData;
          tareas = tareasData;
          tareasFiltradas = tareas;
          loading = false;
        });
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proyecto no encontrado')),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  Color _estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'completado':
        return Colors.green;
      case 'en progreso':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Icon _iconoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'completado':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'en progreso':
        return const Icon(Icons.timelapse, color: Colors.orange);
      case 'pendiente':
      default:
        return const Icon(Icons.hourglass_empty, color: Colors.grey);
    }
  }

  Widget _buildTareaCard(dynamic tarea) {
    double progreso = (tarea['porcentaje_progreso'] ?? 0).toDouble();
    Color progresoColor = _getColorForProgress(progreso);
    String estado = tarea['estado'] ?? '';
    String titulo = tarea['titulo'] ?? 'Sin título';

    List encargados = tarea['encargados'] ?? [];
    String responsable = encargados.isNotEmpty ? encargados.join(', ') : 'N/A';

    return GestureDetector(
      onTap: () => _mostrarOpcionesTarea(tarea),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 10),
        elevation: 5,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircularPercentIndicator(
                radius: 36.0,
                lineWidth: 6.0,
                animation: true,
                percent: progreso / 100,
                center: Text(
                  "${progreso.toInt()}%",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: progresoColor,
                backgroundColor: Colors.grey[300]!,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _iconoEstado(estado),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            titulo,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildTag(estado, _estadoColor(estado)),
                        _buildTag('👤 $responsable', Colors.indigo),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildGraficaEstados() {
    int completadas = tareas.where((t) => t['estado']?.toLowerCase() == 'completado').length;
    int enProgreso = tareas.where((t) => t['estado']?.toLowerCase() == 'en progreso').length;
    int pendientes = tareas.where((t) => t['estado']?.toLowerCase() == 'pendiente').length;
    int total = completadas + enProgreso + pendientes;

    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text("No hay tareas para mostrar en la gráfica.")),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
     
      final double size = constraints.maxWidth * 0.7 > 300 ? 300 : constraints.maxWidth * 0.7;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Resumen de Estado",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: size,
              height: size,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: size * 0.08,
                  sectionsSpace: 2,
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: completadas.toDouble(),
                      title: "${((completadas / total) * 100).toStringAsFixed(1)}%",
                      radius: size * 0.23,
                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: Colors.orange,
                      value: enProgreso.toDouble(),
                      title: "${((enProgreso / total) * 100).toStringAsFixed(1)}%",
                      radius: size * 0.23,
                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: Colors.grey,
                      value: pendientes.toDouble(),
                      title: "${((pendientes / total) * 100).toStringAsFixed(1)}%",
                      radius: size * 0.23,
                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: const [
              _LegendItem(color: Colors.green, label: "Completado"),
              _LegendItem(color: Colors.orange, label: "En progreso"),
              _LegendItem(color: Colors.grey, label: "Pendiente"),
            ],
          ),
          const SizedBox(height: 24),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final porcentaje = (proyecto?['porcentaje_progreso'] ?? 0).toDouble();
    final anchoPantalla = MediaQuery.of(context).size.width;

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
                  Expanded(
                    child: Text(
                      'Detalles del proyecto',
                      style: const TextStyle(
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : proyecto == null
              ? const Center(child: Text('Proyecto no encontrado'))
              : SafeArea(
                 child: RefreshIndicator(
              onRefresh: cargarDatos,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            proyecto!['nombre'] ?? '',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Column(
                            children: [
                              Text("${porcentaje.toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: anchoPantalla * 0.8,
                                child: LinearProgressIndicator(
                                  value: porcentaje / 100.0,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[300],
                                  color: _getColorForProgress(porcentaje),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (proyecto!['miembros'] != null && proyecto!['miembros'].isNotEmpty) ...[
                                const Text(
                                  "Miembros del Proyecto:",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                miembrosList(proyecto!['miembros']),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                "Vencimiento: ${proyecto!['fecha_fin'] ?? '-'}",
                                style: const TextStyle(color: Colors.black54, fontSize: 14),
                              ),
                              Text(
                                "Responsable: ${proyecto!['responsable'] ?? 'Sin asignar'}",
                                style: const TextStyle(color: Colors.black54, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (tareas.isNotEmpty) _buildGraficaEstados(),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar tarea...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filtrarTareas();
                                    },
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text("Tareas:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        tareasFiltradas.isEmpty
                            ? const Center(child: Text("No hay tareas"))
                            : ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: tareasFiltradas.length,
                                itemBuilder: (context, index) => _buildTareaCard(tareasFiltradas[index]),
                              ),
                      ],
                    ),
                  ),
                ),
                ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AsignarUsuarioScreen()),
                );
              },
              backgroundColor: Colors.yellow[600],
              child: const Icon(Icons.edit_note, color: Colors.black),
            ),
          ),
          Positioned(
            bottom: 86,
            right: 16,
            child: FloatingActionButton(
              onPressed: () async{
                int? usuarioId = await _getUsuarioId();

                if (usuarioId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuario no identificado')),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistroTareaPage(proyectoId: widget.proyectoId, usuarioId: usuarioId,),
                  ),
                );
              },
              backgroundColor: Colors.cyan,
              child: const Icon(Icons.add_task),
              tooltip: 'Registrar tarea',
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForProgress(double porcentaje) {
    if (porcentaje >= 100) return Colors.green;
    if (porcentaje >= 50) return Colors.amber;
    return Colors.red;
  }

  void _confirmarEliminacion(int tareaId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar eliminación'),
        content: const Text('¿Quieres solicitar la eliminación de esta tarea? Esta acción deberá ser aprobada por un administrador.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final currentContext = context;
              Navigator.pop(currentContext);

              final prefs = await SharedPreferences.getInstance();
              final tokenUsuario = prefs.getString('token') ?? '';

              if (tokenUsuario.isEmpty) {
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  const SnackBar(content: Text('Error: Token no disponible')),
                );
                return;
              }

              final exito = await Notificaciones.solicitarEliminacionTarea(
                tareaId: tareaId,
                jwtToken: tokenUsuario,
              );

              if (!mounted) return;

              ScaffoldMessenger.of(currentContext).showSnackBar(
                SnackBar(
                  content: Text(
                    exito
                        ? '✅ Solicitud enviada, espera aprobación del administrador'
                        : '❌ Error al enviar la solicitud',
                  ),
                ),
              );

              if (exito) await cargarDatos();
            },
            child: const Text('Solicitar eliminación', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

Widget miembrosList(List miembros) {
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: miembros.map<Widget>((miembro) {
      String nombreCompleto = miembro['nombre'] ?? '';
      String iniciales = nombreCompleto.isNotEmpty
          ? nombreCompleto.trim().split(' ').map((e) => e[0]).take(2).join()
          : '';

      return GestureDetector(
        onTap: () => _confirmarEliminarMiembro(miembro),
        child: Tooltip(
          message: nombreCompleto,
          waitDuration: const Duration(milliseconds: 500),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              constraints: const BoxConstraints(maxWidth: 180),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 18,
                    child: Text(
                      iniciales.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      nombreCompleto,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );
}

void _confirmarEliminarMiembro(dynamic miembro) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Eliminar miembro'),
        content: Text('¿Estás seguro que quieres eliminar a ${miembro['nombre']} del proyecto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), 
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); 
              _eliminarMiembro(miembro);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}

Future<void> _eliminarMiembro(dynamic miembro) async {
  bool success = await ApiService.eliminarMiembroProyecto(
    proyectoId: widget.proyectoId,
    usuarioId: miembro['usuario_id'], 
  );

  if (success) {
    setState(() {
      proyecto!['miembros'].removeWhere((m) => m['usuario_id'] == miembro['usuario_id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Miembro ${miembro['nombre']} eliminado correctamente')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error al eliminar miembro')),
    );
  }
}



  void _mostrarOpcionesTarea(dynamic tarea) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          initialChildSize: 0.5,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tarea['titulo'] ?? 'Sin título',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                 ListTile(
  leading: const Icon(Icons.visibility, color: Colors.blue),
  title: const Text('Ver detalles'),
  onTap: () {
    Navigator.pop(context); // si estás en un modal
    Navigator.push(
      context,
      MaterialPageRoute(
   builder: (_) => TareaDetallesScreen(tareaId: tarea['tarea_id']),
      ),
    );
  },
),

   ListTile(
  leading: const Icon(Icons.edit, color: Colors.orange),
  title: const Text('Editar tarea'),
  onTap: () async {
    Navigator.pop(context); 

    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('userId');


    if (usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no identificado')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroTareaPage(
          proyectoId: tarea['proyecto_id'],
          tareaExistente: tarea,
          usuarioId: usuarioId,  
        ),
      ),
    );
  },
),


                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmarEliminacion(tarea['tarea_id']);
                    },
                  ),
                  
                  ListTile(
  leading: const Icon(Icons.person_remove, color: Colors.deepPurple),
  title: const Text('Eliminar asignación de miembro'),
  onTap: () {
    Navigator.pop(context);
    _mostrarDialogoEliminarAsignacion(tarea);
  },
),

                ],
              ),
            );
          },
        );
      },
    );
  }
void _mostrarDialogoEliminarAsignacion(dynamic tarea) async {
  List miembros = tarea['miembros'] ?? [];  

  if (miembros.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No hay miembros asignados a esta tarea')),
    );
    return;
  }

  String? miembroSeleccionado;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Eliminar asignación'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Selecciona el miembro a eliminar:'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: miembroSeleccionado,
                  items: miembros.map<DropdownMenuItem<String>>((miembro) {
                    
                    final id = miembro['id']?.toString() ?? '';
                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(miembro['nombre']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      miembroSeleccionado = value;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (miembroSeleccionado != null && miembroSeleccionado!.isNotEmpty) {
                Navigator.pop(context);
                _eliminarAsignacionMiembro(miembroSeleccionado!, tarea['tarea_id']);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Selecciona un miembro')),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      );
    },
  );
}

void _eliminarAsignacionMiembro(String miembroId, int tareaId) async {
  try {
    final exito = await ApiService.eliminarAsignacion(miembroId: miembroId, tareaId: tareaId);
    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asignación eliminada')),
      );
      
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la asignación')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error al conectar con el servidor')),
    );
  }
}



}
