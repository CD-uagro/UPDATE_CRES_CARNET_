# Agenda Integrada MVP - Deploy Backend Node Appointments

Fecha: 2026-06-17

## Objetivo

Publicar de forma controlada solo el backend Node del Carnet Digital para exponer los endpoints de Agenda Universitaria:

```http
GET /me/appointments
POST /me/appointments
PATCH /me/appointments/:id/cancel
```

Backend Render:

```text
https://carnet-alumnos-nodes.onrender.com
```

## Causa inicial

Flutter local apuntaba correctamente a:

```text
https://carnet-alumnos-nodes.onrender.com
```

pero produccion respondia:

```text
GET /me/appointments -> 404 {"success":false,"message":"Endpoint no encontrado"}
POST /me/appointments -> 404 {"success":false,"message":"Endpoint no encontrado"}
PATCH /me/appointments/probe/cancel -> 404 {"success":false,"message":"Endpoint no encontrado"}
```

La causa era que el backend Node productivo aun no tenia publicado el router `routes/appointments.js` ni el registro:

```js
app.use('/me', appointmentsRoutes)
```

## Archivos incluidos en el commit Node

Repositorio:

```text
C:\Users\gilbe\Documents\Carnet_digital _alumnos\carnet_alumnos_nodes
```

Archivos:

```text
config/database.js
index.js
routes/appointments.js
```

## Variables requeridas en Render

```text
COSMOS_ENDPOINT
COSMOS_KEY
COSMOS_DATABASE_ID o COSMOS_DATABASE
COSMOS_CONTAINER_CARNETS
COSMOS_CONTAINER_APPOINTMENTS=appointments
```

Para la coleccion Cosmos `appointments`:

```text
Partition key path: /student/matricula
Partition key value: appointment.student.matricula
```

Nota:

`COSMOS_PK_APPOINTMENTS=/student/matricula` es requisito operativo/documental para crear el contenedor con la particion correcta. El SDK Node no lee esa variable para operar; usa la partition key definida en Cosmos y envia la matricula como valor al actualizar.

## Validaciones previas

Comandos ejecutados:

```text
node --check config/database.js
node --check index.js
node --check routes/appointments.js
```

Resultado:

```text
OK
```

Revision de secretos:

```text
No se encontraron secretos hardcodeados.
Solo hay referencias a variables de entorno como process.env.COSMOS_KEY.
```

## Commit y push

Commit creado:

```text
23cd486 feat: add student appointments endpoints
```

Push:

```text
origin/main
3a02131..23cd486
```

## Verificacion Render

URL probada:

```text
https://carnet-alumnos-nodes.onrender.com/me/appointments
```

Antes del deploy:

```text
404 {"success":false,"message":"Endpoint no encontrado"}
```

Despues del deploy:

```text
401 {"success":false,"message":"Token de acceso requerido"}
```

Interpretacion:

La ruta ya existe en produccion y esta protegida por autenticacion. El resultado esperado sin token es 401/403, no 404.

## Verificacion Flutter local

Se verifico que Flutter Web local esta sirviendo en:

```text
http://localhost:3000
```

Resultado:

```text
localhost:3000 -> 200
flutter_web_detected=true
```

La prueba funcional con sesion de alumno queda lista para ejecutarse manualmente desde la UI local.

## Estado Render

El deploy de Render se reflejo durante la verificacion: los primeros probes respondieron 404 y posteriormente empezaron a responder 401.

Estado:

```text
Router appointments publicado en produccion.
```

## Dictamen

```text
APTO PARA PRUEBA E2E
```

Siguiente paso recomendado:

1. Entrar a `http://localhost:3000`.
2. Iniciar sesion como alumno.
3. Abrir Agenda Universitaria.
4. Crear cita.
5. Confirmar que ya no aparece "Endpoint no encontrado".
6. Si aparece error Cosmos, verificar que el contenedor `appointments` exista con partition key `/student/matricula`.

