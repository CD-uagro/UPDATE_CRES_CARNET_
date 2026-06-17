# Agenda Integrada SASU / Carnet Digital - Publicacion controlada

Fecha: 2026-06-17

## Resumen

La Agenda Integrada SASU / Carnet Digital fue publicada de forma controlada en los componentes requeridos para operacion productiva.

Flujo publicado:

```text
Carnet Digital Web
-> Backend Node Carnet
-> Cosmos DB appointments
-> Backend FastAPI SASU
-> SASU Windows
```

## Commits publicados

### Backend Node Carnet

Repositorio:

```text
https://github.com/CD-uagro/carnet_alumnos_nodes.git
```

Commit publicado:

```text
d25814b feat: finalize agenda integrada mvp
```

Resultado:

```text
main -> origin/main
```

Validacion productiva:

```http
GET https://carnet-alumnos-nodes.onrender.com/me/appointments
```

Resultado sin token:

```text
401 Unauthorized
```

Esto confirma que el endpoint existe y ya no responde 404.

Variables requeridas en Render:

```text
COSMOS_CONTAINER_APPOINTMENTS=appointments
COSMOS_PK_APPOINTMENTS=/student/matricula
```

SMTP queda pendiente y no bloquea la creacion de citas.

## Backend FastAPI SASU

Repositorio:

```text
https://github.com/CD-uagro/fastapi-backend.git
```

Commit publicado:

```text
8c727c8 feat: finalize agenda integrada mvp
```

Resultado:

```text
main -> origin/main
```

Validaciones locales previas:

```text
python -m py_compile appointment_models.py appointment_repository.py appointment_routes.py main.py
python -m unittest tests.test_ticket_models tests.test_ticket_routes
```

Resultado:

```text
27 tests OK
```

Validacion productiva:

```http
GET https://fastapi-backend-o7ks.onrender.com/health
```

Resultado:

```text
200 OK
status=healthy
cosmos_connected=true
```

OpenAPI productivo contiene:

```text
/appointments
/appointments/{appointment_id}
/appointments/{appointment_id}/confirm
/appointments/{appointment_id}/reschedule
/appointments/{appointment_id}/cancel
/appointments/{appointment_id}/attended
/appointments/{appointment_id}/no-show
```

Prueba sin token:

```http
GET https://fastapi-backend-o7ks.onrender.com/appointments
```

Resultado:

```text
401 Unauthorized
```

Esto confirma que el endpoint existe y exige autenticacion.

Variables requeridas en Render:

```text
COSMOS_CONTAINER_APPOINTMENTS=appointments
COSMOS_PK_APPOINTMENTS=/student/matricula
```

## Carnet Digital Web

Repositorio fuente:

```text
https://github.com/CD-uagro/edukshare-max.github.io.git
```

Commit fuente publicado:

```text
352bb51 feat: finalize agenda integrada mvp
```

Repositorio Pages real:

```text
https://github.com/CD-uagro/app.carnetdigital.space.git
```

Commit Pages publicado:

```text
ef026f1 deploy: publish agenda integrada mvp
```

URL productiva:

```text
https://app.carnetdigital.space
```

Build local ejecutado:

```text
flutter clean
flutter pub get
flutter build web --release
```

Resultado:

```text
Build web OK
```

Verificacion del bundle productivo:

```text
Agenda Universitaria = true
Solicitar atencion = true
/me/appointments = true
Cancelar cita = true
Timeline = true
```

## SASU Windows

Repositorio:

```text
https://github.com/CD-uagro/UPDATE_CRES_CARNET_.git
```

Commits publicados:

```text
327d655 feat: finalize agenda integrada mvp
f0ba899 chore: publish sasu 2.6.2 agenda mvp
```

Rama publicada:

```text
feature/sasu-2.6.0
```

Tag publicado:

```text
v2.6.2
```

Version publicada:

```text
2.6.2+42
```

Instalador generado:

```text
releases/installers/CRES_Carnets_Setup_v2.6.2.exe
```

SHA256:

```text
AFAF9BDE87A4CF71E839E04D5AFA07F8F94FD5C6DFE8C874CD6CDBEED9B42E1A
```

File size:

```text
13986552
```

Release:

```text
https://github.com/CD-uagro/UPDATE_CRES_CARNET_/releases/tag/v2.6.2
```

Asset publicado:

```text
CRES_Carnets_Setup_v2.6.2.exe
```

## Canal de actualizacion

Metadata productiva publicada en:

```http
POST https://fastapi-backend-o7ks.onrender.com/updates/publish
```

Validacion:

```http
GET https://fastapi-backend-o7ks.onrender.com/updates/latest
```

Resultado:

```text
version=2.6.2
build_number=42
download_url=https://github.com/CD-uagro/UPDATE_CRES_CARNET_/releases/download/v2.6.2/CRES_Carnets_Setup_v2.6.2.exe
checksum=AFAF9BDE87A4CF71E839E04D5AFA07F8F94FD5C6DFE8C874CD6CDBEED9B42E1A
file_size=13986552
```

Validacion desde 2.6.1:

```http
POST /updates/check
current_version=2.6.1
current_build=41
```

Resultado:

```text
update_available=true
latest_version=2.6.2
```

Validacion desde 2.6.0:

```http
POST /updates/check
current_version=2.6.0
current_build=40
```

Resultado:

```text
update_available=true
latest_version=2.6.2
```

Validacion desde 2.6.2:

```http
POST /updates/check
current_version=2.6.2
current_build=42
```

Resultado:

```text
update_available=false
```

## Pruebas realizadas

### Tecnicas

```text
Backend Node /me/appointments sin token -> 401
FastAPI /appointments sin token -> 401
FastAPI OpenAPI contiene rutas /appointments
Carnet Digital bundle productivo contiene Agenda Universitaria
SASU Windows instalador 2.6.2 generado
GitHub Release v2.6.2 creado con asset
Updater productivo anuncia 2.6.2 build 42
```

### E2E autenticada

La prueba E2E con alumno real y operador SASU requiere sesion productiva y validacion visual manual:

```text
Alumno crea cita desde app.carnetdigital.space
SASU Windows 2.6.2 lista solicitud en Agenda Integrada
Operador confirma/reprograma/cancela
Alumno ve estado actualizado
```

Queda como paso operativo posterior inmediato, no como bloqueo tecnico de publicacion.

## Pendientes

```text
Configurar SMTP institucional cuando existan credenciales productivas.
Ejecutar prueba E2E autenticada con usuario real y operador SASU.
Monitorear Cosmos appointments durante operacion controlada.
Planificar Referencias y Contrarreferencias en SASU 2.7.0.
```

## Dictamen

```text
AGENDA INTEGRADA SASU / CARNET DIGITAL
PUBLICACION CONTROLADA COMPLETADA

[OK] Backend Node publicado
[OK] FastAPI publicado
[OK] Carnet Digital Web actualizado en app.carnetdigital.space
[OK] SASU Windows instalador generado
[OK] Canal de actualizacion actualizado
[PENDIENTE MANUAL] Prueba E2E autenticada alumno-operador-alumno

Estado:
OPERATIVA EN PRODUCCION CONTROLADA
```
