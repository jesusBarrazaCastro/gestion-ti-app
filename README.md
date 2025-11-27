# Gestión TI App

Aplicación para la **gestión de procesos de Tecnologías de la Información**, desarrollada con **Flutter** y utilizando **Supabase** como backend.  
Este proyecto centraliza módulos clave como gestión de configuraciones, gestión de cambios, administración de personas, elementos y otros recursos de TI dentro de una organización.

##  Tecnologías utilizadas

- **Flutter** (Frontend)
- **Dart**
- **Supabase** (Base de datos PostgreSQL + Auth + API)
- **Modal Progress HUD**
- **Widgets personalizados** (button, input, simple_table, pilltag)
- **Utilidades** como `msg_util.dart`, `dialog_util.dart`
- **AppTheme** para estilos globales

##  Estructura del proyecto

```text
gestion-ti-app/
└── gestion_ti_frontend/
    ├── lib/
    │   ├── app_theme.dart
    │   ├── utilities/
    │   │   ├── msg_util.dart
    │   │   └── dialog_util.dart
    │   ├── widgets/
    │   ├── screens/private/
    │   └── main.dart
```

##  Módulos principales

###  Gestión de Cambios
Permite:
- Registrar cambios (título, descripción, tipo, estado)
- Ver tabla de cambios registrados
- Guardar registros en Supabase

###  Configuración General
Incluye:
- Lectura de configuraciones desde Supabase
- Actualización de listas tipo catálogo
- Edición visual mediante `SimpleTable`

###  Gestión de Personas
Pantalla de detalle (`persona_detail.dart`) con información individual del personal.

##  Instalación

### 1 Clonar el repositorio
```bash
git clone https://github.com/jesusBarrazaCastro/gestion-ti-app.git
cd gestion-ti-app/gestion_ti_frontend
```

### 2 Instalar dependencias
```bash
flutter pub get
```

### 3 Configurar Supabase
En `main.dart`:

```dart
await Supabase.initialize(
  url: 'https://TU_URL.supabase.co',
  anonKey: 'TU_ANON_KEY',
);
```

### 4 Ejecutar la aplicación
```bash
flutter run
```

##  Tablas en Supabase (Ejemplo)

### `gestion_cambios`

| Campo          | Tipo        |
|----------------|-------------|
| id             | int (PK)    |
| titulo         | text        |
| descripcion    | text        |
| tipo           | text        |
| estado         | text        |
| fecha_registro | timestamptz |

### `configuracion_general`

| Campo    | Tipo     |
|----------|----------|
| modulo   | text     |
| elemento | text     |
| valores  | jsonb    |

##  Comandos útiles

```bash
flutter clean
flutter pub get
flutter analyze
```

##  Autores
- Proyecto académico desarrollado por estudiantes de TI.
- Repositorio oficial: **jesusBarrazaCastro/gestion-ti-app**
- Programadores: Jesus Barraza y Omar Bermejo.

