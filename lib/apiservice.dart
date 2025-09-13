import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/project_screen.dart'; 
import '/servicionotificaciones/config.dart'; 
import '/screens/notificacionscreen.dart';
class ApiService {
  static final String baseUrl = Config.baseUrl;

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
 static Future<Map<String, dynamic>> registrarUsuario({
    required String nombre,
    required String email,
    required String telefono,
    required String contrasena,
  }) async {
    final url = Uri.parse('$baseUrl/registro');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'telefono': telefono,
        'contrasena': contrasena,
      }),
    );

    return {
      'status': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> editarUsuario({
  required int usuarioId,
  String? nombre,
  String? email,
  String? telefono,
  String? contrasena,
}) async {
  final url = Uri.parse('$baseUrl/usuario/editar');

  // Solo enviamos los campos que no sean null
  final Map<String, dynamic> data = {
    'usuario_id': usuarioId,
    if (nombre != null) 'nombre': nombre,
    if (email != null) 'email': email,
    if (telefono != null) 'telefono': telefono,
    if (contrasena != null) 'contrasena': contrasena,
  };

  final response = await http.put(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );

  return {
    'status': response.statusCode,
    'body': jsonDecode(response.body),
  };
}

  static Future<List<Proyecto>> fetchProyectos() async {
  final token = await _getToken();
  print('Token obtenido para proyectos: $token');
  if (token == null) throw Exception('Token no encontrado');

  final response = await http.get(
    Uri.parse('$baseUrl/proyectos'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  print('Status code: ${response.statusCode}');
  print('Response body: ${response.body}');

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Proyecto.fromJson(e)).toList();
  } else if (response.statusCode == 401) {
  final body = jsonDecode(response.body);
  if (body['message'] == 'Token expirado') {
    throw Exception('Token expirado');  
  } else {
    throw Exception('No autorizado');
  }
}
 else {
    throw Exception('Error al cargar proyectos: ${response.statusCode}');
  }
}
static Future<List<Map<String, dynamic>>> fetchTareasAsignadas() async {
  final token = await _getToken();
  if (token == null) throw Exception('Token no encontrado');

  final response = await http.get(
    Uri.parse('$baseUrl/tareas-asignadas'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    
    return List<Map<String, dynamic>>.from(data);
  } else if (response.statusCode == 401) {
    throw Exception('No autorizado: token inválido o expirado');
  } else {
    throw Exception('Error al cargar tareas asignadas: ${response.statusCode}');
  }
}

static Future<Map<String, dynamic>> fetchTareaPorId(int tareaId) async {
  final token = await _getToken(); 
  if (token == null) {
    throw Exception('Token no encontrado');
  }

  final response = await http.get(
    Uri.parse('$baseUrl/tarea/$tareaId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('No se pudo obtener la tarea. Código: ${response.statusCode}');
  }
}
static Future<List<Map<String, dynamic>>> fetchUsuariosEquipo(int proyectoId, String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/equipo_proyecto/$proyectoId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data);
  } else {
    throw Exception('Error al obtener usuarios del equipo');
  }
}

static Future<Map<String, dynamic>> asignarTarea({
  required int tareaId,
  required int usuarioId,
  required String fechaAsignacion,
  required String token,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/asignaciones'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'tarea_id': tareaId,
      'usuario_id': usuarioId,
      'fecha_asignacion': fechaAsignacion,
    }),
  );

  if (response.statusCode == 201) {
    return {'success': true};
  } else {
    try {
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['error'] ?? 'Error desconocido',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error inesperado: ${response.statusCode}',
      };
    }
  }
}

static Future<List<Map<String, dynamic>>> fetchTodasLasTareas() async {
  final token = await _getToken();
  if (token == null) throw Exception('Token no encontrado');

  final response = await http.get(
    Uri.parse('$baseUrl/todas-las-tareas'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data);
  } else {
    throw Exception('Error al cargar tareas: ${response.statusCode}');
  }
}


  static Future<bool> eliminarProyecto(int id) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('$baseUrl/proyectos/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

 static Future<List<Proyecto>> buscarProyectosPorNombre(String nombre) async {
  final token = await _getToken();
  if (token == null) throw Exception('Token no encontrado');

  final response = await http.get(
    Uri.parse('$baseUrl/proyectos/buscar?nombre=$nombre'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Proyecto.fromJson(e)).toList();
  } else {
    throw Exception('Error al buscar proyectos');
  }
}
static Future<bool> guardarProyecto({
  int? id,
  required String nombre,
  required String descripcion,
  required String fechaInicio,
  required String fechaFin,
  required int porcentaje,
}) async {
  final token = await _getToken();
  if (token == null) throw Exception('Token no encontrado');

  final url = id != null
      ? Uri.parse('$baseUrl/proyectos/$id')
      : Uri.parse('$baseUrl/proyectos');

  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  final body = jsonEncode({
    'nombre': nombre,
    'descripcion': descripcion,
    'fecha_inicio': fechaInicio,
    'fecha_fin': fechaFin,
    'porcentaje_progreso': porcentaje,
  });

  final response = id != null
      ? await http.put(url, headers: headers, body: body)
      : await http.post(url, headers: headers, body: body);

  return response.statusCode == 200 || response.statusCode == 201;
}
static Future<Map<String, dynamic>> login({
  required String email,
  required String password,
  required String fcmToken,
}) async {
  final url = Uri.parse('$baseUrl/login');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
      'fcm_token': fcmToken,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data['token'] != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token']);
  }

  return data;
}
static Future<Map<String, dynamic>?> fetchProyecto(int id) async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/proyectos/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar proyecto');
    }
  }
  static Future<List<dynamic>> fetchTareas(int proyectoId) async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/proyectos/$proyectoId/tareas'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar tareas');
    }
  }
  static Future<bool> asignarUsuarioAProyecto({
  required int proyectoId,
  required int usuarioId,
  required String rol,
}) async {
  final token = await _getToken();
  if (token == null) throw Exception('Token no encontrado');

  final url = Uri.parse('$baseUrl/equipo-proyecto');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'proyecto_id': proyectoId,
      'usuario_id': usuarioId,
      'rol_en_proyecto': rol,
    }),
  );

  if (response.statusCode == 201) {
    return true;
  } else {
    final body = jsonDecode(response.body);
    throw Exception('Error al asignar usuario: ${body["message"]}');
  }
}
static Future<List<Map<String, dynamic>>> obtenerProyectos() async {
  final token = await _getToken();
  final response = await http.get(
    Uri.parse('$baseUrl/proyectos'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  } else {
    throw Exception('Error al obtener proyectos');
  }
}

static Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
  final token = await _getToken();
  final response = await http.get(
    Uri.parse('$baseUrl/usuarios'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  } else {
    throw Exception('Error al obtener usuarios');
  }
}
static Future<List<Map<String, dynamic>>> obtenerEquipoDelProyecto(int proyectoId) async {
  final token = await _getToken();
  final response = await http.get(
    Uri.parse('$baseUrl/equipo-proyecto/$proyectoId'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  } else {
    throw Exception('Error al cargar equipo del proyecto');
  }
}
static Future<bool> eliminarTarea(int tareaId) async {
  final token = await _getToken(); // Usa tu método para obtener el token
  final response = await http.delete(
    Uri.parse('$baseUrl/tareas/$tareaId'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  
  if (response.statusCode == 200) {
    print("✅ Tarea eliminada correctamente");
    return true;
  } else {
    print("❌ Error al eliminar tarea: ${response.body}");
    return false;
  }
}

static Future<List<Notificacion>> fetchNotificaciones(int userId) async {
    final url = Uri.parse('$baseUrl/notificaciones-historial?user_id=$userId');

    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((n) => Notificacion.fromJson(n)).toList();
    } else {
      throw Exception('Error al cargar notificaciones');
    }
  }

  static Future<bool> responderSolicitud({
    required String solicitudId,
    required String decision,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final tokenAdmin = prefs.getString('token') ?? '';

    if (tokenAdmin.isEmpty) return false;

    final url = Uri.parse('$baseUrl/responder-solicitud/$solicitudId');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $tokenAdmin',
      },
      body: json.encode({'decision': decision}),
    );

    return response.statusCode == 200;
  }

 static Future<bool> registrarTarea({
    required int proyectoId,
    required String titulo,
    required String descripcion,
    required String fechaInicio,
    required String fechaFin,
    required int porcentajeProgreso,
    required String estado,
  }) async {
    final url = Uri.parse('$baseUrl/registrar-tareas');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'proyecto_id': proyectoId,
        'titulo': titulo,
        'descripcion': descripcion,
        'fecha_inicio': fechaInicio,
        'fecha_fin': fechaFin,
        'porcentaje_progreso': porcentajeProgreso,
        'estado': estado,
      }),
    );

    return response.statusCode == 201;
  }
static Future<List<Map<String, dynamic>>> fetchEstadisticasTareas() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token == null || token.isEmpty) {
    throw Exception('Token no disponible');
  }

  final url = Uri.parse('$baseUrl/proyectos/tareas/estadisticas');

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    List<dynamic> jsonData = jsonDecode(response.body);
    return jsonData.map((e) => Map<String, dynamic>.from(e)).toList();
  } else if (response.statusCode == 401) {
    throw Exception('No autorizado: verifica tu token');
  } else {
    throw Exception('Error al obtener estadísticas de tareas');
  }
}
static Future<bool> editarTarea({
  required int tareaId,
  required String titulo,
  required String descripcion,
  required String fechaInicio,
  required String fechaFin,
  required String estado,
  required int porcentajeProgreso,
  required int usuarioId,
  required String motivo,  // <-- agregado motivo
}) async {
  final url = Uri.parse('$baseUrl/modificar-tarea/$tareaId');

  final response = await http.put(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      'estado': estado,
      'porcentaje_progreso': porcentajeProgreso,
      'usuario_id': usuarioId,
      'motivo': motivo,  // <-- incluido motivo en el body
    }),
  );

  return response.statusCode == 200;
}
static Future<bool> eliminarAsignacion({
  required String miembroId,
  required int tareaId,
}) async {
  final token = await _getToken();
  final url = Uri.parse('$baseUrl/eliminar-asignacion-miembro');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'tarea_id': tareaId,
      'miembro_id': miembroId,
    }),
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    print('❌ Error al eliminar asignación: ${response.body}');
    return false;
  }
}
static Future<bool> eliminarMiembroProyecto({
  required int proyectoId,
  required int usuarioId,
}) async {
  final token = await _getToken();
  final url = Uri.parse('$baseUrl/equipo_proyecto/$proyectoId/usuario/$usuarioId');

  final response = await http.delete(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    print('❌ Error al eliminar miembro: ${response.body}');
    return false;
  }
}

}
