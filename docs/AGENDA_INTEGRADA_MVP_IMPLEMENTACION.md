# Agenda Integrada MVP - Implementacion

Fecha: 2026-06-16

Estado: implementacion local inicial. No se hizo push, deploy, release ni tag.

## 1. Alcance implementado

Se implemento el MVP de Agenda Integrada usando una coleccion nueva:

```text
appointments
```

El flujo queda separado de las citas legacy `cita_id` para no romper SASU 2.6.1 ni las pantallas actuales de Expedientes.

Arquitectura implementada:

```text
Carnet Digital Web
  -> Backend Node.js del Carnet Digital
  -> Cosmos DB: appointments
  -> Backend FastAPI SASU
  -> SASU Windows
```

## 2. Archivos modificados

### Repo raiz SASU Windows

```text
docs/AGENDA_INTEGRADA_DIAGNOSTICO.md
docs/AGENDA_INTEGRADA_MVP_IMPLEMENTACION.md
lib/data/api_service.dart
lib/models/appointment_admin_model.dart
lib/screens/appointments_screen.dart
lib/screens/dashboard_screen.dart
temp_backend/appointment_models.py
temp_backend/appointment_repository.py
temp_backend/appointment_routes.py
temp_backend/main.py
```

### Carnet Digital Web

```text
lib/main.dart
lib/models/appointment_model.dart
lib/providers/session_provider.dart
lib/screens/citas_screen.dart
lib/services/api_service.dart
```

### Backend Node.js Carnet Digital

```text
config/database.js
index.js
routes/appointments.js
```

## 3. Backend Node.js - endpoints alumno

Se agregaron endpoints bajo `/me`:

```http
POST /me/appointments
GET /me/appointments
GET /me/appointments/:id
PATCH /me/appointments/:id/cancel
```

Validaciones implementadas:

- La matricula se toma del JWT del Carnet Digital.
- No se acepta matricula libre desde Flutter.
- Se busca el carnet por matricula.
- Se compara correo de sesion/usuario con correo del carnet.
- Se valida dominio institucional configurable por:

```text
INSTITUTIONAL_EMAIL_DOMAINS
```

Default:

```text
uagro.mx,uagro.edu.mx
```

- Se evita duplicado activo por matricula + area cuando el estado es:

```text
requested
confirmed
rescheduled
```

- La cancelacion del alumno es logica, no destructiva.
- El alumno solo puede cancelar estados:

```text
requested
confirmed
rescheduled
```

Tambien se agrego `PATCH` a CORS en Node porque la cancelacion usa ese metodo.

## 4. Backend FastAPI SASU - endpoints administrativos

Se agrego router:

```text
appointment_routes.py
```

Endpoints:

```http
GET /appointments
GET /appointments/{appointment_id}
PATCH /appointments/{appointment_id}/confirm
PATCH /appointments/{appointment_id}/reschedule
PATCH /appointments/{appointment_id}/cancel
PATCH /appointments/{appointment_id}/attended
PATCH /appointments/{appointment_id}/no-show
```

Permisos:

- Lectura: `citas:read`
- Cambios: `citas:update`

Motivo:

Estos permisos ya existen en FastAPI para usuarios internos SASU y evitan introducir un sistema paralelo de autorizacion.

Cada cambio de estado agrega entrada en `history` con:

- estado anterior
- estado nuevo
- usuario interno
- rol
- fecha
- mensaje

## 5. Carnet Digital Web

Se agrego modelo:

```text
AppointmentModel
CreateAppointmentRequest
```

Se agregaron metodos en `ApiService`:

```dart
getAppointments(token)
createAppointment(token, request)
cancelAppointment(token, appointmentId)
```

Se extendio `SessionProvider` con:

```dart
appointments
isAppointmentsLoading
appointmentsError
loadAppointments()
createAppointment()
cancelAppointment()
```

Se reemplazo la pantalla existente `citas_screen.dart` por una pantalla "Mis citas" del MVP:

- listado de solicitudes
- estado visible
- boton "Solicitar cita"
- formulario con area, motivo, fecha preferida, bloque manana/tarde y comentario breve
- cancelacion visible solo cuando el estado lo permite
- detalle con historial

Se registro ruta:

```text
/citas
```

La navegacion existente desde `CarnetScreenNew` sigue funcionando porque ya abre `CitasScreen`.

## 6. SASU Windows

Se agrego modelo:

```text
AppointmentAdminModel
```

Se agregaron metodos en `ApiService`:

```dart
getAppointments()
getAppointmentDetail()
updateAppointmentAction()
```

Se creo pantalla:

```text
AppointmentsScreen
```

Funciones:

- bandeja de solicitudes
- filtros por estado, area, campus y matricula
- detalle con historial
- confirmar
- reprogramar
- cancelar
- marcar atendida
- marcar no asistio

Se integro al dashboard como:

```text
Agenda Integrada
```

con permiso local:

```text
citas:read
```

## 7. Decisiones tecnicas

### 7.1 No reutilizar `cita_id` como fuente del MVP

`cita_id` representa citas ya programadas. `appointments` representa solicitudes y su ciclo de vida. Esto evita forzar campos como `inicio` y `fin` cuando el alumno solo esta solicitando atencion.

### 7.2 No borrar citas desde el alumno

La cancelacion se guarda como estado:

```text
cancelled_by_student
```

No se usa `DELETE /me/citas/pasadas`.

### 7.3 No cambiar autenticacion global

El alumno sigue usando el JWT del backend Node.

El operador SASU sigue usando el JWT interno de FastAPI.

### 7.4 No restringir por campus

El campus queda como filtro/metadata. No se usa como bloqueo fuerte de permisos en esta fase.

## 8. Variables y Cosmos

Nueva variable opcional:

```text
COSMOS_CONTAINER_APPOINTMENTS=appointments
```

FastAPI tambien acepta:

```text
COSMOS_PK_APPOINTMENTS=/student/matricula
```

Requisito operativo:

Crear en Cosmos DB el contenedor:

```text
appointments
```

Partition key recomendada:

```text
/student/matricula
```

No se modifico `cita_id`.

## 9. Pruebas realizadas

### Python / FastAPI

```text
python -m py_compile appointment_models.py appointment_repository.py appointment_routes.py main.py
```

Resultado:

```text
OK
```

```text
python -m unittest tests.test_ticket_models tests.test_ticket_routes
```

Resultado:

```text
Ran 27 tests in 0.053s
OK
```

### Node.js

```text
node --check routes/appointments.js
node --check config/database.js
node --check index.js
```

Resultado:

```text
OK
```

### Flutter SASU Windows

Comando:

```text
flutter analyze lib/models/appointment_admin_model.dart lib/screens/appointments_screen.dart lib/data/api_service.dart lib/screens/dashboard_screen.dart --no-pub --no-fatal-infos
```

Resultado:

```text
OK
```

Observacion:

El analizador reporta solo `info` historicos por `print` en `lib/data/api_service.dart`.

### Flutter Carnet Digital Web

Comando:

```text
flutter analyze lib/models/appointment_model.dart lib/screens/citas_screen.dart lib/services/api_service.dart lib/providers/session_provider.dart lib/main.dart --no-pub --no-fatal-infos
```

Resultado:

```text
OK
```

Observacion:

El analizador reporta solo `info` no fatales ya compatibles con el estado actual del proyecto.

### Verificacion OpenAPI local

Se intento importar `main.py` para inspeccionar OpenAPI local, pero el entorno local de Python no tenia disponible `email_validator`, dependencia requerida por `EmailStr` en `auth_models.py`.

El archivo:

```text
temp_backend/requirements.txt
```

si incluye:

```text
email-validator
```

Por lo tanto, el bloqueo corresponde al entorno local de validacion, no al codigo nuevo.

## 10. Pendientes

- Crear contenedor Cosmos `appointments` antes de desplegar.
- Confirmar partition key real del contenedor `appointments`.
- Confirmar si `INSTITUTIONAL_EMAIL_DOMAINS` debe quedar en `uagro.mx,uagro.edu.mx` o incluir otro dominio institucional.
- Probar E2E con alumno real:
  - login Carnet
  - solicitar cita
  - verla en Mis citas
  - verla en SASU Windows
  - confirmar/reprogramar/cancelar
  - validar estado actualizado en Carnet
- Definir si una cita confirmada debe crear registro legacy en `cita_id` en una fase posterior.
- Implementar correos solo cuando exista infraestructura validada.

## 11. Instrucciones para probar

### Backend Node local

1. Configurar Cosmos y JWT como ya usa el backend Carnet.
2. Asegurar contenedor `appointments`.
3. Iniciar Node.
4. Con token de alumno:

```http
POST /me/appointments
GET /me/appointments
GET /me/appointments/:id
PATCH /me/appointments/:id/cancel
```

### FastAPI local

1. Instalar dependencias de `requirements.txt`.
2. Configurar variables Cosmos.
3. Iniciar FastAPI.
4. Con JWT interno SASU:

```http
GET /appointments
PATCH /appointments/{id}/confirm
PATCH /appointments/{id}/reschedule
PATCH /appointments/{id}/cancel
PATCH /appointments/{id}/attended
PATCH /appointments/{id}/no-show
```

### Carnet Digital Web

1. Login como alumno.
2. Abrir "Citas y Consultas" / "Mis citas".
3. Solicitar cita.
4. Confirmar que aparece con estado `requested`.
5. Cancelar si aplica.

### SASU Windows

1. Login como usuario interno con permiso `citas:read`.
2. Abrir "Agenda Integrada".
3. Buscar solicitud.
4. Abrir detalle.
5. Confirmar o reprogramar.

## 12. Fuera de alcance no implementado

- Referencias.
- Contrarreferencias.
- Chat.
- IA.
- Recordatorios avanzados.
- Disponibilidad compleja por slots.
- Deploy.
- Release.
- Tags.
- Migraciones destructivas.

## 13. Estado

Implementacion local lista para revision tecnica y prueba E2E controlada.

No se hizo push.
No se hizo deploy.
No se creo commit.
No se creo release.
