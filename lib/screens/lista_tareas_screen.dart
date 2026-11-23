import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/tarea.dart';
import 'form_tarea_screen.dart';

// Pantalla principal que muestra la lista de tareas
class ListaTareasScreen extends StatefulWidget {
  const ListaTareasScreen({super.key});

  @override
  State<ListaTareasScreen> createState() => _ListaTareasScreenState();
}

class _ListaTareasScreenState extends State<ListaTareasScreen> {
  List<Tarea> _tareas = [];

  @override
  void initState() {
    super.initState();
    _cargarTareas(); // carga las tareas al abrir la pantalla
  }

  // Lee todas las tareas de la BD y refresca la pantalla
  Future<void> _cargarTareas() async {
    final tareas = await DBHelper.instance.obtenerTodas();
    setState(() => _tareas = tareas);
  }

  // Muestra un mensaje corto en la parte inferior
  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  // Marca o desmarca una tarea como completada
  Future<void> _cambiarCompletada(Tarea tarea, bool valor) async {
    final actualizada = Tarea(
      id: tarea.id,
      titulo: tarea.titulo,
      descripcion: tarea.descripcion,
      fecha: tarea.fecha,
      completada: valor,
    );
    await DBHelper.instance.actualizar(actualizada);
    await _cargarTareas();
  }

  // Abre el formulario (tarea == null es crear, si no es editar)
  Future<void> _abrirFormulario([Tarea? tarea]) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FormTareaScreen(tarea: tarea)),
    );
    await _cargarTareas(); // recarga al volver
    if (guardado == true && mounted) _mostrarMensaje('Tarea guardada');
  }

  // Pide confirmación y elimina la tarea
  Future<void> _eliminarTarea(Tarea tarea) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar esta tarea?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return; // canceló o cerró el diálogo
    await DBHelper.instance.eliminar(tarea.id!);
    await _cargarTareas();
    if (mounted) _mostrarMensaje('Tarea eliminada');
  }

  // Construye la Card de una tarea
  Widget _tarjetaTarea(Tarea tarea) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _abrirFormulario(tarea),
        leading: Checkbox(
          value: tarea.completada,
          onChanged: (valor) => _cambiarCompletada(tarea, valor!),
        ),
        title: Text(
          tarea.titulo,
          style: TextStyle(
            // tachado si está completada
            decoration: tarea.completada ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text('${tarea.descripcion}\n${tarea.fecha}'),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Eliminar',
          onPressed: () => _eliminarTarea(tarea),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cuenta cuántas tareas faltan completar
    final pendientes = _tareas.where((t) => !t.completada).length;
    // Singular o plural según la cantidad
    final textoPendientes = pendientes == 1 ? 'pendiente' : 'pendientes';
    final textoTareas = _tareas.length == 1 ? 'tarea' : 'tareas';

    return Scaffold(
      appBar: AppBar(title: const Text('Mis tareas')),
      body: _tareas.isEmpty
          ? const Center(child: Text('No hay tareas todavía'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contador de tareas
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    '$pendientes $textoPendientes de ${_tareas.length} $textoTareas',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                // Lista de tareas
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _tareas.length,
                    itemBuilder: (context, index) =>
                        _tarjetaTarea(_tareas[index]),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
