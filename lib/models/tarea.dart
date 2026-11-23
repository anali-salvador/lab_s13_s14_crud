// Modelo que representa una tarea
class Tarea {
  final int? id; // null cuando aún no se guarda en la BD
  final String titulo;
  final String descripcion;
  final String fecha;
  final bool completada;

  Tarea({
    this.id,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    this.completada = false,
  });

  // Convierte la tarea a Map para guardarla en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha': fecha,
      'completada': completada ? 1 : 0, // SQLite no tiene bool
    };
  }

  // Crea una tarea a partir de un Map leído de SQLite
  factory Tarea.fromMap(Map<String, dynamic> map) {
    return Tarea(
      id: map['id'] as int?,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String,
      fecha: map['fecha'] as String,
      completada: map['completada'] == 1,
    );
  }
}
