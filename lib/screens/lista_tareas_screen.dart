import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../main.dart' show temaApp;
import '../models/tarea.dart';
import '../utils/fechas.dart';
import '../widgets/fondo_degradado.dart';
import 'form_tarea_screen.dart';

// Opciones de filtro (solo filtran en pantalla, no en la BD)
enum Filtro { todas, pendientes, completadas }

// Formas de ordenar la lista
enum Orden { recientes, fechaLimite, alfabetico }

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
  Orden _orden = Orden.recientes;
  String _busqueda = ''; // texto del buscador
  final _buscadorCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarTareas(); // carga las tareas al abrir la pantalla
  }

  @override
  void dispose() {
    _buscadorCtrl.dispose();
    super.dispose();
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

  // Tareas que se muestran según filtro, búsqueda y orden elegidos
  List<Tarea> get _tareasFiltradas {
    // 1) Filtro por estado
    var lista = switch (_filtro) {
      Filtro.pendientes => _tareas.where((t) => !t.completada).toList(),
      Filtro.completadas => _tareas.where((t) => t.completada).toList(),
      Filtro.todas => List<Tarea>.of(_tareas),
    };

    // 2) Búsqueda por título o descripción (sin importar mayúsculas)
    final texto = _busqueda.trim().toLowerCase();
    if (texto.isNotEmpty) {
      lista = lista
          .where(
            (t) =>
                t.titulo.toLowerCase().contains(texto) ||
                t.descripcion.toLowerCase().contains(texto),
          )
          .toList();
    }

    // 3) Orden (las completadas siempre van al final)
    int porEstado(Tarea a, Tarea b) =>
        (a.completada ? 1 : 0) - (b.completada ? 1 : 0);
    switch (_orden) {
      case Orden.recientes:
        break; // ya viene ordenada así desde la BD
      case Orden.fechaLimite:
        lista.sort((a, b) {
          final estado = porEstado(a, b);
          if (estado != 0) return estado;
          final fa = leerFecha(a.fecha) ?? DateTime(9999);
          final fb = leerFecha(b.fecha) ?? DateTime(9999);
          return fa.compareTo(fb);
        });
      case Orden.alfabetico:
        lista.sort((a, b) {
          final estado = porEstado(a, b);
          if (estado != 0) return estado;
          return a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase());
        });
    }
    return lista;
  }

  // true si la tarea sigue pendiente y su fecha ya pasó
  bool _estaVencida(Tarea tarea) {
    final fecha = leerFecha(tarea.fecha);
    return !tarea.completada && fecha != null && fecha.isBefore(hoy());
  }

  // Muestra un mensaje corto flotante
  // (opcional) con un botón de acción, por ejemplo "Deshacer"
  void _mostrarMensaje(String texto, IconData icono, {SnackBarAction? accion}) {
    final colores = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          action: accion,
          duration: Duration(seconds: accion == null ? 2 : 4),
          content: Row(
            children: [
              Icon(icono, color: colores.onInverseSurface),
              const SizedBox(width: 12),
              Expanded(child: Text(texto)),
            ],
          ),
        ),
      );
  }

  // Elimina al deslizar la tarjeta y permite deshacer
  Future<void> _eliminarDeslizando(Tarea tarea) async {
    // Se quita primero de la lista para que la animación sea fluida
    setState(() => _tareas.removeWhere((t) => t.id == tarea.id));
    await DBHelper.instance.eliminar(tarea.id!);
    if (!mounted) return;
    _mostrarMensaje(
      'Tarea eliminada',
      Icons.delete_outline,
      accion: SnackBarAction(
        label: 'Deshacer',
        onPressed: () async {
          await DBHelper.instance.restaurar(tarea);
          await _cargarTareas();
        },
      ),
    );
  }

  // Saludo según la hora del día
  String get _saludo {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días';
    if (hora < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  // Alterna entre modo claro y oscuro
  void _cambiarTema() {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    temaApp.value = oscuro ? ThemeMode.light : ThemeMode.dark;
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
              _buscador(),
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
    final completadas = total - pendientes;
    final vencidas = _tareas.where(_estaVencida).length;
    final progreso = total == 0 ? 0.0 : completadas / total;
    final oscuro = Theme.of(context).brightness == Brightness.dark;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_saludo 👋',
                      style: textos.bodyMedium?.copyWith(
                        color: colores.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mis tareas',
                      style: textos.headlineMedium?.copyWith(
                        color: colores.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Botón para cambiar entre modo claro y oscuro
              IconButton.filledTonal(
                tooltip: oscuro ? 'Modo claro' : 'Modo oscuro',
                style: IconButton.styleFrom(
                  backgroundColor: colores.onPrimary.withValues(alpha: 0.18),
                  foregroundColor: colores.onPrimary,
                ),
                onPressed: _cambiarTema,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animacion) =>
                      RotationTransition(turns: animacion, child: child),
                  child: Icon(
                    oscuro ? Icons.light_mode : Icons.dark_mode,
                    key: ValueKey(oscuro),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tres contadores: total, pendientes y completadas
          Row(
            children: [
              _estadistica('$total', 'Total', Icons.list_alt),
              const SizedBox(width: 8),
              _estadistica('$pendientes', 'Pendientes', Icons.schedule),
              const SizedBox(width: 8),
              _estadistica('$completadas', 'Hechas', Icons.task_alt),
            ],
          ),
          if (vencidas > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: colores.onPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  vencidas == 1
                      ? '1 tarea vencida'
                      : '$vencidas tareas vencidas',
                  style: textos.bodySmall?.copyWith(
                    color: colores.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
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
                      backgroundColor: colores.onPrimary.withValues(
                        alpha: 0.25,
                      ),
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

  // Cajita con un número y su etiqueta (dentro del encabezado)
  Widget _estadistica(String numero, String etiqueta, IconData icono) {
    final colores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colores.onPrimary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 18, color: colores.onPrimary),
            const SizedBox(height: 6),
            Text(
              numero,
              style: textos.titleLarge?.copyWith(
                color: colores.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              etiqueta,
              style: textos.labelSmall?.copyWith(
                color: colores.onPrimary.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Campo para buscar tareas por título o descripción
  Widget _buscador() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _buscadorCtrl,
        textInputAction: TextInputAction.search,
        onChanged: (valor) => setState(() => _busqueda = valor),
        // Tocar fuera del buscador cierra el teclado
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          hintText: 'Buscar tareas...',
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          // Botón para limpiar la búsqueda
          suffixIcon: _busqueda.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Limpiar',
                  onPressed: () {
                    _buscadorCtrl.clear();
                    FocusScope.of(context).unfocus(); // cierra el teclado
                    setState(() => _busqueda = '');
                  },
                ),
        ),
      ),
    );
  }

  // Chips para filtrar Todas / Pendientes / Completadas + menú de orden
  Widget _filtros() {
    const nombres = {
      Filtro.todas: 'Todas',
      Filtro.pendientes: 'Pendientes',
      Filtro.completadas: 'Completadas',
    };
    const ordenes = {
      Orden.recientes: ('Más recientes', Icons.history),
      Orden.fechaLimite: ('Fecha límite', Icons.event),
      Orden.alfabetico: ('Alfabético (A-Z)', Icons.sort_by_alpha),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filtro in Filtro.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(nombres[filtro]!),
                        selected: _filtro == filtro,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (_) => setState(() => _filtro = filtro),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Menú para elegir el orden de la lista
          PopupMenuButton<Orden>(
            tooltip: 'Ordenar',
            icon: const Icon(Icons.swap_vert),
            initialValue: _orden,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (orden) => setState(() => _orden = orden),
            itemBuilder: (context) => [
              for (final entrada in ordenes.entries)
                PopupMenuItem(
                  value: entrada.key,
                  child: Row(
                    children: [
                      Icon(entrada.value.$2, size: 20),
                      const SizedBox(width: 12),
                      Text(entrada.value.$1),
                      if (entrada.key == _orden) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.check, size: 18),
                      ],
                    ],
                  ),
                ),
            ],
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
    final buscando = _busqueda.trim().isNotEmpty;

    // Ícono, título y texto según el motivo por el que está vacío
    final (IconData icono, String titulo, String detalle) = sinTareas
        ? (
            Icons.task_alt,
            'No hay tareas todavía',
            'Toca "Nueva tarea" para crear la primera.',
          )
        : buscando
        ? (
            Icons.search_off,
            'Sin resultados',
            'Ninguna tarea coincide con "${_busqueda.trim()}".',
          )
        : (
            Icons.filter_list_off,
            'Nada por aquí',
            'No hay tareas en este filtro.',
          );

    // SingleChildScrollView evita que se desborde cuando el teclado está abierto
    return SingleChildScrollView(
      key: ValueKey('vacio-$_filtro-$buscando'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colores.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icono, size: 48, color: colores.onPrimaryContainer),
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              style: textos.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              detalle,
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        // Deslizar a la izquierda elimina la tarea (con opción de deshacer)
        child: Dismissible(
          key: ValueKey('deslizar-${tarea.id}'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _eliminarDeslizando(tarea),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: colores.error,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Eliminar',
                  style: textos.titleSmall?.copyWith(
                    color: colores.onError,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.delete_sweep, color: colores.onError),
              ],
            ),
          ),
          child: _cuerpoTarjeta(tarea, colorEstado, vencida),
        ),
      ),
    );
  }

  // Contenido visual de la tarjeta (franja, checkbox, textos y botones)
  Widget _cuerpoTarjeta(Tarea tarea, Color colorEstado, bool vencida) {
    final colores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    return Container(
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
                            _chipFecha(tarea),
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
    );
  }

  // Chip con la fecha y, si está pendiente, cuánto falta ("Hoy", "Mañana"...)
  Widget _chipFecha(Tarea tarea) {
    final colores = Theme.of(context).colorScheme;
    final fecha = leerFecha(tarea.fecha);
    final relativa = (fecha == null || tarea.completada)
        ? null
        : fechaRelativa(fecha);
    return _chip(
      icono: Icons.calendar_today_outlined,
      texto: relativa == null ? tarea.fecha : '${tarea.fecha} · $relativa',
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
