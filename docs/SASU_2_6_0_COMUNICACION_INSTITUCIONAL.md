# SASU 2.6.0 - Comunicacion Institucional SASU

## 1. Objetivo del modulo

Disenar el modulo de Comunicacion Institucional SASU para permitir continuidad de atencion entre estudiantes/pacientes y profesionales de salud sin compartir telefonos personales ni canales informales.

El modulo debe conectar:

- Carnet Digital Web para estudiantes/pacientes.
- App interna Flutter SASU para profesionales.
- Backend FastAPI.
- Cosmos DB como persistencia institucional.

La fase 2.6.0 debe enfocarse en tickets institucionales, conversacion asociada, asignacion a area/profesional, estados de atencion y registro de enlaces externos de videollamada.

No se desarrollara videollamada nativa en esta fase.

## 2. Problema institucional que resuelve

Actualmente, la continuidad de atencion puede depender de canales personales, conversaciones fuera de SASU o seguimiento manual. Eso genera riesgos:

- Exposicion de telefonos personales.
- Falta de trazabilidad institucional.
- Perdida de historial de solicitudes.
- Dificultad para asignar o reasignar atenciones.
- Saturacion de personal sin priorizacion.
- Falta de evidencia de respuesta institucional.
- Mezcla de informacion clinica, administrativa y operativa en canales no controlados.

Comunicacion Institucional SASU busca crear un canal formal, auditable y segmentado por roles/campus/area.

## 3. Usuarios involucrados

### Estudiante/paciente

Usuario que accede desde Carnet Digital Web y solicita apoyo, seguimiento o informacion.

Acciones:

- Crear solicitud.
- Responder mensajes.
- Consultar estado.
- Recibir indicaciones institucionales.
- Ver enlace externo de videollamada si se programa.

### Psicologia

Profesionales que atienden solicitudes de salud mental, orientacion, seguimiento psicologico y canalizacion.

### Medicina

Profesionales que atienden solicitudes medicas, seguimiento clinico general y orientacion inicial.

### Nutricion

Profesionales que atienden solicitudes nutricionales, seguimiento alimentario y control de avances.

### Vacunacion

Personal que atiende dudas o pendientes relacionados con esquema de vacunacion, aplicaciones y registros.

### Promocion de salud

Personal que atiende solicitudes vinculadas con campanas, actividades preventivas, orientacion general y seguimiento comunitario.

### Atencion estudiantil

Area institucional para apoyo administrativo, canalizacion, orientacion general o coordinacion de servicios.

### Administrador

Usuario con capacidad de supervisar, reasignar, auditar y configurar areas, permisos y estados operativos.

## 4. Flujos funcionales

### 4.1 Estudiante solicita apoyo

1. El estudiante entra a su Carnet Digital Web.
2. Abre la seccion "Solicitar apoyo SASU".
3. Selecciona categoria o area.
4. Captura titulo y descripcion inicial.
5. Acepta aviso de privacidad y advertencia de no usar el canal para emergencias.
6. El sistema crea un ticket.
7. El estudiante ve numero de ticket, estado inicial y mensaje de confirmacion.

Estado inicial recomendado:

- `abierto`

### 4.2 Profesional responde

1. Profesional entra a SASU interno.
2. Abre bandeja de tickets.
3. Filtra por area, campus, prioridad o estado.
4. Abre ticket.
5. Lee descripcion y mensajes.
6. Responde desde SASU.
7. El sistema registra mensaje, usuario, rol y fecha UTC.

Estados posibles despues de responder:

- `en_atencion`
- `pendiente_paciente`

### 4.3 Profesional asigna o reasigna

1. Usuario con permiso abre ticket.
2. Selecciona profesional, rol o area destino.
3. Captura razon opcional de reasignacion.
4. El sistema registra evento de asignacion.
5. El estado pasa a `asignado` o se mantiene en `en_atencion` segun contexto.

### 4.4 Estudiante responde

1. Estudiante entra a Carnet Digital Web.
2. Abre sus solicitudes.
3. Consulta mensajes nuevos.
4. Responde.
5. El ticket actualiza `lastMessageAtUtc`.
6. Si estaba `pendiente_paciente`, puede pasar a `en_atencion` o quedar pendiente de revision profesional.

### 4.5 Profesional programa atencion presencial

1. Profesional abre ticket.
2. Selecciona modo `presencial`.
3. Captura fecha/hora de atencion.
4. Captura indicaciones.
5. El sistema actualiza:
   - `appointmentMode = presencial`
   - `appointmentAtUtc`
   - mensaje automatico opcional.

Nota:

- Esta fase no debe modificar el modulo de citas existente sin aprobacion especifica.

### 4.6 Profesional registra enlace de videollamada

1. Profesional abre ticket.
2. Selecciona modo `virtual`.
3. Pega enlace externo de Google Meet, Teams u otro servicio institucional.
4. Captura fecha/hora.
5. El sistema guarda:
   - `videoCallUrl`
   - `appointmentMode = virtual`
   - `appointmentAtUtc`

No se genera videollamada nativa.

### 4.7 Cierre de ticket

1. Profesional marca ticket como `resuelto`.
2. Puede agregar mensaje final.
3. Despues de validacion o periodo definido, se marca `cerrado`.
4. El ticket conserva historial y mensajes.

Regla recomendada:

- `resuelto` significa que el profesional considera atendido el caso.
- `cerrado` significa que el ticket queda archivado y sin conversacion activa.

## 5. Arquitectura propuesta

### App interna Flutter

Rol:

- Bandeja de tickets.
- Vista por area/profesional.
- Conversacion institucional.
- Asignacion/reasignacion.
- Cambio de estados.
- Registro de cita presencial o enlace externo virtual.

Integracion:

- Nuevo servicio/repository de tickets.
- Nueva pantalla interna.
- Nuevos permisos.
- Integracion ligera en dashboard.

### Carnet Digital Web

Rol:

- Crear solicitud.
- Ver mis tickets.
- Enviar y leer mensajes.
- Ver estado.
- Ver fecha de atencion o enlace externo de videollamada.

Observacion de repositorio:

- En este repo se identifica `web/` como shell Flutter y `temp_backend/admin_panel` como panel administrativo.
- No se identifico una app dedicada de Carnet Digital Web de estudiante dentro de este arbol.
- La implementacion del Carnet Digital Web debe ubicarse antes de programar su vista.

### Backend

Rol:

- API unica para app interna y Carnet Digital Web.
- Validacion de identidad y permisos.
- Control de estados.
- Persistencia en Cosmos.
- Auditoria basica.

Modulo propuesto:

- Rutas `/tickets`.
- Modelos Pydantic.
- Helper de Cosmos para tickets y mensajes.

### Cosmos DB

Contenedores recomendados:

- `tickets`
- `ticket_messages`
- `ticket_events` opcional

Partition keys recomendadas:

- `tickets`: `/campus`
- `ticket_messages`: `/ticketId`
- `ticket_events`: `/ticketId`

Razon:

- La bandeja institucional se consulta por campus/area.
- Los mensajes se consultan por ticket.
- Los eventos/auditoria se consultan por ticket.

### SQLite local

Para SASU interno:

- No recomendado como fuente principal para conversaciones.
- Puede usarse cache local de lectura en una fase posterior.

Para Carnet Digital Web:

- No aplica SQLite local en navegador, salvo storage web minimo.

## 6. Estrategia online/offline

### Opciones

#### A) Solo online contra backend/Cosmos

Ventajas:

- Menor complejidad.
- Evita conflictos de mensajes.
- Mensajes y estados siempre institucionales.
- Mejor para privacidad y auditoria.
- Compatible con Carnet Digital Web.

Desventajas:

- Sin internet no se pueden crear ni responder tickets.
- Depende del backend.

#### B) Offline first con SQLite

Ventajas:

- Profesionales podrian redactar o crear tickets sin conexion.
- Consistente con otros modulos SASU.

Desventajas:

- Alto riesgo de conflictos.
- Mensajeria offline requiere colas, reintentos, ordenamiento y deduplicacion.
- El estudiante web no tendria simetria offline.
- Aumenta riesgo de datos sensibles en equipos compartidos.

#### C) Hibrido

Ventajas:

- Online para conversacion.
- Cache local solo para consulta de ultimos tickets en app interna.
- Permite resiliencia limitada sin duplicar complejidad.

Desventajas:

- Requiere distinguir claramente cache de fuente de verdad.

### Recomendacion

Recomiendo enfoque hibrido con fuente de verdad online.

Para SASU 2.6.0:

- Crear y responder tickets solo online.
- Cosmos/backend como fuente de verdad.
- App interna puede guardar cache temporal de lectura si se justifica, pero no debe crear mensajes offline en MVP.
- No crear tabla Drift en fase inicial salvo que se decida cache local posterior.

Justificacion:

- Comunicacion institucional es multiusuario y sensible.
- El orden de mensajes y estados importa.
- El estudiante participa desde web.
- La sincronizacion offline de mensajes es mas riesgosa que en registros clinicos locales.

## 7. Modelo de datos propuesto

### 7.1 tickets

Campos minimos:

- `id`
- `ticketNumber`
- `studentId`
- `pacienteId`
- `matricula`
- `nombreEstudiante`
- `area`
- `categoria`
- `prioridad`
- `estado`
- `titulo`
- `descripcionInicial`
- `assignedTo`
- `assignedToName`
- `assignedArea`
- `campus`
- `createdBy`
- `createdByRole`
- `createdAtUtc`
- `updatedAtUtc`
- `closedAtUtc`
- `lastMessageAtUtc`
- `videoCallUrl`
- `appointmentMode`
- `appointmentAtUtc`
- `deleted`
- `schemaVersion`

Campos opcionales recomendados:

- `source`: `carnet_web`, `sasu_internal`, `admin`.
- `privacyAcceptedAtUtc`.
- `emergencyDisclaimerAcceptedAtUtc`.
- `resolutionSummary`.
- `closedBy`.
- `lastMessagePreview`.
- `unreadForStudent`.
- `unreadForStaff`.

Estados:

- `abierto`
- `asignado`
- `en_atencion`
- `pendiente_paciente`
- `resuelto`
- `cerrado`

Categorias:

- `psicologia`
- `medicina`
- `nutricion`
- `vacunacion`
- `promocion_salud`
- `soporte_carnet`
- `administrativo`
- `otro`

Prioridades:

- `baja`
- `media`
- `alta`
- `urgente`

Modo de atencion:

- `presencial`
- `virtual`

### 7.2 ticket_messages

Campos minimos:

- `id`
- `ticketId`
- `senderId`
- `senderRole`
- `senderName`
- `message`
- `createdAtUtc`
- `readAtUtc`
- `attachmentUrl`
- `deleted`

Campos opcionales recomendados:

- `messageType`: `text`, `system`, `appointment`, `videocall`, `status_change`.
- `visibleToStudent`: boolean.
- `editedAtUtc`.
- `deletedAtUtc`.
- `metadata`.

Regla:

- Los mensajes de sistema pueden registrar cambios de estado, asignacion o cita.

### 7.3 ticket_assignments opcional

No es obligatorio para MVP si `tickets` contiene `assignedTo`.

Usarlo en 2.7 si se requiere historial formal de asignaciones.

Campos:

- `id`
- `ticketId`
- `assignedFrom`
- `assignedTo`
- `assignedArea`
- `reason`
- `createdAtUtc`
- `createdBy`

### 7.4 ticket_events/audit opcional

Recomendado desde MVP si el costo es bajo, aunque puede implementarse como mensajes de sistema.

Campos:

- `id`
- `ticketId`
- `eventType`
- `actorId`
- `actorRole`
- `actorName`
- `createdAtUtc`
- `metadata`

Eventos:

- `created`
- `assigned`
- `status_changed`
- `message_sent`
- `appointment_set`
- `videocall_set`
- `resolved`
- `closed`

## 8. Endpoints backend propuestos

### Tickets

- `POST /tickets`
- `GET /tickets/my`
- `GET /tickets`
- `GET /tickets/{id}`
- `PATCH /tickets/{id}/status`
- `PATCH /tickets/{id}/assign`
- `PATCH /tickets/{id}/videocall`
- `PATCH /tickets/{id}/appointment`

### Mensajes

- `POST /tickets/{id}/messages`
- `GET /tickets/{id}/messages`
- `PATCH /tickets/{id}/messages/{messageId}/read`

### Auditoria opcional

- `GET /tickets/{id}/events`

### Consideraciones de filtros

`GET /tickets` para personal interno debe aceptar:

- `campus`
- `area`
- `estado`
- `prioridad`
- `categoria`
- `assignedTo`
- `matricula`
- `from`
- `to`
- `limit`
- `continuationToken`

`GET /tickets/my` para estudiante debe devolver solo tickets del estudiante autenticado.

## 9. Seguridad y privacidad

Principios:

- No compartir telefonos personales.
- Solo usuarios autenticados.
- Roles y permisos por area.
- Trazabilidad institucional.
- Historial institucional basico.
- Evitar mensajes anonimos.
- No usar como canal de urgencias o emergencias.

Requisitos:

- Aviso visible: "Este canal no atiende emergencias. En caso de urgencia acude a servicios de emergencia o a la unidad correspondiente."
- Cada mensaje debe guardar autor, rol y fecha UTC.
- Estudiante solo ve sus propios tickets.
- Profesional solo ve tickets de su area/campus, salvo permisos administrativos.
- Administrador puede auditar y reasignar.
- Enlace de videollamada debe ser externo y preferentemente institucional.
- No almacenar contrasenas, tokens ni secretos en mensajes.
- Sanitizar URLs y texto.
- Limitar tamano de mensajes.
- Registrar eventos criticos.

Permisos propuestos:

- `tickets:create`
- `tickets:read`
- `tickets:reply`
- `tickets:assign`
- `tickets:update_status`
- `tickets:manage`

## 10. Riesgos

### Uso clinico indebido como urgencias

Riesgo:

- Estudiantes pueden usar el canal para crisis o emergencia.

Mitigacion:

- Disclaimer obligatorio.
- Categoria "urgente" no debe prometer respuesta inmediata.
- Mensajes de orientacion para emergencias.
- Escalamiento institucional fuera de la app.

### Saturacion de mensajes

Riesgo:

- Profesionales reciben mas solicitudes de las que pueden atender.

Mitigacion:

- Filtros por area, prioridad y estado.
- Asignacion a area antes que a persona.
- Estados claros.
- KPIs de carga.

### Privacidad

Riesgo:

- Mensajes pueden contener datos sensibles.

Mitigacion:

- Autenticacion obligatoria.
- Acceso por rol/campus.
- Auditoria.
- Evitar exportaciones en MVP.
- No enviar datos sensibles a canales externos.

### Notificaciones pendientes

Riesgo:

- Sin push, el usuario puede no ver respuesta a tiempo.

Mitigacion:

- MVP con consulta manual y badges.
- 2.7 puede agregar notificaciones email/push si se aprueba.

### Permisos por campus

Riesgo:

- Un profesional podria ver tickets de otra sede.

Mitigacion:

- Filtrar backend por campus del usuario.
- Admin global solo con permiso especifico.

### Retencion de conversaciones

Riesgo:

- No tener politica de retencion.

Mitigacion:

- No borrar fisicamente en MVP.
- Definir retencion institucional antes de 3.0.
- `deleted` logico solo para ocultar si procede.

### Carga en backend

Riesgo:

- Mensajes frecuentes aumentan lecturas/escrituras en Cosmos.

Mitigacion:

- Paginacion.
- `lastMessageAtUtc` en ticket para ordenar sin leer mensajes.
- Separar `tickets` y `ticket_messages`.

## 11. MVP recomendado para SASU 2.6.0

### Entra en MVP

- Crear ticket desde Carnet Digital Web.
- Bandeja interna SASU para profesionales.
- Ver detalle de ticket.
- Enviar mensajes texto.
- Cambiar estados.
- Asignar a area o profesional.
- Registrar enlace externo de videollamada.
- Registrar cita presencial/virtual como dato del ticket.
- Historial basico mediante mensajes de sistema o eventos.
- Filtros basicos por estado, area, prioridad y campus.

### No entra en MVP

- Videollamada nativa.
- Notificaciones push.
- Adjuntos complejos.
- Mensajes offline.
- Borrado fisico.
- Exportaciones.
- Integracion automatica con modulo de citas.
- Integracion con notas clinicas.
- Analitica avanzada.
- SLA automatizado.

### Queda para 2.7.0

- Notificaciones.
- Mis tickets asignados.
- Plantillas de respuesta.
- Comentarios internos no visibles al estudiante.
- Adjuntos controlados.
- Historial formal de asignaciones.
- Mejoras de panel para carga de trabajo.

## 12. Plan de implementacion por fases y commits

### Fase 1: Contrato y documentacion

Commit:

- `docs: define institutional communication module`

Incluye:

- Documento tecnico.
- Decision de arquitectura.

### Fase 2: Backend base

Commit:

- `feat(tickets): add backend ticket models and routes`

Incluye:

- Modelos Pydantic.
- Contenedores Cosmos.
- Endpoints `POST /tickets`, `GET /tickets/{id}`, `GET /tickets`.

### Fase 3: Mensajes

Commit:

- `feat(tickets): add ticket messages`

Incluye:

- `ticket_messages`.
- `POST /tickets/{id}/messages`.
- `GET /tickets/{id}/messages`.

### Fase 4: Seguridad y permisos

Commit:

- `feat(tickets): add ticket permissions`

Incluye:

- Permisos backend.
- Validacion por campus/area.
- Permisos Flutter.

### Fase 5: App interna Flutter

Commit:

- `feat(tickets): add internal ticket inbox`

Incluye:

- Bandeja.
- Detalle.
- Respuesta.
- Cambio de estado.

### Fase 6: Carnet Digital Web

Commit:

- `feat(tickets): add student ticket portal`

Incluye:

- Crear solicitud.
- Ver mis solicitudes.
- Responder.

Nota:

- Requiere ubicar el proyecto real de Carnet Digital Web antes de implementar.

### Fase 7: Videollamada externa y cita

Commit:

- `feat(tickets): add appointment and videocall fields`

Incluye:

- `appointmentMode`.
- `appointmentAtUtc`.
- `videoCallUrl`.

### Fase 8: Validacion

Commit:

- `test(tickets): cover institutional communication flows`

Incluye:

- Tests backend.
- Tests de parser/mapeo Flutter.
- Verificacion manual app interna + Carnet Web.

## 13. Archivos probablemente modificados

### App interna Flutter

- `lib/data/api_service.dart`
- `lib/data/auth_service.dart`
- `lib/screens/dashboard_screen.dart`
- `lib/screens/tickets/ticket_inbox_screen.dart` nuevo
- `lib/screens/tickets/ticket_detail_screen.dart` nuevo
- `lib/screens/tickets/ticket_compose_screen.dart` nuevo opcional
- `lib/models/ticket.dart` nuevo
- `lib/models/ticket_message.dart` nuevo
- `lib/data/ticket_service.dart` nuevo
- `lib/ui/widgets/ticket_summary_panel.dart` nuevo

No modificar en MVP:

- `lib/data/db.dart`, salvo que se apruebe cache local.
- `lib/data/sync_service.dart`, salvo que se apruebe offline.
- `lib/screens/nueva_nota_screen.dart`.
- `lib/data/recent_activity_service.dart`.
- Updater.

### Carnet Digital Web

Pendiente ubicar repo/app real.

Archivos probables, segun arquitectura del proyecto web:

- Pagina de solicitudes/tickets.
- Servicio API de tickets.
- Componente de conversacion.
- Componente de aviso de emergencia/no urgencias.
- Estado de autenticacion de estudiante.

### Backend

- `temp_backend/main.py`
- `temp_backend/auth_models.py`
- `temp_backend/cosmos_helper.py`
- `temp_backend/README_AUTH.md` si se documentan permisos.
- `.env.example` si existe o se crea sin secretos.

Posible refactor futuro:

- `temp_backend/ticket_models.py`
- `temp_backend/ticket_routes.py`

### Documentacion

- `docs/SASU_2_6_0_COMUNICACION_INSTITUCIONAL.md`
- Documentacion de API.
- Guia de uso para profesionales.
- Aviso para estudiantes.

## 14. Arquitectura recomendada final

Recomendacion final:

- Hibrido con fuente de verdad online.
- Backend/Cosmos como sistema principal.
- App interna sin SQLite para mensajes en MVP.
- Carnet Digital Web online.
- Cache local opcional solo de lectura en una fase posterior.

Motivo:

- Es un modulo conversacional multiusuario.
- La consistencia y trazabilidad son mas importantes que permitir mensajes offline.
- Evita conflictos de orden de mensajes.
- Reduce riesgos de privacidad.
- Permite que estudiante y profesional vean el mismo estado institucional.

## 15. Criterios de exito MVP

- Un estudiante puede crear un ticket desde Carnet Digital Web.
- Un profesional puede ver el ticket en SASU interno.
- Un profesional puede responder.
- El estudiante puede responder.
- El ticket conserva historial institucional.
- El ticket puede asignarse a area/profesional.
- El ticket puede cambiar de estado.
- Puede registrarse enlace externo de videollamada.
- No se usan telefonos personales.
- No se modifican notas clinicas.
- No se requiere videollamada nativa.
