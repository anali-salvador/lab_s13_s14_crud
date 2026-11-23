import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/tarea.dart';

// Formulario para crear o editar una tarea
class FormTareaScreen extends StatefulWidget {
  final Tarea? tarea; // si viene, es editar; si es null, es crear

  const FormTareaScreen({super.key, this.tarea});

  @override
  State<FormTareaScreen> createState() => _FormTareaScreenState();
}

class _FormTareaScreenState extends State<FormTareaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController(); // guarda la fecha dd/MM/yyyy

  bool get _esEdicion => widget.tarea != null;

  @override
  void initState() {
    super.initState();
    // Si es edición, llena los campos con los datos de la tarea
    if (_esEdicion) {
      _tituloCtrl.text = widget.tarea!.titulo;
      _descripcionCtrl.text = widget.tarea!.descripcion;
      _fechaCtrl.text = widget.tarea!.fecha;
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _fechaCtrl.dispose();
    super.dispose();
  }

  // Convierte DateTime a texto dd/MM/yyyy
  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  // Convierte texto dd/MM/yyyy a DateTime (o null si está vacío)
  DateTime? _leerFecha(String texto) {
    final partes = texto.split('/');
    if (partes.length != 3) return null;
    return DateTime(
      int.parse(partes[2]),
      int.parse(partes[1]),
      int.parse(partes[0]),
    );
  }

  // Abre el calendario para elegir la fecha
  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _leerFecha(_fechaCtrl.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('es'), // calendario en español
      helpText: 'Selecciona la fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (elegida != null) {
      setState(() => _fechaCtrl.text = _formatearFecha(elegida));
    }
  }

  // Valida y guarda la tarea en la BD
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final tarea = Tarea(
      id: widget.tarea?.id,
      titulo: _tituloCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      fecha: _fechaCtrl.text,
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
    return Scaffold(
      appBar: AppBar(title: Text(_esEdicion ? 'Editar tarea' : 'Nueva tarea')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Campo título (obligatorio)
            TextFormField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
              validator: (valor) {
                final texto = valor?.trim() ?? '';
                if (texto.isEmpty) return 'El título es obligatorio';
                if (texto.length < 3) return 'Escribe al menos 3 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Campo descripción (varias líneas)
            TextFormField(
              controller: _descripcionCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            // Campo fecha: solo lectura, se elige con el calendario
            TextFormField(
              controller: _fechaCtrl,
              readOnly: true,
              onTap: _elegirFecha,
              decoration: const InputDecoration(
                labelText: 'Fecha',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              validator: (valor) => (valor == null || valor.isEmpty)
                  ? 'La fecha es obligatoria'
                  : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _guardar,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
