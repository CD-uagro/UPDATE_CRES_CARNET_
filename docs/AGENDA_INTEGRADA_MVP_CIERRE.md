# Agenda Integrada SASU / Carnet Digital - Cierre MVP

Fecha de cierre: 2026-06-17

## Resumen ejecutivo

La Agenda Integrada SASU / Carnet Digital queda cerrada en version MVP para operacion controlada.

El flujo completo fue estabilizado:

```text
Carnet Digital Web
-> Backend Node
-> Cosmos DB appointments
-> Backend FastAPI
-> SASU Windows
```

El estudiante puede solicitar atencion desde Carnet Digital. La solicitud se registra en Cosmos DB, SASU Windows la recibe en una bandeja interna, el personal puede confirmar, reprogramar, cancelar o marcar la atencion, y el alumno puede consultar el estado actualizado.

SMTP institucional queda preparado como integracion futura y no bloquea la operacion del MVP.

## Objetivo cumplido

Se cumplio el objetivo del MVP:

```text
Alumno
-> Solicita atencion
-> Cosmos appointments
-> SASU recibe solicitud
-> Confirma / Reprograma / Cancela / Atiende
-> Alumno consulta estado actualizado
```

No se implementaron referencias, contrarreferencias, chat, IA ni recordatorios avanzados dentro de esta etapa.

## Arquitectura final

### Carnet Digital Web

Responsabilidades:

- Mostrar el modulo Agenda Universitaria.
- Permitir al alumno consultar sus citas.
- Permitir crear solicitudes de cita.
- Permitir cancelar solicitudes elegibles.
- Consumir el backend Node del Carnet Digital con el JWT del alumno.

### Backend Node Carnet

Responsabilidades:

- Exponer endpoints bajo `/me/appointments`.
- Validar la sesion del alumno.
- Usar la identidad del token y no confiar en matricula enviada por el cliente.
- Crear documentos en Cosmos DB dentro de la coleccion `appointments`.
- Evitar solicitudes activas duplicadas.
- Preparar envio futuro de notificaciones por correo.

### Cosmos DB

Coleccion utilizada:

```text
appointments
```

Partition key esperada por la implementacion:

```text
/student/matricula
```

Estados soportados por el MVP:

```text
requested
confirmed
rescheduled
cancelled_by_student
cancelled_by_staff
attended
no_show
rejected
```

### Backend FastAPI SASU

Responsabilidades:

- Exponer endpoints internos `/appointments`.
- Permitir al personal SASU listar, consultar y gestionar solicitudes.
- Actualizar estado y registrar historial.
- Mantener compatibilidad con autenticacion interna SASU.

### SASU Windows

Responsabilidades:

- Mostrar el modulo Agenda Integrada.
- Listar solicitudes desde FastAPI.
- Filtrar y abrir detalle.
- Confirmar, reprogramar, cancelar, marcar atendida o no asistio.
- Mantener intactos los modulos existentes de Expedientes, Tickets, Notas y Dashboard.

## Componentes entregados

### SASU Windows

- Pantalla de Agenda Integrada.
- Modelo administrativo de citas.
- Consumo de endpoints FastAPI.
- Integracion visual al dashboard.
- Validacion de build Windows release.

### FastAPI SASU

- Modelos de appointment.
- Repositorio Cosmos.
- Rutas `/appointments`.
- Registro de router en `main.py`.
- Validacion sintactica y pruebas existentes sin regresion.

### Carnet Digital Web

- Pantalla Mis Citas / Agenda Universitaria.
- Modelo de appointment para alumno.
- Integracion de rutas Flutter.
- Consumo de endpoints Node.
- Build web release validado.

### Backend Node Carnet

- Router `routes/appointments.js`.
- Servicio de correo preparado.
- Configuracion Cosmos para appointments.
- Validacion sintactica de archivos Node.

## Validaciones realizadas

### FastAPI

```text
python -m py_compile appointment_models.py appointment_repository.py appointment_routes.py main.py
python -m unittest tests.test_ticket_models tests.test_ticket_routes
```

Resultado:

```text
OK - 27 pruebas ejecutadas
```

### Backend Node

```text
node --check config/database.js
node --check index.js
node --check routes/appointments.js
node --check services/mailService.js
```

Resultado:

```text
OK - validacion sintactica completada
```

### SASU Windows

```text
flutter analyze lib/data/api_service.dart lib/models/appointment_admin_model.dart lib/screens/appointments_screen.dart lib/screens/dashboard_screen.dart --no-pub --no-fatal-infos
flutter build windows --release --no-pub
```

Resultado:

```text
OK - sin errores ni warnings bloqueantes
OK - build Windows release generado
```

Notas:

- El analisis reporta solo diagnosticos informativos historicos en `lib/data/api_service.dart`.

### Carnet Digital Web

```text
flutter analyze lib/main.dart lib/models/appointment_model.dart lib/providers/session_provider.dart lib/screens/citas_screen.dart lib/services/api_service.dart --no-pub --no-fatal-infos
flutter build web --release --no-pub
```

Resultado:

```text
OK - sin errores ni warnings bloqueantes
OK - build web release generado
```

Notas:

- El build web JS fue exitoso.
- La prueba de compilacion Wasm reporta una advertencia por uso existente de `dart:html` en `carnet_screen_new.dart`; no bloquea el build web actual.

## Limpieza realizada

- Se retiraron logs temporales excesivos de agenda en el ApiService del Carnet Digital.
- No se modifico logica de negocio.
- No se modificaron endpoints.
- No se cambiaron secretos.
- No se hizo push, deploy, release ni tag.

## Riesgos conocidos

### SMTP institucional

El servicio de correo queda preparado, pero la activacion productiva depende de credenciales y politicas institucionales. No bloquea el MVP.

### Centro de notificaciones

La tabla o coleccion `notification_history` queda como evolucion futura. El MVP no depende de ella para operar.

### Compatibilidad Wasm Flutter

El Carnet Digital compila correctamente para web JS. Existe una advertencia de compatibilidad Wasm por uso historico de `dart:html`; no forma parte del alcance del MVP.

### Operacion controlada

Se recomienda iniciar con operacion controlada antes de ampliar a recordatorios, referencias o flujos mas complejos.

## Recomendaciones para SASU 2.7.0

SASU 2.7.0 debe abrirse como proyecto independiente para:

```text
Referencias
Contrarreferencias
Centro de notificaciones del estudiante
Recordatorios automaticos
SMTP institucional en produccion
```

No se recomienda agregar mas funcionalidades al MVP de Agenda antes de estabilizar operacion real.

## Estado Git documentado

El cierre involucra repositorios separados:

```text
C:\CRES_Carnets_UAGROPRO
C:\CRES_Carnets_UAGROPRO\temp_backend
C:\Users\gilbe\Documents\Carnet_digital _alumnos
C:\Users\gilbe\Documents\Carnet_digital _alumnos\carnet_alumnos_nodes
```

Por esa razon, el cierre tecnico se registra con commits locales separados por repositorio cuando corresponde. No se hizo push, deploy, release ni tag durante este cierre.

## Funcionalidades futuras

```text
SMTP institucional
Centro de notificaciones del estudiante
Referencias
Contrarreferencias
Recordatorios automaticos
```

## Dictamen final

```text
AGENDA INTEGRADA SASU / CARNET DIGITAL
VERSION MVP

ESTADO:
COMPLETADA Y OPERATIVA

Componentes:
[OK] Carnet Digital Web
[OK] Backend Node
[OK] Cosmos DB appointments
[OK] Backend FastAPI
[OK] SASU Windows

Pendientes:
[FUTURO] SMTP institucional
[FUTURO] Centro de notificaciones del estudiante
[FUTURO] Referencias y Contrarreferencias (SASU 2.7.0)

Dictamen:
APTA PARA OPERACION CONTROLADA
```
