# Lab S13-S14 · CRUD de tareas con SQLite (Flutter)

Aplicación móvil en Flutter para gestionar tareas usando una **base de datos local SQLite** (paquete `sqflite`).
No consume ninguna API: todos los datos se guardan en el celular. Se ejecuta en Android (celular o emulador).

## Funcionalidades

| Operación | Dónde |
|-----------|-------|
| **Create** – crear tarea (título, descripción, fecha límite) | `DBHelper.insertar()` |
| **Read** – listar tareas | `DBHelper.obtenerTodas()` |
| **Update** – editar tarea / marcar como completada | `DBHelper.actualizar()` |
| **Delete** – eliminar (botón o deslizando, con "Deshacer") | `DBHelper.eliminar()` / `DBHelper.restaurar()` |

Interfaz:

- Encabezado con saludo, contadores (total, pendientes, hechas), tareas vencidas y barra de progreso.
- Buscador por título o descripción.
- Filtros *Todas / Pendientes / Completadas* y orden por *más recientes*, *fecha límite* o *alfabético*.
- Fechas amigables ("Hoy", "Mañana", "En 3 días") y aviso de tareas **vencidas**.
- Validación del formulario (título obligatorio, fecha no anterior a hoy).
- Modo claro / oscuro.

## Estructura

```
lib/
├── main.dart                     # Punto de entrada y tema (Material 3)
├── database/db_helper.dart       # Conexión SQLite y operaciones CRUD
├── models/tarea.dart             # Modelo Tarea (toMap / fromMap)
├── screens/
│   ├── lista_tareas_screen.dart  # Pantalla principal (lista)
│   └── form_tarea_screen.dart    # Formulario crear / editar
├── utils/fechas.dart             # Ayudas para fechas dd/MM/yyyy
└── widgets/fondo_degradado.dart  # Fondo reutilizable
```

## Base de datos

- Archivo: `tareas.db`, en la carpeta de bases de datos de la app (`getDatabasesPath()` de sqflite).
- Tabla:

```sql
CREATE TABLE tareas (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  titulo TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  fecha TEXT NOT NULL,
  completada INTEGER NOT NULL DEFAULT 0
)
```

## Patrón de diseño

- **Singleton** en `DBHelper` (`static final DBHelper instance = DBHelper._();`): una sola instancia y una sola conexión a la base de datos en toda la app. La BD se abre la primera vez que se usa (*lazy initialization*).
- **Modelo** `Tarea` con `toMap()` / `fromMap()` para convertir entre objetos Dart y filas de SQLite.
- Separación por capas: modelo (`models`), acceso a datos (`database`) y presentación (`screens`, `widgets`).

## Cómo ejecutar

```bash
flutter pub get
flutter run        # con un celular Android conectado (depuración USB) o un emulador
```
