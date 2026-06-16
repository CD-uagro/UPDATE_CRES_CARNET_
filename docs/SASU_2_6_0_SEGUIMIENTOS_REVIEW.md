# SASU 2.6.0 - Revision final de arquitectura de seguimientos

## Resumen ejecutivo

El documento `docs/SASU_2_6_0_SEGUIMIENTOS.md` propone una arquitectura viable y compatible con SASU actual: modulo independiente, tabla Drift nueva, contenedor Cosmos propio, sincronizacion offline first y UI separada del timeline de notas clinicas.

La recomendacion final es mantener el seguimiento como entidad independiente del expediente y de la nota clinica, pero permitir vinculos opcionales a paciente y a nota de origen. Esto reduce riesgo legal y tecnico: una nota clinica conserva su integridad, y el seguimiento funciona como tarea operativa clinica.

Decision recomendada para MVP 2.6.0:

- Seguimiento independiente.
- Tabla Drift nueva en schema `8`.
- Cosmos container propio.
- `clientId` como ID logico compartido local/remoto.
- Sin chat, sin notificaciones push, sin recurrencias y sin integracion profunda con notas.

## 1. Observaciones al modelo de datos

### Suficiencia del modelo propuesto

El modelo propuesto es suficiente para un MVP funcional:

- Identifica al paciente por `matricula` y `pacienteId`.
- Permite clasificacion clinica por `tipoSeguimiento`.
- Permite gestion operativa con `prioridad`, `estado`, `responsable` y `fechaObjetivo`.
- Soporta offline first mediante `clientId`, `synced` y `deleted`.

Sin embargo, para evitar ambiguedades de sync y auditoria, conviene ajustar algunos campos antes de implementar.

### Campos que deben quedar obligatorios

Campos obligatorios recomendados:

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
- `campus`
- `createdBy`
- `updatedAtUtc`
- `synced`
- `deleted`

Razon:

- `campus` es indispensable para filtrar, permisos y particion en Cosmos.
- `createdBy` permite auditoria minima.
- `updatedAtUtc` es necesario para resolver conflictos.

### Campos faltantes recomendados

Agregar estos campos al diseno final:

- `updatedBy`: ultimo usuario que modifico el seguimiento.
- `lastSyncAttemptUtc`: diagnostico local de sincronizacion.
- `syncError`: error local de ultimo intento.
- `completedAtUtc`: fecha real de cierre/completado.
- `cancelledAtUtc`: fecha real de cancelacion.
- `cancelReason`: motivo de cancelacion cuando aplique.
- `source`: origen del registro, por ejemplo `sasu_flutter`.
- `schemaVersion`: version del documento remoto.
- `originNoteClientId`: opcional, para vincular el seguimiento a una nota clinica sin depender de ella.
- `originModule`: opcional, valores como `nota`, `vacunacion`, `promocion`, `manual`.

Campos que pueden esperar a 2.7:

- `assignedToUserId`
- `assignedToRole`
- `assignedDepartment`
- `reminderAtUtc`
- `recurrenceRule`
- `attachments`
- `history`

### Campos innecesarios o riesgosos para MVP

- `remoteId`: no es necesario si el backend acepta `clientId` como `id` remoto. Mantener ambos puede reabrir el riesgo de duplicados local/nube. Solo usar `remoteId` si Cosmos exige otro ID, que no parece necesario.
- `pacienteId`: util, pero no debe ser obligatorio porque no todos los flujos garantizan tener `carnet:<uuid>` cargado. La `matricula` debe ser el identificador funcional minimo.
- `responsable`: es necesario, pero es ambiguo si guarda nombre visible. Para MVP puede ser texto; futuro debe migrar a `responsableUserId` o `responsableUsername`.
- `fechaCreacion` sin sufijo `Utc`: debe evitarse. Usar siempre `fechaCreacionUtc`.

## 2. Arquitectura final recomendada

### Entidad principal

Nombre tecnico:

- Drift: `SeguimientosClinicos`
- SQLite: `seguimientos_clinicos`
- Cosmos: `seguimientos_clinicos`
- API: `/seguimientos`

### Identidad

Regla final:

- Flutter genera `clientId`.
- Backend usa `clientId` como `id` remoto o como llave idempotente.
- Recomendacion fuerte: `id = clientId` en Cosmos.

Formato:

- `seguimiento:<uuid>`

Beneficio:

- Evita doble identidad.
- Simplifica merge.
- Evita el error historico de duplicacion local/nube visto en notas.

### Partition key Cosmos

Recomendacion para MVP:

- `/campus`

Justificacion:

- La operacion diaria sera por campus.
- Permite dashboards por sede sin cross-partition en la mayoria de los casos.
- Es comprensible y auditable.

Riesgo:

- Reportes de toda la UAGro requeriran consultas cross-partition.

Alternativa futura:

- Container analitico separado o materializacion de KPIs por campus para reportes globales.

### Permisos

Permisos recomendados:

- `seguimientos:create`
- `seguimientos:read`
- `seguimientos:update`
- `seguimientos:cancel`
- `seguimientos:complete`

Evitar `seguimientos:delete` en MVP si no habra borrado fisico. Usar cancelacion logica.

## 3. Sincronizacion SQLite <-> Cosmos

### Viabilidad

La sincronizacion es viable si se mantiene aislada de notas y se integra como otro bloque dentro de `SyncService`, similar a citas y vacunaciones pendientes.

Condiciones para que sea segura:

- Tabla local propia.
- `clientId` unico.
- Upsert remoto idempotente.
- `updatedAtUtc` obligatorio.
- No usar `DateTime` local ambiguo.
- No mezclar con `notes`.

### Flujo local a nube

1. Crear seguimiento local con `synced = false`.
2. Intentar `POST /seguimientos`.
3. Backend hace upsert por `id = clientId`.
4. Si 2xx, marcar `synced = true`.
5. Si falla, conservar local, guardar `syncError` y `lastSyncAttemptUtc`.

### Flujo nube a local

Para MVP:

- Pull al abrir pantalla principal.
- Pull por campus.
- Pull por matricula en vista de paciente.
- Merge por `clientId`.

No se recomienda pull global automatico en cada inicio de app durante MVP.

### Conflictos

Regla final recomendada:

- Si local `synced = false`, local gana temporalmente y se reintenta push.
- Si ambos estan sincronizados, gana el mayor `updatedAtUtc`.
- Estados terminales `completado` y `cancelado` no deben regresar a `pendiente` por un remoto viejo.
- `fechaCreacionUtc` no se sobrescribe nunca.

### Consistencia con SASU actual

El enfoque es consistente con SASU:

- Carnets, notas, citas y vacunaciones ya tienen persistencia local y sync.
- El patron de pendientes existe en `SyncService`.
- El modelo offline first evita perdida de trabajo en campo.

La diferencia critica es que seguimientos tendra mas cambios de estado que notas, por lo que requiere `updatedAtUtc` y no solo `createdAt`.

## 4. Migracion Drift

### Riesgo de afectacion

La migracion propuesta a schema `8` puede ser segura si es estrictamente aditiva:

- Agregar nueva tabla.
- Agregar indices.
- No modificar columnas existentes.
- No tocar tabla `notes`.
- No tocar conversion de fechas clinicas.

### Riesgo principal

El archivo `db.g.dart` se regenera completo. Aunque sea esperado, puede producir un diff grande.

Mitigacion:

- Commit exclusivo para Drift schema `8`.
- Prueba de apertura de base existente schema `7`.
- Prueba de consulta de notas despues de migrar.
- No formatear archivos no relacionados.

### Indices indispensables

Indices minimos para MVP:

- Unico: `client_id`.
- Simple: `matricula`.
- Simple: `estado`.
- Simple: `fecha_objetivo_utc`.
- Compuesto: `estado, fecha_objetivo_utc`.
- Compuesto: `matricula, estado`.

Indices posponibles:

- `prioridad`, si la lista se mantiene acotada.
- `responsable`, hasta que exista asignacion formal por usuario.
- `campus`, si la base local es por usuario/campus unico; aun asi puede ser util si hay multicampus local.

## 5. Volumen estimado

Estos son rangos de planeacion, no cifras oficiales.

### 1 campus

Supuestos:

- 500 a 5,000 estudiantes atendibles.
- 10% a 30% con algun seguimiento activo o historico por semestre.
- 1 a 3 seguimientos por paciente con seguimiento activo.

Estimacion:

- Activos: 50 a 1,500.
- Historico anual: 500 a 10,000.

Impacto:

- SQLite lo maneja sin problema con indices minimos.
- Cosmos con `/campus` funciona bien.

### 3 campus

Estimacion:

- Activos: 150 a 4,500.
- Historico anual: 1,500 a 30,000.

Impacto:

- Dashboard por campus sigue siendo barato.
- Reportes regionales requieren paginacion y filtros.

### Toda la UAGro

Supuestos:

- 80+ instituciones/campus/unidades.
- Uso desigual entre sedes.

Estimacion:

- Activos: 5,000 a 50,000.
- Historico anual: 50,000 a 300,000.

Impacto:

- Cosmos viable.
- Reportes globales deben evitar scans frecuentes.
- Recomendable en 3.0 crear agregados por campus/estado/fecha.

## 6. Seguimiento independiente vs asociado a nota clinica

### Opcion A: Seguimiento independiente del expediente

Ventajas:

- No toca notas clinicas.
- Menor riesgo juridico sobre documentos clinicos ya guardados.
- Permite seguimientos administrativos, vacunacion y promocion.
- Permite crear seguimiento sin crear nota.
- Mejor para dashboards y pendientes operativos.

Desventajas:

- Requiere UI propia.
- Puede sentirse separado del acto clinico si no se vincula visualmente.
- Requiere cuidado para no duplicar informacion del expediente.

### Opcion B: Seguimiento asociado a una nota clinica

Ventajas:

- Relacion directa con la atencion que origino el pendiente.
- Contexto clinico inmediato.
- Facilita auditoria del motivo original si nace desde una nota.

Desventajas:

- Riesgo de tocar flujo sensible de notas.
- Puede reabrir errores de duplicacion/sync de notas.
- No todos los seguimientos nacen de una nota.
- Complica permisos si el seguimiento es administrativo.
- Puede mezclar tareas operativas con documentos clinicos inmutables.

### Decision recomendada

Usar opcion A como arquitectura base, con vinculo opcional a nota:

- `originNoteClientId` nullable.
- `originModule` nullable.

Esto permite crear un seguimiento desde una nota en el futuro sin que el seguimiento dependa de la nota para existir o sincronizarse.

## 7. Dashboard

### Dashboard propuesto

KPIs actuales propuestos:

- Pendientes.
- Vencidos.
- Completados.
- Alta prioridad.

Son suficientes para MVP.

### Ajustes recomendados

Agregar dos indicadores operativos:

- Hoy.
- Sin sincronizar.

Dashboard MVP recomendado:

- Pendientes.
- Vencidos.
- Hoy.
- Alta prioridad.

Completados puede moverse a filtro o vista secundaria, porque ocupa espacio de decision diaria y no exige accion inmediata.

Para 2.7:

- Mis seguimientos.
- Por responsable.
- Por tipo.
- Por campus.

Para 3.0:

- Tendencia semanal/mensual.
- Cumplimiento por area.
- Tiempo promedio de cierre.
- Seguimientos vencidos por campus.

## 8. Riesgos

### Tecnicos

- Migracion Drift mal aplicada.
- Regeneracion amplia de `db.g.dart`.
- Desalineacion de permisos backend/Flutter.
- Fechas UTC/local mal interpretadas.
- Duplicados si `id` y `clientId` divergen.

Mitigacion:

- Commits pequenos.
- `id = clientId`.
- Tests de fecha y merge.
- Migracion aditiva.

### Operativos

- Usuarios pueden crear demasiados seguimientos sin responsable claro.
- Seguimientos vencidos pueden saturar dashboard.
- Cancelaciones sin motivo pueden perder contexto.

Mitigacion:

- Responsable obligatorio.
- `cancelReason` obligatorio al cancelar.
- Filtros por estado y prioridad.

### Rendimiento

- Listas grandes sin paginacion.
- Consultas Cosmos cross-partition para reportes globales.
- Dashboard recalculando demasiados registros.

Mitigacion:

- Paginacion en backend.
- Filtros por campus y fecha.
- Indices SQLite minimos.
- Limitar dashboard a ventanas: hoy, vencidos, proximos 30 dias.

### Sincronizacion

- Conflictos de estado.
- Cambios offline simultaneos.
- Pull remoto que pisa cambios locales pendientes.

Mitigacion:

- `updatedAtUtc`.
- `synced = false` protege cambios locales.
- Estados terminales no retroceden.
- `lastSyncAttemptUtc` y `syncError`.

### Experiencia de usuario

- Demasiados campos en formulario inicial.
- Confusion entre nota clinica y seguimiento.
- Dashboard saturado.

Mitigacion:

- Formulario MVP corto.
- Separar visualmente "Nota clinica" de "Seguimiento".
- Acciones rapidas: iniciar, completar, cancelar.

## 9. Ajustes recomendados al diseno original

Cambios recomendados antes de implementar:

1. Eliminar `remoteId` del MVP.
2. Hacer `campus` obligatorio.
3. Hacer `createdBy` obligatorio.
4. Agregar `updatedBy`.
5. Agregar `lastSyncAttemptUtc`.
6. Agregar `syncError`.
7. Agregar `cancelReason`.
8. Agregar `originModule` y `originNoteClientId` como opcionales.
9. Usar `id = clientId` en Cosmos.
10. Reemplazar KPI "Completados" por "Hoy" en dashboard MVP.

## 10. Alcance MVP 2.6.0

### Incluido

- Crear seguimiento.
- Listar seguimientos.
- Filtrar por estado, prioridad, tipo y matricula.
- Ver vencidos.
- Ver seguimientos de hoy.
- Cambiar estado:
  - `pendiente` a `en_proceso`.
  - `en_proceso` a `completado`.
  - cualquier estado no terminal a `cancelado`.
- Sincronizar local a nube.
- Pull basico por campus y matricula.
- Dashboard con KPIs:
  - Pendientes.
  - Vencidos.
  - Hoy.
  - Alta prioridad.

### Excluido

- Notificaciones push.
- Recordatorios automaticos.
- Recurrencias.
- Chat.
- Adjuntos.
- Auditoria avanzada.
- Reportes globales UAGro.
- Asociacion obligatoria a nota clinica.
- Modificacion del timeline de notas.

## 11. Alcance futuro

### SASU 2.7

- Asignacion formal a usuarios o roles.
- "Mis seguimientos".
- Recordatorios locales.
- Historial de cambios por seguimiento.
- Comentarios internos simples.
- Filtros por area/departamento.
- Exportacion CSV/PDF.

### SASU 3.0

- Notificaciones push.
- Panel institucional multicampus.
- Reportes de cumplimiento.
- Indicadores por unidad academica.
- Automatizacion de seguimientos recurrentes.
- Integracion con agenda/citas.
- Analitica longitudinal por paciente.
- Integracion opcional con chat/ticket institucional.

## 12. Veredicto final

El diseno es viable, pero debe ajustarse antes de iniciar desarrollo.

Arquitectura final recomendada:

- Seguimiento independiente.
- Vinculo opcional a nota.
- `id = clientId`.
- Schema Drift `8`, migracion aditiva.
- Cosmos `/campus`.
- Dashboard MVP enfocado en accion diaria.
- Sync protegido por `updatedAtUtc`, `synced`, `syncError` y estados terminales.

El desarrollo puede iniciar despues de aprobar estos ajustes.
