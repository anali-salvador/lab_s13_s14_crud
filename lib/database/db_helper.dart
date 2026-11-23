import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/tarea.dart';

// Clase que maneja la base de datos SQLite (patrón singleton)
class DBHelper {
  // Única instancia de la clase
  static final DBHelper instance = DBHelper._();
  DBHelper._();

  static Database? _database;

  // Devuelve la BD, la abre solo la primera vez
  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  // Abre (o crea) el archivo de la base de datos
  Future<Database> _initDB() async {
    final directorio = await getApplicationDocumentsDirectory();
    final ruta = join(directorio.path, 'tareas.db');
    return await openDatabase(ruta, version: 1, onCreate: _crearTabla);
  }

  // Crea la tabla "tareas" al crear la BD
  Future<void> _crearTabla(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tareas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        fecha TEXT NOT NULL,
        completada INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // CREATE: inserta una tarea y devuelve su id
  Future<int> insertar(Tarea tarea) async {
    final db = await database;
    final datos = tarea.toMap()..remove('id'); // el id lo genera SQLite
    return await db.insert('tareas', datos);
  }

  // READ: obtiene todas las tareas (pendientes primero, completadas al final)
  Future<List<Tarea>> obtenerTodas() async {
    final db = await database;
    final resultado =
        await db.query('tareas', orderBy: 'completada ASC, id DESC');
    return resultado.map((fila) => Tarea.fromMap(fila)).toList();
  }

  // UPDATE: actualiza una tarea según su id
  Future<int> actualizar(Tarea tarea) async {
    final db = await database;
    return await db.update(
      'tareas',
      tarea.toMap(),
      where: 'id = ?',
      whereArgs: [tarea.id],
    );
  }

  // DELETE: elimina una tarea según su id
  Future<int> eliminar(int id) async {
    final db = await database;
    return await db.delete('tareas', where: 'id = ?', whereArgs: [id]);
  }
}
