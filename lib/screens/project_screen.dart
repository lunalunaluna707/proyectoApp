import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../widgets/custom_bottom_nav.dart';
import '../form/proyectos_form_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../apiservice.dart';
import 'detalles_proyecto.dart';
import 'diagrama_gant.dart';  
import 'pantallasugerencia.dart';  
import 'package:intl/intl.dart';
import 'carrusel.dart';
import 'estadisticas_panel.dart';



class Proyecto {
  final int id;
  final String nombre;
  final String descripcion;
  final int porcentaje;
  final String fechaInicio;
  final String fechaFin;

  Proyecto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.porcentaje,
    required this.fechaInicio,
    required this.fechaFin,
  });

  factory Proyecto.fromJson(Map<String, dynamic> json) {
    return Proyecto(
      id: json['proyecto_id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'] ?? '',
      porcentaje: json['porcentaje_progreso'] ?? 0,
      fechaInicio: json['fecha_inicio'] ?? '',
      fechaFin: json['fecha_fin'] ?? '',
    );
  }
}

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  List<Proyecto> proyectos = [];
  bool cargando = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProyectos();
  }

Future<void> fetchProyectos() async {
  try {
    final data = await ApiService.fetchProyectos();
    setState(() {
      proyectos = data;
      cargando = false;
    });
  } catch (e) {
    setState(() => cargando = false);

    if (e.toString().contains('Token expirado')) {
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');

      
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.folder_open,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Proyectos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
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
                const Spacer(),
            
                
              ],
            ),
          ),
        ),
      ),
    ),
    body: cargando
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: fetchProyectos,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusBox(
                          proyectos.where((p) => p.porcentaje == 100).length.toString(),
                          "Completados",
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatusBox(
                          proyectos.where((p) => p.porcentaje < 100).length.toString(),
                          "Sin terminar",
                          Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Proyectos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Buscar proyecto...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          fetchProyectos();
                        },
                      ),
                    ),
                    onChanged: (value) async {
                      if (value.isEmpty) {
                        fetchProyectos();
                      } else {
                        final resultados = await ApiService.buscarProyectosPorNombre(value);
                        setState(() {
                          proyectos = resultados;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  ...proyectos.map((proyecto) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildProjectCard(
                          proyecto,
                          proyecto.porcentaje / 100.0,
                          getColorForPercentage(proyecto.porcentaje),
                        ),
                      )),
                ],
              ),
            ),
          ),
    floatingActionButton: FloatingActionButton(
      backgroundColor: Colors.yellow[600],
      child: const Icon(Icons.add, color: Colors.black),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProyectoForm()),
        );
        fetchProyectos();
      },
    ),
    bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
  );
}

  Widget _buildStatusBox(String count, String label, Color color) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(count, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 14, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(Proyecto proyecto, double progress, Color color) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showProjectOptions(proyecto),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: Colors.black45,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                proyecto.nombre,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                proyecto.descripcion,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              
              LayoutBuilder(
                builder: (context, constraints) {
                  double fullWidth = constraints.maxWidth;
                  return Stack(
                    children: [
                      Container(
                        height: 22,
                        width: fullWidth,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                        height: 22,
                        width: fullWidth * progress.clamp(0.0, 1.0),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            '${proyecto.porcentaje}%',
  style: const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(
        blurRadius: 4,
        color: Colors.black38,
        offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProjectOptions(Proyecto proyecto) {
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
                    proyecto.nombre,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.visibility, color: Colors.blue),
                    title: const Text('Ver detalles'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetallesProyectoScreen(proyectoId: proyecto.id),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.timeline, color: Colors.indigo),
                    title: const Text('Ver Diagrama de Gantt'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PantallaSugerida(
                            siguientePantalla: DiagramaGantt(
                              proyectoId: proyecto.id,
                              nombreProyecto: proyecto.nombre,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  ListTile(
                        leading: const Icon(Icons.view_carousel, color: Colors.purple),
                        title: const Text('Ver Carrusel de Tareas'),
                        onTap: () {
                          Navigator.pop(context); 
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CarruselProgresoTareas(proyectoId: proyecto.id, nombreProyecto: proyecto.nombre),
                            ),
                          );
                        },
                      ),

                  ListTile(
                leading: const Icon(Icons.bar_chart, color: Colors.teal),
                title: const Text('Resumen de tareas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PantallaSugerida(
                      siguientePantalla: EstadisticasScreen(
                        proyectoId: proyecto.id,
                        nombreProyecto: proyecto.nombre,
                      ),
                    ),
                  ),
                );
              },
            ),


                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.orange),
                    title: const Text('Editar'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProyectoForm(
                            proyecto: {
                              'proyecto_id': proyecto.id,
                              'nombre': proyecto.nombre,
                              'descripcion': proyecto.descripcion,
                              'fecha_inicio': proyecto.fechaInicio,
                              'fecha_fin': proyecto.fechaFin,
                              'porcentaje_progreso': proyecto.porcentaje,
                            },
                          ),
                        ),
                      ).then((_) => fetchProyectos());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Confirmar eliminación"),
                          content: const Text("¿Seguro que deseas eliminar este proyecto?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("Cancelar"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                eliminarProyecto(proyecto.id);
                              },
                              child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color getColorForPercentage(int porcentaje) {
    if (porcentaje == 100) {
      return Colors.green;
    } else if (porcentaje > 50) {
      return Colors.amber[700]!;
    } else {
      return Colors.red;
    }
  }

  Future<void> eliminarProyecto(int id) async {
    final exito = await ApiService.eliminarProyecto(id);
    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proyecto eliminado')),
      );
      fetchProyectos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar')),
      );
    }
  }
}