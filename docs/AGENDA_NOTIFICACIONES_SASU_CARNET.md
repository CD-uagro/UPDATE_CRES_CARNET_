# Agenda Universitaria - Notificaciones SASU / Carnet Digital

Fecha: 2026-06-17

## Alcance

Se implemento el ajuste de notificaciones para Agenda Universitaria MVP:

- SASU Windows recibe notificacion interna.
- El estudiante recibe confirmacion visual en Carnet Digital.
- El backend Node intenta enviar correo institucional al estudiante.

No se implementaron referencias, contrarreferencias, chat, IA, WebSockets, tags, releases, push ni deploy.

## Que se implemento

### SASU Windows

En el dashboard:

- La tarjeta `Agenda Integrada` muestra badge con contador:

```text
X nuevas
```

- El contador se alimenta consultando:

```http
GET /appointments?status=requested
```

- Al volver desde la bandeja de Agenda, el dashboard refresca el contador.

En la bandeja Agenda Integrada:

- Las solicitudes con `status=requested` se priorizan en la lista.
- Se agrego accion clara:

```text
Nuevas solicitudes
```

- El boton de recarga ahora dice:

```text
Actualizar solicitudes
```

- Si hay solicitudes pendientes al cargar la bandeja, se muestra Snackbar discreto:

```text
Tienes X solicitudes de cita pendientes.
```

- Se agrego polling cada 60 segundos mientras la pantalla Agenda esta abierta.

### Carnet Digital

El flujo visual ya muestra:

```text
Solicitud enviada
Tu solicitud fue registrada correctamente.
El equipo SASU revisara tu solicitud y te notificara cuando sea atendida.
```

Adicionalmente, se evita mostrar en el timeline del alumno eventos internos de sistema relacionados con notificaciones de correo.

### Backend Node Carnet

En `POST /me/appointments`:

- La cita se crea primero en Cosmos.
- Despues se intenta enviar correo al estudiante.
- Si el correo falla, la cita permanece creada.
- El fallo de correo no rompe la respuesta HTTP.
- Se registra evento no destructivo en `appointment.history`.

Eventos posibles:

```json
{
  "event": "student_email_sent",
  "by": "system",
  "note": "Correo de confirmacion enviado al estudiante"
}
```

```json
{
  "event": "student_email_failed",
  "by": "system",
  "note": "No se pudo enviar correo de confirmacion al estudiante"
}
```

Para mantener compatibilidad con la UI existente, el evento tambien conserva campos `from`, `to`, `actor`, `actor_role`, `message` y `created_at`.

## Como se notifica a SASU Windows

SASU Windows no recibe correo.

La notificacion interna es:

- contador en dashboard;
- badge visual en tarjeta Agenda Integrada;
- boton/filtro `Nuevas solicitudes`;
- orden prioritario de solicitudes `requested`;
- Snackbar discreto al cargar la bandeja;
- refresco manual y polling cada 60 segundos.

## Como se notifica al estudiante

El estudiante recibe:

1. Confirmacion visual en Carnet Digital.
2. Correo institucional enviado por Node.

Destinatario preferente:

```text
student.correo_institucional
```

Fallback:

```text
requested_by.email_session
```

El correo no incluye diagnostico, sintomas, notas clinicas, CURP, telefono, domicilio ni datos sensibles.

Contenido informativo:

```text
Area solicitada
Estado: Solicitud enviada
Fecha preferida
Bloque
Indicacion de consultar estado desde Carnet Digital
Advertencia para no responder con datos sensibles
```

## Variables necesarias

Node Carnet Digital:

```env
SMTP_HOST=
SMTP_PORT=
SMTP_SECURE=
SMTP_USER=
SMTP_PASS=
MAIL_FROM=
```

Variables de Agenda ya requeridas:

```env
COSMOS_ENDPOINT=
COSMOS_KEY=
COSMOS_DATABASE_ID= # o COSMOS_DATABASE
COSMOS_CONTAINER_CARNETS=
COSMOS_CONTAINER_APPOINTMENTS=appointments
```

Cosmos:

```text
Container: appointments
Partition key: /student/matricula
```

## Archivos modificados

SASU Windows:

```text
lib/screens/dashboard_screen.dart
lib/screens/appointments_screen.dart
```

Carnet Digital Web:

```text
lib/screens/citas_screen.dart
```

Backend Node Carnet:

```text
package.json
package-lock.json
routes/appointments.js
services/mailService.js
```

Documentacion:

```text
docs/AGENDA_NOTIFICACIONES_SASU_CARNET.md
```

## Pruebas realizadas

Node:

```text
node --check routes/appointments.js
node --check services/mailService.js
node --check config/database.js
```

Resultado:

```text
OK
```

SASU Windows:

```text
flutter analyze lib/screens/appointments_screen.dart lib/screens/dashboard_screen.dart lib/data/api_service.dart --no-pub --no-fatal-infos
```

Resultado:

```text
OK sin errores ni warnings fatales.
Solo infos historicos avoid_print en api_service.dart.
```

Carnet Digital:

```text
flutter analyze lib/screens/citas_screen.dart --no-pub --no-fatal-infos
```

Resultado:

```text
OK sin errores ni warnings fatales.
Solo infos no fatales de deprecaciones y BuildContext async.
```

NPM:

```text
npm install nodemailer@^6.9.14
```

Observacion:

El install reporto vulnerabilidades existentes del arbol npm. No se ejecuto `npm audit fix` para no modificar dependencias fuera del alcance.

## Pendientes

1. Configurar SMTP real en Render sin exponer secretos.
2. Validar envio real de correo con un alumno de prueba.
3. Confirmar que `appointments` existe en Cosmos con partition key `/student/matricula`.
4. Probar E2E:
   - alumno crea cita;
   - correo se intenta enviar;
   - SASU Windows muestra badge;
   - bandeja muestra Snackbar;
   - operador confirma/reprograma/cancela;
   - alumno ve estado actualizado.
5. Decidir si en una fase posterior conviene guardar eventos de notificacion en un campo separado como `notification_history`.

## Estado

```text
LISTO PARA VALIDACION LOCAL Y CONFIGURACION SMTP CONTROLADA
```

