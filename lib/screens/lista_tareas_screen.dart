import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/tarea.dart';
import '../utils/fechas.dart';
import '../widgets/fondo_degradado.dart';
import 'form_tarea_screen.dart';

// Opciones de filtro (solo filtran en pantalla, no en la BD)
enum Filtro { todas, pendientes, completadas }

// Pantalla principal que muestra la lista de tareas
class ListaTareasScreen extends StatefulWidget {
  const ListaTareasScreen({super.key});

  @override
  State<ListaTareasScreen> createState() => _ListaTareasScreenState();
}

class _ListaTareasScreenState extends State<ListaTareasScreen> {
  List<Tarea> _tareas = [];
  bool _cargando = true;
  Filtro _filtro = Filtro.todas;

  @override
  void initState() {
    super.initState();
    _cargarTareas(); // carga las tareas al abrir la pantalla
  }

  // Lee todas las tareas de la BD y refresca la pantalla
  Future<void> _cargarTareas() async {
    final tareas = await DBHelper.instance.obtenerTodas();
    if (!mounted) return;
    setState(() {
      _tareas = tareas;
      _cargando = false;
    });
  }

  // Tareas que se muestran según el filtro elegido
  List<Tarea> get _tareasFiltradas {
    switch (_filtro) {
      case Filtro.pendientes:
        return _tareas.where((t) => !t.completada).toList();
      case Filtro.completadas:
        return _tareas.where((t) => t.completada).toList();
      case Filtro.todas:
        return _tareas;
    }
  }

  // true si la tarea sigue pendiente y su fecha ya pasó
  bool _estaVencida(Tarea tarea) {
    final fecha = leerFecha(tarea.fecha);
    return !tarea.completada && fecha != null && fecha.isBefore(hoy());
  }

  // Muestra un mensaje corto flotante
  void _mostrarMensaje(String texto, IconData icono) {
    final colores = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icono, color: colores.onInverseSurface),
              const SizedBox(width: 12),
              Text(texto),
            ],
          ),
        ),
      );
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
    if (guardado == true && mounted) {
      _mostrarMensaje('Tarea guardada', Icons.check_circle_outline);
    }
  }

  // Pide confirmación y elimina la tarea
  Future<void> _eliminarTarea(Tarea tarea) async {
    final colores = Theme.of(context).colorScheme;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.delete_outline, color: colores.error, size: 32),
        title: const Text('¿Eliminar esta tarea?'),
        content: Text(
          '"${tarea.titulo}" se borrará de forma permanente.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colores.error,
              foregroundColor: colores.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return; // canceló o cerró el diálogo
    await DBHelper.instance.eliminar(tarea.id!);
    await _cargarTareas();
    if (mounted) _mostrarMensaje('Tarea eliminada', Icons.delete_outline);
  }

  @override
  Widget build(BuildContext context) {
    return FondoDegradado(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _encabezado(),
              _filtros(),
              Expanded(child: _contenido()),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _abrirFormulario(),
          icon: const Icon(Icons.add),
          label: const Text('Nueva tarea'),
        ),
      ),
    );
  }

  // Encabezado con degradado, contador y barra de progreso
  Widget _encabezado() {
    final colores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    final total = _tareas.length;
    final pendientes = _tareas.where((t) => !t.completada).length;
    final progreso = total == 0 ? 0.0 : (total - pendientes) / total;

    // Singular o plural según la cantidad
    final textoPendientes = pendientes == 1 ? 'pendiente' : 'pendientes';
    final textoTareas = total == 1 ? 'tarea' : 'tareas';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colores.primary, colores.tertiary],
        ),
        boxShadow: [
          BoxShadow(
            color: colores.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mis tareas',
            style: textos.headlineMedium?.copyWith(
              color: colores.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            total == 0
                ? 'Organiza tu día'
                : '$pendientes $textoPendientes de $total $textoTareas',
            style: textos.bodyMedium?.copyWith(
              color: colores.onPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Barra de progreso animada
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progreso),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, valor, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: valor,
                      minHeight: 8,
                      color: colores.onPrimary,
                      backgroundColor: colores.onPrimary.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progreso * 100).round()}%',
                style: textos.titleMedium?.copyWith(
                  color: colores.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Chips para filtrar Todas / Pendientes / Completadas
  Widget _filtros() {
    const nombres = {
      Filtro.todas: 'Todas',
      Filtro.pendientes: 'Pendientes',
      Filtro.completadas: 'Completadas',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        children: [
          for (final filtro in Filtro.values)
            ChoiceChip(
              label: Text(nombres[filtro]!),
              selected: _filtro == filtro,
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (_) => setState(() => _filtro = filtro),
            ),
        ],
      ),
    );
  }

  // Lista de tarjetas, estado vacío o indicador de carga
  Widget _contenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    final tareas = _tareasFiltradas;

    // AnimatedSwitcher hace un fundido al cambiar de filtro
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: tareas.isEmpty
          ? _estadoVacio()
          : ListView.builder(
              key: ValueKey(_filtro),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: tareas.length,
              itemBuilder: (context, index) => _tarjetaTarea(tareas[index]),
            ),
    );
  }

  // Mensaje bonito cuando no hay tareas que mostrar
  Widget _estadoVacio() {
    final colores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final sinTareas = _tareas.isEmpty;

    return Center(
      key: ValueKey('vacio-$_filtro'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colores.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                sinTareas ? Icons.task_alt : Icons.filter_list_off,
                size: 48,
                color: colores.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              sinTareas ? 'No hay tareas todavía' : 'Nada por aquí',
              style: textos.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              sinTareas
                  ? 'Toca "Nueva tarea" para crear la primera.'
                  : 'No hay tareas en este filtro.',
              textAlign: TextAlign.center,
              style: textos.bodyMedium?.copyWith(
                color: colores.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tarjeta de una tarea
  Widget _tarjetaTarea(Tarea tarea) {
    final colores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final vencida = _estaVencida(tarea);

    // Color de la franja según el estado
    final colorEstado = tarea.completada
        ? Colors.green
        : vencida
            ? colores.error
            : colores.primary;

    // Aparece con un fundido y un pequeño deslizamiento
    return TweenAnimationBuilder<double>(
      key: ValueKey(tarea.id),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, valor, child) => Opacity(
        opacity: valor,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - valor)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colores.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => _abrirFormulario(tarea), // tocar la tarjeta edita
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Franja de color a la izquierda
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 6,
                    color: colorEstado,
                  ),
                  // Checkbox redondeado
                  Center(
                    child: Checkbox(
                      value: tarea.completada,
                      shape: const CircleBorder(),
                      onChanged: (valor) => _cambiarCompletada(tarea, valor!),
                    ),
                  ),
                  // Textos de la tarea
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Título tachado y atenuado si está completada
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: textos.titleMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: tarea.completada
                                  ? colores.onSurface.withValues(alpha: 0.45)
                                  : colores.onSurface,
                              decoration: tarea.completada
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                            child: Text(tarea.titulo),
                          ),
                          if (tarea.descripcion.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              tarea.descripcion,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textos.bodyMedium?.copyWith(
                                color: colores.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _chipFecha(tarea.fecha),
                              if (vencida) _chipVencida(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Botones editar y eliminar
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar',
                        color: colores.primary,
                        onPressed: () => _abrirFormulario(tarea),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Eliminar',
                        color: colores.error,
                        onPressed: () => _eliminarTarea(tarea),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Chip pequeño con ícono de calendario y la fecha
  Widget _chipFecha(String fecha) {
    final colores = Theme.of(context).colorScheme;
    return _chip(
      icono: Icons.calendar_today_outlined,
      texto: fecha,
      fondo: colores.secondaryContainer,
      color: colores.onSecondaryContainer,
    );
  }

  // Chip rojo "Vencida"
  Widget _chipVencida() {
    final colores = Theme.of(context).colorScheme;
    return _chip(
      icono: Icons.warning_amber_rounded,
      texto: 'Vencida',
      fondo: colores.errorContainer,
      color: colores.error,
    );
  }

  // Chip genérico (ícono + texto)
  Widget _chip({
    required IconData icono,
    required String texto,
    required Color fondo,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
