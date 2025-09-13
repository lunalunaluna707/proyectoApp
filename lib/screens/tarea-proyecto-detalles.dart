import 'package:flutter/material.dart';
import '../apiservice.dart'; // Ajusta la ruta si es necesario
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
class TareaDetallesScreen extends StatefulWidget {
  final int tareaId;

  const TareaDetallesScreen({Key? key, required this.tareaId}) : super(key: key);

  @override
  State<TareaDetallesScreen> createState() => _TareaDetallesScreenState();
}

class _TareaDetallesScreenState extends State<TareaDetallesScreen> {
  late Future<Map<String, dynamic>> _futureTarea;
  List<Map<String, dynamic>> equipoUsuarios = []; 
  int? usuarioSeleccionado;


  final List<Color> coloresNotas = [
    Colors.teal.shade300,
    Colors.orange.shade300,
    Colors.purple.shade300,
    Colors.green.shade300,
    Colors.blue.shade300,
    Colors.pink.shade300,
  ];

  @override
  void initState() {
    super.initState();
    _futureTarea = ApiService.fetchTareaPorId(widget.tareaId);
    _cargarUsuariosEquipo();
  }

  Future<void> _cargarUsuariosEquipo() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      throw Exception('No hay token disponible');
    }

    final tarea = await ApiService.fetchTareaPorId(widget.tareaId);
    final int proyectoId = tarea['proyecto_id']; 

    final List<Map<String, dynamic>> usuarios = await ApiService.fetchUsuariosEquipo(proyectoId, token);

    setState(() {
      equipoUsuarios = usuarios;
    });
  } catch (e) {
    debugPrint("Error cargando usuarios equipo: $e");
  }
}

 void _mostrarFormularioAsignacion() {
  final _formKey = GlobalKey<FormState>();
  DateTime fechaAsignacion = DateTime.now();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      final maxWidth = MediaQuery.of(context).size.width * 0.9;
      final maxHeight = MediaQuery.of(context).size.height * 0.7;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Asignar tarea',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                      ),
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Usuario',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      items: equipoUsuarios.map((usuario) {
                        return DropdownMenuItem<int>(
                          value: usuario['usuario_id'],
                          child: Text(usuario['nombre_usuario'] ?? 'Sin nombre'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          usuarioSeleccionado = val;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Selecciona un usuario' : null,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      initialValue: DateFormat('yyyy-MM-dd').format(fechaAsignacion),
                      decoration: InputDecoration(
                        labelText: 'Fecha de asignación',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan,         
                            foregroundColor: Colors.white,         
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;

                            final prefs = await SharedPreferences.getInstance();
                            final token = prefs.getString('token') ?? '';

                            if (token.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('No hay token disponible. Inicia sesión'),
                                ),
                              );
                              return;
                            }

                            

                            final resultado = await ApiService.asignarTarea(
                              tareaId: widget.tareaId,
                              usuarioId: usuarioSeleccionado!,
                              fechaAsignacion: DateFormat('yyyy-MM-dd').format(fechaAsignacion),
                              token: token,
                            );

                            if (resultado['success'] == true) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Asignación realizada con éxito')),
                              );
                            } else {
                              final mensaje = resultado['message'] ?? 'Error desconocido';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $mensaje')),
                              );
                            }

                          },
                          child: const Text('Asignar'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
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
                    'Detalles de tarea',
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
     
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureTarea,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tarea = snapshot.data!;
          final List<Map<String, String>> datos = [
            {'Título': tarea['titulo'] ?? 'Sin título'},
            {'Descripción': tarea['descripcion'] ?? 'Sin descripción'},
            {'Fecha de inicio': tarea['fecha_inicio'] ?? 'Sin fecha'},
            {'Fecha de fin': tarea['fecha_fin'] ?? 'Sin fecha'},
            {'Estado': tarea['estado'] ?? 'Sin estado'},
            {'Proyecto': tarea['nombre_proyecto'] ?? 'Sin proyecto asignado'},
          ];

          final List<dynamic> historial = tarea['historial_avances'] ?? [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                ...datos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final titulo = entry.value.keys.first;
                  final valor = entry.value[titulo]!;
                  final color = coloresNotas[index % coloresNotas.length];
                  return _detallePostIt(titulo, valor, color);
                }),
                const SizedBox(height: 20),
                const Text(
                  'Historial de avances',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                historial.isEmpty
                    ? const Text('No hay avances registrados.')
                    : _buildTimeline(historial, coloresNotas),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormularioAsignacion,
        label: const Text('Asignar'),
        icon: const Icon(Icons.person_add_alt_1),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget _detallePostIt(String titulo, String valor, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.6), blurRadius: 10, offset: const Offset(3, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 6),
          Text(valor, style: const TextStyle(fontSize: 15, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<dynamic> historial, List<Color> coloresNotas) {
    Map<String, Color> colorPorFecha = {};

    Color obtenerColorParaFecha(String fecha) {
      if (!colorPorFecha.containsKey(fecha)) {
        colorPorFecha[fecha] = coloresNotas[colorPorFecha.length % coloresNotas.length];
      }
      return colorPorFecha[fecha]!;
    }

    return Column(
      children: historial.asMap().entries.map((entry) {
        final index = entry.key;
        final avance = entry.value;

        String fechaCompleta = avance['fecha_registro'] ?? 'Sin fecha';
        String fechaDia = fechaCompleta.split(' ').first;

        final color = obtenerColorParaFecha(fechaDia);

        final porcentaje = avance['porcentaje']?.toString() ?? '0';
        final motivo = avance['motivo'] ?? 'Sin motivo';
        final usuario = avance['nombre_usuario']?.toString() ?? 'Desconocido';

        final isLast = index == historial.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.7),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Container(
                      height: 80,
                      width: 4,
                      color: color.withOpacity(0.7),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(fechaCompleta,
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('Usuario: $usuario',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('$porcentaje%',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(motivo, style: const TextStyle(fontSize: 15, color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
