# SASU 2.6.0 - Changelog

Fecha de preparación: 2026-06-16

Estado: **Release Candidate**

## Resumen

SASU 2.6.0 incorpora el Centro de Atención Universitaria como flujo completo Alumno -> Universidad -> Operador SASU -> Alumno.

La versión conecta Carnet Digital Web, backend FastAPI, Cosmos DB y SASU Windows para crear, consultar y atender solicitudes universitarias con control de visibilidad de mensajes.

## Agregado

- Centro de Atención Universitaria en Carnet Digital Web.
- Creación de solicitudes por alumno desde Carnet Digital.
- Consulta de solicitudes propias del alumno.
- Visualización de respuestas visibles para alumno.
- Rediseño UX/UI del Centro de Atención del alumno:
  - Hero institucional.
  - KPIs.
  - Tarjetas modernas.
  - Vista de detalle.
  - Conversación tipo chat.
  - Barra de progreso.
  - Ayuda inmediata.
- Backend FastAPI Tickets:
  - `POST /tickets`
  - `GET /tickets/my`
  - `GET /tickets`
  - `GET /tickets/{ticket_id}`
  - `PATCH /tickets/{ticket_id}/status`
  - `POST /tickets/{ticket_id}/followups`
  - `GET /tickets/{ticket_id}/messages`
  - `POST /tickets/{ticket_id}/messages`
- Adaptador JWT alumno para Carnet Digital.
- Bandeja de Tickets en SASU Windows.
- Detalle de solicitud para operadores SASU.
- Cambio de estado por operador.
- Seguimientos con visibilidad `internal` o `student`.

## Cambiado

- Carnet Digital conserva `https://carnet-alumnos-nodes.onrender.com` para login, carnet y foto.
- Carnet Digital usa `https://fastapi-backend-o7ks.onrender.com` para solicitudes del Centro de Atención.
- El lenguaje visible para alumno prioriza:
  - solicitud
  - seguimiento
  - respuesta
  - apoyo universitario
  - Centro de Atención Universitaria

## Corregido

- Validación de JWT alumno con `STUDENT_JWT_SECRET`.
- Compatibilidad de claims `role`/`rol` y matrícula para alumnos.
- Publicación de endpoints admin completos en producción.
- Lectura de mensajes visibles para alumno desde Carnet Digital.
- Ocultamiento de mensajes `visibility = internal` para alumno.
- Publicación del rediseño final en `app.carnetdigital.space`.

## Validado

- FastAPI producción saludable.
- Cosmos conectado.
- OpenAPI productivo completo para tickets.
- `app.carnetdigital.space` responde HTTP 200.
- `app.carnetdigital.space/#/atencion` responde HTTP 200.
- Bundle productivo contiene señales del rediseño final.
- `flutter analyze` focalizado en Centro de Atención: OK.
- `flutter build web --release`: OK.

## Commits Principales

- Backend: `0471c62 fix: show student-visible ticket followups`
- Carnet Digital: `940d78b fix: expose attention center title in web bundle`
- `app.carnetdigital.space`: `55b1df4 deploy: publish attention center redesign`
- SASU Windows: `e612c21 feat: add ticket management dashboard`

Commits base:

- `f6d1138 fix: validate student JWT secret for tickets`
- `86e2b2d feat: add admin ticket management endpoints`
- `b8bf318 fix: label student ticket detail view`
- `831fcb4 feat: redesign student attention center ui`

## Pendientes Conocidos

- Ejecutar aceptación manual final con alumno y operador.
- Confirmar que un seguimiento `visibility = internal` no aparece para alumno.
- Decidir si el gitlink `temp_backend` actualizado a `0471c62` se commitea en el repo raíz.
- Crear tag y release oficial solo después de autorización explícita.

## Recomendación

Marcar SASU 2.6.0 como **Release Candidate aprobado**.

No crear tag ni release oficial hasta completar la prueba E2E final con usuarios reales o cuentas de validación.
