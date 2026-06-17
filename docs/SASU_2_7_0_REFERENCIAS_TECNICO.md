# SASU 2.7.0 - Referencias y Contrarreferencias

## Documento tecnico

Version base estable: `SASU 2.6.5+45`

Documentos base:

```text
docs/SASU_2_7_0_REFERENCIAS_DIAGNOSTICO.md
docs/SASU_2_7_0_REFERENCIAS_FUNCIONAL.md
```

Este documento define el diseno tecnico propuesto para implementar el modulo de Referencias y Contrarreferencias en SASU 2.7.0.

No modifica codigo.
No crea endpoints.
No crea modelos.
No modifica Flutter Windows, Flutter Web, FastAPI, Node, Cosmos, JWT, Tickets ni Agenda Integrada.
No implica commit, push, deploy, tag ni release.

---

## 1. Arquitectura tecnica detallada

El modulo debe vivir tecnicamente en la arquitectura actual:

```text
SASU Windows
-> FastAPI SASU
-> Cosmos DB
-> Agenda Integrada
-> Expediente
```

Carnet Digital Web queda fuera del MVP operativo. Solo se contempla visualizacion futura limitada y no sensible.

### Responsabilidades por componente

#### SASU Windows

- mostrar Bandeja de Referencias
- crear referencias
- recibir referencias por area destino
- aceptar referencias
- convertir referencias aceptadas en citas
- registrar atencion
- registrar contrarreferencia
- cerrar o cancelar referencias
- mostrar referencias en el expediente
- mostrar notificaciones internas tipo Messenger

#### FastAPI SASU

- validar JWT interno SASU
- aplicar permisos por rol y area
- exponer endpoints `/referrals`
- validar transiciones de estado
- persistir documentos en Cosmos
- relacionar referencias con citas de Agenda Integrada
- exponer consultas para expediente y notificaciones

#### Cosmos DB

- almacenar referencias en contenedor nuevo `referrals`
- conservar contrarreferencia embebida
- conservar historial de estados
- permitir consultas por estudiante, area, estado y prioridad

#### Agenda Integrada

- conservar flujo actual de citas
- recibir creacion de cita derivada desde referencia aceptada
- mantener relacion bidireccional `referralId / appointmentId`

#### Expediente

- consultar referencias por matricula
- mostrar eventos relevantes en timeline
- no duplicar citas ni notas

---

## 2. Diseno Cosmos DB

### Contenedor

Contenedor propuesto:

```text
referrals
```

### Partition key

Partition key propuesta:

```text
/student/matricula
```

Justificacion:

- el expediente se consulta naturalmente por matricula
- agrupa la historia institucional del estudiante
- facilita timeline por alumno
- reduce cruces complejos al mostrar expediente
- permite relacionar referencia, cita y contrarreferencia bajo el mismo estudiante

### Indices sugeridos

Cosmos indexa automaticamente propiedades por defecto, pero se recomienda garantizar buen rendimiento para:

```text
/status
/priority
/origin/area
/destination/area
/createdAt
/updatedAt
/student/matricula
/student/nombre
/appointmentId
/counterReferral/createdAt
```

Consultas esperadas:

- referencias por matricula
- referencias por area destino
- referencias por area origen
- referencias pendientes
- referencias por estado
- referencias por prioridad
- referencias con cita relacionada
- referencias actualizadas recientemente

### Estrategia de consultas

#### Bandeja por area

Consulta principal para usuarios internos:

```sql
SELECT * FROM c
WHERE c.type = "referral"
AND c.destination.area = @area
AND c.status IN ("sent", "received", "accepted", "scheduled", "attended")
ORDER BY c.updatedAt DESC
```

Para administradores:

```sql
SELECT * FROM c
WHERE c.type = "referral"
ORDER BY c.updatedAt DESC
```

#### Referencias enviadas por area

```sql
SELECT * FROM c
WHERE c.type = "referral"
AND c.origin.area = @area
ORDER BY c.updatedAt DESC
```

#### Expediente por estudiante

Consulta con partition key:

```sql
SELECT * FROM c
WHERE c.type = "referral"
AND c.student.matricula = @matricula
ORDER BY c.createdAt DESC
```

#### Pendientes de notificacion

```sql
SELECT * FROM c
WHERE c.type = "referral"
AND c.destination.area = @area
AND c.status IN ("sent", "received", "accepted")
ORDER BY c.updatedAt DESC
```

### Relacion con appointments

La referencia es el documento rector.

Relacion propuesta:

```text
referrals.appointmentId -> appointments.id
appointments.referralId -> referrals.id
appointments.sourceType = "referral"
appointments.sourceId = referrals.id
```

Reglas:

- una referencia puede tener cero o una cita activa relacionada
- una cita derivada debe apuntar a una sola referencia
- si una cita derivada se cancela, la referencia no debe borrarse
- si se reprograma la cita, la referencia conserva el mismo `appointmentId`

---

## 3. Modelo Referral completo

Modelo logico propuesto:

```json
{
  "id": "ref_20260617_abc123",
  "type": "referral",
  "student": {
    "matricula": "12345678",
    "nombre": "Nombre del estudiante",
    "correo": "alumno@uagro.mx",
    "programa": "Licenciatura",
    "campus": "CRES Llano Largo",
    "unidadAcademica": "Unidad Academica"
  },
  "origin": {
    "area": "medico",
    "userId": "user_001",
    "userName": "Dr. Nombre",
    "role": "medico"
  },
  "destination": {
    "area": "psicologia",
    "assignedUserId": null,
    "assignedUserName": null
  },
  "priority": "media",
  "reason": "Motivo institucional de referencia.",
  "observations": "Observaciones internas opcionales.",
  "status": "sent",
  "createdAt": "2026-06-17T10:00:00-06:00",
  "updatedAt": "2026-06-17T10:00:00-06:00",
  "receivedAt": null,
  "acceptedAt": null,
  "scheduledAt": null,
  "attendedAt": null,
  "closedAt": null,
  "cancelledAt": null,
  "cancellationReason": null,
  "appointmentId": null,
  "counterReferral": null,
  "statusHistory": [],
  "audit": {
    "createdByUserId": "user_001",
    "createdByUserName": "Dr. Nombre",
    "createdByRole": "medico",
    "updatedByUserId": "user_001",
    "updatedByUserName": "Dr. Nombre",
    "updatedByRole": "medico"
  }
}
```

### Campos requeridos

- `id`
- `type`
- `student.matricula`
- `student.nombre`
- `origin.area`
- `origin.userId`
- `origin.userName`
- `origin.role`
- `destination.area`
- `priority`
- `reason`
- `status`
- `createdAt`
- `updatedAt`
- `statusHistory`

### Campos opcionales

- `student.correo`
- `student.programa`
- `student.campus`
- `student.unidadAcademica`
- `destination.assignedUserId`
- `destination.assignedUserName`
- `observations`
- fechas de eventos
- `appointmentId`
- `counterReferral`
- `cancellationReason`

---

## 4. Modelo CounterReferral completo

La contrarreferencia vive embebida en el documento `Referral`.

```json
{
  "responseArea": "psicologia",
  "responseUserId": "user_010",
  "responseUserName": "Psic. Nombre",
  "responseRole": "psicologia",
  "summary": "Resumen institucional de la atencion.",
  "recommendations": "Recomendaciones para el area origen.",
  "followUpRequired": true,
  "followUpArea": "psicologia",
  "nextSuggestedAction": "Continuar seguimiento semanal.",
  "createdAt": "2026-06-18T12:00:00-06:00"
}
```

### Campos requeridos

- `responseArea`
- `responseUserId`
- `responseUserName`
- `responseRole`
- `summary`
- `createdAt`

### Campos opcionales

- `recommendations`
- `followUpRequired`
- `followUpArea`
- `nextSuggestedAction`

Reglas:

- solo area destino o administrador puede registrar contrarreferencia
- una referencia cerrada no debe aceptar nueva contrarreferencia
- una contrarreferencia no debe exponer datos sensibles en notificaciones

---

## 5. Modelo StatusHistory completo

Cada cambio relevante debe agregar un evento inmutable:

```json
{
  "status": "accepted",
  "previousStatus": "received",
  "at": "2026-06-17T11:00:00-06:00",
  "byUserId": "user_010",
  "byUserName": "Psic. Nombre",
  "byRole": "psicologia",
  "area": "psicologia",
  "note": "Referencia aceptada por Psicologia.",
  "appointmentId": null
}
```

### Campos requeridos

- `status`
- `previousStatus`
- `at`
- `byUserId`
- `byUserName`
- `byRole`
- `area`

### Campos opcionales

- `note`
- `appointmentId`
- `reason`
- `metadata`

Reglas:

- no editar eventos previos
- no borrar historial
- cada transicion de estado debe registrar evento
- registrar tambien creacion, cita generada, contrarreferencia, cierre y cancelacion

---

## 6. Enumeraciones

### Estados

```text
draft
sent
received
accepted
scheduled
attended
closed
cancelled
```

### Prioridades

```text
baja
media
alta
urgente
```

Nota:

`urgente` es prioridad operativa interna. No sustituye protocolos medicos o de emergencia.

### Areas

```text
medico
psicologia
nutricion
odontologia
atencion_estudiantil
administracion
```

El catalogo debe quedar extensible para futuras areas.

### Roles

```text
medico
psicologia
nutricion
odontologia
atencion_estudiantil
administrador
```

No se agrega rol de alumno al MVP operativo de referencias.

---

## 7. Diseno de endpoints FastAPI

Los endpoints siguientes son propuesta tecnica. No se implementan en esta etapa.

### POST /referrals

Crea referencia en `draft` o `sent`.

Permisos:

- usuarios internos SASU autorizados
- no alumno

Request:

```json
{
  "student": {
    "matricula": "12345678",
    "nombre": "Nombre del estudiante",
    "correo": "alumno@uagro.mx",
    "programa": "Licenciatura",
    "campus": "CRES Llano Largo",
    "unidadAcademica": "Unidad Academica"
  },
  "destinationArea": "psicologia",
  "priority": "media",
  "reason": "Motivo de referencia.",
  "observations": "Observaciones opcionales.",
  "send": true
}
```

Response:

```json
{
  "id": "ref_20260617_abc123",
  "status": "sent",
  "student": {
    "matricula": "12345678",
    "nombre": "Nombre del estudiante"
  },
  "destination": {
    "area": "psicologia"
  },
  "createdAt": "2026-06-17T10:00:00-06:00"
}
```

Errores esperados:

- `400`: datos incompletos o prioridad invalida
- `401`: sin token
- `403`: rol no autorizado
- `409`: referencia duplicada activa, si se define regla de duplicado

### GET /referrals

Lista referencias segun permisos y filtros.

Filtros:

```text
status
priority
origin_area
destination_area
matricula
student_name
from
to
```

Permisos:

- administrador ve todas
- area origen ve enviadas
- area destino ve recibidas

Response:

```json
{
  "items": [],
  "total": 0
}
```

Errores:

- `401`: sin token
- `403`: rol no autorizado

### GET /referrals/{referral_id}

Obtiene detalle completo.

Permisos:

- administrador
- area origen
- area destino
- usuario participante autorizado

Errores:

- `401`: sin token
- `403`: sin permiso sobre la referencia
- `404`: referencia inexistente

### PATCH /referrals/{referral_id}/status

Transicion generica controlada.

Request:

```json
{
  "status": "received",
  "note": "Referencia revisada por el area destino."
}
```

Errores:

- `400`: estado invalido
- `401`: sin token
- `403`: sin permiso
- `404`: referencia inexistente
- `409`: transicion invalida

### POST /referrals/{referral_id}/accept

Acepta referencia.

Request:

```json
{
  "assignedUserId": "user_010",
  "assignedUserName": "Psic. Nombre",
  "note": "Referencia aceptada."
}
```

Errores:

- `409`: solo referencias `received` pueden aceptarse

### POST /referrals/{referral_id}/schedule

Genera cita en Agenda Integrada.

Request:

```json
{
  "scheduledStart": "2026-06-18T09:00:00-06:00",
  "scheduledEnd": "2026-06-18T09:30:00-06:00",
  "assignedTo": "Psic. Nombre",
  "message": "Cita generada desde referencia."
}
```

Response:

```json
{
  "referralId": "ref_20260617_abc123",
  "appointmentId": "appt_20260618_xyz789",
  "status": "scheduled"
}
```

Errores:

- `400`: fecha invalida
- `409`: referencia ya tiene cita activa
- `409`: referencia no esta en `accepted`

### POST /referrals/{referral_id}/counter-referral

Registra contrarreferencia.

Request:

```json
{
  "summary": "Resumen institucional.",
  "recommendations": "Recomendaciones.",
  "followUpRequired": true,
  "followUpArea": "psicologia",
  "nextSuggestedAction": "Continuar seguimiento."
}
```

Errores:

- `400`: resumen obligatorio
- `403`: solo destino o administrador
- `409`: referencia cerrada o cancelada

### POST /referrals/{referral_id}/close

Cierra referencia.

Request:

```json
{
  "note": "Ciclo cerrado con contrarreferencia."
}
```

Errores:

- `409`: requiere atencion previa
- `409`: requiere contrarreferencia cuando aplique

### POST /referrals/{referral_id}/cancel

Cancela referencia.

Request:

```json
{
  "reason": "Referencia creada por error."
}
```

Errores:

- `400`: motivo obligatorio
- `409`: referencia ya cerrada

### GET /students/{matricula}/referrals

Consulta referencias para expediente.

Permisos:

- usuarios internos autorizados
- no alumno en MVP

### GET /referrals/pending

Consulta referencias pendientes para notificaciones.

Filtros:

```text
area
since
```

Response:

```json
{
  "items": [],
  "unreadCount": 0
}
```

---

## 8. Maquina de estados

### Transiciones validas

```text
draft -> sent
draft -> cancelled
sent -> received
sent -> cancelled
received -> accepted
received -> cancelled
accepted -> scheduled
accepted -> attended
accepted -> cancelled
scheduled -> attended
scheduled -> cancelled
attended -> closed
attended -> cancelled
```

### Estados terminales

```text
closed
cancelled
```

### Transiciones invalidas principales

```text
draft -> accepted
draft -> scheduled
sent -> scheduled
received -> scheduled
scheduled -> received
attended -> scheduled
closed -> any
cancelled -> any
```

Reglas tecnicas:

- toda transicion debe validar estado actual
- toda transicion debe validar permiso
- toda transicion debe actualizar `updatedAt`
- toda transicion debe agregar `StatusHistory`
- toda transicion debe ser atomica desde la perspectiva funcional

---

## 9. Diseno de permisos por rol y area

### Principios

- El permiso depende de rol interno SASU y area funcional.
- El campus no es restriccion fuerte en 2.7.0.
- El campus puede usarse como filtro.
- Administrador puede auditar todas las referencias.
- Alumno no accede al modulo operativo.

### Reglas tecnicas

Un usuario puede ver una referencia si:

- es administrador
- su area coincide con `origin.area`
- su area coincide con `destination.area`
- aparece como usuario asignado

Un usuario puede modificar una referencia si:

- es administrador
- su area corresponde al lado responsable de la accion
- la referencia no esta en estado terminal

Ejemplos:

- area origen crea y envia
- area destino recibe, acepta, agenda, atiende y contrarrefiere
- area origen puede cerrar si ya existe contrarreferencia
- administrador puede cancelar o reasignar con auditoria

---

## 10. Integracion con Agenda

### referral -> appointment

Cuando una referencia `accepted` se convierte en cita:

1. validar referencia existente
2. validar permiso de area destino
3. validar que no exista cita activa ligada
4. crear cita en `appointments`
5. guardar `appointmentId` en referencia
6. guardar `referralId` o `sourceId` en cita
7. cambiar referencia a `scheduled`
8. agregar evento a `statusHistory`

### appointment -> referral

Cuando Agenda actualiza una cita derivada:

- si cita se marca atendida, la referencia puede pasar a `attended`
- si cita se cancela, la referencia puede permanecer `accepted` o pasar a `cancelled` segun decision del operador
- si cita se reprograma, la referencia conserva `scheduled`

### Reglas de sincronizacion

- no borrar referencia si se cancela cita
- no borrar cita si se cierra referencia
- usar IDs cruzados para navegacion
- evitar duplicado con `appointmentId`, `sourceType`, `sourceId` y `referralId`
- registrar cambios relevantes en ambos historiales cuando aplique

---

## 11. Diseno de notificaciones internas

### Estrategia

Reutilizar el patron tipo Messenger ya existente en SASU Windows.

No usar:

- correo
- WhatsApp
- SMS
- push externo

### Polling

SASU Windows puede consultar periodicamente:

```text
GET /referrals/pending?area={area}
```

La frecuencia debe ser moderada para no saturar:

```text
60 a 120 segundos
```

### Eventos notificables

- nueva referencia recibida
- contrarreferencia recibida
- referencia pendiente sin atender

### Control de duplicados

Cliente:

- recordar IDs notificados durante la sesion
- no repetir si el detalle esta abierto
- no repetir dentro de una ventana corta

Backend:

- devolver `updatedAt`, `status` y `id`
- opcionalmente exponer `notificationKey`

Ejemplo:

```text
referral:{id}:{status}:{updatedAt}
```

### Privacidad

La notificacion no debe mostrar:

- diagnostico
- motivo clinico completo
- observaciones sensibles

Texto recomendado:

```text
Nueva referencia recibida
Tu area tiene una referencia pendiente de revision.
```

---

## 12. Diseno del timeline del expediente

El expediente debe combinar informacion existente sin reemplazarla:

- notas clinicas
- citas
- tickets, si aplica
- referencias
- contrarreferencias

### Fuente de datos

Consulta por matricula:

```text
GET /students/{matricula}/referrals
```

### Eventos de timeline

```text
referral_created
referral_sent
referral_received
referral_accepted
appointment_created_from_referral
appointment_attended
counter_referral_created
referral_closed
referral_cancelled
```

### Dedupe funcional

Si una cita derivada ya aparece en el timeline de Agenda:

- mostrarla una sola vez
- agregar etiqueta "Derivada de referencia"
- enlazar al detalle de referencia

### Visualizacion

Campos minimos:

- fecha
- area origen
- area destino
- estado
- prioridad
- cita relacionada
- resumen de contrarreferencia si el rol puede verlo

---

## 13. Estrategia de auditoria

Toda referencia debe conservar:

### Creacion

- quien creo
- rol
- area
- fecha

### Modificacion

- quien modifico
- rol
- area
- fecha
- cambio realizado

### Historial de estado

Cada evento en `statusHistory` debe guardar:

- estado anterior
- estado nuevo
- fecha
- usuario
- rol
- area
- nota o motivo

### Auditoria minima recomendada

```json
{
  "audit": {
    "createdByUserId": "user_001",
    "createdByUserName": "Dr. Nombre",
    "createdByRole": "medico",
    "createdAt": "2026-06-17T10:00:00-06:00",
    "updatedByUserId": "user_010",
    "updatedByUserName": "Psic. Nombre",
    "updatedByRole": "psicologia",
    "updatedAt": "2026-06-18T12:00:00-06:00"
  }
}
```

Reglas:

- no borrar eventos historicos
- no sobreescribir contrarreferencia sin registrar auditoria
- no permitir cambios silenciosos de area destino despues de aceptacion

---

## 14. Estrategia de migracion

Objetivo:

Agregar el modulo sin afectar SASU 2.6.5+45.

### Principios

- no cambiar JWT
- no cambiar Tickets
- no cambiar Agenda Integrada salvo puntos de integracion
- no cambiar Carnet Digital Web en MVP
- no hacer migraciones destructivas
- crear contenedor nuevo `referrals`
- mantener compatibilidad con instalaciones existentes

### Pasos recomendados

1. Crear variables de entorno nuevas solo si son necesarias.
2. Crear contenedor `referrals` en Cosmos con partition key `/student/matricula`.
3. Agregar modelos backend sin tocar modelos existentes.
4. Agregar endpoints bajo `/referrals`.
5. Agregar cliente API en SASU Windows.
6. Agregar pantallas nuevas en SASU Windows.
7. Integrar Agenda solo desde accion "generar cita".
8. Integrar Expediente solo como nueva seccion de timeline.
9. Validar que Agenda, Tickets y Expedientes existentes sigan funcionando.

### Compatibilidad

Si el contenedor `referrals` no existe:

- el modulo debe mostrar error claro de configuracion
- no debe impedir abrir SASU
- no debe impedir Expedientes, Agenda ni Tickets

---

## 15. Riesgos tecnicos y mitigaciones

### Riesgo: consultas cross-partition costosas

Mitigacion:

- usar partition key por matricula para expediente
- limitar filtros globales con paginacion
- usar area y estado como filtros principales

### Riesgo: duplicidad con appointments

Mitigacion:

- guardar IDs cruzados
- bloquear cita activa duplicada por referencia
- validar `appointmentId` antes de crear

### Riesgo: ruptura de modulos existentes

Mitigacion:

- endpoints nuevos bajo `/referrals`
- pantallas nuevas aisladas
- no tocar JWT
- no tocar flujos actuales de Agenda salvo integracion controlada

### Riesgo: permisos demasiado amplios

Mitigacion:

- validar rol y area en backend
- administrador como unica excepcion global
- campus solo como filtro, no como restriccion fuerte

### Riesgo: informacion sensible en notificaciones

Mitigacion:

- mensajes genericos
- no incluir motivo ni observaciones
- abrir detalle solo con permiso

### Riesgo: estados inconsistentes

Mitigacion:

- maquina de estados centralizada en backend
- pruebas unitarias de transiciones
- `statusHistory` obligatorio

### Riesgo: Carnet Digital expone datos prematuramente

Mitigacion:

- no implementar visualizacion de alumno en 2.7.0
- dejar endpoint estudiantil fuera del MVP

---

## 16. Plan de implementacion por fases

### Fase 1 Backend

Objetivo:

Crear base tecnica en FastAPI sin afectar modulos existentes.

Entregables:

- modelos `Referral`, `CounterReferral`, `StatusHistory`
- enums de estados, prioridades, areas y roles
- repositorio Cosmos para `referrals`
- endpoints `/referrals`
- validacion JWT interno existente
- permisos por rol y area
- maquina de estados
- pruebas unitarias backend

### Fase 2 Cosmos

Objetivo:

Preparar almacenamiento seguro.

Entregables:

- contenedor `referrals`
- partition key `/student/matricula`
- validacion de queries principales
- pruebas con documentos de ejemplo
- documentacion de variables si aplica

### Fase 3 SASU Windows

Objetivo:

Crear experiencia operativa interna.

Entregables:

- Bandeja de Referencias
- Nueva Referencia
- Detalle de Referencia
- Contrarreferencia
- cliente API
- filtros
- estados visuales
- permisos visibles por accion
- notificaciones tipo Messenger

### Fase 4 Agenda

Objetivo:

Permitir que una referencia aceptada genere cita.

Entregables:

- accion "Generar cita"
- validacion de cita duplicada
- escritura `appointmentId`
- escritura `referralId`
- transicion a `scheduled`
- verificacion de Agenda existente

### Fase 5 Expediente

Objetivo:

Mostrar trazabilidad en historial del estudiante.

Entregables:

- consulta por matricula
- eventos de timeline
- relacion cita-referencia
- contrarreferencia visible segun permisos
- deduplicacion con citas existentes

### Fase 6 Release

Objetivo:

Liberar SASU 2.7.0 de forma controlada.

Entregables:

- pruebas backend
- pruebas Flutter Windows
- prueba E2E referencia -> cita -> atencion -> contrarreferencia -> cierre
- validacion de no regresion en Agenda, Tickets y Expedientes
- documento de release candidate
- changelog 2.7.0
- tag y release solo con autorizacion

---

## Conclusion tecnica

El modulo de Referencias y Contrarreferencias debe implementarse como una extension aislada y trazable sobre FastAPI, Cosmos DB y SASU Windows.

La coleccion `referrals` con partition key `/student/matricula` permite integrar el modulo con Expedientes sin alterar la base estable de SASU 2.6.5+45.

La integracion con Agenda debe ser relacional y controlada, no una sustitucion del flujo de citas.

La implementacion recomendada para SASU 2.7.0 debe avanzar por fases, priorizando backend, almacenamiento, SASU Windows, Agenda, Expediente y finalmente release controlado.
