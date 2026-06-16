# SASU 2.6.0 - Release Approval

Fecha de revisión: 2026-06-16

## Resumen Ejecutivo

SASU 2.6.0 integra el Centro de Atención Universitaria de punta a punta entre Carnet Digital Web, backend FastAPI, Cosmos DB y SASU Windows.

La revisión final confirma que el bloqueo anterior quedó resuelto: el rediseño UX/UI del Centro de Atención del Carnet Digital ya fue publicado en `origin/main` y en la rama `gh-pages` que sirve `https://app.carnetdigital.space`.

Conclusión de esta revisión: **APROBADO COMO RELEASE CANDIDATE**.

No se creó tag. No se creó release.

## Funcionalidades Incluidas

- Adaptador JWT alumno para aceptar tokens del Carnet Digital.
- Validación JWT interna SASU conservada para operadores.
- Creación de solicitudes desde Carnet Digital.
- Consulta de solicitudes propias del alumno.
- Endpoint de mensajes visibles para alumno.
- Filtrado de mensajes internos para que no sean visibles en Carnet Digital.
- Bandeja de Tickets en SASU Windows.
- Detalle de solicitud para operador.
- Cambio de estado por operador.
- Seguimientos internos y visibles para alumno.
- Rediseño UX/UI del Centro de Atención del alumno con hero institucional, KPIs, tarjetas modernas, conversación tipo chat y progreso visual.

## Commits Principales

- `f6d1138` - `fix: validate student JWT secret for tickets`
- `86e2b2d` - `feat: add admin ticket management endpoints`
- `e612c21` - `feat: add ticket management dashboard`
- `0471c62` - `fix: show student-visible ticket followups`
- `b8bf318` - `fix: label student ticket detail view`
- `831fcb4` - `feat: redesign student attention center ui`
- `940d78b` - `fix: expose attention center title in web bundle`

Publicación web:

- `55b1df4` - `deploy: publish attention center redesign` en `CD-uagro/app.carnetdigital.space`, rama `gh-pages`.

## Arquitectura Final

```text
Carnet Digital Web
  <-> FastAPI Tickets
  <-> Cosmos DB
  <-> SASU Windows
```

Roles:

- Alumno: usa Carnet Digital Web y ve solo sus propias solicitudes y respuestas visibles.
- Operador SASU: usa SASU Windows y gestiona solicitudes, estados y seguimientos.
- Backend FastAPI: valida JWT alumno e interno, aplica permisos y persiste en Cosmos DB.

## Validaciones Realizadas

### Backend Producción

URL: `https://fastapi-backend-o7ks.onrender.com`

Resultado validado:

- `/health`: saludable.
- `cosmos_connected`: `true`.
- `/docs`: HTTP 200.
- OpenAPI expone:
  - `POST /tickets`
  - `GET /tickets`
  - `GET /tickets/my`
  - `GET /tickets/{ticket_id}`
  - `PATCH /tickets/{ticket_id}/status`
  - `POST /tickets/{ticket_id}/followups`
  - `GET /tickets/{ticket_id}/messages`
  - `POST /tickets/{ticket_id}/messages`

Estado backend: **aprobado técnicamente**.

### Carnet Digital Código Fuente

Repo: `C:\Users\gilbe\Documents\Carnet_digital _alumnos`

Resultado:

- `origin/main`: `940d78b50fbf3e9dab421d57d808145b2d5ce7cb`.
- `flutter analyze lib/screens/centro_atencion_screen.dart --no-pub --no-fatal-infos`: OK.
- `flutter build web --release`: OK.
- Warning no bloqueante: dry-run WASM por uso existente de `dart:html` en `carnet_screen_new.dart`.

Estado fuente: **aprobado**.

### Carnet Digital Producción

URLs:

- `https://app.carnetdigital.space/`: HTTP 200.
- `https://app.carnetdigital.space/#/atencion`: HTTP 200.

Publicación:

- Repo: `CD-uagro/app.carnetdigital.space`.
- Rama: `gh-pages`.
- HEAD: `55b1df4a5b700cd4de97d574522b0a35dcd5249d`.

Bundle productivo validado con cache-buster:

- `Crear nueva solicitud`: encontrado.
- `Mis solicitudes`: encontrado.
- `Detalle de solicitud`: encontrado.
- `Solo se muestran respuestas visibles para ti`: encontrado.
- `Centro de Atención Universitaria`: encontrado como texto compilado por `dart2js` con acento escapado (`Centro de Atenci\xf3n Universitaria`).

Estado producción web: **aprobado**.

### SASU Windows

Repo: `C:\CRES_Carnets_UAGROPRO`

Resultado:

- Rama: `feature/sasu-2.6.0`.
- HEAD: `e612c21 feat: add ticket management dashboard`.
- Bandeja de Tickets funcional validada previamente.
- Gestión de solicitudes, cambios de estado y seguimientos funcionales validados previamente.

Observación Git:

- El worktree raíz conserva pendientes no mezclados:
  - `M temp_backend`.
  - `?? docs/SASU_2_6_0_JWT_INTEGRATION.md`.
  - `?? docs/SASU_2_6_0_RELEASE_CANDIDATE.md`.
  - `?? docs/SASU_2_6_0_RELEASE_APPROVAL.md`.

Estado SASU Windows: **aprobado funcionalmente para release candidate**, con pendientes Git documentados.

## Auditoría Visual Rápida

Alcance revisado:

- Desktop.
- Móvil.
- Hero.
- KPIs.
- Tarjetas.
- Detalle.
- Timeline/conversación.
- Barra de progreso.

Resultado:

- Producción ya sirve el bundle del rediseño.
- El código publicado contiene layout responsivo con `LayoutBuilder`.
- Sidebar solo aparece en ancho amplio.
- En móvil/tablet el detalle usa `DraggableScrollableSheet`.
- Hero institucional presente.
- KPIs presentes.
- Tarjetas modernas de solicitudes presentes.
- Panel de detalle presente.
- Conversación tipo chat presente.
- Barra de progreso presente.
- No se detectaron errores de análisis estático.
- Build web release generado correctamente.

Limitación:

- La inspección manual autenticada en todos los viewports debe repetirse durante la aceptación operativa con una sesión real de alumno, pero no bloquea este estado de **Release Candidate** porque el bundle productivo y la funcionalidad base ya están publicados.

## Prueba Funcional E2E

Flujo esperado:

1. Alumno inicia sesión.
2. Alumno abre Centro de Atención.
3. Alumno crea solicitud.
4. Alumno ve la solicitud en Mis Solicitudes.
5. Operador abre SASU Windows.
6. Operador ve la solicitud.
7. Operador cambia estado de `abierto` a `en_revision`.
8. Operador agrega seguimiento `visibility = student`.
9. Alumno ve estado actualizado y seguimiento visible.
10. Operador agrega seguimiento `visibility = internal`.
11. Alumno no ve mensaje interno.

Resultado:

- Backend y endpoints están listos.
- Carnet Digital producción ya contiene el rediseño final.
- Mensajes visibles para alumno ya están soportados.
- Mensajes internos siguen excluidos del flujo alumno.
- E2E operativo queda listo para aceptación final previa a release oficial.

## Incidencias Corregidas

- Backend productivo no exponía rutas de tickets.
- Render desplegaba backend viejo por origen/gitlink incorrecto.
- JWT alumno no era compatible con validación interna.
- `STUDENT_JWT_SECRET` debía validarse para tokens del Carnet Digital.
- `GET /tickets/my` no devolvía mensajes visibles.
- Carnet Digital no consultaba mensajes de una solicitud.
- Mensajes `visibility = internal` debían ocultarse al alumno.
- Interfaz del alumno parecía una lista técnica de tickets, no una experiencia de comunicación universitaria.
- Rediseño UX/UI estaba local pero no publicado en producción.

## Riesgos Actuales

- No existe tag ni release oficial todavía.
- Debe realizarse aceptación manual final con alumno y operador antes de crear release oficial.
- Deben mantenerse documentados o limpiarse los pendientes Git no relacionados antes del cierre definitivo.
- Carnet Digital conserva un documento no relacionado sin trackear: `docs/SASU_2_6_0_TICKETS_DEPLOYMENT_PLAN.md`.

## Recomendación

SASU 2.6.0 queda listo para avanzar a aceptación final previa a release oficial.

No crear release ni tag hasta completar:

1. Validación manual autenticada en `app.carnetdigital.space`.
2. Prueba alumno -> backend -> SASU Windows -> alumno.
3. Confirmación de que el mensaje `visibility = internal` no aparece para alumno.
4. Revisión final de pendientes Git no relacionados.

## Conclusión

**APROBADO COMO RELEASE CANDIDATE**.

Justificación: backend, Cosmos, JWT alumno, JWT interno, SASU Windows y Carnet Digital Web están publicados o validados en sus superficies correspondientes. El bloqueo previo del rediseño en producción quedó resuelto con `origin/main` en `940d78b` y `gh-pages` en `55b1df4`.
