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
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  final isLandscape = screenWidth > screenHeight;

  return Scaffold(
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text('Error: $_error'))
            : RefreshIndicator(
                onRefresh: _cargarTareasAsignadas,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // AppBar siempre visible
                    SliverAppBar(
                      pinned: false,
                      expandedHeight: screenHeight * (isLandscape ? 0.55 : 0.40),
                      backgroundColor: Colors.transparent,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Fondo curvo
                            ClipPath(
                              clipper: DashboardClipper(),
                              child: Container(
                                height: screenHeight * (isLandscape ? 0.55 : 0.40),
                                decoration: const BoxDecoration(color: Colors.cyan),
                              ),
                            ),
                            // Contenido AppBar
                            SafeArea(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.05,
                                  vertical: screenHeight * 0.015,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.task_alt,
                                            color: Colors.white,
                                            size: isLandscape
                                                ? screenHeight * 0.07
                                                : screenWidth * 0.08),
                                        SizedBox(width: screenWidth * 0.03),
                                        Flexible(
                                          child: Text(
                                            'Tareas Asignadas',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isLandscape
                                                  ? screenHeight * 0.035
                                                  : screenWidth * 0.065,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: screenHeight * 0.015),
                                    // Tarjeta resumen flotante
                                    Container(
                                      padding: EdgeInsets.all(screenWidth * 0.04),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildResumenColumn(
                                              "Completadas",
                                              completadas,
                                              Colors.green.shade200,
                                              screenWidth,
                                              screenHeight),
                                          _buildResumenColumn(
                                              "Vencidas",
                                              vencidas,
                                              Colors.red.shade200,
                                              screenWidth,
                                              screenHeight),
                                          _buildResumenColumn(
                                              "Por vencer",
                                              porVencer,
                                              Colors.orange.shade200,
                                              screenWidth,
                                              screenHeight),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Simbología solo si hay tareas
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: screenHeight * 0.01),
                        child: _tareas.isNotEmpty
                            ? _buildSimbolosLeyenda()
                            : const SizedBox.shrink(),
                      ),
                    ),

                    // Lista de tareas o mensaje si está vacía
                    _tareas.isNotEmpty
                        ? SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final tarea = _tareas[index];
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.05,
                                      vertical: screenHeight * 0.01),
                                  child: _buildTareaCard(tarea),
                                );
                              },
                              childCount: _tareas.length,
                            ),
                          )
                        : SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                'No tienes tareas asignadas',
                                style: TextStyle(fontSize: 18, color: Colors.black54),
                              ),
                            ),
                          ),

                    // Espacio inferior
                    SliverToBoxAdapter(
                      child: SizedBox(height: screenHeight * 0.05),
                    ),
                  ],
                ),
              ),
    bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
  );
}


// Método auxiliar para columnas de resumen (resizable)
Widget _buildResumenColumn(String label, int valor, Color color,
    double screenWidth, double screenHeight) {
  final isLandscape = screenWidth > screenHeight;
  return Column(
    children: [
      Text(
        valor.toString(),
        style: TextStyle(
            fontSize: isLandscape ? screenHeight * 0.03 : screenWidth * 0.05,
            fontWeight: FontWeight.bold),
      ),
      Text(label, style: const TextStyle(color: Colors.grey)),
    ],
  );
}

 Widget _buildTareaCard(Map<String, dynamic> tarea) {
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
class DashboardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height - 60);
    path.quadraticBezierTo(size.width * 0.75, size.height - 120, size.width, size.height - 80);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}