# SASU 2.6.0 - Seguimiento Clinico Integrado

## 1. Objetivo

Disenar el modulo oficial de Seguimiento Clinico Integrado para SASU 2.6.0, orientado a registrar, consultar y sincronizar pendientes clinicos o administrativos por paciente sin alterar el flujo existente de notas clinicas.

El modulo debe permitir que un profesional de salud cree seguimientos como:

- Revision de glucosa en 30 dias.
- Revision de anemia en 15 dias.
- Seguimiento nutricional.
- Seguimiento psicologico.
- Completar esquema de vacunacion.
- Verificar evolucion clinica.
- Gestion administrativa asociada al expediente.

Alcance de esta fase:

- Definir arquitectura.
- Definir modelo de datos local y remoto.
- Definir flujo offline first.
- Definir endpoints backend.
- Definir pantallas e indicadores.
- Definir plan de implementacion por commits.

Fuera de alcance en esta fase:

- No implementar codigo todavia.
- No tocar notas clinicas.
- No tocar sincronizacion actual de notas.
- No tocar Actividad Reciente.
- No tocar updater.
- No cambiar version ni instalador.

## 2. Arquitectura

### Estado actual del sistema

SASU usa una arquitectura hibrida:

- Flutter como cliente interno.
- Drift/SQLite local para operacion offline.
- `SyncService` para enviar registros pendientes.
- `ApiService` para comunicacion HTTP con `temp_backend`.
- FastAPI en `temp_backend`.
- Azure Cosmos DB como persistencia remota.

Tablas Drift actuales en `lib/data/db.dart`:

- `HealthRecords`
- `Notes`
- `Citas`
- `VacunacionesPendientes`

Version actual de schema Drift:

- `schemaVersion = 7`

El modulo de seguimientos debe agregarse como dominio nuevo, aislado de notas clinicas. La integracion debe ser aditiva:

- Nueva tabla local.
- Nuevos metodos de consulta/sync.
- Nuevos endpoints backend.
- Nuevo contenedor Cosmos.
- Nueva UI.

### Recomendacion arquitectonica

Implementar Seguimiento Clinico Integrado como modulo offline first con tabla Drift propia.

Justificacion:

- Un seguimiento es un pendiente operativo que puede registrarse durante una atencion aunque no haya internet.
- Debe sobrevivir reinicios de app.
- Debe sincronizarse con Cosmos cuando haya conexion.
- No debe depender de notas clinicas ni insertarse dentro de documentos de expediente.

### Componentes propuestos

Flutter:

- Tabla `SeguimientosClinicos` en Drift.
- Modelo/dto Dart para mapeo local/remoto.
- Servicio/repository de seguimientos.
- Metodos HTTP en `ApiService`.
- Integracion opcional en `SyncService`.
- Pantalla principal de seguimientos.
- Widget resumen en dashboard.
- Vista de seguimientos por paciente.

Backend:

- Modelo Pydantic `SeguimientoModel`.
- Helper Cosmos para contenedor de seguimientos.
- Endpoints REST para crear, listar, actualizar estado y sincronizar.
- Permisos por rol para leer/crear/actualizar seguimientos.

Cosmos:

- Contenedor nuevo recomendado: `seguimientos_clinicos`
- Partition key recomendada: `/campus`

## 3. Modelo de datos

### Campos requeridos por negocio

Campos del seguimiento:

- `id`
- `clientId`
- `pacienteId`
- `matricula`
- `nombrePaciente`
- `tipoSeguimiento`
- `motivo`
- `fechaCreacion`
- `fechaObjetivo`
- `prioridad`
- `estado`
- `responsable`
- `observaciones`
- `synced`
- `deleted`

### Campos obligatorios minimos

Para crear un seguimiento:

- `clientId`
- `matricula`
- `nombrePaciente`
- `tipoSeguimiento`
- `motivo`
- `fechaCreacionUtc`
- `fechaObjetivoUtc`
- `prioridad`
- `estado`
- `responsable`

Campos opcionales:

- `id`, si el backend no lo necesita generar.
- `pacienteId`, si se cuenta con ID de carnet/expediente.
- `observaciones`.
- `asignadoA`, si se agrega en una fase posterior.

### Valores permitidos

Prioridades:

- `baja`
- `media`
- `alta`
- `urgente`

Estados:

- `pendiente`
- `en_proceso`
- `completado`
- `cancelado`

Tipos:

- `medico`
- `psicologico`
- `nutricional`
- `vacunacion`
- `promocion`
- `administrativo`

Nota de normalizacion:

- Guardar valores sin acentos en base de datos y API.
- Mostrar etiquetas con acentos en UI cuando corresponda.

### Modelo Drift propuesto

Tabla: `seguimientos_clinicos`

Campos:

- `id`: integer autoIncrement local.
- `clientId`: text, unico logico local/remoto.
- `remoteId`: text nullable, opcional si backend devuelve un ID distinto.
- `pacienteId`: text nullable.
- `matricula`: text.
- `nombrePaciente`: text.
- `tipoSeguimiento`: text.
- `motivo`: text.
- `fechaCreacionUtc`: dateTime.
- `fechaObjetivoUtc`: dateTime.
- `prioridad`: text.
- `estado`: text.
- `responsable`: text.
- `observaciones`: text nullable.
- `campus`: text nullable.
- `createdBy`: text nullable.
- `updatedAtUtc`: dateTime nullable.
- `completedAtUtc`: dateTime nullable.
- `synced`: bool default false.
- `deleted`: bool default false.
- `syncError`: text nullable.

Indices recomendados en SQLite:

- `clientId` unico.
- `matricula`.
- `estado`.
- `fechaObjetivoUtc`.
- `prioridad`.
- compuesto: `estado, fechaObjetivoUtc`.
- compuesto: `matricula, estado, fechaObjetivoUtc`.

Drift permite definir indices con `customStatement` durante migracion si no se declaran directamente en la tabla.

### Modelo Cosmos propuesto

Contenedor: `seguimientos_clinicos`

Partition key recomendada: `/campus`

Documento:

```json
{
  "id": "seguimiento:<uuid>",
  "clientId": "seguimiento:<uuid>",
  "pacienteId": "carnet:<uuid>",
  "matricula": "15662",
  "nombrePaciente": "Nombre del paciente",
  "tipoSeguimiento": "medico",
  "motivo": "Revision de glucosa en 30 dias",
  "fechaCreacionUtc": "2026-06-16T02:30:00.000Z",
  "fechaObjetivoUtc": "2026-07-16T02:30:00.000Z",
  "prioridad": "media",
  "estado": "pendiente",
  "responsable": "Dr. Responsable",
  "observaciones": "",
  "campus": "cres-llano-largo",
  "createdBy": "usuario@campus",
  "updatedAtUtc": "2026-06-16T02:30:00.000Z",
  "completedAtUtc": null,
  "deleted": false,
  "schemaVersion": 1,
  "source": "sasu_flutter"
}
```

Indice/consulta Cosmos esperada:

- Por campus y estado.
- Por campus y fecha objetivo.
- Por matricula.
- Por responsable.
- Por prioridad.

Queries principales:

- Seguimientos pendientes del campus.
- Seguimientos vencidos del campus.
- Seguimientos del dia.
- Seguimientos por paciente/matricula.
- Seguimientos asignados al usuario actual.

## 4. Flujo SQLite <-> Cosmos

### Creacion offline first

1. Usuario selecciona paciente o captura matricula/nombre.
2. App genera `clientId` antes de guardar.
3. App guarda en SQLite con:
   - `synced = false`
   - `deleted = false`
   - `fechaCreacionUtc`
   - `fechaObjetivoUtc`
4. UI muestra el seguimiento inmediatamente.
5. Si hay conexion, intenta enviar a backend.
6. Si backend confirma, se marca `synced = true`.
7. Si falla, queda pendiente con `syncError`.

### Sincronizacion local a nube

El flujo debe integrarse de forma aditiva a `SyncService.syncAll()`:

- Obtener seguimientos con `synced = false`.
- Enviar a `POST /seguimientos`.
- Usar `clientId` como identidad estable.
- Si Cosmos ya tiene el `clientId`, backend debe hacer upsert idempotente.
- Marcar como sincronizado solo si hay respuesta 2xx.

### Sincronizacion nube a local

Para fase MVP se recomienda:

- Cargar desde backend al abrir pantalla principal.
- Filtrar por campus y/o matricula.
- Hacer merge local por `clientId`.
- Si existe local pendiente con mismo `clientId`, no duplicar.
- Si remoto tiene `updatedAtUtc` mas nuevo, actualizar local salvo que local tenga cambios pendientes.

### Eliminacion logica

No borrar fisicamente por defecto.

Usar:

- `deleted = true`
- `estado = cancelado` cuando sea cancelacion operativa.

La eliminacion visual puede ocultar registros cancelados/eliminados por defecto, pero deben seguir disponibles para auditoria si se requiere.

### Resolucion de conflictos

Regla recomendada:

1. `clientId` manda como identidad logica.
2. Si local y remoto tienen cambios:
   - comparar `updatedAtUtc`.
   - si local `synced = false`, conservar local y reintentar envio.
   - si ambos estan sincronizados, gana el `updatedAtUtc` mas reciente.
3. Cambios de estado deben preservar trazabilidad:
   - `pendiente` -> `en_proceso`
   - `en_proceso` -> `completado`
   - cualquier estado -> `cancelado`
4. Evitar que un remoto viejo regrese un seguimiento completado a pendiente.

Regla de seguridad:

- No sobrescribir `fechaCreacionUtc`.
- Usar `updatedAtUtc` para cambios posteriores.
- Usar `completedAtUtc` solo al completar.

## 5. Diseno UI

### Pantalla principal de seguimientos

Nombre propuesto:

- `Seguimiento Clinico`

Ruta/pantalla propuesta:

- `lib/screens/seguimientos/seguimientos_screen.dart`

Secciones:

- Encabezado con filtros rapidos.
- KPIs superiores.
- Lista de seguimientos.
- Panel lateral o modal para crear/editar seguimiento.

Filtros:

- Estado.
- Prioridad.
- Tipo.
- Vencidos.
- Hoy.
- Por responsable.
- Por matricula.

Acciones:

- Crear seguimiento.
- Ver detalle.
- Cambiar estado.
- Marcar en proceso.
- Completar.
- Cancelar.
- Sincronizar pendientes.

### Widget resumen en dashboard

Ubicacion:

- Dashboard principal, cerca de tarjetas de actividad clinica.

KPIs requeridos:

- Pendientes.
- Vencidos.
- Completados.
- Alta prioridad.

Indicadores:

- Badge rojo para vencidos.
- Badge amarillo/naranja para alta prioridad.
- Badge azul para pendientes del dia.

### Seguimientos por paciente

Integracion recomendada:

- Desde la busqueda de expediente se puede abrir una seccion "Seguimientos".
- Mostrar lista filtrada por `matricula`.
- Permitir crear seguimiento con datos del paciente precargados.

Importante:

- No mezclar el timeline de notas clinicas con seguimientos en esta fase.
- No alterar deduplicacion ni render de notas.

### Seguimientos del dia

Vista rapida:

- `fechaObjetivoUtc` dentro del dia local.
- Orden por prioridad y hora objetivo.
- Accion rapida para marcar `en_proceso` o `completado`.

### Detalle de seguimiento

Campos visibles:

- Paciente.
- Matricula.
- Tipo.
- Motivo.
- Fecha objetivo.
- Prioridad.
- Estado.
- Responsable.
- Observaciones.
- Estado de sincronizacion.

## 6. Riesgos

### Riesgo: migracion Drift

Agregar tabla nueva requiere subir a schema `8`.

Mitigacion:

- Migracion aditiva.
- No modificar tablas existentes.
- No tocar `notes`.
- No tocar columnas de fecha/hora clinica.
- Probar upgrade desde schema `7`.

### Riesgo: duplicados local/nube

Puede ocurrir si backend genera ID distinto y cliente tambien.

Mitigacion:

- Generar `clientId` en Flutter antes del primer guardado.
- Enviar `clientId` a backend.
- Backend debe usar `clientId` como llave idempotente o conservarlo y consultar por el.
- Deduplicar local por `clientId`.

### Riesgo: fechas vencidas por zona horaria

El seguimiento usa fechas objetivo, no hora clinica de atencion, pero aun asi debe evitar desfases.

Mitigacion:

- Guardar internamente `fechaCreacionUtc`, `fechaObjetivoUtc`, `updatedAtUtc`.
- Convertir a local solo en UI.
- Reutilizar una funcion central de conversion temporal o crear helper especifico sin tocar `ClinicalDateTime`.

### Riesgo: permisos

Si backend y Flutter no tienen permisos alineados, la UI podria mostrar acciones que backend rechaza.

Mitigacion:

- Agregar permisos en backend y Flutter en el mismo commit o commits consecutivos.
- Permisos propuestos:
  - `seguimientos:create`
  - `seguimientos:read`
  - `seguimientos:update`
  - `seguimientos:delete`

### Riesgo: contenedor Cosmos no existente

Si el contenedor no existe en produccion, endpoints fallaran.

Mitigacion:

- Usar variable de entorno `COSMOS_CONTAINER_SEGUIMIENTOS`.
- Documentar creacion del contenedor.
- Usar fallback controlado solo si el equipo lo aprueba.

### Riesgo: alcance excesivo

Seguimiento puede crecer hacia recordatorios, notificaciones y tickets.

Mitigacion:

- MVP sin notificaciones push.
- MVP sin chat.
- MVP sin calendario externo.
- MVP sin modificar notas clinicas.

## 7. Plan de implementacion

### Commit 1: Backend base de seguimientos

Objetivo:

- Agregar modelo Pydantic.
- Agregar contenedor/helper Cosmos.
- Agregar endpoints CRUD minimo.

Archivos:

- `temp_backend/main.py`
- `temp_backend/cosmos_helper.py` si se requiere helper especifico.
- `temp_backend/auth_models.py` si se agregan permisos.
- `.env.example` si se decide documentar `COSMOS_CONTAINER_SEGUIMIENTOS`.

Validacion:

- Crear seguimiento via API.
- Listar por campus.
- Listar por matricula.
- Actualizar estado.

### Commit 2: Modelo local Drift schema 8

Objetivo:

- Agregar tabla `SeguimientosClinicos`.
- Subir schema a `8`.
- Agregar migracion aditiva.
- Agregar metodos de consulta local.

Archivos:

- `lib/data/db.dart`
- `lib/data/db.g.dart`

Validacion:

- `flutter pub run build_runner build --delete-conflicting-outputs`
- Prueba de migracion desde schema `7`.
- Verificar que notas siguen intactas.

### Commit 3: API y repository Flutter

Objetivo:

- Agregar DTO/mapeo.
- Agregar metodos HTTP.
- Agregar repository local/remoto.

Archivos:

- `lib/data/api_service.dart`
- `lib/data/seguimiento_repository.dart`
- `lib/models/seguimiento_clinico.dart` si se decide separar modelo.

Validacion:

- Crear local.
- Enviar remoto.
- Merge por `clientId`.

### Commit 4: Sync offline first

Objetivo:

- Integrar seguimientos pendientes en `SyncService`.
- Extender `SyncResult` con contadores.

Archivos:

- `lib/data/sync_service.dart`
- `lib/data/db.dart`

Validacion:

- Crear seguimiento offline.
- Sincronizar.
- Confirmar que no duplica.
- Confirmar que notas no se sincronizan diferente.

### Commit 5: UI principal

Objetivo:

- Agregar pantalla principal de seguimientos.
- Agregar lista, filtros y formulario.

Archivos:

- `lib/screens/seguimientos/seguimientos_screen.dart`
- `lib/screens/seguimientos/seguimiento_form.dart`
- `lib/screens/seguimientos/seguimiento_detail.dart`

Validacion:

- Crear seguimiento.
- Filtrar por estado/prioridad.
- Cambiar estado.

### Commit 6: Dashboard e integracion por paciente

Objetivo:

- Agregar widget resumen.
- Agregar entrada en dashboard.
- Agregar acceso desde expediente por matricula si se aprueba.

Archivos:

- `lib/screens/dashboard_screen.dart`
- `lib/ui/widgets/seguimientos_summary_panel.dart`
- `lib/screens/nueva_nota_screen.dart` solo si se aprueba integracion por paciente.

Nota:

- Si se toca `nueva_nota_screen.dart`, debe limitarse a acceso visual a seguimientos por matricula.
- No modificar guardado, timeline ni sincronizacion de notas.

### Commit 7: Tests y cierre de fase

Objetivo:

- Cubrir mapeo, sync y reglas de estado.

Archivos:

- `test/data/seguimiento_repository_test.dart`
- `test/services/seguimientos_sync_test.dart`
- `test/models/seguimiento_clinico_test.dart`

Validacion:

- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- Tests especificos del modulo.

## 8. Lista exacta de archivos a modificar

### Backend

- `temp_backend/main.py`
- `temp_backend/auth_models.py`
- `temp_backend/cosmos_helper.py`
- `.env.example` si existe o se decide crear uno seguro.

### Flutter datos/sync

- `lib/data/db.dart`
- `lib/data/db.g.dart`
- `lib/data/api_service.dart`
- `lib/data/sync_service.dart`
- `lib/data/auth_service.dart`
- `lib/data/seguimiento_repository.dart` nuevo.
- `lib/models/seguimiento_clinico.dart` nuevo, opcional si se separa modelo.

### Flutter UI

- `lib/screens/seguimientos/seguimientos_screen.dart` nuevo.
- `lib/screens/seguimientos/seguimiento_form.dart` nuevo.
- `lib/screens/seguimientos/seguimiento_detail.dart` nuevo.
- `lib/ui/widgets/seguimientos_summary_panel.dart` nuevo.
- `lib/screens/dashboard_screen.dart`.
- `lib/screens/nueva_nota_screen.dart` solo si se aprueba acceso por paciente.

### Tests

- `test/models/seguimiento_clinico_test.dart` nuevo.
- `test/data/seguimiento_repository_test.dart` nuevo.
- `test/services/seguimientos_sync_test.dart` nuevo.

### Documentacion

- `docs/SASU_2_6_0_SEGUIMIENTOS.md`

## Recomendacion final

Iniciar implementacion por backend y contrato remoto, despues Drift local, despues sync, y finalmente UI.

Orden recomendado:

1. Backend minimo.
2. Tabla Drift schema `8`.
3. Repository/API Flutter.
4. Sync offline first.
5. UI principal.
6. Dashboard.
7. Tests y validacion.

La razon principal es que el seguimiento es un modulo institucional compartido entre usuarios y campus. Conviene fijar primero contrato, permisos y persistencia remota antes de construir una UI que pueda quedar desalineada con backend.
