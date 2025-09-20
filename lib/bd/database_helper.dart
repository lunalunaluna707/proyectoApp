import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'koalgenda.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        usuario_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        telefono TEXT,
        contraseña TEXT NOT NULL,
        rol TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE proyectos (
        proyecto_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        fecha_inicio TEXT,
        fecha_fin TEXT,
        porcentaje_progreso INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE tareas (
        tarea_id INTEGER PRIMARY KEY AUTOINCREMENT,
        proyecto_id INTEGER,
        titulo TEXT NOT NULL,
        descripcion TEXT,
        fecha_inicio TEXT,
        fecha_fin TEXT,
        porcentaje_progreso INTEGER DEFAULT 0,
        estado TEXT DEFAULT 'pendiente',
        FOREIGN KEY (proyecto_id) REFERENCES proyectos (proyecto_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE asignaciones (
        asignacion_id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarea_id INTEGER,
        usuario_id INTEGER,
        fecha_asignacion TEXT,
        FOREIGN KEY (tarea_id) REFERENCES tareas (tarea_id) ON DELETE CASCADE,
        FOREIGN KEY (usuario_id) REFERENCES usuarios (usuario_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE avance_historial (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarea_id INTEGER NOT NULL,
        porcentaje INTEGER NOT NULL CHECK (porcentaje BETWEEN 0 AND 100),
        motivo TEXT NOT NULL,
        fecha_registro TEXT NOT NULL,
        usuario_id INTEGER NOT NULL,
        FOREIGN KEY (tarea_id) REFERENCES tareas (tarea_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE equipo_proyecto (
        equipo_id INTEGER PRIMARY KEY AUTOINCREMENT,
        proyecto_id INTEGER,
        usuario_id INTEGER,
        rol_en_proyecto TEXT,
        FOREIGN KEY (proyecto_id) REFERENCES proyectos (proyecto_id) ON DELETE CASCADE,
        FOREIGN KEY (usuario_id) REFERENCES usuarios (usuario_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE notificaciones_historial (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proyecto_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        solicitado_por INTEGER NOT NULL,
        titulo TEXT NOT NULL,
        cuerpo TEXT NOT NULL,
        fecha TEXT NOT NULL,
        leido INTEGER NOT NULL DEFAULT 0,
        tipo_accion TEXT,
        tabla_afectada TEXT,
        registro_id INTEGER,
        estado TEXT NOT NULL DEFAULT 'pendiente',
        fecha_respuesta TEXT,
        procesada_por INTEGER,
        solicitud_id TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tokens_fcm (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        fcm_token TEXT NOT NULL,
        last_login TEXT NOT NULL
      )
    ''');
  }

  // ===============================
  // === CRUD GENERICO PARA USUARIOS
  // ===============================

  Future<int?> insertarUsuario(Map<String, dynamic> usuario) async {
    try {
      final db = await database;
      return await db.insert('usuarios', usuario, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('Error insertando usuario: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    try {
      final db = await database;
      return await db.query('usuarios');
    } catch (e) {
      print('Error obteniendo usuarios: $e');
      return [];
    }
  }

  Future<int?> actualizarUsuario(int id, Map<String, dynamic> usuario) async {
    try {
      final db = await database;
      return await db.update('usuarios', usuario, where: 'usuario_id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error actualizando usuario: $e');
      return null;
    }
  }

  Future<int?> eliminarUsuario(int id) async {
    try {
      final db = await database;
      return await db.delete('usuarios', where: 'usuario_id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error eliminando usuario: $e');
      return null;
    }
  }

  // ===============================
  // === CRUD PARA PROYECTOS
  // ===============================

  Future<int?> insertarProyecto(Map<String, dynamic> proyecto) async {
    try {
      final db = await database;
      return await db.insert('proyectos', proyecto, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('Error insertando proyecto: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerProyectos() async {
    try {
      final db = await database;
      return await db.query('proyectos');
    } catch (e) {
      print('Error obteniendo proyectos: $e');
      return [];
    }
  }

  Future<int?> actualizarProyecto(int id, Map<String, dynamic> proyecto) async {
    try {
      final db = await database;
      return await db.update('proyectos', proyecto, where: 'proyecto_id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error actualizando proyecto: $e');
      return null;
    }
  }

  Future<int?> eliminarProyecto(int id) async {
    try {
      final db = await database;
      return await db.delete('proyectos', where: 'proyecto_id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error eliminando proyecto: $e');
      return null;
    }
  }

  // ===============================
  // === CRUD PARA TAREAS
  // ===============================

  Future<int?> insertarTarea(Map<String, dynamic> tarea) async {
    try {
      final db = await database;
      return await db.insert('tareas', tarea, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('Error insertando tarea: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerTareas() async {
    try {
      final db = await database;
      return await db.query('tareas');
    } catch (e) {
      print('Error obteniendo tareas: $e');
      return [];
    }
  }

  Future<int?> actualizarTarea(int id, Map<String, dynamic> tarea) async {
    try {
      final db = await database;
      return await db.update('tareas', tarea, where: 'tarea_id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error actualizando tarea: $e');
      return null;
    }
  }

  Future<int?> eliminarTarea(int id) async {
    try {
      final db = await database;
      return await db.delete('tareas', where: 'tarea_id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error eliminando tarea: $e');
      return null;
    }
  }

// ===============================
// === CRUD PARA ASIGNACIONES
// ===============================

Future<int?> insertarAsignacion(Map<String, dynamic> asignacion) async {
  try {
    final db = await database;
    return await db.insert('asignaciones', asignacion, conflictAlgorithm: ConflictAlgorithm.replace);
  } catch (e) {
    print('Error insertando asignación: $e');
    return null;
  }
}

Future<List<Map<String, dynamic>>> obtenerAsignaciones() async {
  try {
    final db = await database;
    return await db.query('asignaciones');
  } catch (e) {
    print('Error obteniendo asignaciones: $e');
    return [];
  }
}

Future<int?> actualizarAsignacion(int id, Map<String, dynamic> asignacion) async {
  try {
    final db = await database;
    return await db.update('asignaciones', asignacion, where: 'asignacion_id = ?', whereArgs: [id]);
  } catch (e) {
    print('Error actualizando asignación: $e');
    return null;
  }
}

Future<int?> eliminarAsignacion(int id) async {
  try {
    final db = await database;
    return await db.delete('asignaciones', where: 'asignacion_id = ?', whereArgs: [id]);
  } catch (e) {
    print('Error eliminando asignación: $e');
    return null;
  }
}

// ===============================
// === CRUD PARA AVANCE_HISTORIAL
// ===============================

Future<int?> insertarAvance(Map<String, dynamic> avance) async {
  try {
    final db = await database;
    return await db.insert('avance_historial', avance, conflictAlgorithm: ConflictAlgorithm.replace);
  } catch (e) {
    print('Error insertando avance: $e');
    return null;
  }
}

Future<List<Map<String, dynamic>>> obtenerAvances() async {
  try {
    final db = await database;
    return await db.query('avance_historial');
  } catch (e) {
    print('Error obteniendo avances: $e');
    return [];
  }
}

Future<int?> actualizarAvance(int id, Map<String, dynamic> avance) async {
  try {
    final db = await database;
    return await db.update('avance_historial', avance, where: 'id = ?', whereArgs: [id]);
  } catch (e) {
    print('Error actualizando avance: $e');
    return null;
  }
}

Future<int?> eliminarAvance(int id) async {
  try {
    final db = await database;
    return await db.delete('avance_historial', where: 'id = ?', whereArgs: [id]);
  } catch (e) {
    print('Error eliminando avance: $e');
    return null;
  }
}

// ===============================
// === CRUD PARA EQUIPO_PROYECTO
// ===============================

Future<int?> insertarEquipo(Map<String, dynamic> equipo) async {
  try {
    final db = await database;
    return await db.insert('equipo_proyecto', equipo, conflictAlgorithm: ConflictAlgorithm.replace);
  } catch (e) {
    print('Error insertando equipo: $e');
    return null;
  }
}

Future<List<Map<String, dynamic>>> obtenerEquipo() async {
  try {
    final db = await database;
    return await db.query('equipo_proyecto');
  } catch (e) {
    print('Error obteniendo equipo: $e');
    return [];
  }
}

Future<int?> actualizarEquipo(int id, Map<String, dynamic> equipo) async {
  try {
    final db = await database;
    return await db.update('equipo_proyecto', equipo, where: 'equipo_id = ?', whereArgs: [id]);
  } catch (e) {
    print('Error actualizando equipo: $e');
    return null;
  }
}

Future<int?> eliminarEquipo(int id) async {
  try {
    final db = await database;
    return await db.delete('equipo_proyecto', where: 'equipo_id = ?', whereArgs: [id]);
  } catch (e) {
    print('Error eliminando equipo: $e');
    return null;
  }
}

// ===============================
// === CRUD PARA NOTIFICACIONES_HISTORIAL
// ===============================

Future<int?> insertarNotificacion(Map<String, dynamic> notificacion) async {
  try {
    final db = await database;
    return await db.insert('notificaciones_historial', notificacion, conflictAlgorithm: ConflictAlgorithm.replace);
  } catch (e) {
    print('Error insertando notificación: $e');
    return null;
  }
}

Future<List<Map<String, dynamic>>> obtenerNotificaciones() async {
  try {
    final db = await database;
    return await db.query('notificaciones_historial');
  } catch (e) {
    print('Error obteniendo notificaciones: $e');
    return [];
  }
}

Future<int?> actualizarNotificacion(int id, Map<String, dynamic> notificacion) async {
  try {
    final db = await database;
    return await db.update('notificaciones_historial', notificacion, where: 'id = ?', whereArgs: [id]);
  } catch (e) {
    print('Error actualizando notificación: $e');
    return null;
  }
}

Future<int?> eliminarNotificacion(int id) async {
  try {
    final db = await database;
    return await db.delete('notificaciones_historial', where: 'id = ?', whereArgs: [id]);
  } catch (e) {
    print('Error eliminando notificación: $e');
    return null;
  }
}

// ===============================
// === CRUD PARA TOKENS_FCM
// ===============================

Future<int?> insertarToken(Map<String, dynamic> token) async {
  try {
    final db = await database;
    return await db.insert('tokens_fcm', token, conflictAlgorithm: ConflictAlgorithm.replace);
  } catch (e) {
    print('Error insertando token: $e');
    return null;
  }
}

Future<List<Map<String, dynamic>>> obtenerTokens() async {
  try {
    final db = await database;
    return await db.query('tokens_fcm');
  } catch (e) {
    print('Error obteniendo tokens: $e');
    return [];
  }
}

Future<int?> actualizarToken(int id, Map<String, dynamic> token) async {
  try {
    final db = await database;
    return await db.update('tokens_fcm', token, where: 'id = ?', whereArgs: [id]);
  } catch (e) {
    print('Error actualizando token: $e');
    return null;
  }
}

Future<int?> eliminarToken(int id) async {
  try {
    final db = await database;
    return await db.delete('tokens_fcm', where: 'id = ?', whereArgs: [id]);
  } catch (e) {
    print('Error eliminando token: $e');
    return null;
  }
}
}
