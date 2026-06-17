# Agenda Universitaria UX V2 - Carnet Digital

Fecha: 2026-06-17

## Alcance

Rediseño UX/UI del modulo Agenda Universitaria en Carnet Digital Web, con enfoque en estudiantes de 16 a 22 años.

No se modifico:

- Backend Node.
- FastAPI.
- Cosmos DB.
- JWT.
- Seguridad.
- Roles.
- Endpoints.
- Modelos funcionales.

## Problemas encontrados

1. La pantalla tenia dos acciones principales visibles para lo mismo: boton del banner y boton flotante.
2. Al enviar una solicitud, el feedback era limitado al estado del boton.
3. El alumno podia dudar si la solicitud habia sido enviada.
4. Los estados eran comprensibles pero aun cercanos a lenguaje administrativo.
5. El historial se mostraba como una lista, no como seguimiento visual del proceso.
6. El estado vacio no explicaba con claridad para que servia la Agenda Universitaria.

## Mejoras implementadas

### Flujo de solicitud

Se reforzo el flujo:

```text
Clic en Solicitar atencion
-> overlay "Enviando solicitud..."
-> bloqueo de segundo clic
-> confirmacion "Solicitud enviada"
-> cita visible inmediatamente en la lista
```

### Prevencion de doble envio

Se mantiene `_submitting` en el formulario y se agrego:

- bloqueo del formulario completo con `AbsorbPointer`;
- boton deshabilitado durante envio;
- guard clause para ignorar dobles clics;
- overlay semitransparente con spinner.

### Feedback de exito

Al terminar correctamente se muestra:

```text
Solicitud enviada
Tu solicitud fue registrada correctamente.
El equipo SASU revisara tu solicitud y te notificara cuando sea atendida.
```

### Actualizacion inmediata

`SessionProvider.createAppointment` ahora agrega la cita devuelta por la API directamente a la lista local cuando `data` viene en la respuesta. Si no viene `data`, conserva el fallback de recargar desde backend.

### Eliminacion de duplicidad

Se elimino el boton flotante.

Decision UX:

- Si hay solicitudes existentes, el CTA principal vive en el hero.
- Si no hay solicitudes, el CTA principal vive en el estado vacio.

Asi siempre hay una accion clara, sin duplicar botones flotantes y botones de banner en la misma vista.

### Lenguaje para estudiante

Estados visibles:

```text
requested -> Solicitud enviada
confirmed -> Atencion confirmada
rescheduled -> Fecha reprogramada
attended -> Atencion completada
cancelled_by_student -> Cancelada por ti
cancelled_by_staff -> Cancelada por SASU
no_show -> No asististe
```

Areas visibles:

```text
🏥 Medico
🧠 Psicologia
🥗 Nutricion
🦷 Odontologia
🎓 Atencion estudiantil
```

### Timeline visual

El detalle de solicitud ahora muestra el historial como timeline:

```text
● Solicitud enviada
│
● Atencion confirmada
│
● Atencion completada
```

Cada evento muestra estado, mensaje y fecha.

### Estado vacio

Se reemplazo el mensaje administrativo por una guia clara:

```text
¿Necesitas apoyo?
Puedes solicitar atencion medica, psicologica, nutricional, odontologica o estudiantil.
Nuestro equipo revisara tu solicitud y dara seguimiento.
```

### Colores

Se ajustaron colores suaves por estado:

- Solicitud enviada: amarillo/ambar.
- Atencion confirmada: azul institucional.
- Fecha reprogramada: naranja.
- Atencion completada: verde.
- Canceladas: gris.
- No asististe: rojo suave.

## Capturas descriptivas antes/despues

### Antes

La pantalla se percibia como una lista simple de citas:

- CTA duplicado: banner y boton flotante.
- Envio con poco feedback.
- Historial como lista de movimientos.
- Estado vacio breve y poco orientador.

### Despues

La pantalla se percibe como una guia de acompañamiento universitario:

- Una sola accion principal visible.
- Overlay de envio con spinner.
- Confirmacion clara de exito.
- Tarjeta aparece inmediatamente.
- Detalle con timeline de seguimiento.
- Estado vacio explicativo y orientado a apoyo.

## Archivos modificados

Carnet Digital Web:

```text
lib/screens/citas_screen.dart
lib/providers/session_provider.dart
```

Documentacion:

```text
docs/AGENDA_UNIVERSITARIA_UX_V2.md
```

## Pruebas realizadas

Comando:

```text
flutter analyze lib/screens/citas_screen.dart lib/providers/session_provider.dart --no-pub --no-fatal-infos
```

Resultado:

```text
OK sin errores ni warnings fatales.
```

Observaciones:

- Quedaron 13 `info` no fatales relacionados con `withOpacity`, `DropdownButtonFormField.value` y `use_build_context_synchronously`.
- No se ejecuto deploy.
- No se modifico backend.
- No se modificaron endpoints.

## Pendiente de validacion visual

Validar manualmente en:

- Android.
- Web movil.
- Chrome escritorio.

Checklist visual:

- Sin overflow en hero.
- Sin overflow en tarjetas.
- Modal usable en pantallas pequeñas.
- Overlay visible al enviar.
- Exito visible despues de crear solicitud.
- Timeline legible en detalle.

## Dictamen

```text
UX/UI V2 LISTO PARA VALIDACION VISUAL LOCAL
```

