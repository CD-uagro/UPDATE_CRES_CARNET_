# SASU 2.7.0 - Referencias y Contrarreferencias

## Documento funcional

Version base estable: `SASU 2.6.5+45`

Documento derivado de:

```text
docs/SASU_2_7_0_REFERENCIAS_DIAGNOSTICO.md
```

Este documento define el comportamiento funcional esperado del modulo de Referencias y Contrarreferencias para SASU 2.7.0.

No modifica codigo.
No crea endpoints.
No modifica FastAPI, Flutter Windows, Flutter Web, Node, Cosmos ni Agenda Integrada.
No implica commit, push, deploy, tag ni release.

---

## 1. Objetivo funcional del modulo

Implementar un flujo institucional y trazable para que las areas SASU puedan referir formalmente a un estudiante hacia otra area de atencion, dar seguimiento a la recepcion, generar una cita cuando aplique, registrar la atencion, emitir una contrarreferencia y cerrar el ciclo dentro del expediente.

El modulo debe resolver funcionalmente estos problemas:

- evitar referencias informales sin evidencia
- conocer que area origino la referencia
- conocer que area debe recibirla
- saber si la referencia fue atendida
- mantener historial institucional del estudiante
- conectar referencia, cita, atencion y contrarreferencia
- evitar recaptura de datos del estudiante
- evitar duplicidad con Agenda Integrada

El objetivo central no es crear una agenda nueva ni un expediente paralelo, sino agregar una capa formal de derivacion entre areas que reutilice Agenda Integrada, Expedientes, autenticacion SASU y notificaciones internas existentes.

---

## 2. Actores

### Medico

Usuario interno SASU que puede detectar necesidades de atencion en otra area, crear referencias, enviarlas, consultar el estado de las referencias originadas por su area, revisar contrarreferencias recibidas y cerrar referencias cuando el ciclo este completo.

### Psicologia

Area interna que puede recibir referencias, aceptarlas, convertirlas en cita, registrar atencion, emitir contrarreferencia y cerrar el ciclo cuando corresponda.

Tambien puede crear referencias hacia otras areas cuando durante la atencion detecte una necesidad adicional.

### Nutricion

Area interna que puede recibir, aceptar, atender y contrarreferir casos relacionados con orientacion o seguimiento nutricional.

Tambien puede originar referencias hacia Medico, Psicologia, Odontologia o Atencion Estudiantil.

### Odontologia

Area interna que puede recibir referencias para valoracion odontologica, aceptar, programar cita, registrar atencion y emitir contrarreferencia.

### Atencion Estudiantil

Area interna que puede recibir referencias de apoyo administrativo, academico o de orientacion universitaria. Puede aceptar referencias, canalizarlas internamente, registrar seguimiento y emitir contrarreferencia funcional.

### Administrador

Usuario con capacidad de supervision institucional. Puede ver todas las referencias, filtrar por area, estado, estudiante y prioridad, auditar historial, reasignar destino si hay error y cancelar referencias justificadas.

No debe alterar evidencia historica ya registrada.

### Alumno

Actor de visualizacion futura limitada.

En SASU 2.7.0 no se recomienda permitir que el alumno cree referencias ni vea detalles clinicos. En una fase posterior podria visualizar solamente informacion general, como:

- que existe una canalizacion institucional
- cita derivada, si aplica
- estado general no sensible
- indicaciones no clinicas autorizadas

---

## 3. Casos de uso

### Crear referencia

Actor principal: area origen.

El usuario interno selecciona al estudiante desde Expedientes o busqueda institucional, elige area destino, prioridad y motivo. La referencia puede guardarse inicialmente como borrador.

Resultado esperado:

- se crea una referencia en estado `draft`
- se conserva estudiante, area origen, usuario creador, area destino, prioridad y motivo
- no se notifica aun al area destino mientras siga en borrador

### Enviar referencia

Actor principal: area origen.

El usuario revisa la informacion minima obligatoria y envia la referencia al area destino.

Resultado esperado:

- el estado cambia de `draft` a `sent`
- se registra evento en historial de estados
- se notifica internamente al area destino
- la referencia aparece en la bandeja del area destino

### Recibir referencia

Actor principal: area destino.

El area destino visualiza la referencia recibida en su bandeja. Al abrirla por primera vez, puede marcarse como recibida.

Resultado esperado:

- el estado cambia de `sent` a `received`
- se registra fecha de recepcion
- se registra usuario que visualizo o recibio la referencia
- el area origen puede ver que la referencia ya fue recibida

### Aceptar referencia

Actor principal: area destino.

El area destino confirma que atendera la referencia.

Resultado esperado:

- el estado cambia de `received` a `accepted`
- se registra evento en historial
- se habilita la opcion de convertir en cita si la atencion requiere programacion
- la referencia queda bajo responsabilidad del area destino

### Convertir referencia en cita

Actor principal: area destino.

Una referencia aceptada puede generar una cita en Agenda Integrada sin recapturar datos del estudiante.

Resultado esperado:

- se crea una cita relacionada en `appointments`
- la referencia guarda `appointmentId`
- la cita guarda `referralId` o equivalente funcional
- la referencia cambia a `scheduled`
- no se crea cita duplicada si ya existe una cita activa ligada a la referencia

### Registrar atencion

Actor principal: area destino.

Despues de atender al estudiante, el usuario marca la referencia como atendida y registra una nota funcional de atencion o resumen interno segun corresponda.

Resultado esperado:

- el estado cambia a `attended`
- se registra fecha de atencion
- se conserva trazabilidad del usuario que marco la atencion
- queda habilitada la contrarreferencia cuando aplique

### Generar contrarreferencia

Actor principal: area destino.

El area destino informa al area origen el resultado institucional de la atencion, recomendaciones o cierre funcional del caso.

Resultado esperado:

- la contrarreferencia queda asociada a la referencia original
- el area origen recibe notificacion interna
- se registra fecha, autor, area y resumen
- el expediente puede mostrar el evento dentro de la linea de tiempo

### Cerrar referencia

Actor principal: area origen o area destino segun configuracion funcional.

Una referencia puede cerrarse cuando el ciclo institucional esta completo: fue atendida, se registro contrarreferencia cuando aplica y no quedan acciones pendientes.

Resultado esperado:

- el estado cambia a `closed`
- se registra usuario, fecha y motivo de cierre
- la referencia queda en modo historico
- no permite cambios operativos salvo auditoria administrativa

### Cancelar referencia

Actor principal: area origen, area destino o administrador, segun estado y permisos.

Se cancela una referencia cuando fue creada por error, el estudiante no requiere atencion, el caso se resolvio por otro canal o la referencia ya no procede.

Resultado esperado:

- el estado cambia a `cancelled`
- se registra motivo obligatorio
- si existe cita relacionada activa, debe evaluarse cancelacion o preservacion segun reglas de Agenda
- la cancelacion queda visible en historial

---

## 4. Pantallas propuestas

### Bandeja de Referencias

Pantalla principal del modulo.

Debe permitir:

- ver referencias recibidas por el area del usuario
- ver referencias enviadas por el area del usuario
- filtrar por estado
- filtrar por prioridad
- filtrar por area origen
- filtrar por area destino
- buscar por matricula
- buscar por nombre del estudiante
- abrir detalle de referencia
- diferenciar visualmente pendientes, urgentes y cerradas

Columnas o tarjetas sugeridas:

- folio o ID corto
- fecha
- estudiante
- matricula
- area origen
- area destino
- prioridad
- estado
- cita relacionada
- ultima actualizacion

### Nueva Referencia

Formulario para crear o enviar una referencia.

Debe permitir:

- buscar o seleccionar estudiante
- mostrar datos basicos del estudiante sin recaptura
- seleccionar area destino
- seleccionar prioridad
- capturar motivo
- capturar observaciones opcionales
- guardar borrador
- enviar referencia

Debe evitar lenguaje tecnico excesivo. La accion principal debe ser clara:

```text
Enviar referencia
```

### Detalle de Referencia

Pantalla de seguimiento integral.

Debe mostrar:

- informacion del estudiante
- area origen
- area destino
- prioridad
- estado actual
- motivo
- observaciones
- cita relacionada, si existe
- historial de cambios de estado
- contrarreferencia, si existe
- acciones permitidas segun rol y estado

Acciones posibles:

- recibir
- aceptar
- generar cita
- registrar atencion
- generar contrarreferencia
- cerrar
- cancelar

### Contrarreferencia

Formulario asociado al detalle de referencia.

Debe permitir registrar:

- resumen de atencion
- recomendaciones
- indicaciones para el area origen
- si requiere seguimiento adicional
- fecha de registro

No debe funcionar como nota clinica completa. Debe ser una respuesta institucional suficiente para cerrar o continuar el ciclo de referencia.

### Timeline en expediente

Vista dentro del expediente del estudiante.

Debe mostrar:

- referencia creada
- referencia enviada
- referencia recibida
- cita generada desde referencia
- atencion registrada
- contrarreferencia emitida
- cierre o cancelacion

El timeline debe integrarse con el historial existente sin sustituir notas, citas ni tickets.

---

## 5. Campos obligatorios y opcionales

### Campos obligatorios

- `id`
- `type`
- `student.matricula`
- `student.nombre`
- `origin.area`
- `origin.userId`
- `origin.userName`
- `origin.role`
- `destination.area`
- `priority`
- `reason`
- `status`
- `createdAt`
- `updatedAt`
- `statusHistory`

### Campos obligatorios para enviar

Para pasar de `draft` a `sent` deben existir:

- estudiante
- matricula
- area origen
- area destino
- prioridad
- motivo

### Campos opcionales

- `student.correo`
- `student.programa`
- `student.campus`
- `student.unidadAcademica`
- `destination.assignedUserId`
- `destination.assignedUserName`
- `observations`
- `receivedAt`
- `acceptedAt`
- `scheduledAt`
- `attendedAt`
- `closedAt`
- `cancelledAt`
- `cancellationReason`
- `appointmentId`
- `counterReferral`
- `attachments`
- `followUpRequired`
- `internalNotes`

### Campos de contrarreferencia

Obligatorios cuando se genera contrarreferencia:

- `counterReferral.responseArea`
- `counterReferral.responseUserId`
- `counterReferral.responseUserName`
- `counterReferral.summary`
- `counterReferral.createdAt`

Opcionales:

- `counterReferral.recommendations`
- `counterReferral.followUpRequired`
- `counterReferral.followUpArea`
- `counterReferral.nextSuggestedAction`

---

## 6. Estados

Estados funcionales permitidos:

```text
draft
sent
received
accepted
scheduled
attended
closed
cancelled
```

Descripcion:

- `draft`: referencia creada pero no enviada
- `sent`: referencia enviada al area destino
- `received`: area destino ya visualizo o registro recepcion
- `accepted`: area destino acepta atender
- `scheduled`: referencia convertida en cita
- `attended`: estudiante atendido
- `closed`: ciclo institucional cerrado
- `cancelled`: referencia cancelada

---

## 7. Reglas de transicion entre estados

Transiciones permitidas:

| Estado actual | Estado siguiente | Regla funcional |
| --- | --- | --- |
| `draft` | `sent` | Requiere estudiante, area destino, prioridad y motivo. |
| `draft` | `cancelled` | Permitido si el borrador ya no procede. |
| `sent` | `received` | El area destino abre o registra recepcion. |
| `sent` | `cancelled` | Permitido con motivo, por origen o administrador. |
| `received` | `accepted` | El area destino acepta atender. |
| `received` | `cancelled` | Permitido con motivo. |
| `accepted` | `scheduled` | Se genera cita relacionada. |
| `accepted` | `attended` | Permitido si la atencion no requiere agenda formal. |
| `accepted` | `cancelled` | Permitido con motivo. |
| `scheduled` | `attended` | La cita relacionada fue atendida o el operador registra atencion. |
| `scheduled` | `cancelled` | Permitido si se cancela el proceso y se documenta motivo. |
| `attended` | `closed` | Requiere contrarreferencia cuando aplique. |
| `attended` | `cancelled` | Solo por administrador y con justificacion excepcional. |
| `closed` | N/A | Estado terminal. |
| `cancelled` | N/A | Estado terminal. |

Reglas generales:

- no permitir saltos de `draft` a `accepted`
- no permitir cerrar una referencia que nunca fue atendida
- no permitir generar cita si la referencia ya tiene cita activa
- no permitir editar destino despues de `accepted`, salvo administrador
- no permitir modificar historico de estados
- registrar cada transicion en `statusHistory`

---

## 8. Permisos por rol y area

### Reglas base

- Los permisos se basan en rol interno SASU y area funcional.
- El campus no debe usarse como restriccion fuerte en esta etapa.
- El campus puede usarse como filtro de consulta.
- El administrador puede auditar todo.
- El alumno no opera el modulo en SASU 2.7.0.

### Permisos por actor

| Actor | Puede crear | Puede recibir | Puede aceptar | Puede generar cita | Puede contrarreferir | Puede cerrar | Puede cancelar |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Medico | Si | Si, si destino es Medico | Si, si destino es Medico | Si | Si | Si, si participa | Si, segun estado |
| Psicologia | Si | Si, si destino es Psicologia | Si | Si | Si | Si, si participa | Si, segun estado |
| Nutricion | Si | Si, si destino es Nutricion | Si | Si | Si | Si, si participa | Si, segun estado |
| Odontologia | Si | Si, si destino es Odontologia | Si | Si | Si | Si, si participa | Si, segun estado |
| Atencion Estudiantil | Si | Si, si destino es Atencion Estudiantil | Si | Si | Si | Si, si participa | Si, segun estado |
| Administrador | Si | Si | Si | Si | Si | Si | Si |
| Alumno | No | No | No | No | No | No | No |

### Visualizacion

- Area origen ve referencias que creo.
- Area destino ve referencias dirigidas a su area.
- Administrador ve todas.
- Alumno queda reservado para visualizacion futura limitada.

---

## 9. Notificaciones internas tipo Messenger

El modulo debe reutilizar el patron visual ya validado en SASU para notificaciones tipo Messenger.

### Nueva referencia recibida

Disparador:

- una referencia cambia a `sent`

Destinatarios:

- usuarios internos autorizados del area destino

Contenido sugerido:

```text
Nueva referencia recibida
Tu area tiene una referencia pendiente de revision.
```

No debe mostrar:

- diagnostico
- motivo clinico completo
- datos sensibles innecesarios

### Contrarreferencia recibida

Disparador:

- se registra `counterReferral`

Destinatarios:

- area origen
- usuario creador, si esta disponible

Contenido sugerido:

```text
Contrarreferencia recibida
Ya hay respuesta del area destino.
```

### Referencia pendiente sin atender

Disparador:

- referencia en `sent`, `received` o `accepted` sin avance dentro del umbral definido

Destinatarios:

- area destino
- administrador, si la demora excede un segundo umbral

Contenido sugerido:

```text
Referencia pendiente
Hay una referencia que requiere seguimiento.
```

Reglas de UX:

- evitar repetir la misma notificacion de forma excesiva
- no mostrar si el usuario ya esta dentro del detalle de esa referencia
- permitir abrir la referencia desde la notificacion
- mantener privacidad en texto emergente

---

## 10. Integracion funcional con Agenda Integrada

Una referencia aceptada puede generar una cita en Agenda Integrada.

Reglas funcionales:

- solo referencias en `accepted` pueden convertirse en cita
- no se deben recapturar datos del estudiante
- la cita debe tomar los datos desde la referencia
- no se debe duplicar cita si ya existe una cita activa para la misma referencia
- se debe guardar relacion `referralId / appointmentId`
- la referencia debe cambiar a `scheduled`
- Agenda Integrada conserva su flujo actual de confirmacion, reprogramacion, cancelacion, atendida y no asistio

Relacion esperada:

```text
referrals.appointmentId -> appointments.id
appointments.sourceType = "referral"
appointments.sourceId = referrals.id
appointments.referralId = referrals.id
```

Validacion contra duplicados:

- si `referrals.appointmentId` existe y apunta a cita activa, no crear otra
- si existe `appointments.sourceType = "referral"` y `sourceId = referral.id`, reutilizar o bloquear creacion duplicada
- si la cita relacionada fue cancelada, permitir crear nueva cita solo con confirmacion explicita

---

## 11. Integracion con expediente

El expediente del estudiante debe mostrar referencias, citas relacionadas y contrarreferencias como linea de tiempo institucional.

Eventos sugeridos:

- referencia creada
- referencia enviada
- referencia recibida
- referencia aceptada
- cita generada desde referencia
- cita atendida
- contrarreferencia emitida
- referencia cerrada
- referencia cancelada

Vista funcional:

```text
Referencias y Contrarreferencias
Fecha
Area origen
Area destino
Estado
Prioridad
Cita relacionada
Contrarreferencia
```

Reglas:

- no duplicar la cita si ya aparece en el timeline clinico
- mostrar relacion entre cita y referencia
- no ocultar notas clinicas existentes
- no reemplazar el historial de notas
- permitir abrir detalle de referencia desde expediente si el rol tiene permiso

---

## 12. Validaciones UX

Validaciones obligatorias:

- motivo obligatorio
- area destino obligatoria
- prioridad obligatoria
- estudiante obligatorio
- no permitir cita duplicada
- no cerrar sin contrarreferencia cuando aplique

Mensajes sugeridos:

```text
Selecciona el estudiante.
Selecciona el area destino.
Indica el motivo de la referencia.
Selecciona la prioridad.
Esta referencia ya tiene una cita relacionada.
Para cerrar esta referencia, registra primero la contrarreferencia.
```

Reglas adicionales:

- no permitir enviar referencia al mismo usuario como unico destino cuando no tenga sentido operativo
- confirmar antes de cancelar
- confirmar antes de cerrar
- advertir si la prioridad es urgente
- mantener lenguaje institucional y humano
- evitar terminos tecnicos innecesarios frente al operador

---

## 13. Riesgos funcionales y mitigaciones

### Riesgo: Exposicion de informacion sensible

Mitigacion:

- no mostrar motivo completo en notificaciones
- limitar detalle por rol y area
- mostrar al alumno solo informacion no sensible en una fase futura

### Riesgo: Duplicidad con Agenda Integrada

Mitigacion:

- la referencia no reemplaza la cita
- la cita no reemplaza la referencia
- usar `referralId / appointmentId`
- bloquear duplicados activos

### Riesgo: Estados inconsistentes

Mitigacion:

- controlar transiciones
- registrar `statusHistory`
- bloquear saltos no permitidos
- mantener estados terminales inmutables

### Riesgo: Sobrecarga de notificaciones

Mitigacion:

- agrupar o espaciar recordatorios
- no repetir mientras el usuario esta atendiendo la referencia
- notificar solo al area correspondiente

### Riesgo: Cierre sin respuesta institucional

Mitigacion:

- exigir contrarreferencia cuando aplique
- registrar motivo si se cierra sin contrarreferencia por excepcion
- permitir auditoria administrativa

### Riesgo: Confusion entre referencia clinica y apoyo administrativo

Mitigacion:

- usar areas y motivos claros
- permitir Atencion Estudiantil como destino funcional
- no obligar campos clinicos en referencias administrativas

---

## 14. Alcance MVP recomendado para SASU 2.7.0

El MVP recomendado debe incluir:

1. Modelo funcional de referencia.
2. Estados y transiciones controladas.
3. Bandeja de Referencias en SASU Windows.
4. Formulario Nueva Referencia.
5. Detalle de Referencia.
6. Recepcion y aceptacion por area destino.
7. Conversion de referencia aceptada en cita de Agenda Integrada.
8. Relacion `referralId / appointmentId`.
9. Registro de atencion.
10. Registro de contrarreferencia.
11. Cierre o cancelacion con historial.
12. Notificaciones internas tipo Messenger.
13. Timeline en expediente.
14. Permisos por rol y area.
15. Validaciones UX minimas.

Este alcance permite liberar valor institucional sin abrir todavia la visualizacion del alumno ni dependencias externas.

---

## 15. Lo que NO se implementara en 2.7.0

No se recomienda implementar en SASU 2.7.0:

- creacion de referencias desde Carnet Digital Web
- visualizacion completa del alumno
- correo automatico
- WhatsApp
- SMS
- notificaciones push moviles
- IA clinica
- recomendaciones automatizadas
- videollamada
- adjuntos avanzados
- firma digital
- expediente compartido fuera de SASU
- cambios en JWT
- cambios destructivos en Cosmos
- migraciones destructivas
- sustitucion de Agenda Integrada
- cambios funcionales en Tickets
- cambios funcionales en Carnet Digital
- reglas fuertes por campus
- flujos de referencia externa a instituciones fuera de UAGro

---

## Conclusion funcional

SASU 2.7.0 debe implementar Referencias y Contrarreferencias como un flujo interno, trazable y conectado con Expedientes y Agenda Integrada.

El modulo debe iniciar en SASU Windows para usuarios internos, con notificaciones tipo Messenger, conversion controlada a cita y contrarreferencia como evidencia institucional.

Carnet Digital queda fuera del MVP operativo, salvo una posible visualizacion futura limitada y no sensible para el alumno.
