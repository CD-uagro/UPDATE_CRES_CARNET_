# Agenda Integrada MVP - Validacion E2E

Fecha: 2026-06-17

Estado: validacion tecnica previa a publicacion. No se hizo push, deploy, release ni tag.

## 1. Objetivo

Validar el flujo MVP:

```text
Alumno en Carnet Digital Web
-> solicita cita
-> Node crea documento appointments en Cosmos
-> SASU Windows lista solicitud
-> operador confirma/reprograma/cancela
-> FastAPI actualiza estado
-> alumno ve estado actualizado
```

## 2. Variables requeridas

### Backend Node Carnet Digital

Variables esperadas para el MVP:

```text
COSMOS_ENDPOINT
COSMOS_KEY
COSMOS_DATABASE o COSMOS_DATABASE_ID
COSMOS_CONTAINER_CARNETS
COSMOS_CONTAINER_APPOINTMENTS=appointments
JWT_SECRET
INSTITUTIONAL_EMAIL_DOMAINS
```

Resultado local:

```text
COSMOS_ENDPOINT: presente
COSMOS_KEY: presente, pero no utilizable en la .env local verificada
COSMOS_DATABASE: presente
COSMOS_DATABASE_ID: no presente
COSMOS_CONTAINER_CARNETS: presente
COSMOS_CONTAINER_APPOINTMENTS: no presente, el codigo usa default appointments
INSTITUTIONAL_EMAIL_DOMAINS: no presente, el codigo usa default uagro.mx,uagro.edu.mx
```

Observacion:

El codigo Node usa `COSMOS_DATABASE`, no `COSMOS_DATABASE_ID`. Si Render usa `COSMOS_DATABASE_ID`, se debe agregar compatibilidad o configurar tambien `COSMOS_DATABASE`.

### Backend FastAPI SASU

Variables esperadas para el MVP:

```text
COSMOS_ENDPOINT o COSMOS_URL
COSMOS_KEY
COSMOS_DB o COSMOS_DATABASE
COSMOS_CONTAINER_APPOINTMENTS=appointments
COSMOS_PK_APPOINTMENTS=/student/matricula
```

Resultado local:

```text
COSMOS_URL: presente
COSMOS_ENDPOINT: no presente en .env local
COSMOS_KEY: presente
COSMOS_DB/COSMOS_DATABASE: presente
COSMOS_CONTAINER_APPOINTMENTS: no presente, el codigo usa default appointments
COSMOS_PK_APPOINTMENTS: no presente, el codigo usa default /student/matricula
```

Observacion:

El helper FastAPI acepta `COSMOS_URL` o `COSMOS_ENDPOINT`, y `COSMOS_DB` o `COSMOS_DATABASE`. No usa `COSMOS_DATABASE_ID`.

## 3. Estado Cosmos DB

Se ejecuto una verificacion de solo lectura contra Cosmos usando las variables locales disponibles, sin imprimir secretos.

Resultado FastAPI:

```text
appointments exists: false
appointments var presente: false
partition key: no verificable porque el contenedor no existe
```

Resultado Node:

```text
appointments var presente: false
conexion no verificable con la .env local porque COSMOS_KEY no es una key valida
```

Conclusiones Cosmos:

- El contenedor `appointments` no existe en la Cosmos verificada desde la configuracion FastAPI local.
- El codigo no crea el contenedor automaticamente.
- El contenedor debe crearse manualmente antes del deploy controlado.
- Partition key requerida/recomendada: `/student/matricula`.
- FastAPI consulta con cross-partition query habilitado.
- Node consulta por `student.matricula` y actualiza con partition key igual a matricula.

## 4. Prueba backend Node

Endpoints revisados:

```http
GET /me/appointments
POST /me/appointments
GET /me/appointments/:id
PATCH /me/appointments/:id/cancel
```

Validacion estatica:

- Los endpoints estan registrados en `routes/appointments.js`.
- `index.js` monta las rutas con `app.use('/me', appointmentsRoutes)`.
- CORS incluye `PATCH`.
- El alumno autenticado se identifica por `req.user.matricula`.
- El frontend no envia ni controla matricula.
- `POST /me/appointments` construye el documento desde el carnet encontrado por matricula.
- Se intenta validar que el correo de sesion coincida con el correo del carnet usando usuario/carnet.
- Se valida dominio institucional con `INSTITUTIONAL_EMAIL_DOMAINS`, default `uagro.mx,uagro.edu.mx`.
- Se evita duplicado activo por matricula + area para estados `requested`, `confirmed`, `rescheduled`.
- `GET /me/appointments/:id` exige id + matricula del alumno.
- `PATCH /me/appointments/:id/cancel` exige id + matricula del alumno y solo permite cancelar estados activos.

Pruebas ejecutadas:

```text
node --check routes/appointments.js
node --check config/database.js
node --check index.js
```

Resultado:

```text
OK
```

No se ejecuto prueba HTTP real porque falta verificar/crear el contenedor `appointments` y la `.env` local de Node no permite conectar a Cosmos.

## 5. Prueba backend FastAPI

Endpoints revisados:

```http
GET /appointments
GET /appointments/{appointment_id}
PATCH /appointments/{appointment_id}/confirm
PATCH /appointments/{appointment_id}/reschedule
PATCH /appointments/{appointment_id}/cancel
PATCH /appointments/{appointment_id}/attended
PATCH /appointments/{appointment_id}/no-show
```

Validacion estatica:

- `main.py` incluye `appointments_router`.
- `GET /appointments` requiere `citas:read`.
- Acciones `confirm`, `reschedule`, `cancel`, `attended`, `no-show` requieren `citas:update`.
- Cada cambio agrega entrada en `history`.
- Los estados finales no permiten cambios posteriores.
- Las citas inexistentes devuelven 404.
- Las citas cerradas devuelven 409 ante cambios.
- No se usa campus como restriccion fuerte.

Pruebas ejecutadas:

```text
python -m py_compile appointment_models.py appointment_repository.py appointment_routes.py main.py
python -m unittest tests.test_ticket_models tests.test_ticket_routes
```

Resultado:

```text
py_compile: OK
tests: Ran 27 tests, OK
```

No se ejecuto prueba HTTP real porque el contenedor `appointments` no existe en la Cosmos verificada.

## 6. Prueba Carnet Digital Web

Pantalla revisada:

```text
lib/screens/citas_screen.dart
```

Validacion estatica:

- La ruta `/citas` esta registrada en `main.dart`.
- La pantalla muestra "Mis citas".
- El formulario permite seleccionar area.
- El formulario permite elegir fecha preferida.
- El formulario permite elegir bloque manana/tarde.
- `SessionProvider` carga, crea y cancela citas mediante `ApiService`.
- `ApiService` usa:

```http
GET /me/appointments
POST /me/appointments
PATCH /me/appointments/{id}/cancel
```

- La matricula no se envia en el payload.
- El modelo acepta `history`.
- Login, carnet, QR, KPIs y foto no fueron modificados en esta validacion.

Prueba ejecutada:

```text
flutter analyze lib/models/appointment_model.dart lib/screens/citas_screen.dart lib/services/api_service.dart lib/providers/session_provider.dart lib/main.dart --no-pub --no-fatal-infos
```

Resultado:

```text
OK sin errores ni warnings fatales.
19 infos no fatales: deprecations withOpacity/value y use_build_context_synchronously.
```

No se ejecuto prueba UI real porque no hay backend Node + Cosmos appointments operativo para crear documentos.

## 7. Prueba SASU Windows

Pantalla revisada:

```text
lib/screens/appointments_screen.dart
```

Validacion estatica:

- El dashboard integra "Agenda Integrada".
- La visibilidad usa permiso `citas:read`.
- La bandeja consume `GET /appointments`.
- Los filtros implementados son status, area, campus y matricula.
- El detalle abre informacion e historial.
- Las acciones llaman:

```http
PATCH /appointments/{id}/confirm
PATCH /appointments/{id}/reschedule
PATCH /appointments/{id}/cancel
PATCH /appointments/{id}/attended
PATCH /appointments/{id}/no-show
```

- Tickets, expedientes y la agenda/citas legacy no fueron modificados durante esta validacion.

Prueba ejecutada:

```text
flutter analyze lib/models/appointment_admin_model.dart lib/screens/appointments_screen.dart lib/data/api_service.dart lib/screens/dashboard_screen.dart --no-pub --no-fatal-infos
```

Resultado:

```text
OK sin errores ni warnings fatales.
Infos historicos por print en lib/data/api_service.dart.
```

No se ejecuto prueba UI real porque la E2E requiere que Cosmos tenga `appointments`.

## 8. Bugs y bloqueos encontrados

### Bloqueo mayor: contenedor Cosmos faltante

El contenedor `appointments` no existe en la Cosmos verificada desde la configuracion local FastAPI.

Impacto:

- `POST /me/appointments` no podra crear solicitudes.
- `GET /appointments` no podra listar solicitudes.
- El flujo E2E alumno -> Cosmos -> SASU Windows no puede completarse.

Accion requerida antes de deploy controlado:

```text
Crear contenedor Cosmos:
id: appointments
partition key: /student/matricula
```

### Bloqueo operativo: Node local no verificable contra Cosmos

La `.env` local de Node tiene las keys requeridas, pero la `COSMOS_KEY` no fue utilizable para conectar.

Impacto:

- No se pudo validar existencia del contenedor desde Node local.
- No se pudo hacer prueba HTTP real local contra Cosmos.

### Configuracion pendiente: variables explicitas

`COSMOS_CONTAINER_APPOINTMENTS` no esta en las `.env` locales ni en `.env.example`.

Impacto:

- El codigo usa default `appointments`, pero Render/local quedan menos explicitos.

Recomendacion:

- Agregar `COSMOS_CONTAINER_APPOINTMENTS=appointments` en Node y FastAPI.
- Agregar `COSMOS_PK_APPOINTMENTS=/student/matricula` en FastAPI si se quiere dejar la particion explicita.

## 9. Correcciones minimas aplicadas

No se aplicaron correcciones de codigo durante esta validacion.

Motivo:

- El bloqueo encontrado es operativo/configuracion Cosmos, no una falla de logica del MVP.
- Crear contenedores o cambiar variables productivas debe hacerse como paso controlado antes del deploy.

## 10. Archivos modificados durante esta etapa

```text
docs/AGENDA_INTEGRADA_E2E_VALIDACION.md
```

Archivos del MVP ya existentes en estado local:

```text
temp_backend/appointment_models.py
temp_backend/appointment_repository.py
temp_backend/appointment_routes.py
temp_backend/main.py
lib/data/api_service.dart
lib/models/appointment_admin_model.dart
lib/screens/appointments_screen.dart
lib/screens/dashboard_screen.dart
```

Carnet Digital Web:

```text
lib/main.dart
lib/models/appointment_model.dart
lib/providers/session_provider.dart
lib/screens/citas_screen.dart
lib/services/api_service.dart
```

Backend Node:

```text
config/database.js
index.js
routes/appointments.js
```

## 11. Estado Git final observado

Repo raiz SASU:

```text
M lib/data/api_service.dart
M lib/screens/dashboard_screen.dart
M temp_backend
?? docs/AGENDA_INTEGRADA_DIAGNOSTICO.md
?? docs/AGENDA_INTEGRADA_MVP_IMPLEMENTACION.md
?? docs/AGENDA_INTEGRADA_E2E_VALIDACION.md
?? lib/models/appointment_admin_model.dart
?? lib/screens/appointments_screen.dart
```

temp_backend:

```text
M main.py
?? appointment_models.py
?? appointment_repository.py
?? appointment_routes.py
```

Carnet Digital Web:

```text
M lib/main.dart
M lib/providers/session_provider.dart
M lib/screens/citas_screen.dart
M lib/services/api_service.dart
?? docs/SASU_2_6_0_TICKETS_DEPLOYMENT_PLAN.md
?? lib/models/appointment_model.dart
```

Backend Node:

```text
M config/database.js
M index.js
?? routes/appointments.js
```

No se hizo commit.
No se hizo push.
No se hizo deploy.
No se creo tag.
No se creo release.

## 12. Dictamen final

```text
NO APTO PARA DEPLOY
```

Justificacion:

El codigo del MVP pasa validaciones estaticas y mantiene compatibilidad con SASU 2.6.1, pero el flujo E2E no puede validarse ni publicarse de forma segura porque el contenedor Cosmos `appointments` no existe en la configuracion verificada.

Condiciones para cambiar a `APTO PARA DEPLOY CONTROLADO`:

1. Crear/verificar contenedor Cosmos `appointments`.
2. Confirmar partition key `/student/matricula`.
3. Configurar explicitamente `COSMOS_CONTAINER_APPOINTMENTS=appointments` en Node y FastAPI.
4. Confirmar que Node y FastAPI apuntan a la misma base de datos Cosmos.
5. Ejecutar E2E real:
   - alumno crea solicitud
   - SASU Windows la lista
   - operador confirma/reprograma/cancela
   - alumno ve estado actualizado

