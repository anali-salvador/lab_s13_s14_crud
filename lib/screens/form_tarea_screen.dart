import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/tarea.dart';
import '../utils/fechas.dart';
import '../widgets/fondo_degradado.dart';

// Formulario para crear o editar una tarea
class FormTareaScreen extends StatefulWidget {
  final Tarea? tarea; // si viene, es editar; si es null, es crear

  const FormTareaScreen({super.key, this.tarea});

  @override
  State<FormTareaScreen> createState() => _FormTareaScreenState();
}

class _FormTareaScreenState extends State<FormTareaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fechaKey = GlobalKey<FormFieldState<String>>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  String _fecha = ''; // fecha elegida en formato dd/MM/yyyy
  bool _guardando = false; // evita guardar dos veces

  bool get _esEdicion => widget.tarea != null;

  @override
  void initState() {
    super.initState();
    // Si es edición, llena los campos con los datos de la tarea
    if (_esEdicion) {
      _tituloCtrl.text = widget.tarea!.titulo;
      _descripcionCtrl.text = widget.tarea!.descripcion;
      _fecha = widget.tarea!.fecha;
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  // Valida el título: obligatorio y mínimo 3 caracteres
  String? _validarTitulo(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'El título es obligatorio';
    if (texto.length < 3) return 'Escribe al menos 3 caracteres';
    return null;
  }

  // Valida la fecha: obligatoria y no anterior a hoy
  String? _validarFecha() {
    final fecha = leerFecha(_fecha);
    if (fecha == null) return 'La fecha es obligatoria';

    // Al editar, se permite dejar la fecha original aunque ya pasó
    final sinCambios = _esEdicion && _fecha == widget.tarea!.fecha;
    if (fecha.isBefore(hoy()) && !sinCambios) {
      return 'La fecha no puede ser anterior a hoy';
    }
    return null;
  }

  // Abre el calendario para elegir la fecha (desde hoy en adelante)
  Future<void> _elegirFecha() async {
    final actual = leerFecha(_fecha);
    // initialDate nunca puede ser menor que firstDate (hoy)
    final inicial = (actual == null || actual.isBefore(hoy())) ? hoy() : actual;

    final elegida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: hoy(), // no deja elegir días pasados
      lastDate: DateTime(2100),
      locale: const Locale('es'), // calendario en español
      helpText: 'Selecciona la fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (elegida == null) return;

    setState(() => _fecha = formatearFecha(elegida));
    _fechaKey.currentState?.validate(); // quita el error si ya es válida
  }

  // Valida y guarda la tarea en la BD
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final tarea = Tarea(
      id: widget.tarea?.id,
      titulo: _tituloCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      fecha: _fecha,
      completada: widget.tarea?.completada ?? false,
    );

    if (_esEdicion) {
      await DBHelper.instance.actualizar(tarea);
    } else {
      await DBHelper.instance.insertar(tarea);
    }

    if (!mounted) return;
    Navigator.pop(context, true); // vuelve a la lista avisando que se guardó
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;

    return FondoDegradado(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            _esEdicion ? 'Editar tarea' : 'Nueva tarea',
            style: textos.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        body: Form(
          key: _formKey,
          // ListView permite hacer scroll cuando sale el teclado
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Text(
                _esEdicion
                    ? 'Actualiza los datos de tu tarea'
                    : 'Completa los datos de tu nueva tarea',
                style: textos.bodyLarge?.copyWith(
                  color: colores.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              // Campo título (obligatorio)
              TextFormField(
                controller: _tituloCtrl,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ej. Estudiar para el examen',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: _validarTitulo,
              ),
              const SizedBox(height: 16),
              // Campo descripción (varias líneas, opcional)
              TextFormField(
                controller: _descripcionCtrl,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Detalles de la tarea (opcional)',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.notes),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Campo fecha: tarjeta tocable que abre el calendario
              FormField<String>(
                key: _fechaKey,
                validator: (_) => _validarFecha(),
                builder: (campo) => _tarjetaFecha(campo.errorText),
              ),
              const SizedBox(height: 32),
              // Botón Guardar grande de ancho completo
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: textos.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tarjeta que muestra la fecha en grande y abre el calendario
  Widget _tarjetaFecha(String? error) {
    final textos = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;
    final tieneError = error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: colores.surfaceContainerHighest.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: tieneError
                ? BorderSide(color: colores.error)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _elegirFecha,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Ícono de calendario en un círculo
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colores.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.calendar_month,
                      color: colores.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fecha límite',
                          style: textos.labelMedium?.copyWith(
                            color: tieneError
                                ? colores.error
                                : colores.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _fecha.isEmpty ? 'Toca para elegir' : _fecha,
                          style: _fecha.isEmpty
                              ? textos.titleMedium?.copyWith(
                                  color: colores.onSurfaceVariant,
                                )
                              : textos.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colores.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
        // Mensaje de error debajo de la tarjeta
        if (tieneError)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              error,
              style: textos.bodySmall?.copyWith(color: colores.error),
            ),
          ),
      ],
    );
  }
}
