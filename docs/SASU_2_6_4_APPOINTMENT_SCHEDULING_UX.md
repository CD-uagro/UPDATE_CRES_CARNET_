# SASU 2.6.4 - UX para confirmar y reprogramar citas

Fecha: 2026-06-17

## Problema detectado

La pantalla de Agenda Integrada permitia confirmar o reprogramar citas, pero solicitaba campos tecnicos:

```text
Inicio ISO UTC
Fin ISO UTC
```

Ese formato no es intuitivo para medicos, psicologos, personal administrativo ni servidores universitarios.

## Mejora implementada

Se reemplazo el formulario tecnico por un dialogo operativo con controles simples:

```text
Fecha
Hora
Duracion
Asignado a
Mensaje opcional
```

Para reprogramar, el dialogo muestra la preferencia original del estudiante y solicita:

```text
Nueva fecha
Nueva hora
Duracion
Motivo de reprogramacion
```

## Comportamiento tecnico

La UI ya no expone fechas ISO al usuario.

Internamente SASU convierte:

```text
fecha + hora + duracion
```

a:

```text
scheduled_start
scheduled_end
```

en ISO UTC compatible con el backend FastAPI existente.

No se modificaron endpoints, modelos backend, Cosmos DB, Carnet Digital, Node ni autenticacion.

## UX agregada

Opciones rapidas de fecha:

```text
Hoy
Manana
Proximo lunes
```

Horas rapidas:

```text
08:00
08:30
09:00
09:30
10:00
10:30
11:00
11:30
12:00
13:00
13:30
14:00
```

Duraciones:

```text
30 min
45 min
60 min
```

Duracion por defecto:

```text
30 min
```

## Validaciones

El dialogo impide continuar si:

```text
no hay fecha
no hay hora
la fecha/hora ya paso
la duracion es invalida
```

Mensajes claros:

```text
Selecciona una fecha valida.
Selecciona una hora de atencion.
La cita no puede programarse en una fecha pasada.
```

## Vista de detalle

La cita programada ahora se muestra en lenguaje humano:

```text
18 de junio de 2026, 09:30 a 10:00
```

No se muestra ISO en el detalle.

## Archivos modificados

```text
lib/screens/appointments_screen.dart
lib/widgets/appointment_schedule_dialog.dart
docs/SASU_2_6_4_APPOINTMENT_SCHEDULING_UX.md
```

## Pruebas realizadas

```text
flutter analyze lib/screens/appointments_screen.dart lib/widgets/appointment_schedule_dialog.dart lib/data/api_service.dart lib/models/appointment_admin_model.dart lib/widgets/appointment_toast.dart --no-pub --no-fatal-infos
```

Resultado:

```text
OK sin errores ni warnings bloqueantes.
Solo infos historicos avoid_print en lib/data/api_service.dart.
```

La validacion final de build Windows y publicacion queda registrada en el release SASU 2.6.4.

## Pendientes

```text
Validacion visual final con una cita real.
Catalogo institucional de responsables para reemplazar el campo libre Asignado a.
Disponibilidad real por agenda/horario del personal.
Deteccion de conflictos de horario en backend.
```
