# SASU 2.6.3 - Notificaciones de nuevas solicitudes de cita

Fecha: 2026-06-17

## Objetivo

Agregar una notificacion emergente tipo Messenger en SASU Windows cuando llegue una nueva solicitud de cita desde Carnet Digital.

El cambio aplica solo a SASU Windows. No modifica Carnet Digital Web, backend Node, FastAPI, Cosmos DB, endpoints, modelos de datos ni autenticacion.

## Comportamiento implementado

Cuando el dashboard detecta solicitudes con:

```text
status = requested
```

y la cita no fue notificada antes durante la sesion actual, muestra una tarjeta flotante abajo a la derecha.

La notificacion incluye solo datos no sensibles:

```text
Nueva solicitud de cita
Nombre del estudiante
Area solicitada
```

No se muestra motivo clinico, comentario del alumno, CURP, telefono, domicilio ni datos medicos.

## Reglas de sesion

La no repeticion se maneja en memoria de sesion:

```text
Set<String> _notifiedAppointmentIds
```

La misma cita no vuelve a notificarse mientras SASU Windows siga abierto.

## Polling

El dashboard reutiliza el endpoint administrativo de Agenda Integrada:

```text
GET /appointments?status=requested
```

La consulta se ejecuta:

```text
al cargar permisos del dashboard
cada 60 segundos mientras el dashboard esta activo
```

No se implementaron WebSockets en este hotfix.

## UX

La notificacion:

```text
aparece abajo a la derecha
dura 10 segundos
puede cerrarse con X
permite maximo 3 notificaciones visibles
incluye boton Ver solicitud
no bloquea la aplicacion
```

El boton `Ver solicitud` abre Agenda Integrada con filtro de nuevas solicitudes e intenta abrir el detalle de la cita seleccionada.

## Archivos modificados

```text
lib/screens/dashboard_screen.dart
lib/screens/appointments_screen.dart
lib/widgets/appointment_toast.dart
docs/SASU_2_6_3_APPOINTMENT_TOAST_NOTIFICATIONS.md
```

## Pruebas realizadas

```text
flutter analyze lib/screens/dashboard_screen.dart lib/screens/appointments_screen.dart lib/widgets/appointment_toast.dart lib/data/api_service.dart lib/models/appointment_admin_model.dart --no-pub --no-fatal-infos
```

Resultado:

```text
OK sin errores ni warnings bloqueantes.
Solo infos historicos avoid_print en lib/data/api_service.dart.
```

La validacion final de build y publicacion queda registrada en la salida del release 2.6.3.

## Limitaciones

```text
El polling corre desde dashboard, no desde un servicio global en segundo plano.
La notificacion no persiste entre sesiones.
No hay WebSockets ni push notifications nativas.
```

## Pendientes futuros

```text
Servicio global de notificaciones dentro de SASU.
Historial de notificaciones leidas/no leidas.
WebSockets o SignalR para actualizacion en tiempo real.
Preferencias por usuario para sonido/alertas.
```
