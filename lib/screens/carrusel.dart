import 'package:flutter/material.dart';
import '../apiservice.dart';  

class CarruselProgresoTareas extends StatefulWidget {
  final int proyectoId;
   final String nombreProyecto; 

   const CarruselProgresoTareas({
    Key? key,
    required this.proyectoId,
    required this.nombreProyecto,  
  }) : super(key: key);


  @override
  _CarruselProgresoTareasState createState() => _CarruselProgresoTareasState();
}

class _CarruselProgresoTareasState extends State<CarruselProgresoTareas> {
  List<Map<String, dynamic>> tareasData = [];
  late PageController _pageController;
  int _currentPage = 0;
  bool _isLoading = true;
  bool _autoScrollActivo = true;

  final List<List<Color>> _gradientes = [
    [Colors.teal.shade700, Colors.teal.shade900],
    [Colors.deepPurple.shade700, Colors.deepPurple.shade900],
    [Colors.indigo.shade700, Colors.indigo.shade900],
    [Colors.orange.shade700, Colors.deepOrange.shade900],
    [Colors.blueGrey.shade700, Colors.blueGrey.shade900],
    [Colors.pink.shade700, Colors.pink.shade900],
    [Colors.cyan.shade700, Colors.cyan.shade900],
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _cargarTareas();
  }

  Future<void> _cargarTareas() async {
    try {
      final data = await ApiService.fetchTareas(widget.proyectoId);
      setState(() {
        tareasData = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
      _autoScroll();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error al cargar tareas: $e');
    }
  }

  void _autoScroll() async {
    while (_autoScrollActivo && mounted && tareasData.isNotEmpty) {
      await Future.delayed(Duration(seconds: 5));
      if (_pageController.hasClients) {
        int siguientePagina = (_currentPage + 1) % tareasData.length;
        _pageController.animateToPage(
          siguientePagina,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        _currentPage = siguientePagina;
      }
    }
  }

  @override
  void dispose() {
    _autoScrollActivo = false;
    _pageController.dispose();
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  if (_isLoading) {
    return Center(child: CircularProgressIndicator());
  }

  if (tareasData.isEmpty) {
    return Center(child: Text('No hay tareas', style: TextStyle(fontSize: 24)));
  }

  return Column(
    children: [
      Expanded(
        child: PageView.builder(
          controller: _pageController,
          itemCount: tareasData.length + 1, 
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            if (index == 0) {
              return _proyectoCard(); 
            } else {
              final tarea = tareasData[index - 1];
              final gradiente = _gradientes[(index - 1) % _gradientes.length];
              return _tareaCard(tarea, gradiente);
            }
          },
        ),
      ),
      SizedBox(height: 12),
      _buildPageIndicator(),
      SizedBox(height: 20),
    ],
  );
}

Widget _proyectoCard() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      shadowColor: Colors.black38,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade200,
              Colors.purple.shade400,
            ],

            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Text(
            widget.nombreProyecto,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 3)],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(tareasData.length, (index) {
        bool isActive = index == _currentPage;
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.teal[700] : Colors.grey[400],
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _tareaCard(Map<String, dynamic> tarea, List<Color> gradiente) {
    String fechaInicio = tarea['fecha_inicio'] ?? '';
    String fechaFin = tarea['fecha_fin'] ?? '';
    int progreso = tarea['porcentaje_progreso'] ?? 0;
    String estado = tarea['estado'] ?? '';
    List encargados = tarea['encargados'] ?? [];

    Color estadoColor;
    switch (estado.toLowerCase()) {
      case 'completado':
        estadoColor = Colors.greenAccent;
        break;
      case 'en progreso':
        estadoColor = Colors.orangeAccent;
        break;
      case 'pendiente':
        estadoColor = Colors.redAccent;
        break;
      default:
        estadoColor = Colors.white70;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
        shadowColor: Colors.black38,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: gradiente,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  tarea['titulo'] ?? 'Sin título',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 3)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 14),
              Flexible(
                child: Text(
                  tarea['descripcion'] ?? 'Sin descripción',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Spacer(),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 22, color: Colors.white70),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$fechaInicio → $fechaFin',
                      style: TextStyle(fontSize: 20, color: Colors.white70),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18),
              LinearProgressIndicator(
                value: progreso / 100,
                minHeight: 14,
                backgroundColor: Colors.white30,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.lightGreenAccent.shade400),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.speed, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    '$progreso%',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Text(
                      estado.toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14),
              if (encargados.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.group, color: Colors.white70, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        encargados.join(', '),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
