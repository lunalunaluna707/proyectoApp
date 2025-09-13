import 'package:flutter/material.dart';
import '../apiservice.dart'; 
import 'package:intl/intl.dart';

class RegistroTareaPage extends StatefulWidget {
  final int proyectoId;
  final Map<String, dynamic>? tareaExistente;
  final int usuarioId;

  const RegistroTareaPage({
    Key? key,
    required this.proyectoId,
    this.tareaExistente,
    required this.usuarioId,
  }) : super(key: key);

  @override
  State<RegistroTareaPage> createState() => _RegistroTareaPageState();
}

class _RegistroTareaPageState extends State<RegistroTareaPage> {
  final _formKey = GlobalKey<FormState>();

  String? _titulo;
  String? _descripcion;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _estado = 'pendiente';

  // Formatos para fecha que podrías recibir
  final DateFormat formatoISO = DateFormat('yyyy-MM-dd');
  final DateFormat formatoConBarra = DateFormat('dd/MM/yyyy');
  final DateFormat formatoConGuion = DateFormat('dd-MM-yyyy');

  final DateFormat formatoMostrar = DateFormat('dd/MM/yyyy');

  final List<String> _estados = ['pendiente', 'en progreso', 'completado'];

  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  late TextEditingController _motivoController;
  late TextEditingController _progresoController;

  int _porcentajeProgreso = 0;
  int? _porcentajeProgresoOriginal;

  bool _mostrarMotivo = false;
  bool _estadoCambiadoManual = false;

  @override
  void initState() {
    super.initState();

    _tituloController = TextEditingController(text: widget.tareaExistente?['titulo'] ?? '');
    _descripcionController = TextEditingController(text: widget.tareaExistente?['descripcion'] ?? '');
    _motivoController = TextEditingController();

    _porcentajeProgreso = widget.tareaExistente?['porcentaje_progreso'] ?? 0;
    _porcentajeProgresoOriginal = _porcentajeProgreso;
    _progresoController = TextEditingController(text: _porcentajeProgreso.toString());


if (widget.tareaExistente != null && widget.tareaExistente!['estado'] != null) {
  _estado = widget.tareaExistente!['estado'];
  
 
  if (_porcentajeProgreso == _porcentajeProgresoOriginal) {
    _estadoCambiadoManual = true;
  }
} else {
  
  if (_porcentajeProgreso == 100) {
    _estado = 'completado';
  } else if (_porcentajeProgreso > 0) {
    _estado = 'en progreso';
  } else {
    _estado = 'pendiente';
  }
}


   
    _fechaInicio = _parseFechaFlexible(widget.tareaExistente?['fecha_inicio']);
    _fechaFin = _parseFechaFlexible(widget.tareaExistente?['fecha_fin']);

    _mostrarMotivo = false;

_progresoController.addListener(() {
  final valor = int.tryParse(_progresoController.text) ?? 0;
  final cambio = valor != _porcentajeProgresoOriginal;

  setState(() {
    _mostrarMotivo = cambio;

    
    final antes = _porcentajeProgreso;
    _porcentajeProgreso = valor;

    
    if (valor != antes) {
      _estadoCambiadoManual = false;
    }

    
    if (!_estadoCambiadoManual) {
      if (valor == 100) {
        _estado = 'completado';
      } else if (valor > 0) {
        _estado = 'en progreso';
      } else {
        _estado = 'pendiente';
      }
    }
  });
});


  }

  
  DateTime? _parseFechaFlexible(String? fechaStr) {
    if (fechaStr == null || fechaStr.trim().isEmpty) return null;

    DateTime? fecha;
    List<DateFormat> formatos = [formatoISO, formatoConBarra, formatoConGuion];

    for (var formato in formatos) {
      try {
        fecha = formato.parseStrict(fechaStr);
        if (fecha != null) break;
      } catch (_) {
        
      }
    }
    return fecha;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _motivoController.dispose();
    _progresoController.dispose();
    super.dispose();
  }

  Future<void> _selectFechaInicio(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fechaInicio = picked;
        if (_fechaFin != null && _fechaFin!.isBefore(picked)) {
          _fechaFin = null;
        }
      });
    }
  }

  Future<void> _selectFechaFin(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? (_fechaInicio ?? DateTime.now()),
      firstDate: _fechaInicio ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fechaFin = picked;
      });
    }
  }

  bool get esEdicion => widget.tareaExistente != null;

 void _submit() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();

    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona ambas fechas')),
      );
      return;
    }

    if (_mostrarMotivo && _motivoController.text.trim().isNotEmpty) {
      bool? confirmacion = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Advertencia'),
            content: const Text(
              'Una vez enviado el motivo, no podrás editar ni eliminar este registro. ¿Deseas continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      );

      if (confirmacion != true) {
        return;
      }
    }

    final titulo = _titulo!;
    final descripcion = _descripcion ?? '';
    final fechaInicio = _fechaInicio!.toIso8601String();
    final fechaFin = _fechaFin!.toIso8601String();

    if (!_estadoCambiadoManual) {
      if (_porcentajeProgreso == 100) {
        _estado = 'completado';
      } else if (_porcentajeProgreso > 0) {
        _estado = 'en progreso';
      } else {
        _estado = 'pendiente';
      }
    }

    final estado = _estado;
    final porcentajeProgreso = _porcentajeProgreso;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final bool progresoCambio =
        (_porcentajeProgresoOriginal != null && _porcentajeProgresoOriginal != porcentajeProgreso);

    final exito = esEdicion
        ? await ApiService.editarTarea(
            tareaId: widget.tareaExistente!['tarea_id'],
            titulo: titulo,
            descripcion: descripcion,
            fechaInicio: fechaInicio,
            fechaFin: fechaFin,
            estado: estado,
            porcentajeProgreso: porcentajeProgreso,
            motivo: progresoCambio ? _motivoController.text.trim() : '',
            usuarioId: widget.usuarioId,
          )
        : await ApiService.registrarTarea(
            proyectoId: widget.proyectoId,
            titulo: titulo,
            descripcion: descripcion,
            fechaInicio: fechaInicio,
            fechaFin: fechaFin,
            porcentajeProgreso: porcentajeProgreso,
            estado: estado,
          );

    Navigator.pop(context); 

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(exito
            ? esEdicion
                ? 'Tarea modificada correctamente'
                : 'Tarea registrada correctamente'
            : 'Error al guardar la tarea'),
      ),
    );

    if (exito) Navigator.pop(context);
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
                Text(
                  esEdicion ? 'Editar tarea' : 'Registrar tarea',
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
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title, color: Colors.cyan),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Por favor ingresa un título' : null,
              onSaved: (value) => _titulo = value!.trim(),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description, color: Colors.cyan),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 4,
              onSaved: (value) => _descripcion = value?.trim() ?? '',
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: () => _selectFechaInicio(context),
              child: AbsorbPointer(
                child: TextFormField(
                  controller: TextEditingController(
                      text: _fechaInicio == null ? '' : formatoMostrar.format(_fechaInicio!)),
                  decoration: const InputDecoration(
                    labelText: 'Fecha Inicio',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.date_range, color: Colors.cyan),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Por favor selecciona una fecha' : null,
                ),
              ),
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: _fechaInicio == null ? null : () => _selectFechaFin(context),
              child: AbsorbPointer(
                child: TextFormField(
                  controller: TextEditingController(
                      text: _fechaFin == null ? '' : formatoMostrar.format(_fechaFin!)),
                  decoration: const InputDecoration(
                    labelText: 'Fecha Fin',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.date_range, color: Colors.cyan),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Por favor selecciona una fecha' : null,
                ),
              ),
            ),

            if (esEdicion) ...[
              const SizedBox(height: 16),

              
              TextFormField(
                controller: _progresoController,
                decoration: const InputDecoration(
                  labelText: 'Porcentaje de progreso',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.percent, color: Colors.cyan),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final n = int.tryParse(value ?? '');
                  if (n == null || n < 0 || n > 100) {
                    return 'Ingresa un número entre 0 y 100';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              
              if (_mostrarMotivo)
                TextFormField(
                  controller: _motivoController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo del cambio de progreso',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note, color: Colors.cyan),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (_mostrarMotivo && (value == null || value.trim().isEmpty)) {
                      return 'Por favor ingresa un motivo';
                    }
                    return null;
                  },
                ),
            ],

            const SizedBox(height: 16),

            
            DropdownButtonFormField<String>(
              value: _estado,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.assignment, color: Colors.cyan),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _estados
                  .map((estado) => DropdownMenuItem(value: estado, child: Text(estado)))
                  .toList(),
              onChanged: (value) {
                if (value == 'completado' && _porcentajeProgreso < 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No puedes marcar como completado si el progreso es menor a 100%.',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                } else {
                  setState(() {
                    _estado = value!;
                    _estadoCambiadoManual = true;
                  });
                }
              },
            ),

            const SizedBox(height: 32),

            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(
                  esEdicion ? Icons.edit : Icons.save,
                  color: Colors.white,
                ),
                label: Text(
                  esEdicion ? 'Editar Tarea' : 'Registrar Tarea',
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

}
