# Plan de Implementación: Campo `sedeOrigen`
## CRES Carnets UAGro — v2.4.34

**Fecha de análisis:** 26 de febrero de 2026  
**Elaborado con:** GitHub Copilot (Claude Sonnet 4.6)  
**Estado:** Pendiente de autorización — solo análisis

---

## 1. Objetivo

Agregar un campo `sedeOrigen` a los registros de **carnets** y **notas médicas**, de modo que cada
registro quede etiquetado con la institución que lo creó (ej. "Preparatoria 38", "CRES Llano Largo").
Esto permite al observatorio institucional generar estadísticas por sede.

---

## 2. Arquitectura del sistema (resumen)

| Capa | Tecnología | Archivo principal |
|---|---|---|
| App móvil/escritorio | Flutter 3 + Dart | `lib/` |
| Base de datos local | SQLite vía Drift ORM | `lib/data/db.dart` + `db.g.dart` |
| Servicio de autenticación | JWT + SharedPreferences | `lib/data/auth_service.dart` |
| Comunicación con backend | HTTP | `lib/data/api_service.dart` |
| Sincronización offline | Timer periódico | `lib/data/sync_service.dart` |
| Formulario de carnets | Flutter StatefulWidget | `lib/screens/form_screen.dart` |
| Formulario de notas | Flutter StatefulWidget | `lib/screens/nueva_nota_screen.dart` |
| Backend API | FastAPI en Render.com | `temp_backend/main.py` |
| Base de datos en nube | Azure Cosmos DB | Containers: `carnets`, `notas` |

---

## 3. Flujo de datos (con el campo nuevo)

```
Usuario selecciona escuela en el dropdown de la app
        ↓
[form_screen / nueva_nota_screen]  →  _sedeOrigen = "Preparatoria 38"
        ↓
HealthRecordsCompanion / NotesCompanion  →  sedeOrigen: Value(_sedeOrigen)
        ↓
SQLite local  ←  guardado inmediato (modo offline-first)
        ↓
ApiService.pushSingleCarnet / pushSingleNote  →  payload incluye sedeOrigen
        ↓
POST /carnets  o  POST /notas  →  FastAPI en Render.com
        ↓
CarnetModel / NotaModel  (Pydantic)  →  acepta sedeOrigen: Optional[str]
        ↓
Cosmos DB  →  documento guardado con campo sedeOrigen
```

### Flujo offline → resincronización

```
Sin internet  →  registro queda en SQLite con synced = false
        ↓
SyncService detecta conexión restaurada
        ↓
Lee note.sedeOrigen  →  lo pasa a pushSingleNote(sedeOrigen: ...)
        ↓
Render recibe y guarda en Cosmos DB
```

---

## 4. Archivos a modificar (22 puntos)

### 4.1 `lib/data/db.dart`
**Cambios: 4 puntos**

**a) Agregar columna en tabla `HealthRecords`** (después de `expedienteAdjuntos`):
```dart
BoolColumn get synced => boolean().withDefault(const Constant(false))();
TextColumn get sedeOrigen => text().nullable()(); // ← AGREGAR
```

**b) Agregar columna en tabla `Notes`** (después de `createdAt`):
```dart
BoolColumn get synced => boolean().withDefault(const Constant(false))();
TextColumn get sedeOrigen => text().nullable()(); // ← AGREGAR
```

**c) Subir `schemaVersion`:**
```dart
int get schemaVersion => 5;  // ← cambiar a 6
```

**d) Agregar bloque de migración** (después del bloque `if (from < 5)`):
```dart
if (from < 6) {
  await m.addColumn(healthRecords, healthRecords.sedeOrigen as GeneratedColumn);
  await m.addColumn(notes, notes.sedeOrigen as GeneratedColumn);
}
```

> ⚠️ Después de este cambio se debe ejecutar:
> ```
> flutter pub run build_runner build --delete-conflicting-outputs
> ```
> Esto regenera automáticamente `db.g.dart` (no se edita a mano).

---

### 4.2 `temp_backend/main.py`
**Cambios: 2 puntos**

**a) En `NotaModel`** (después de `createdAt`):
```python
createdAt: Optional[str] = None
sedeOrigen: Optional[str] = ""  # ← AGREGAR
```

**b) En `CarnetModel`** (después de `expedienteAdjuntos`):
```python
expedienteAdjuntos: Optional[str] = "[]"
sedeOrigen: Optional[str] = ""  # ← AGREGAR
```

---

### 4.3 `lib/data/auth_service.dart`
**Cambios: 1 punto**

Agregar después del cierre del método `formatCampusName()` una lista constante con todos los nombres
legibles de instituciones UAGro para alimentar los dropdowns de la UI:

```dart
static const List<String> kTodasLasInstituciones = [
  // Preparatorias (50)
  'Preparatoria 1', 'Preparatoria 2', ..., 'Preparatoria 50',
  // CRES (6)
  'CRES Cruz Grande', 'CRES Zumpango del Río', 'CRES Taxco el Viejo',
  'CRES Huamuxtitlán', 'CRES Llano Largo', 'CRES Tecpan de Galeana',
  // Clínicas Universitarias (4)
  'Clínica Universitaria Chilpancingo', 'Clínica Universitaria Acapulco',
  'Clínica Universitaria Iguala', 'Clínica Universitaria Ometepec',
  // Facultades (20)
  'Facultad de Ciencias Políticas y Gobierno', ...,
  // Rectoría y Coordinaciones (8)
  'Rectoría', 'Coordinación Regional Sur', ...
];
```

> Total en la lista: 88 instituciones UAGro.

---

### 4.4 `lib/data/api_service.dart`
**Cambios: 1 punto**

En el método `pushSingleNote(...)`, agregar parámetro y payload:

```dart
// Firma actual:
static Future<bool> pushSingleNote({
  required String matricula,
  required String departamento,
  required String cuerpo,
  required String tratante,
  String? idOverride,
  DateTime? createdAt,
  // ← AGREGAR:
  String? sedeOrigen,
}) async {
  ...
  final payload = {
    ...
    // ← AGREGAR:
    if (sedeOrigen != null && sedeOrigen.isNotEmpty) 'sedeOrigen': sedeOrigen,
  };
```

---

### 4.5 `lib/data/sync_service.dart`
**Cambios: 1 punto**

En el bucle de re-sincronización de notas pendientes:

```dart
final success = await ApiService.pushSingleNote(
  matricula: note.matricula,
  departamento: note.departamento,
  cuerpo: note.cuerpo,
  tratante: note.tratante ?? '',
  idOverride: 'nota_local_${note.id}',
  createdAt: note.createdAt,
  sedeOrigen: note.sedeOrigen,  // ← AGREGAR
);
```

---

### 4.6 `lib/screens/form_screen.dart`
**Cambios: 7 puntos**

**a) Variable de estado** (línea ~51, después de `String? _donante`):
```dart
String? _donante;
String? _sedeOrigen;  // ← AGREGAR
```

**b) `_cargarDatosExistentes()`** (línea ~156, al final de los dropdowns):
```dart
_donante = _normalizeDropdownValue(carnet['donante']?.toString(), kSiNo_Acento);
_sedeOrigen = carnet['sedeOrigen']?.toString();  // ← AGREGAR
```

**c) `_resetAll()`** (línea ~503):
```dart
_sexo = _categoria = _programa = _discapacidad =
    _tipoSangre = _unidadMedica = _usoSeguro = _donante = null;
_sedeOrigen = null;  // ← AGREGAR
```

**d) UI escritorio — sección "Datos Académicos"** (línea ~692, después del bloque Programa):
```dart
// Agregar al final del Column de la sección academicos (escritorio):
const SizedBox(height: 12),
DropdownButtonFormField<String>(
  value: _sedeOrigen,
  decoration: const InputDecoration(
    labelText: 'Sede de procedencia',
    border: OutlineInputBorder(),
  ),
  items: AuthService.kTodasLasInstituciones
      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
      .toList(),
  onChanged: (v) => setState(() => _sedeOrigen = v),
),
```

**e) UI móvil — sección "Datos Académicos"** (línea ~978, después del bloque twoCols Programa):
```dart
// Agregar después del último twoCols de la sección academicos (móvil):
const SizedBox(height: 12),
DropdownButtonFormField<String>(
  value: _sedeOrigen,
  decoration: const InputDecoration(
    labelText: 'Sede de procedencia',
    border: OutlineInputBorder(),
  ),
  items: AuthService.kTodasLasInstituciones
      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
      .toList(),
  onChanged: (v) => setState(() => _sedeOrigen = v),
),
```

**f) `HealthRecordsCompanion.insert(...)` ** (línea ~1190, después de `synced`):
```dart
synced: const Value(false),
sedeOrigen: Value(_sedeOrigen),  // ← AGREGAR
```

**g) `.write(HealthRecordsCompanion(...))` y `carnetData` map** (línea ~379 y ~413):
```dart
// En el write:
synced: const Value(false),
sedeOrigen: data.sedeOrigen,  // ← AGREGAR

// En carnetData:
'expedienteAdjuntos': data.expedienteAdjuntos.value,
'sedeOrigen': data.sedeOrigen.value,  // ← AGREGAR
```

> También agregar import al inicio del archivo:
> ```dart
> import '../data/auth_service.dart';
> ```

---

### 4.7 `lib/screens/nueva_nota_screen.dart`
**Cambios: 6 puntos**

**a) Variable de estado** (línea ~94, después de `String? _deptChoice`):
```dart
String? _deptChoice;
String? _sedeOrigen;  // ← AGREGAR
```

**b) UI — dropdown "Escuela de origen"** (línea ~2002, después del bloque `if (isOtra)`):
```dart
if (isOtra) ...[ TextField(controller: _depto, ...) ],
const SizedBox(height: 8),
// ← AGREGAR aquí:
DropdownButtonFormField<String>(
  value: _sedeOrigen,
  decoration: const InputDecoration(
    labelText: 'Escuela de origen',
    border: OutlineInputBorder(),
  ),
  items: AuthService.kTodasLasInstituciones
      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
      .toList(),
  onChanged: (v) => setState(() => _sedeOrigen = v),
),
const SizedBox(height: 8),
TextField(controller: _tratante, ...),
```

**c) `NotesCompanion.insert(...)` ** (línea ~690, después de `synced`):
```dart
synced: const Value(false),
sedeOrigen: Value(_sedeOrigen),  // ← AGREGAR
```

**d) `ApiService.pushSingleNote(...)` ** (línea ~701):
```dart
final ok = await ApiService.pushSingleNote(
  matricula: m,
  departamento: dep,
  cuerpo: cuerpoFinal,
  tratante: t,
  sedeOrigen: _sedeOrigen,  // ← AGREGAR
);
```

**e) Limpieza post-guardado** (línea ~781, bloque de limpieza):
```dart
_tipoConsulta = null;
_adjuntos.clear();
setState(() => _sedeOrigen = null);  // ← AGREGAR
```

**f) Visualización en lista de notas de la nube** (línea ~1495, subtitle del ExpansionTile):
```dart
// Agregar recuperación del campo:
final sede = (n['sedeOrigen'] ?? '').toString();

// En el subtitle Row, agregar chip o texto:
if (sede.isNotEmpty)
  Text(
    sede,
    style: TextStyle(fontSize: 11, color: cs.primary),
  ),
```

> También agregar import al inicio del archivo:
> ```dart
> import '../data/auth_service.dart';
> ```

---

## 5. Orden de ejecución recomendado

```
Paso 1 → temp_backend/main.py          (2 cambios — sin dependencias)
Paso 2 → lib/data/auth_service.dart    (1 cambio — sin dependencias)
Paso 3 → lib/data/api_service.dart     (1 cambio — sin dependencias)
Paso 4 → lib/data/sync_service.dart    (1 cambio — depende del paso 3)
Paso 5 → lib/data/db.dart              (4 cambios — base del esquema)
Paso 6 → build_runner                  (regenera db.g.dart automáticamente)
Paso 7 → lib/screens/form_screen.dart  (7 cambios — depende de pasos 2, 5, 6)
Paso 8 → lib/screens/nueva_nota_screen.dart (6 cambios — depende de pasos 2, 3, 5, 6)
```

---

## 6. Comando crítico (Paso 6)

Después de modificar `db.dart`, ejecutar en la raíz del proyecto:

```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

Esto regenera `lib/data/db.g.dart` automáticamente. **No editar `db.g.dart` a mano.**

---

## 7. Verificación post-implementación

- [ ] La app compila sin errores (`flutter build`)
- [ ] Al crear un carnet nuevo, el dropdown "Sede de procedencia" aparece en la sección Académicos
- [ ] Al crear una nota, el dropdown "Escuela de origen" aparece antes del campo Tratante
- [ ] Al guardar una nota, el campo `sedeOrigen` llega al backend (revisar logs `[SYNC]`)
- [ ] En Cosmos DB, el documento de la nota tiene el campo `sedeOrigen`
- [ ] En Swagger de Render (`/docs`), el modelo `NotaModel` muestra `sedeOrigen`
- [ ] Al cargar un carnet existente para edición, el dropdown muestra el valor guardado
- [ ] Al limpiar el formulario de notas, `sedeOrigen` vuelve a `null`
- [ ] La lista de notas en la nube muestra la escuela de origen en el subtítulo

---

## 8. Modelo de IA recomendado para implementación

Para aplicar estos 22 cambios con asistencia de IA se recomienda:

### GitHub Copilot con Claude Sonnet 4.6
- **En qué ayuda:** Aplica cambios en múltiples archivos simultáneamente con la herramienta
  `multi_replace_string_in_file`, sin riesgo de errores de indentación o contexto
- **Cómo usarlo:** Abrir el proyecto en VS Code con GitHub Copilot activo, compartir este
  documento como contexto y dar la instrucción: *"Autorizo aplicar el plan PLAN_SEDE_ORIGEN_v1.md"*
- **Ventaja clave:** Conoce el código existente del proyecto y puede hacer todos los cambios
  en una sola sesión sin perder el hilo

### Alternativa: Claude Sonnet 4.5 o Claude Opus 4
- Capacidad similar para modificaciones multi-archivo
- Útil si se trabaja desde claude.ai directamente pegando los archivos como contexto

### Para el backend (Python/FastAPI)
- Los 2 cambios en `main.py` son triviales y pueden hacerse manualmente en 2 minutos
- No requieren regeneración ni build

---

## 9. Notas importantes

1. **No rompe datos existentes:** La migración `if (from < 6)` agrega las columnas a bases
   de datos ya instaladas. Los registros anteriores tendrán `sedeOrigen = null`, lo cual es válido.

2. **No es obligatorio:** El campo es opcional. Los usuarios pueden guardar sin seleccionar sede.

3. **Los nombres se guardan como texto legible** ("Preparatoria 38"), no como clave interna
   ('prep-38'). Esto simplifica las consultas y la visualización.

4. **El backend de Render no requiere redeploy manual:** Al hacer `git push` con los cambios
   de `main.py`, Render redespliega automáticamente.

5. **Fase futura — estadísticas:** Los endpoints de consulta por `sedeOrigen` (para el
   observatorio) son una segunda fase y no bloquean esta implementación.
