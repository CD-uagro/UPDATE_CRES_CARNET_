# SASU 2.6.0 - Release Candidate

Fecha de cierre RC: 2026-06-16

## Dictamen

**APROBADO COMO RELEASE CANDIDATE**.

SASU 2.6.0 queda listo para aceptación final previa a tag/release oficial.

No se creó tag.
No se creó release.
No se hizo push desde el repo raíz durante este cierre.

## Alcance Funcional

SASU 2.6.0 integra el Centro de Atención Universitaria con cuatro superficies:

- Carnet Digital Web para alumnos.
- Backend FastAPI Tickets.
- Cosmos DB como persistencia.
- SASU Windows para operadores internos.

Flujo cubierto:

1. Alumno inicia sesión en Carnet Digital.
2. Alumno crea una solicitud.
3. Backend FastAPI valida JWT alumno y guarda en Cosmos.
4. Alumno consulta sus solicitudes.
5. Operador SASU consulta la bandeja en SASU Windows.
6. Operador cambia estado y agrega seguimientos.
7. Alumno ve respuestas con `visibility = student`.
8. Alumno no ve seguimientos `visibility = internal`.

## Commits Finales

Backend FastAPI:

- `0471c62 fix: show student-visible ticket followups`

Carnet Digital:

- `940d78b fix: expose attention center title in web bundle`

Publicación `app.carnetdigital.space`:

- `55b1df4 deploy: publish attention center redesign`

SASU Windows:

- `e612c21 feat: add ticket management dashboard`

Commits base relevantes:

- `f6d1138 fix: validate student JWT secret for tickets`
- `86e2b2d feat: add admin ticket management endpoints`
- `b8bf318 fix: label student ticket detail view`
- `831fcb4 feat: redesign student attention center ui`

## Validación Producción

Backend:

- URL: `https://fastapi-backend-o7ks.onrender.com`
- `/health`: `healthy`.
- `cosmos_connected`: `true`.
- OpenAPI productivo contiene:
  - `POST /tickets`
  - `GET /tickets`
  - `GET /tickets/my`
  - `GET /tickets/{ticket_id}`
  - `PATCH /tickets/{ticket_id}/status`
  - `POST /tickets/{ticket_id}/followups`
  - `GET /tickets/{ticket_id}/messages`
  - `POST /tickets/{ticket_id}/messages`

Carnet Digital Web:

- `https://app.carnetdigital.space/`: HTTP 200.
- `https://app.carnetdigital.space/#/atencion`: HTTP 200.
- Bundle productivo contiene:
  - `Crear nueva solicitud`
  - `Mis solicitudes`
  - `Detalle de solicitud`
  - `Solo se muestran respuestas visibles para ti`
  - `Centro de Atenci\xf3n Universitaria` generado por `dart2js`.

## Validación Técnica

Carnet Digital:

- `flutter analyze lib/screens/centro_atencion_screen.dart --no-pub --no-fatal-infos`: OK.
- `flutter build web --release`: OK.
- Warning no bloqueante: dry-run WASM por uso existente de `dart:html` en `carnet_screen_new.dart`.

Backend:

- `temp_backend` local: `main`.
- HEAD local: `0471c62`.
- Repo remoto directo `CD-uagro/fastapi-backend`: `main` en `0471c62bbd88b251ca9d38bca4c82349f1fcbc7c`.

SASU Windows:

- Rama raíz: `feature/sasu-2.6.0`.
- HEAD: `e612c21`.
- Bandeja de Tickets funcional validada previamente.

## Estado Git Separado

Repo raíz `C:\CRES_Carnets_UAGROPRO`:

- Rama: `feature/sasu-2.6.0`.
- HEAD: `e612c21`.
- Pendientes esperados/documentados:
  - `M temp_backend`
  - `?? docs/SASU_2_6_0_JWT_INTEGRATION.md`
  - `?? docs/SASU_2_6_0_RELEASE_CANDIDATE.md`
  - `?? docs/SASU_2_6_0_RELEASE_APPROVAL.md`
  - `?? docs/SASU_2_6_0_CHANGELOG.md`

Separación:

- `temp_backend` es gitlink actualizado de `59f4031` a `0471c62`.
- Los documentos `SASU_2_6_0_*` pertenecen al cierre y diagnóstico 2.6.0.
- No se mezclaron cambios de código SASU Windows, backend, JWT, Cosmos ni Carnet Digital dentro del repo raíz durante este cierre.

Carnet Digital:

- Rama: `main`.
- HEAD local/remoto: `940d78b`.
- Pendiente no relacionado:
  - `docs/SASU_2_6_0_TICKETS_DEPLOYMENT_PLAN.md`

## Riesgos y Pendientes Antes de Release Oficial

- Ejecutar aceptación manual final con alumno y operador.
- Confirmar en una prueba real que `visibility = internal` no aparece para alumno.
- Decidir si el repo raíz debe commitear el gitlink `temp_backend` apuntando a `0471c62`.
- Decidir si los documentos de cierre se commitean juntos en repo raíz.
- No crear tag ni release hasta que el responsable operativo confirme la prueba E2E final.

## Recomendación Para Tag/Release

Cuando se autorice release oficial:

1. Confirmar `git status` del repo raíz.
2. Stagear solo documentación de cierre y, si se decide, el gitlink `temp_backend`.
3. Crear commit de cierre documental.
4. Repetir prueba E2E alumno -> backend -> SASU Windows -> alumno.
5. Crear tag `v2.6.0` solo después de aceptación manual.
6. Crear release oficial con resumen de cambios y pendientes conocidos.

## Conclusión

SASU 2.6.0 está **listo como Release Candidate**.

El sistema no debe etiquetarse ni liberarse oficialmente hasta completar aceptación manual final y decidir el tratamiento del gitlink `temp_backend` en el repo raíz.
