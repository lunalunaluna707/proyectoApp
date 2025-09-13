import 'package:flutter/material.dart';
import '../apiservice.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';

class DiagramaGantt extends StatefulWidget {
  final int proyectoId;
  final String nombreProyecto;

    const DiagramaGantt({
    super.key,
    required this.proyectoId,
    required this.nombreProyecto,  
  });

  @override
  State<DiagramaGantt> createState() => _DiagramaGanttState();
}

class _DiagramaGanttState extends State<DiagramaGantt> {
  final ScrollController _horizontalScroll = ScrollController();
  final ScrollController _verticalScroll = ScrollController();

  DateTime? startOfMonth;
  int totalDays = 0;
  List<Map<String, dynamic>> tareas = [];

  // Paleta formal, tonos azules y grises
final List<List<Color>> colorsList = [
  [Color(0xFF00ACC1), Color(0xFF00838F)],  // Azul turquesa fuerte
  [Color(0xFFFDD835), Color(0xFFFBC02D)],  // Amarillo intenso
  [Color(0xFF43A047), Color(0xFF2E7D32)],  // Verde fuerte
  [Color(0xFFEF6C00), Color(0xFFE65100)],  // Naranja profundo
  [Color(0xFF8E24AA), Color(0xFF6A1B9A)],  // Púrpura fuerte
  [Color(0xFF1E88E5), Color(0xFF1565C0)],  // Azul fuerte
];



  final Map<String, List<Color>> encargadoColorMap = {};

  @override
  void initState() {
    super.initState();
    _cargarTareas();
  }

  Future<void> _cargarTareas() async {
    try {
      final data = await ApiService.fetchTareas(widget.proyectoId);

      final transformed = data.map<Map<String, dynamic>>((tarea) {
        return {
          ...tarea,
          'fecha_inicio': _parseDate(tarea['fecha_inicio']),
          'fecha_fin': _parseDate(tarea['fecha_fin']),
          'porcentaje_progreso': _parseProgress(tarea['porcentaje_progreso']),
        };
      }).toList();

      if (transformed.isNotEmpty) {
        DateTime minFecha = transformed.first['fecha_inicio'];
        DateTime maxFecha = transformed.first['fecha_fin'];

        final contador = <String, int>{};

        for (var tarea in transformed) {
          if (tarea['fecha_inicio'].isBefore(minFecha)) {
            minFecha = tarea['fecha_inicio'];
          }
          if (tarea['fecha_fin'].isAfter(maxFecha)) {
            maxFecha = tarea['fecha_fin'];
          }

          final encargados = (tarea['encargados'] as List?)?.cast<String>() ?? [];
          if (encargados.isEmpty) {
            contador['Sin asignar'] = 1;
          } else {
            for (var encargado in encargados) {
              contador[encargado] = 1;
            }
          }
        }

        final encargadosUnicos = contador.keys.toSet().toList();
        encargadoColorMap.clear();
        for (int i = 0; i < encargadosUnicos.length; i++) {
          encargadoColorMap[encargadosUnicos[i]] = colorsList[i % colorsList.length];
        }
        encargadoColorMap['Sin asignar'] = [Colors.grey.shade400, Colors.grey.shade600];

        setState(() {
          tareas = transformed;
          startOfMonth = minFecha.subtract(const Duration(days: 2));
          totalDays = maxFecha.difference(startOfMonth!).inDays + 4;
        });
      } else {
        setState(() {
          tareas = [];
          startOfMonth = DateTime.now();
          totalDays = 30;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar tareas: $e')),
      );
    }
  }

  DateTime _parseDate(dynamic date) {
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }

  double _parseProgress(dynamic value) {
    if (value is int) return value / 100;
    if (value is double) return value.clamp(0.0, 1.0);
    return 0.0;
  }

  void scrollHorizontally(double offset) {
    if (_horizontalScroll.hasClients) {
      _horizontalScroll.animateTo(
        (_horizontalScroll.offset + offset).clamp(0.0, _horizontalScroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _mostrarDetalleTarea(Map<String, dynamic> tarea) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            tarea['titulo'] ?? 'Tarea',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('📅 Inicio:', tarea['fecha_inicio'].toString().split(' ')[0]),
              _infoRow('⏳ Fin:', tarea['fecha_fin'].toString().split(' ')[0]),
              _infoRow('👤 Encargado:', (tarea['encargados'] as List?)?.join(', ') ?? 'Sin asignar'),
              _infoRow('📈 Progreso:', '${(tarea['porcentaje_progreso'] * 100).toInt()}%'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          children: [
            TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: ' $value'),
          ],
        ),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  final tareaLabelWidth = 280.0;

  return Scaffold(
    backgroundColor: Colors.grey.shade100,
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
                    decoration: const BoxDecoration(
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
                  'Diagrama de Gantt',
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

  body: tareas.isEmpty
    ? const Center(child: CircularProgressIndicator())
    : LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isWide = screenWidth > 600;

          final double idealDayWidth = screenWidth / (totalDays + 4);
          final dayWidth = idealDayWidth.clamp(20.0, 90.0);

          return Scrollbar(
            controller: _verticalScroll,
            thumbVisibility: true,
            radius: const Radius.circular(12),
            thickness: 10,
            child: SingleChildScrollView(
              controller: _verticalScroll,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📁 Proyecto: ${widget.nombreProyecto}",
                    style: TextStyle(
                      fontSize: isWide ? 24 : 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_left, size: 30, color: Colors.grey),
                        onPressed: () => scrollHorizontally(-140),
                        tooltip: 'Desplazar a la izquierda',
                      ),
                      Expanded(
                        child: Scrollbar(
                          controller: _horizontalScroll,
                          thumbVisibility: true,
                          radius: const Radius.circular(12),
                          thickness: 10,
                          child: SingleChildScrollView(
                            controller: _horizontalScroll,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: tareaLabelWidth + (dayWidth * totalDays),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeaderDays(dayWidth, tareaLabelWidth),
                                  const SizedBox(height: 10),
                                  ..._buildTaskRows(dayWidth, tareaLabelWidth),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_right, size: 30, color: Colors.grey),
                        onPressed: () => scrollHorizontally(140),
                        tooltip: 'Desplazar a la derecha',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),

  
  
  
  );
}


  Widget _buildHeaderDays(double dayWidth, double tareaLabelWidth) {
    if (startOfMonth == null) return const SizedBox.shrink();

    List<DateTime> days = List.generate(totalDays, (i) => startOfMonth!.add(Duration(days: i)));

    Map<String, List<DateTime>> monthMap = {};
    for (var day in days) {
      String key = '${day.year}-${day.month}';
      monthMap.putIfAbsent(key, () => []).add(day);
    }

    return Column(
      children: [
        
        Row(
          children: [
            Container(
              width: tareaLabelWidth,
              height: 36,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text("Mes", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            ...monthMap.entries.map((entry) {
              final month = entry.value.first;
              final width = entry.value.length * dayWidth;
              return Container(
                width: width,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade700, width: 0.7),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${_monthAbbreviation(month.month)} ${month.year}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              );
            }).toList(),
          ],
        ),
        Row(
          children: [
            Container(
              width: tareaLabelWidth,
              height: 42,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade400),
                  right: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              child: const Text("Tarea", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            ...days.map((day) {
              final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
              return Container(
                width: dayWidth,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isWeekend ? Colors.grey.shade300 : Colors.grey.shade100,
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade400),
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isWeekend ? Colors.grey.shade700 : Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildTaskRows(double dayWidth, double tareaLabelWidth) {
    if (startOfMonth == null) return [];

    return tareas.map((task) {
      final DateTime inicio = task['fecha_inicio'];
      final DateTime fin = task['fecha_fin'];
      final double porcentaje = task['porcentaje_progreso'];

      final int offset = inicio.difference(startOfMonth!).inDays;
      final int duracion = fin.difference(inicio).inDays + 1;

      final encargados = (task['encargados'] as List?)?.cast<String>() ?? [];
      int tareaIndex = tareas.indexOf(task);
      final gradient = colorsList[tareaIndex % colorsList.length];

    

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: tareaLabelWidth,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['titulo'] ?? 'Sin título',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.grey.shade900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (encargados.isNotEmpty)
                    Text(
                      encargados.join(', '),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),

            ),
            SizedBox(
              width: dayWidth * totalDays,
              height: 44,
              child: GestureDetector(
                onTap: () => _mostrarDetalleTarea(task),
                child: Stack(
                  children: [
                    Positioned(
                      left: offset * dayWidth,
                      child: Container(
                        width: duracion * dayWidth,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              gradient[0].withOpacity(0.45),
                              gradient[1].withOpacity(0.45),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: gradient[1].withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (porcentaje > 0)
                      Positioned(
                        left: offset * dayWidth,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 450),
                          width: duracion * dayWidth * porcentaje,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: gradient[1].withOpacity(0.7),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.centerLeft,
                          child: Builder(
  builder: (context) {
    final double progressWidth = duracion * dayWidth * porcentaje;
    if (progressWidth > 40) {
      return Text(
        '${(porcentaje * 100).round()}%',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          shadows: [Shadow(blurRadius: 1.2, color: Colors.black38, offset: Offset(0,1))],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  },
),

                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _monthAbbreviation(int month) {
    const months = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return months[month];
  }
void generarPDF() async {
  final pdf = pw.Document();

  if (startOfMonth == null || tareas.isEmpty) {
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Text('No hay datos para mostrar en el diagrama'),
        ),
      ),
    );
  } else {
    final tareaLabelWidth = 100.0;
    final maxDaysPerPage = 35;
    final days = List.generate(totalDays, (i) => startOfMonth!.add(Duration(days: i)));

    int totalPages = (days.length / maxDaysPerPage).ceil();

    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      final startIndex = pageIndex * maxDaysPerPage;
      final endIndex = (startIndex + maxDaysPerPage).clamp(0, days.length);
      final visibleDays = days.sublist(startIndex, endIndex);
      final dayWidth = (PdfPageFormat.a4.landscape.availableWidth - tareaLabelWidth) / visibleDays.length;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Diagrama de Gantt - Proyecto: ${widget.nombreProyecto}',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),

                
                pw.Row(
                  children: [
                    pw.Container(
                      width: tareaLabelWidth,
                      child: pw.Text('Tarea',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    ...visibleDays.map((day) => pw.Container(
                          width: dayWidth,
                          alignment: pw.Alignment.center,
                          child: pw.Text('${day.day}/${day.month}',
                              style: pw.TextStyle(fontSize: 8)),
                        )),
                  ],
                ),
                pw.Divider(),

                
                ...tareas.map((task) {
                  final inicio = task['fecha_inicio'];
                  final fin = task['fecha_fin'];
                  final porcentaje = task['porcentaje_progreso'];

                  final encargados = (task['encargados'] as List?)?.cast<String>() ?? [];
                  final encargadoClave = encargados.isNotEmpty ? encargados.first : 'Sin asignar';

                  final offset = inicio.difference(startOfMonth!).inDays;
                  final duracion = fin.difference(inicio).inDays + 1;

                  
                  if (offset + duracion < startIndex || offset > endIndex) {
                    return pw.SizedBox(); 
                  }

                  final visibleOffset = (offset - startIndex).clamp(0, maxDaysPerPage);
                  final visibleDuracion = ((offset + duracion) - startIndex).clamp(0, maxDaysPerPage) - visibleOffset;

                  final baseColor = PdfColors.blue;

                  return pw.Row(
                    children: [
                      pw.Container(
                        width: tareaLabelWidth,
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Text(task['titulo'] ?? 'Sin título',
                            style: pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Stack(
                        children: [
                          pw.Container(
                            width: dayWidth * visibleDays.length,
                            height: 16,
                            color: PdfColors.grey300,
                          ),
                          pw.Positioned(
                            left: visibleOffset * dayWidth,
                            child: pw.Container(
                              width: visibleDuracion * dayWidth,
                              height: 16,
                              color: PdfColors.blue100,
                            ),
                          ),
                          pw.Positioned(
                            left: visibleOffset * dayWidth,
                            child: pw.Container(
                              width: visibleDuracion * dayWidth * porcentaje,
                              height: 16,
                              color: baseColor,
                            ),
                          ),
                          if (porcentaje > 0)
                            pw.Positioned(
                              left: visibleOffset * dayWidth + 2,
                              top: 2,
                              child: pw.Text('${(porcentaje * 100).round()}%',
                                  style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  )),
                            ),
                        ],
                      ),
                    ],
                  );
                }).toList(),
              ],
            );
          },
        ),
      );
    }
  }

  try {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/diagrama_gantt.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(filePath);
  } catch (e) {
    debugPrint("Error al generar o guardar el PDF: $e");
  }
}


}
