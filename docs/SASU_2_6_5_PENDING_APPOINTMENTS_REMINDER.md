# SASU 2.6.5 - Recordatorio horario de citas pendientes

Fecha: 2026-06-17

## Problema operativo

SASU Windows 2.6.3 muestra una notificacion tipo Messenger cuando detecta una nueva solicitud de cita.

En operacion real, la aplicacion puede permanecer abierta durante horas. Si ya existen solicitudes pendientes y el operador no entra a Agenda Integrada, esas citas pueden quedar sin confirmar o reprogramar.

## Solucion implementada

Se agrego un recordatorio acumulado para solicitudes pendientes de cita.

Mientras SASU Windows esta abierto, el dashboard reutiliza el polling existente de:

```text
GET /appointments?status=requested
```

Si existen solicitudes pendientes, muestra una notificacion flotante:

```text
Solicitudes de cita pendientes
Tienes X solicitudes por confirmar o reprogramar.
```

El boton `Ver solicitudes` abre Agenda Integrada con filtro:

```text
requested
```

## Frecuencia

La frecuencia productiva queda definida en codigo:

```dart
static const Duration _pendingAppointmentsReminderInterval = Duration(hours: 1);
```

El recordatorio puede aparecer al iniciar el dashboard si ya existen pendientes y despues como maximo una vez cada hora mientras sigan existiendo.

## Reglas anti-molestia

```text
No se muestra si no hay pendientes.
No se repite antes de una hora.
No se muestra mientras Agenda Integrada esta abierta.
Permite cerrar con X.
No reproduce sonido.
No muestra datos sensibles.
```

## Diferencia con toast de nueva solicitud

El toast individual sigue funcionando:

```text
Nueva solicitud de cita
Nombre del estudiante
Area
```

El recordatorio horario es acumulado:

```text
Solicitudes de cita pendientes
Tienes X solicitudes por confirmar o reprogramar.
```

## Archivos modificados

```text
lib/screens/dashboard_screen.dart
lib/widgets/pending_appointments_reminder_toast.dart
docs/SASU_2_6_5_PENDING_APPOINTMENTS_REMINDER.md
```

## Pruebas realizadas

```text
flutter analyze lib/screens/dashboard_screen.dart lib/widgets/appointment_toast.dart lib/widgets/pending_appointments_reminder_toast.dart lib/screens/appointments_screen.dart --no-pub --no-fatal-infos
```

Resultado:

```text
OK sin errores ni warnings bloqueantes.
```

La compilacion Windows release y publicacion del instalador quedan registradas en el release SASU 2.6.5.

## Limitaciones

```text
El recordatorio se ejecuta desde el dashboard, no como servicio global en segundo plano.
No persiste entre sesiones.
No usa WebSockets.
No tiene sonido ni preferencias por usuario.
```

## Pendientes futuros

```text
Servicio global de notificaciones.
Centro de notificaciones leidas/no leidas.
Preferencias de frecuencia por usuario.
WebSockets o push interno.
```
