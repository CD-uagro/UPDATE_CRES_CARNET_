# SASU 2.6.0 - Release Completed

Fecha de liberación: 2026-06-16 14:58:08 -06:00

Estado: **LIBERADO**

Tag final: `v2.6.0`

Release GitHub:

- `https://github.com/edukshare-max/UPDATE_CRES_CARNET_/releases/tag/v2.6.0`

## Resultado de Aceptación E2E

Resultado: **APROBADO**.

Evidencia operativa confirmada:

1. Alumno inició sesión en Carnet Digital.
2. Alumno abrió Centro de Atención Universitaria.
3. Alumno creó una nueva solicitud.
4. La solicitud apareció en Mis Solicitudes.
5. Operador abrió SASU Windows.
6. Operador abrió Centro de Atención.
7. La solicitud apareció en la bandeja del operador.
8. Operador cambió estado de `abierto` a `en_revision`.
9. Operador agregó seguimiento con `visibility = student`.
10. Alumno abrió el detalle de la solicitud.
11. Alumno confirmó estado actualizado y seguimiento visible.
12. Operador agregó seguimiento con `visibility = internal`.
13. Alumno confirmó que el mensaje interno no aparece.

## Commits Principales

Backend FastAPI:

- `f6d1138 fix: validate student JWT secret for tickets`
- `86e2b2d feat: add admin ticket management endpoints`
- `0471c62 fix: show student-visible ticket followups`

SASU Windows:

- `e612c21 feat: add ticket management dashboard`

Carnet Digital:

- `940d78b fix: expose attention center title in web bundle`

Repo raíz:

- `edeaaa5 docs: close sasu 2.6.0 release candidate`

## URLs de Producción

Carnet Digital:

- `https://app.carnetdigital.space`
- `https://app.carnetdigital.space/#/atencion`

Backend FastAPI:

- `https://fastapi-backend-o7ks.onrender.com`
- `https://fastapi-backend-o7ks.onrender.com/docs`
- `https://fastapi-backend-o7ks.onrender.com/openapi.json`

## Arquitectura Final

```text
Carnet Digital
  <-> FastAPI
  <-> Cosmos DB
  <-> SASU Windows
```

## Alcance Final

- Centro de Atención Universitaria para alumnos en Carnet Digital.
- Creación de solicitudes por alumno.
- Consulta de solicitudes propias.
- Mensajes visibles para alumno.
- Ocultamiento de seguimientos internos.
- Backend FastAPI Tickets en producción.
- Persistencia en Cosmos DB.
- Bandeja de Tickets en SASU Windows.
- Gestión de solicitudes por operador.
- Cambio de estado.
- Seguimientos `student` e `internal`.
- Rediseño UX/UI del Centro de Atención en Carnet Digital.

## Incidencias Corregidas

- Backend productivo sin rutas `/tickets`.
- Render desplegando backend anterior por origen/gitlink incorrecto.
- Incompatibilidad inicial entre JWT alumno y backend tickets.
- Validación de `STUDENT_JWT_SECRET`.
- Falta de endpoint/mapeo de mensajes visibles para alumno.
- Carnet Digital sin lectura de respuestas visibles.
- Exposición incorrecta potencial de mensajes internos.
- Rediseño final del Centro de Atención no publicado inicialmente en `app.carnetdigital.space`.

## Validaciones Finales

Backend:

- FastAPI saludable.
- Cosmos conectado.
- OpenAPI tickets completo.
- Tickets funcionales.
- Seguimientos funcionales.
- Mensajes visibles para alumno funcionales.

Carnet Digital:

- Producción publicada.
- Centro de Atención Universitaria visible.
- Rediseño UX/UI publicado.
- Flujo alumno validado.

SASU Windows:

- Bandeja de Tickets operativa.
- Gestión de solicitudes validada.
- Seguimientos y cambio de estado validados.

## Cierre

SASU 2.6.0 queda liberado oficialmente.

Siguiente etapa: planificación formal de SASU 2.7.0.
