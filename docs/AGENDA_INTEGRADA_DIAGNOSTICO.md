# Agenda Integrada SASU / Carnet Digital - Diagnostico Tecnico

Fecha: 2026-06-16

Estado: diagnostico inicial. No se implemento codigo, no se generaron migraciones, no se hizo push ni deploy.

## 0. Resumen ejecutivo

SASU Windows ya tiene una base funcional de citas: captura interna desde Expedientes, persistencia local en Drift, sincronizacion con FastAPI y almacenamiento en Cosmos. Esa base no debe descartarse.

El Carnet Digital Web tambien tiene una vista de lectura de citas, pero no tiene todavia el flujo MVP requerido para que el alumno solicite una cita, consulte el estado de la solicitud, cancele logicamente una solicitud o vea un historial de cambios.

El modelo actual de `citas` esta orientado a citas ya programadas, con `inicio`, `fin`, `motivo`, `departamento` y estados como `programada`. El MVP de Agenda Integrada requiere un modelo previo de solicitud, donde todavia puede no existir horario confirmado. Por eso la opcion mas segura es crear una coleccion nueva `appointments` para solicitudes integradas y mantener la coleccion actual `cita_id` como compatibilidad con el flujo historico de SASU.

La arquitectura recomendada para el MVP es:

```text
Carnet Digital Web
  -> backend Node.js del Carnet Digital
  -> Cosmos DB: appointments
  -> backend FastAPI SASU
  -> SASU Windows
```

El backend Node debe ser el punto de entrada del alumno porque ya valida el JWT del Carnet Digital y conoce la matricula real del estudiante. El backend FastAPI debe ser el punto de entrada de usuarios internos SASU porque ya concentra los patrones de autorizacion interna y la integracion reciente de tickets.

## 1. Proyectos revisados

### SASU Windows

Ruta local:

```text
C:\CRES_Carnets_UAGROPRO
```

Estado Git observado:

```text
feature/sasu-2.6.0
M temp_backend
```

La modificacion en `temp_backend` ya existia como estado pendiente del repo raiz. No se mezclo con este diagnostico.

### Carnet Digital Web

Ruta local identificada como fuente activa:

```text
C:\Users\gilbe\Documents\Carnet_digital _alumnos
```

Estado observado:

```text
main...origin/main
?? docs/SASU_2_6_0_TICKETS_DEPLOYMENT_PLAN.md
```

El archivo no versionado ya existia y no se modifica en esta etapa.

### Backend Node.js del Carnet Digital

Ruta local:

```text
C:\Users\gilbe\Documents\Carnet_digital _alumnos\carnet_alumnos_nodes
```

Estado observado:

```text
main...origin/main
```

Este backend es el candidato natural para los endpoints del alumno porque el Carnet Digital ya usa `https://carnet-alumnos-nodes.onrender.com` para login, carnet y datos de alumno.

### Backend FastAPI SASU

Ruta local:

```text
C:\CRES_Carnets_UAGROPRO\temp_backend
```

Es el backend SASU usado para tickets y servicios FastAPI. Actualmente contiene endpoints de citas heredados y la arquitectura reciente de tickets, que puede servir como patron para permisos, modelos, repositorios y rutas.

## 2. Inventario SASU

### 2.1 Pantallas de agenda y citas existentes

#### `lib/screens/cita_form_screen.dart`

Pantalla interna para agendar cita desde SASU.

Comportamiento observado:

- Recibe `matricula` y `AppDatabase`.
- Permite capturar:
  - motivo
  - departamento
  - fecha
  - hora de inicio
  - hora de fin
- Construye payload con:
  - `matricula`
  - `inicio`
  - `fin`
  - `motivo`
  - `departamento`
  - `estado: programada`
- Envia la cita a FastAPI mediante `ApiService.createCita`.

Conclusion: reutilizable parcialmente para citas ya programadas, pero no representa una solicitud del alumno pendiente de confirmacion.

#### `lib/screens/nueva_nota_screen.dart`

Contiene integracion de citas dentro del flujo de Expedientes.

Elementos relevantes:

- Importa `cita_form_screen.dart`.
- Tiene accion interna para agendar cita.
- Consulta citas del paciente por matricula.
- Integra citas con el contexto clinico del expediente.

Conclusion: es reutilizable como punto de acceso interno, pero el MVP necesita una bandeja de solicitudes de agenda mas clara para confirmar, reprogramar o cancelar solicitudes recibidas desde Carnet Digital.

#### Pantallas de sincronizacion y mantenimiento

Archivos relacionados:

- `lib/screens/pending_sync_screen.dart`
- `lib/screens/database_cleaner_screen.dart`

Ambas pantallas reconocen la existencia de citas dentro del estado local/sincronizable.

### 2.2 Modelos y persistencia local existentes

#### `lib/data/db.dart`

Existe tabla Drift `Citas` con campos:

- `id`
- `matricula`
- `inicio`
- `fin`
- `motivo`
- `departamento`
- `estado`
- `googleEventId`
- `htmlLink`
- `createdAt`
- `synced`

Metodos relevantes:

- `getCitasForMatricula`
- `getPendingCitas`
- `markCitaAsSynced`
- `insertCita`

Version de esquema actual:

```text
schemaVersion = 7
```

Conclusion: la tabla local cubre citas calendarizadas, no solicitudes previas. No conviene reutilizarla directamente para `requested` sin campos adicionales o sin una capa de compatibilidad.

### 2.3 Servicios SASU existentes

#### `lib/data/api_service.dart`

Metodos relevantes:

- `pushSingleCita`
- `getCitasForMatricula`
- `getCitaById`
- `createCita`
- `getCitasByMatricula`

Endpoints consumidos:

- `POST /citas`
- `GET /citas/{cita_id}`
- `GET /citas/por-matricula/{matricula}`

Conclusion: hay un cliente API funcional para citas historicas, pero falta cliente para una bandeja administrativa de solicitudes `appointments`.

#### `lib/data/sync_service.dart`

Sincroniza citas pendientes locales hacia FastAPI.

Payload actual:

- `matricula`
- `inicio`
- `fin`
- `motivo`
- `departamento`
- `estado`
- `googleEventId`
- `htmlLink`

Conclusion: util para mantener compatibilidad con citas internas, pero el MVP integrado debe evitar que una solicitud del alumno se convierta automaticamente en cita local sin confirmacion de SASU.

### 2.4 Endpoints FastAPI existentes

En `temp_backend/main.py` existen endpoints de citas:

- `POST /citas`
- `GET /citas/{cita_id}`
- `GET /citas/por-matricula/{matricula}`

Modelo actual `CitaModel`:

- `id`
- `matricula`
- `inicio`
- `fin`
- `motivo`
- `departamento`
- `estado`
- `createdAt`
- `updatedAt`

Observacion de seguridad:

Estos endpoints heredados no muestran el mismo patron de autenticacion/autorizacion que el modulo de tickets. Para Agenda Integrada no deben exponerse como API administrativa principal sin reforzar permisos.

### 2.5 Cosmos DB y colecciones relacionadas

En `temp_backend/cosmos_helper.py`:

- `COSMOS_CONTAINER_CITAS`
- valor default: `cita_id`
- `COSMOS_PK_CITAS`
- valor default: `/id`

Metodo relevante:

- `upsert_cita(doc)`

El backend Node tambien usa:

- `COSMOS_CONTAINER_CITAS || cita_id`

Riesgo detectado:

El helper FastAPI asume por defecto particion `/id`, mientras que algunas operaciones del backend Node eliminan citas usando `matricula` como partition key. Antes de modificar citas existentes se debe confirmar la partition key real de `cita_id` en Cosmos.

### 2.6 Flujos reutilizables en SASU

Reutilizables:

- Integracion visual con Expedientes.
- Cliente API y patrones de carga asincrona.
- Persistencia local de citas programadas.
- Sincronizacion de citas internas.
- Patrones recientes del modulo Tickets para:
  - rutas FastAPI separadas
  - permisos internos
  - historial de cambios
  - errores claros
  - compatibilidad alumno/interno sin mezclar roles

No reutilizable directamente:

- `CitaFormScreen` como pantalla de solicitudes del alumno.
- Estado `programada` como equivalente de `requested`.
- Eliminacion fisica de citas desde Carnet Digital.

## 3. Inventario Carnet Digital

### 3.1 Autenticacion actual

El Carnet Digital Web usa el backend Node:

```text
https://carnet-alumnos-nodes.onrender.com
```

En `carnet_alumnos_nodes/middleware/auth.js`:

- Se valida Bearer token.
- El JWT se firma con `JWT_SECRET`.
- El token contiene principalmente:
  - `matricula`
  - `iat`
  - `exp`

En `carnet_alumnos_nodes/routes/auth.js`:

- Login usa matricula y password.
- Registro valida correo, matricula y password.
- El token generado no incluye correo ni nombre.

Implicacion:

Para validar correo institucional en Agenda MVP no se debe confiar en el payload del JWT. El backend debe consultar la fuente de verdad del alumno por matricula y validar el correo registrado.

### 3.2 Servicios API actuales del Carnet Digital

En `lib/services/api_service.dart`:

- `baseUrl = https://carnet-alumnos-nodes.onrender.com`
- `ticketsBaseUrl = https://fastapi-backend-o7ks.onrender.com`

Metodos actuales de citas:

- `getCitas(token)` -> `GET /me/citas`
- `deleteCitasPasadas(token)` -> `DELETE /me/citas/pasadas`

No existen metodos para:

- solicitar cita
- consultar detalle de solicitud
- cancelar solicitud logicamente
- consultar historial de estados de una solicitud

### 3.3 Modelos actuales de citas en Carnet Digital

En `lib/models/cita_model.dart` existe `CitaModel` con:

- `id`
- `matricula`
- `inicio`
- `fin`
- `motivo`
- `departamento`
- `estado`
- `createdAt`
- `updatedAt`

Estados visuales actuales:

- `programada`
- `confirmada`
- `cancelada`
- `completada`

Conclusion:

El modelo puede reutilizarse como compatibilidad para citas existentes, pero no cubre el contrato MVP `appointments` con estados `requested`, `confirmed`, `rescheduled`, etc.

### 3.4 Pantallas y navegacion actuales

En `lib/screens/citas_screen.dart` existe una pantalla de lectura:

- Titulo: citas medicas del alumno.
- Lista tarjetas de citas.
- Muestra estado, departamento, fecha, hora y motivo.
- Tiene accion para eliminar citas pasadas.

En `lib/main.dart`:

- No hay ruta dedicada `/citas`.
- Si existe ruta `/atencion` para Centro de Atencion.

En `lib/screens/carnet_screen_new.dart`:

- Existe seccion "Citas y Consultas".
- La seccion es una ubicacion natural para enlazar el futuro modulo "Mis Citas".

Conclusion:

Aunque el prompt indica que Carnet Digital no tiene "Mis Citas", si existe una pantalla de lectura de citas. Lo que falta es el flujo integrado de solicitud, estado, historial y cancelacion logica.

### 3.5 Backend Node.js: citas actuales

En `carnet_alumnos_nodes/routes/citas.js` existen:

- `GET /me/citas`
- `GET /me/citas/:id`
- `DELETE /me/citas/pasadas`

Hallazgos importantes:

- `GET /me/citas` consulta por matricula del JWT.
- Si falla Cosmos o no hay citas reales, puede devolver datos mock.
- `DELETE /me/citas/pasadas` elimina citas antiguas.

Riesgos:

- Los datos mock no deben permanecer en un flujo productivo de Agenda Integrada.
- La eliminacion fisica no es compatible con auditoria ni historial institucional.
- No hay endpoint de solicitud de cita.

## 4. Brecha funcional

### 4.1 Que existe

SASU Windows:

- Captura interna de citas.
- Tabla local de citas.
- Sincronizacion de citas.
- Consulta de citas por matricula.
- FastAPI con endpoints heredados `/citas`.
- Cosmos con contenedor actual `cita_id`.

Carnet Digital:

- Login de alumno.
- JWT con matricula.
- Pantalla de lectura de citas.
- Modelo basico de cita.
- API para consultar citas por alumno.

Backend Node:

- Auth alumno.
- Consulta de citas por matricula.
- Conexion Cosmos.

Backend FastAPI:

- Endpoints de citas heredados.
- Patrones robustos recientes de tickets para rutas, permisos e historial.

### 4.2 Que falta

Backend:

- Coleccion `appointments`.
- Repositorio de solicitudes de cita.
- Endpoints alumno:
  - crear solicitud
  - listar solicitudes propias
  - ver detalle propio
  - cancelar solicitud propia
- Endpoints internos SASU:
  - listar solicitudes
  - ver detalle
  - confirmar
  - reprogramar
  - cancelar
  - marcar atendida
  - marcar no asistio
  - rechazar
- Historial de cambios por solicitud.
- Validacion de duplicados.
- Validacion de correo institucional.
- Autorizacion interna para personal SASU.

Carnet Digital:

- Pantalla/formulario de solicitud.
- "Mis Citas" integrado como modulo de alumno.
- Detalle de solicitud.
- Estado e historial.
- Cancelacion logica por alumno.

SASU Windows:

- Bandeja operativa de solicitudes de agenda.
- Filtros por estado, area, fecha, matricula y alumno.
- Acciones de confirmar/reprogramar/cancelar/atender/no show.
- Vista de historial.

### 4.3 Que puede reutilizarse

- `CitasScreen` como base visual para "Mis Citas".
- `CitaModel` solo como compatibilidad, no como modelo final.
- `SessionProvider` para token y datos del alumno.
- `ApiService` del Carnet para conservar `baseUrl` Node.
- `CitaFormScreen` como referencia para captura de fecha/hora por personal.
- `ApiService` SASU y patrones de Tickets para nuevo cliente interno.
- Autorizacion FastAPI ya usada en Tickets para usuarios SASU.
- Cosmos helper/repository patterns.

### 4.4 Que no debe reutilizarse directamente

- `DELETE /me/citas/pasadas` para cancelacion.
- Datos mock de `/me/citas`.
- Endpoints `/citas` sin reforzar permisos como API principal del MVP.
- Estado `programada` como sinonimo de `requested`.
- La tabla local `Citas` como fuente unica de solicitudes del alumno.

## 5. Diseno a validar para Agenda MVP

### 5.1 Coleccion

Coleccion propuesta:

```text
appointments
```

Motivo:

- Evita romper compatibilidad con `cita_id`.
- Permite representar solicitudes antes de que exista horario confirmado.
- Permite historial institucional sin eliminar registros.
- Facilita separar alumno, personal SASU y auditoria.

### 5.2 Estados

Estados del MVP:

- `requested`
- `confirmed`
- `rescheduled`
- `cancelled_by_student`
- `cancelled_by_staff`
- `attended`
- `no_show`
- `rejected`

No se recomienda agregar `expired` en el MVP porque no esta en la lista solicitada para esta fase.

### 5.3 Modelo sugerido

```json
{
  "id": "appointment:{uuid}",
  "type": "appointment",
  "student": {
    "matricula": "15662",
    "nombre": "NOMBRE DEL ALUMNO",
    "email": "alumno@uagro.mx",
    "campus": "CRES Llano Largo",
    "unidadAcademica": "Preparatoria / Facultad"
  },
  "requestedBy": "student:15662",
  "area": "psicologia",
  "reasonCategory": "consulta_general",
  "reasonText": "Motivo capturado por el alumno",
  "preferredDate": "2026-06-20",
  "preferredTimeBlock": "morning",
  "scheduledStart": null,
  "scheduledEnd": null,
  "status": "requested",
  "history": [
    {
      "from": null,
      "to": "requested",
      "actor": "student:15662",
      "actorRole": "student",
      "message": "Solicitud creada por el alumno",
      "createdAtUtc": "2026-06-16T18:00:00Z"
    }
  ],
  "createdAtUtc": "2026-06-16T18:00:00Z",
  "updatedAtUtc": "2026-06-16T18:00:00Z"
}
```

### 5.4 Validaciones requeridas

#### Matricula

- El alumno no debe enviar matricula editable.
- El backend debe tomar la matricula desde el JWT.
- Todas las consultas del alumno deben filtrar por esa matricula.

#### Correo institucional

- El JWT actual del Carnet no contiene correo.
- La validacion debe hacerse consultando usuario/carnet por matricula.
- Si el correo no existe o no cumple la regla institucional, la solicitud debe rechazarse con error claro.

#### Citas duplicadas

Evitar duplicados activos por:

- matricula
- area
- estados activos:
  - `requested`
  - `confirmed`
  - `rescheduled`

Regla recomendada:

Un alumno no debe tener mas de una solicitud activa para la misma area, salvo que SASU cierre, cancele, rechace, marque atendida o marque no asistencia la anterior.

## 6. Endpoints propuestos

### 6.1 Alumno - backend Node.js

Base actual:

```text
https://carnet-alumnos-nodes.onrender.com
```

Endpoints MVP:

```text
POST /me/appointments
GET /me/appointments
GET /me/appointments/:id
PATCH /me/appointments/:id/cancel
```

Justificacion:

- Mantiene login/carnet sin cambios.
- Reutiliza el token actual del alumno.
- Evita acoplar el Carnet Web al JWT interno de SASU.
- Permite validar matricula y correo usando las colecciones actuales del Carnet.

### 6.2 Personal SASU - backend FastAPI

Base actual:

```text
https://fastapi-backend-o7ks.onrender.com
```

Endpoints MVP:

```text
GET /appointments
GET /appointments/{appointment_id}
PATCH /appointments/{appointment_id}/confirm
PATCH /appointments/{appointment_id}/reschedule
PATCH /appointments/{appointment_id}/cancel
PATCH /appointments/{appointment_id}/attended
PATCH /appointments/{appointment_id}/no-show
PATCH /appointments/{appointment_id}/reject
```

Justificacion:

- SASU Windows ya opera contra FastAPI.
- El backend FastAPI ya tiene roles internos SASU.
- El patron de Tickets puede replicarse para permisos, filtros e historial.

### 6.3 Compatibilidad con `/citas`

Los endpoints actuales deben conservarse:

```text
POST /citas
GET /citas/{cita_id}
GET /citas/por-matricula/{matricula}
GET /me/citas
```

Pero no deben ser el contrato nuevo de Agenda Integrada.

## 7. Riesgos identificados

### 7.1 Doble modelo de citas

Actualmente existe `cita_id`; el MVP propone `appointments`.

Riesgo:

- Que SASU muestre datos de `appointments` y Carnet muestre datos viejos de `cita_id`.

Mitigacion:

- Definir `appointments` como fuente de verdad del MVP.
- Mantener `cita_id` solo para compatibilidad.
- En fase posterior, decidir si una cita confirmada crea/actualiza registro compatible en `cita_id`.

### 7.2 Partition key de Cosmos no confirmada

Hay senales de uso distinto:

- FastAPI default `COSMOS_PK_CITAS=/id`.
- Node elimina citas usando `matricula` como partition key.

Mitigacion:

- Antes de escribir o borrar en `cita_id`, verificar la partition key real en Cosmos.
- Para `appointments`, definir desde el inicio una partition key estable.

Recomendacion:

```text
/student/matricula
```

o, si se prefiere query administrativa global:

```text
/type
```

La eleccion debe considerar volumen, filtros y costo de consultas.

### 7.3 Datos mock en produccion

`GET /me/citas` puede devolver citas mock si no encuentra datos reales o si falla Cosmos.

Riesgo:

- El alumno podria ver citas que no existen.

Mitigacion:

- Eliminar o proteger mocks antes de usar formalmente "Mis Citas".
- Para MVP, `/me/appointments` no debe tener fallback mock.

### 7.4 Eliminacion fisica desde Carnet Digital

`DELETE /me/citas/pasadas` elimina registros.

Riesgo:

- Perdida de trazabilidad.
- Conflicto con auditoria institucional.

Mitigacion:

- Agenda MVP debe usar cancelacion logica con estado `cancelled_by_student`.

### 7.5 JWT alumno vs JWT SASU

El Carnet Digital usa token Node con `matricula`. SASU interno usa otro JWT con roles internos.

Mitigacion:

- Alumno usa Node.
- Operador usa FastAPI.
- Ambos escriben en la misma coleccion `appointments` bajo reglas de autorizacion distintas.

### 7.6 Estados actuales incompatibles

Estados actuales:

- `programada`
- `confirmada`
- `cancelada`
- `completada`

Estados MVP:

- `requested`
- `confirmed`
- `rescheduled`
- `cancelled_by_student`
- `cancelled_by_staff`
- `attended`
- `no_show`
- `rejected`

Mitigacion:

- No mezclar estados en el mismo modelo sin capa de traduccion.
- Si se muestran citas heredadas junto a solicitudes nuevas, etiquetarlas claramente como fuente legacy.

## 8. Propuesta tecnica final

### Fase 1A - Contrato y backend alumno

Crear en backend Node:

- Repositorio Cosmos para `appointments`.
- Validacion de matricula desde JWT.
- Validacion de correo institucional desde carnet/usuario.
- Endpoints:
  - `POST /me/appointments`
  - `GET /me/appointments`
  - `GET /me/appointments/:id`
  - `PATCH /me/appointments/:id/cancel`
- Reglas:
  - no aceptar matricula desde cliente
  - no crear duplicados activos
  - no borrar registros
  - historial obligatorio

### Fase 1B - Backend SASU interno

Crear en FastAPI:

- `appointment_models.py`
- `appointment_repository.py`
- `appointment_routes.py`

Usar patron de Tickets:

- autenticacion interna obligatoria
- roles SASU autorizados
- filtros por estado, area, matricula, campus y unidad
- historial de estado
- errores claros

### Fase 1C - Carnet Digital Web

Agregar modulo "Mis Citas" sin romper login/carnet:

- Formulario de solicitud.
- Lista de solicitudes.
- Detalle con estado e historial.
- Cancelacion logica.

Ubicacion recomendada:

- Seccion existente "Citas y Consultas" en `carnet_screen_new.dart`.
- Ruta nueva sugerida: `/citas`.

### Fase 1D - SASU Windows

Agregar Bandeja de Agenda:

- Lista de solicitudes `appointments`.
- Filtros por estado, area, fecha, matricula y alumno.
- Detalle.
- Acciones:
  - confirmar
  - reprogramar
  - cancelar
  - atendida
  - no asistio
  - rechazar

No reemplazar todavia `CitaFormScreen`; puede convivir mientras se estabiliza el flujo nuevo.

## 9. Recomendacion de implementacion MVP

Recomendacion:

Implementar Agenda Integrada MVP usando `appointments` como coleccion nueva y manteniendo `cita_id` sin cambios destructivos.

Orden recomendado:

1. Backend Node: endpoints alumno.
2. FastAPI: endpoints operador/admin.
3. Carnet Digital: solicitud y mis citas.
4. SASU Windows: bandeja administrativa.
5. Validacion E2E.
6. Solo despues, evaluar puente opcional entre `appointments` confirmadas y `cita_id`.

No se recomienda:

- Modificar destructivamente `cita_id`.
- Reutilizar `DELETE /me/citas/pasadas`.
- Exponer `/citas` heredado como contrato publico del MVP.
- Crear una agenda compleja por horarios en esta fase.
- Implementar referencias o contrarreferencias antes de cerrar Agenda MVP.

## 10. Pendientes antes de implementar

Antes de autorizar codigo:

- Confirmar partition key deseada para `appointments`.
- Confirmar regla exacta de correo institucional.
- Confirmar areas iniciales:
  - medicina
  - psicologia
  - nutricion
  - odontologia
  - atencion estudiantil
- Confirmar si el alumno puede elegir fecha preferida o solo bloque de horario.
- Confirmar si una confirmacion SASU debe crear tambien una cita legacy en `cita_id`.
- Confirmar roles internos autorizados para gestionar agenda.

## 11. Dictamen

El MVP es viable sin romper SASU 2.6.1 si se implementa como extension controlada y no como reemplazo del sistema actual de citas.

Dictamen tecnico:

```text
APTO PARA PASAR A DISENO/IMPLEMENTACION, PENDIENTE DE AUTORIZACION.
```

No se realizaron cambios de codigo.
No se crearon commits.
No se hizo push.
No se hizo deploy.
