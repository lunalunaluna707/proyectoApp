import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  
import '../apiservice.dart';
import '../widgets/custom_bottom_nav.dart';
import 'detallles_tarea.dart';
import '../form/form_tarea.dart';
import 'package:shared_preferences/shared_preferences.dart';
class TareasScreen extends StatefulWidget {
  const TareasScreen({super.key});

  @override
  State<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _tareas = [];
  String? _error;

  final Map<String, Color> _coloresProyectos = {};

  final List<Color> _listaColores = [
    Colors.teal.shade300,
    Colors.orange.shade300,
    Colors.purple.shade300,
    Colors.green.shade300,
    Colors.blue.shade300,
    Colors.pink.shade300,
    Colors.amber.shade300,
    Colors.cyan.shade300,
  ];

  int _indiceColor = 0;

  int completadas = 0;
  int vencidas = 0;
  int porVencer = 0;
  int noTerminadasYVencidas = 0;

  final DateFormat formatoFechaServidor = DateFormat('dd/MM/yyyy');


  @override
  void initState() {
    super.initState();
    _cargarTareasAsignadas();
  }

  Future<void> _cargarTareasAsignadas() async {
    try {
      final tareas = await ApiService.fetchTareasAsignadas();

      final now = DateTime.now();
      final hoy = DateTime(now.year, now.month, now.day);
      final limitePorVencer = hoy.add(const Duration(days: 3)); 

      completadas = 0;
      vencidas = 0;
      porVencer = 0;
      noTerminadasYVencidas = 0;

      for (var tarea in tareas) {
        final porcentaje = tarea['porcentaje_progreso'] ?? 0;
        final estado = (tarea['estado'] ?? '').toString().toLowerCase();

        DateTime? fechaFin;
        try {
            if (tarea['fecha_fin'] != null && tarea['fecha_fin'].isNotEmpty) {
              fechaFin = formatoFechaServidor.parse(tarea['fecha_fin']);
              fechaFin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
            }
          } catch (e) {
            fechaFin = null;
          }


        if (porcentaje == 100 || estado == 'completado' || estado == 'terminado') {
          completadas++;
        } else if (fechaFin != null) {
          if (fechaFin.isBefore(hoy)) {
            vencidas++;
            noTerminadasYVencidas++;
          } else if (!fechaFin.isBefore(hoy) && !fechaFin.isAfter(limitePorVencer)) {
            porVencer++;
            noTerminadasYVencidas++;
          }
        }
      }

      setState(() {
        _tareas = tareas;
        _loading = false;

        for (var tarea in tareas) {
          final proyecto = tarea['nombre_proyecto'] ?? 'Proyecto desconocido';
          if (!_coloresProyectos.containsKey(proyecto)) {
            _coloresProyectos[proyecto] = _listaColores[_indiceColor % _listaColores.length];
            _indiceColor++;
          }
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _colorPorProgreso(int porcentaje) {
    if (porcentaje == 100) return Colors.green;
    if (porcentaje >= 45) return Colors.orange;
    return Colors.red;
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
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      tarea['titulo'] ?? 'Sin título',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tarea['descripcion'] != null && tarea['descripcion'].toString().length > 100
                        ? '${tarea['descripcion'].toString().substring(0, 100)}...'
                        : tarea['descripcion']?.toString() ?? 'Sin descripción',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const Divider(height: 30),
                  ListTile(
                    leading: const Icon(Icons.visibility, color: Colors.blue),
                    title: const Text('Ver detalles'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetalleTareaScreen(tarea: tarea),
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
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildResumenCard(IconData icono, int cantidad, Color color) {
    return Expanded(
      child: Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 30, color: Colors.white),
            const SizedBox(height: 6),
            Text(
              '$cantidad',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
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
            BoxShadow(color: Colors.black38, offset: Offset(0, 3), blurRadius: 8),
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
                  decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.task_alt, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Tareas Asignadas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 4),
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
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text('Error: $_error'))
            : _tareas.isEmpty
                ? const Center(child: Text('No tienes tareas asignadas'))
                : RefreshIndicator(
                    onRefresh: _cargarTareasAsignadas,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildResumenCard(Icons.check_circle, completadas, Colors.green.shade200),
                                _buildResumenCard(Icons.schedule, vencidas, Colors.red.shade200),
                                _buildResumenCard(Icons.warning, porVencer, Colors.orange.shade200),
                              ],
                            ),
                            _buildSimbolosLeyenda(),
                            const SizedBox(height: 16),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _tareas.length,
                              itemBuilder: (context, index) {
                                final tarea = _tareas[index];
                                final nombreProyecto = tarea['nombre_proyecto'] ?? 'Proyecto desconocido';
                                final colorProyecto = _coloresProyectos[nombreProyecto] ?? Colors.blue.shade100;
                                final porcentajeProgreso = (tarea['porcentaje_progreso'] ?? 0);
                                final progreso = (porcentajeProgreso is int || porcentajeProgreso is double)
                                    ? (porcentajeProgreso.clamp(0, 100) / 100)
                                    : 0.0;
                                final porcentajeInt = (progreso * 100).toInt();
                                final colorBarra = _colorPorProgreso(porcentajeInt);
                                final estadoBD = tarea['estado']?.toString() ?? 'Desconocido';

                                DateTime? fechaFin;
                                try {
                                  if (tarea['fecha_fin'] != null && tarea['fecha_fin'].isNotEmpty) {
                                    fechaFin = formatoFechaServidor.parse(tarea['fecha_fin']);
                                  }
                                } catch (_) {}

                                final hoy = DateTime.now();
                                final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
                                final limitePorVencer = hoySinHora.add(const Duration(days: 3));

                                IconData? iconoVencimiento;
                                Color? colorIcono;
                                if (porcentajeInt == 100 || estadoBD.toLowerCase() == 'completado') {
                                  iconoVencimiento = Icons.check_circle;
                                  colorIcono = Colors.green;
                                } else if (fechaFin != null && fechaFin.isBefore(hoySinHora)) {
                                  iconoVencimiento = Icons.schedule;
                                  colorIcono = Colors.red;
                                } else if (fechaFin != null && !fechaFin.isBefore(hoySinHora) && !fechaFin.isAfter(limitePorVencer)) {
                                  iconoVencimiento = Icons.warning;
                                  colorIcono = Colors.orange;
                                }

                                return GestureDetector(
                                  onTap: () => _mostrarOpcionesTarea(tarea),
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 4,
                                    child: Stack(
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: colorProyecto,
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(12),
                                                  topRight: Radius.circular(12),
                                                ),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.folder, color: Colors.white),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      nombreProyecto,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    tarea['titulo'] ?? 'Sin título',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    tarea['descripcion'] ?? 'Sin descripción',
                                                    style: const TextStyle(fontSize: 14),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Text(
                                                        'Progreso:',
                                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                                      ),
                                                      Text(
                                                        '$porcentajeInt%',
                                                        style: const TextStyle(fontSize: 14),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: TweenAnimationBuilder<double>(
                                                      tween: Tween<double>(begin: 0, end: progreso),
                                                      duration: const Duration(milliseconds: 800),
                                                      curve: Curves.easeInOut,
                                                      builder: (context, value, child) {
                                                        return LinearProgressIndicator(
                                                          value: value,
                                                          minHeight: 10,
                                                          backgroundColor: Colors.grey.shade300,
                                                          valueColor: AlwaysStoppedAnimation<Color>(colorBarra),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    estadoBD,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: colorBarra,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (iconoVencimiento != null)
                                          Positioned(
                                            right: 12,
                                            bottom: 12,
                                            child: Icon(iconoVencimiento, color: colorIcono, size: 24),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
    bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
  );
}

 Widget _buildSimbolosLeyenda() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Simbología:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 18),
            SizedBox(width: 8),
            Text('Completada', style: TextStyle(fontSize: 13)),
          ],
        ),
        SizedBox(height: 6),
        Row(
          children: const [
            Icon(Icons.schedule, color: Colors.red, size: 18),
            SizedBox(width: 8),
            Text('Vencida', style: TextStyle(fontSize: 13)),
          ],
        ),
        SizedBox(height: 6),
        Row(
          children: const [
            Icon(Icons.warning, color: Colors.orange, size: 18),
            SizedBox(width: 8),
            Text('Próxima a vencer', style: TextStyle(fontSize: 13)),
          ],
        ),
      ],
    ),
  );
}

}
