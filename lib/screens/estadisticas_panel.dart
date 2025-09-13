import 'package:flutter/material.dart';
import '../apiservice.dart';
import 'package:fl_chart/fl_chart.dart';

class EstadisticasScreen extends StatefulWidget {
  final int proyectoId;
  final String nombreProyecto;

  const EstadisticasScreen({super.key, required this.proyectoId, required this.nombreProyecto});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  final ScrollController _scrollController = ScrollController();
final GlobalKey _keyDistribucion = GlobalKey();
  final GlobalKey _keyTareasPorSemana = GlobalKey();
  final GlobalKey _keyProgresoUsuarios = GlobalKey();
  bool cargando = true;
  Map<String, dynamic>? proyectoData;
  String? error;

  List<dynamic> tareasSeleccionadas = [];
String miembroSeleccionado = '';


  @override
  void initState() {
    super.initState();
    cargarDatosProyecto();
  }

@override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  
int totalTareas = 0;
int tareasCompletadas = 0;
int totalMiembros = 0;
double porcentajeAvance = 0.0;

void calcularIndicadores() {
  if (proyectoData == null) return;

  final tareas = proyectoData!['todas_las_tareas'] as List<dynamic>? ?? [];
  final miembros = proyectoData!['miembros'] as List<dynamic>? ?? [];

  totalTareas = tareas.length;
  tareasCompletadas = tareas.where((t) => (t['estado']?.toString().toLowerCase() == 'completado')).length;
  totalMiembros = miembros.length;
  porcentajeAvance = totalTareas == 0 ? 0 : (tareasCompletadas / totalTareas) * 100;
}

  Future<void> cargarDatosProyecto() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final data = await ApiService.fetchProyecto(widget.proyectoId);
      setState(() {
        proyectoData = data;
        cargando = false;
        calcularIndicadores();
      });
    } catch (e) {
      setState(() {
        error = 'Error al cargar datos: $e';
        cargando = false;
      });
    }
  }
List<Map<String, dynamic>> calcularProgresoPorUsuario() {
  if (proyectoData == null) return [];

  final miembros = proyectoData!['miembros'] as List<dynamic>? ?? [];
  final tareasAsignadas = proyectoData!['tareas_asignadas'] as List<dynamic>? ?? [];

  List<Map<String, dynamic>> progresoUsuarios = [];

  for (var miembro in miembros) {
    int usuarioId = miembro['usuario_id'];
    String nombre = miembro['nombre'] ?? 'Sin nombre';

    // Filtrar tareas asignadas a este usuario
    final tareasUsuario = tareasAsignadas.where((t) => t['usuario_id'] == usuarioId).toList();

    int total = tareasUsuario.length;
    int completadas = tareasUsuario.where((t) => (t['estado']?.toString().toLowerCase() == 'completado')).length;
    int enProgreso = tareasUsuario.where((t) => (t['estado']?.toString().toLowerCase() == 'en progreso')).length;
    int pendientes = tareasUsuario.where((t) => (t['estado']?.toString().toLowerCase() == 'pendiente')).length;

    progresoUsuarios.add({
      'usuarioId': usuarioId,
      'nombre': nombre,
      'total': total,
      'completadas': completadas,
      'enProgreso': enProgreso,
      'pendientes': pendientes,
    });
  }

  return progresoUsuarios;
}

 void _scrollASeccion(String seccion) {
    RenderBox? box;
    double offset = 0;

    switch (seccion) {
      case 'distribucion':
        box = _keyDistribucion.currentContext?.findRenderObject() as RenderBox?;
        break;
      case 'tareasPorSemana':
        box = _keyTareasPorSemana.currentContext?.findRenderObject() as RenderBox?;
        break;
      case 'progresoUsuarios':
        box = _keyProgresoUsuarios.currentContext?.findRenderObject() as RenderBox?;
        break;
    }

    if (box != null) {
      offset = box.localToGlobal(Offset.zero, ancestor: context.findRenderObject()).dy + _scrollController.offset;
      _scrollController.animateTo(
        offset - 100,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

 List<BarChartGroupData> _crearGraficaMiembros() {
  if (proyectoData == null) return [];

  final miembros = proyectoData!['miembros'] as List<dynamic>? ?? [];
  final tareasAsignadas = proyectoData!['tareas_asignadas'] as List<dynamic>? ?? [];

  Map<int, int> tareasPorUsuario = {};
  int tareasSinAsignar = 0;

  for (var tarea in tareasAsignadas) {
    var usuarioId = tarea['usuario_id'];
    if (usuarioId == null || usuarioId == 0) {
      tareasSinAsignar++;
    } else {
      tareasPorUsuario[usuarioId] = (tareasPorUsuario[usuarioId] ?? 0) + 1;
    }
  }

  
  final List<Color> colores = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.pink,
    Colors.cyan,
    Colors.brown,
    Colors.deepPurple,
    Colors.grey,  
  ];

  List<BarChartGroupData> grupos = List.generate(miembros.length, (index) {
    final miembro = miembros[index];
    final usuarioId = miembro['usuario_id'];
    final cantidadTareas = tareasPorUsuario[usuarioId] ?? 0;
    final color = colores[index % colores.length];

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: cantidadTareas.toDouble(),
          width: 18,
          borderRadius: BorderRadius.circular(8),
          color: color,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: (tareasPorUsuario.values.isEmpty
                    ? 0
                    : tareasPorUsuario.values.reduce((a, b) => a > b ? a : b))
                .toDouble() +
                2,
            color: Colors.grey.shade300,
          ),
        ),
      ],
    );
  });

  // Agregar barra para tareas sin asignar, solo si hay alguna
  if (tareasSinAsignar > 0) {
    final maxY = (tareasPorUsuario.values.isEmpty
            ? 0
            : tareasPorUsuario.values.reduce((a, b) => a > b ? a : b))
        .toDouble() +
        2;

    grupos.add(BarChartGroupData(
      x: miembros.length,  // índice siguiente
      barRods: [
        BarChartRodData(
          toY: tareasSinAsignar.toDouble(),
          width: 18,
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: Colors.grey.shade300,
          ),
        ),
      ],
    ));
  }

  return grupos;
}

  List<String> _obtenerNombresMiembros() {
  if (proyectoData == null) return [];
  final miembros = proyectoData!['miembros'] as List<dynamic>? ?? [];
  List<String> nombres = miembros.map((m) => (m['nombre'] ?? '').toString()).toList();

  // Si hay tareas sin asignar, agregar etiqueta
  final tareasAsignadas = proyectoData!['tareas_asignadas'] as List<dynamic>? ?? [];
  bool hayTareasSinAsignar = tareasAsignadas.any((t) => t['usuario_id'] == null || t['usuario_id'] == 0);
  if (hayTareasSinAsignar) {
    nombres.add('Sin asignar');
  }

  return nombres;
}

  List<BarChartGroupData> _crearGraficaTareasPorSemana() {
    if (proyectoData == null) return [];

    final tareasPorSemana = proyectoData!['tareas_por_semana'] as List<dynamic>? ?? [];

    return List.generate(tareasPorSemana.length, (index) {
      final semanaData = tareasPorSemana[index];
      final completadas = semanaData['completadas'] ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: completadas.toDouble(),
            width: 18,
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: completadas > 0
                  ? [Colors.green.shade700, Colors.green.shade400]
                  : [Colors.grey.shade400, Colors.grey.shade200],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: (tareasPorSemana.map((e) => (e['completadas'] ?? 0) as int).fold(0, (a, b) => a > b ? a : b)).toDouble() + 2,
              color: Colors.grey.shade300,
            ),
          ),
        ],
      );
    });
  }

  List<String> _obtenerEtiquetasSemanas() {
    if (proyectoData == null) return [];
    final tareasPorSemana = proyectoData!['tareas_por_semana'];
    if (tareasPorSemana == null || tareasPorSemana is! List) return [];

    return tareasPorSemana.whereType<Map>().map((e) {
      if (e.containsKey('semana_label')) {
        return e['semana_label']?.toString() ?? '';
      }
      return '';
    }).toList();
  }

  @override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;

  final miembrosCount = proyectoData?['miembros']?.length ?? 1;
  final tareasPorSemanaCount = proyectoData?['tareas_por_semana']?.length ?? 1;

  final miembrosWidth = miembrosCount * 80.0;
  final tareasWidth = tareasPorSemanaCount * 80.0;

  final miembrosBoxWidth = miembrosWidth > screenWidth ? miembrosWidth : screenWidth;
  final tareasBoxWidth = tareasWidth > screenWidth ? tareasWidth : screenWidth;

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
                    'Resumen de tareas',
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
    body: cargando
        ? const Center(child: CircularProgressIndicator())
        : error != null
            ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // BOTONES DE NAVEGACIÓN A SECCIONES
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _scrollASeccion('distribucion'),
                                  child: const Text("Distribución"),
                                ),
                                ElevatedButton(
                                  onPressed: () => _scrollASeccion('tareasPorSemana'),
                                  child: const Text("Por semana"),
                                ),
                                ElevatedButton(
                                  onPressed: () => _scrollASeccion('progresoUsuarios'),
                                  child: const Text("Progreso"),
                                ),
                              ],
                            ),
                          ),

                          // INDICADORES
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _KpiCard(title: 'Tareas', value: '$totalTareas', color: Colors.teal),
                                    _KpiCard(title: 'Completadas', value: '$tareasCompletadas', color: Colors.green),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _KpiCard(title: 'Miembros', value: '$totalMiembros', color: Colors.blue),
                                    _KpiCard(title: 'Avance', value: '${porcentajeAvance.toStringAsFixed(1)}%', color: Colors.deepOrange),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // DISTRIBUCION DE TAREAS
                          Container(
                            key: _keyDistribucion,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Distribución de tareas', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 250,
                                  child: Scrollbar(
                                    thumbVisibility: true,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: miembrosBoxWidth,
                                          maxWidth: miembrosBoxWidth,
                                        ),
                                        child: _GraficaBarrasMiembros(
                                          miembrosData: _crearGraficaMiembros(),
                                          nombres: _obtenerNombresMiembros(),
                                          onBarTouched: (index) {
                                            final miembros = proyectoData!['miembros'] as List<dynamic>;
                                            final tareasAsignadas = proyectoData!['tareas_asignadas'] as List<dynamic>;

                                            if (index < miembros.length) {
                                              final usuario = miembros[index];
                                              final usuarioId = usuario['usuario_id'];
                                              final nombre = usuario['nombre'];
                                              final asignadas = tareasAsignadas
                                                  .where((t) => t['usuario_id'] == usuarioId)
                                                  .toList();
                                              setState(() {
                                                tareasSeleccionadas = asignadas;
                                                miembroSeleccionado = nombre;
                                              });
                                            } else {
                                              final sinAsignar = tareasAsignadas
                                                  .where((t) => t['usuario_id'] == null || t['usuario_id'] == 0)
                                                  .toList();
                                              setState(() {
                                                tareasSeleccionadas = sinAsignar;
                                                miembroSeleccionado = 'Sin asignar';
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (tareasSeleccionadas.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text('Tareas de $miembroSeleccionado', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: tareasSeleccionadas.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final tarea = tareasSeleccionadas[index];
                                return ListTile(
                                  leading: const Icon(Icons.task_alt_outlined),
                                  title: Text(tarea['titulo'] ?? 'Sin título'),
                                  subtitle: Text('Estado: ${tarea['estado'] ?? 'Desconocido'}'),
                                );
                              },
                            ),
                          ],

                          const SizedBox(height: 30),

                          // TAREAS 
                          Container(
                            key: _keyTareasPorSemana,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tareas completadas por semana', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 250,
                                  child: Scrollbar(
                                    thumbVisibility: true,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: tareasBoxWidth,
                                          maxWidth: tareasBoxWidth,
                                        ),
                                        child: _GraficaBarrasTareasCompletadas(
                                          tareasData: _crearGraficaTareasPorSemana(),
                                          dias: _obtenerEtiquetasSemanas(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          
                          Container(
                            key: _keyProgresoUsuarios,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Progreso por usuario', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 8),
                                _buildProgresoUsuarios(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
  );
}
  Widget _buildProgresoUsuarios() {
  final progresoUsuarios = calcularProgresoPorUsuario();

  if (progresoUsuarios.isEmpty) {
    return const Center(child: Text('No hay datos de progreso por usuario'));
  }

  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: progresoUsuarios.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (context, index) {
      final usuario = progresoUsuarios[index];
      final total = usuario['total'] as int;

      if (total == 0) {
        return ListTile(
          title: Text(usuario['nombre']),
          subtitle: const Text('No tiene tareas asignadas'),
        );
      }

      double porcCompletadas = usuario['completadas'] / total;
      double porcEnProgreso = usuario['enProgreso'] / total;
      double porcPendientes = usuario['pendientes'] / total;

      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usuario['nombre'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

            
              Stack(
                children: [
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: (porcCompletadas * 1000).toInt(),
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                              topRight: porcEnProgreso == 0 && porcPendientes == 0 ? Radius.circular(10) : Radius.zero,
                              bottomRight: porcEnProgreso == 0 && porcPendientes == 0 ? Radius.circular(10) : Radius.zero,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: (porcEnProgreso * 1000).toInt(),
                        child: Container(
                          height: 20,
                          color: Colors.orange,
                        ),
                      ),
                      Expanded(
                        flex: (porcPendientes * 1000).toInt(),
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Completadas: ${usuario['completadas']}'),
                  Text('En progreso: ${usuario['enProgreso']}'),
                  Text('Pendientes: ${usuario['pendientes']}'),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}


}

class _GraficaBarrasMiembros extends StatelessWidget {
  final List<BarChartGroupData> miembrosData;
  final List<String> nombres;
  final Function(int index) onBarTouched;

  const _GraficaBarrasMiembros({
    required this.miembrosData,
    required this.nombres,
    required this.onBarTouched,
  });

  @override
  Widget build(BuildContext context) {
    if (miembrosData.isEmpty) return const Center(child: Text('No hay datos de miembros'));

    final maxY = miembrosData.map((e) => e.barRods[0].toY).fold(0.0, (prev, curr) => curr > prev ? curr : prev) + 2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        groupsSpace: 30,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, interval: maxY / 5, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= nombres.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    nombres[index],
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        barGroups: miembrosData,
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade400),
            left: BorderSide(color: Colors.grey.shade400),
          ),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: maxY / 5,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (event, response) {
            if (response != null && response.spot != null) {
              final index = response.spot!.touchedBarGroupIndex;
              onBarTouched(index);
            }
          },
        ),
      ),
    );

    
  }
  
}

class _GraficaBarrasTareasCompletadas extends StatelessWidget {
  final List<BarChartGroupData> tareasData;
  final List<String> dias;

  const _GraficaBarrasTareasCompletadas({required this.tareasData, required this.dias});

  @override
  Widget build(BuildContext context) {
    if (tareasData.isEmpty) return const Center(child: Text('No hay datos de tareas'));

    final maxY = tareasData.map((e) => e.barRods[0].toY).fold(0.0, (prev, curr) => curr > prev ? curr : prev) + 2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        groupsSpace: 30,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, interval: maxY / 5, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dias.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    dias[index],
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        barGroups: tareasData,
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade400),
            left: BorderSide(color: Colors.grey.shade400),
          ),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: maxY / 5,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1),
        ),
        barTouchData: BarTouchData(enabled: true),
      ),
    );
  }
}
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
