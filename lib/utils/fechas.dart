// Funciones de ayuda para fechas en formato dd/MM/yyyy

// Fecha de hoy sin hora (para comparar solo el día)
DateTime hoy() {
  final ahora = DateTime.now();
  return DateTime(ahora.year, ahora.month, ahora.day);
}

// Convierte DateTime a texto dd/MM/yyyy
String formatearFecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}

// Convierte texto dd/MM/yyyy a DateTime (null si no es válido)
DateTime? leerFecha(String texto) {
  final partes = texto.split('/');
  if (partes.length != 3) return null;
  final dia = int.tryParse(partes[0]);
  final mes = int.tryParse(partes[1]);
  final anio = int.tryParse(partes[2]);
  if (dia == null || mes == null || anio == null) return null;
  return DateTime(anio, mes, dia);
}
