# SASU 2.6.0 - Infraestructura Comunicacion Institucional

## 1. Objetivo

Validar la infraestructura minima requerida para continuar con el modulo de Comunicacion Institucional SASU 2.6.0, sin implementar funcionalidades nuevas ni tocar Flutter, Carnet Digital, SQLite, notas clinicas, updater o instalador.

## 2. Estado Cosmos

### Configuracion usada por el modulo tickets

El backend MVP usa `temp_backend/ticket_repository.py`.

Contenedores esperados:

- `COSMOS_CONTAINER_TICKETS`, con fallback `tickets`.
- `COSMOS_CONTAINER_TICKET_MESSAGES`, con fallback `ticket_messages`.

Partition keys esperadas:

- `tickets`: `/campus`.
- `ticket_messages`: `/ticketId`.

Credenciales base usadas por `temp_backend/cosmos_helper.py`:

- `COSMOS_URL`.
- `COSMOS_KEY`.
- `COSMOS_DB`.

### Diagnostico del error `Incorrect padding`

El error ocurre antes de consultar o crear contenedores. La traza proviene del SDK de Azure Cosmos al ejecutar internamente:

`base64.b64decode(master_key)`

Variable afectada:

- `COSMOS_KEY`.

Hallazgos locales seguros:

- `temp_backend/.env` contiene `COSMOS_URL`.
- `temp_backend/.env` contiene `COSMOS_KEY`.
- `temp_backend/.env` no contiene `COSMOS_DB`; contiene `COSMOS_DATABASE`.
- `COSMOS_KEY` local tiene longitud 26.
- `COSMOS_KEY` local no es base64 valido.

Formato esperado:

- `COSMOS_KEY` debe ser la Primary Key o Secondary Key de Azure Cosmos DB.
- Debe ser una cadena base64 valida, normalmente mucho mas larga que 26 caracteres.
- No debe ser endpoint, connection string incompleta, nombre de secreto, placeholder ni valor recortado.

Impacto real:

- El cliente Cosmos no puede inicializarse.
- No se puede verificar existencia fisica de `tickets` ni `ticket_messages`.
- No se puede crear contenedores desde esta maquina con la configuracion local actual.
- El fallo no prueba que los contenedores no existan; solo prueba que la credencial local no es utilizable.

Correccion recomendada:

1. Actualizar el entorno local o de despliegue con `COSMOS_KEY` real de Azure Cosmos DB.
2. Alinear el nombre de base de datos requerido por el backend:
   - Usar `COSMOS_DB=SASU`, o el nombre real de la base.
   - Evitar depender de `COSMOS_DATABASE` si el codigo usa `COSMOS_DB`.
3. Confirmar que `COSMOS_URL` apunte al endpoint de Cosmos, por ejemplo `https://<cuenta>.documents.azure.com:443/`.
4. En Render, confirmar que exista `COSMOS_URL` o ajustar el entorno para que coincida con el codigo. `render.yaml` menciona `COSMOS_ENDPOINT`, mientras `cosmos_helper.py` usa `COSMOS_URL`.
5. No imprimir ni commitear llaves.

### Existencia fisica de contenedores

Resultado de validacion:

- `tickets`: no verificado por credencial local invalida.
- `ticket_messages`: no verificado por credencial local invalida.

No se puede afirmar que existan ni que falten sin una llave valida.

### Procedimiento seguro de verificacion

Ejecutar desde `temp_backend` con variables validas ya cargadas en el entorno, sin imprimir secretos:

```powershell
python -c "from azure.cosmos import CosmosClient; import os; client=CosmosClient(os.environ['COSMOS_URL'], credential=os.environ['COSMOS_KEY']); db=client.get_database_client(os.environ['COSMOS_DB']); names=[c['id'] for c in db.list_containers()]; print('tickets=' + str('tickets' in names)); print('ticket_messages=' + str('ticket_messages' in names))"
```

Si se usan nombres personalizados:

```powershell
python -c "from azure.cosmos import CosmosClient; import os; client=CosmosClient(os.environ['COSMOS_URL'], credential=os.environ['COSMOS_KEY']); db=client.get_database_client(os.environ['COSMOS_DB']); tickets=os.environ.get('COSMOS_CONTAINER_TICKETS','tickets'); messages=os.environ.get('COSMOS_CONTAINER_TICKET_MESSAGES','ticket_messages'); names=[c['id'] for c in db.list_containers()]; print('tickets=' + str(tickets in names)); print('ticket_messages=' + str(messages in names))"
```

### Procedimiento seguro de creacion

Crear solo si la verificacion confirma que faltan. No imprimir secretos.

```powershell
python -c "from azure.cosmos import CosmosClient, PartitionKey; import os; client=CosmosClient(os.environ['COSMOS_URL'], credential=os.environ['COSMOS_KEY']); db=client.get_database_client(os.environ['COSMOS_DB']); tickets=os.environ.get('COSMOS_CONTAINER_TICKETS','tickets'); messages=os.environ.get('COSMOS_CONTAINER_TICKET_MESSAGES','ticket_messages'); db.create_container_if_not_exists(id=tickets, partition_key=PartitionKey(path='/campus')); db.create_container_if_not_exists(id=messages, partition_key=PartitionKey(path='/ticketId')); print('ticket containers ready')"
```

Recomendaciones operativas:

- Ejecutar con una cuenta/llave autorizada a crear contenedores.
- Validar throughput/costo antes de produccion.
- Mantener `tickets` y `ticket_messages` separados.
- No usar `ticketId` como partition key de `tickets`; para bandejas institucionales conviene `/campus`.

## 3. Estado autenticacion

### SASU interno

SASU interno se autentica contra `POST /auth/login` del backend FastAPI.

Flujo actual:

1. Flutter envia `username`, `password` y `campus`.
2. Backend busca usuario en Cosmos con ID `user:{username}@{campus}`.
3. Valida hash de password con bcrypt.
4. Genera JWT con:
   - `sub`: username.
   - `rol`: rol institucional.
   - `campus`: campus.
   - `exp`: expiracion.
5. Flutter guarda el token en almacenamiento seguro y lo envia como `Authorization: Bearer`.

Roles actuales:

- `admin`
- `medico`
- `nutricion`
- `psicologia`
- `odontologia`
- `enfermeria`
- `recepcion`
- `servicios_estudiantiles`
- `lectura`

El MVP de tickets ya agrego permisos `tickets:*` a roles internos, pero no creo un rol nuevo de alumno.

### Carnet Digital

En este arbol no se identifico una app dedicada de Carnet Digital Web de estudiante. El directorio `web/` corresponde al shell web de Flutter, no a un portal de estudiantes con login propio.

Tampoco se identifico un endpoint de autenticacion de alumno separado para Carnet Digital.

Estado:

- Identidad de SASU interno: existe.
- Identidad de estudiante/Carnet Digital: no ubicada en este repo.
- JWT comun estudiante-profesional: no existe todavia.
- Relacion formal alumno-ticket-profesional: aun no existe como tabla/coleccion independiente.

## 4. Estrategia de identidad recomendada

Objetivo:

Alumno -> Ticket -> Profesional, sin compartir credenciales entre sistemas.

### Principio

No mezclar cuentas internas SASU con cuentas de alumnos.

Los profesionales deben seguir usando usuarios internos con roles institucionales. Los alumnos deben usar una identidad de estudiante separada, validada por matricula y por un mecanismo propio del Carnet Digital.

### Propuesta minima

Crear en fase posterior un contrato de identidad de estudiante con estas propiedades:

- `studentId`: ID interno estable del estudiante, si existe.
- `matricula`: identificador funcional obligatorio.
- `nombre`: nombre mostrado.
- `campus`: campus o unidad academica.
- `source`: `carnet_digital`.
- `sub`: sujeto JWT distinto de usuarios internos, por ejemplo `student:{matricula}`.
- `role`: `alumno`.

El ticket debe guardar:

- `createdBy`: sujeto autenticado (`student:{matricula}` o username interno).
- `createdByRole`: `alumno`, `medico`, `psicologia`, etc.
- `matricula`: identificador del alumno.
- `patientId`: opcional, si se enlaza a expediente/carnet.

### JWT comun o JWT separado

Recomendacion:

- Usar un JWT emitido por el mismo backend, pero con claims claramente separados.
- No compartir credenciales ni tabla de usuarios entre alumnos y profesionales.
- El backend puede aceptar ambos tipos de sujeto:
  - Usuarios internos: `sub=username`, `rol=medico/admin/...`.
  - Estudiantes: `sub=student:{matricula}`, `rol=alumno`, `matricula=...`.

Esto permite proteger `/tickets` con una sola dependencia de autenticacion, pero con modelos de identidad separados.

### Tabla o coleccion de relacion

No es obligatoria para el MVP backend actual, pero si se requiere antes de UI de estudiante si el Carnet Digital no tiene identidad verificable.

Opciones:

1. `student_sessions` o `student_identities`:
   - `id`: `student:{matricula}`.
   - `matricula`.
   - `nombre`.
   - `campus`.
   - `createdAtUtc`.
   - `lastAccessAtUtc`.
   - `active`.

2. Resolver identidad desde el carnet existente:
   - Validar matricula contra `carnets`.
   - Emitir token temporal de estudiante.
   - No permitir acciones si la matricula no existe.

Recomendacion:

- Para 2.6.0, usar identidad estudiante separada y token emitido por backend.
- Evitar usar credenciales de profesionales en Carnet Digital.
- Evitar tickets anonimos.

## 5. Riesgos

### Cosmos

- Credencial local invalida bloquea pruebas reales.
- `COSMOS_DATABASE` vs `COSMOS_DB` puede causar fallos al desplegar o probar localmente.
- `COSMOS_ENDPOINT` vs `COSMOS_URL` en Render puede causar inconsistencia si Render no define ambas.
- Contenedores no verificados fisicamente.
- Partition key incorrecta obligaria a recrear contenedores; debe definirse antes de produccion.

### Autenticacion

- No existe identidad de alumno ubicada en el repo.
- Agregar `alumno` al enum interno sin diseno puede mezclar dominios.
- Un JWT comun mal disenado podria permitir escalamiento de privilegios si no separa roles internos de estudiante.
- Los tickets creados por Carnet Digital requieren validacion fuerte de matricula.

### Operacion

- Sin contenedores reales, la UI futura fallara aunque compile.
- Sin portal de estudiante ubicado, no se puede probar el flujo completo Alumno -> Profesional.
- Sin notificaciones en MVP, el seguimiento depende de consulta manual.

### Privacidad

- Los mensajes pueden contener datos sensibles.
- Debe evitarse registrar secretos, tokens, contrasenas o URLs privadas en logs.
- El alumno solo debe ver tickets propios por `matricula`/`studentId`.

## 6. Dependencias antes de construir UI

Obligatorias:

1. Corregir `COSMOS_KEY`.
2. Definir `COSMOS_DB` en entorno local y produccion.
3. Confirmar `COSMOS_URL` en Render o alinear con `COSMOS_ENDPOINT`.
4. Crear/verificar contenedores:
   - `tickets` con `/campus`.
   - `ticket_messages` con `/ticketId`.
5. Definir identidad de estudiante:
   - fuente real del Carnet Digital.
   - claims JWT.
   - permisos de alumno.
6. Definir si `patientId` sera `carnet:<uuid>` o solo opcional.
7. Ejecutar smoke test backend real contra Cosmos.

No obligatorias para MVP:

- WebSockets.
- Push notifications.
- Adjuntos binarios.
- Videollamada nativa.
- SQLite/offline para tickets.

## 7. Requisitos recomendados de smoke test

Con infraestructura corregida:

1. Crear ticket con usuario interno autorizado.
2. Leer `GET /tickets/my`.
3. Leer detalle `GET /tickets/{id}`.
4. Agregar mensaje.
5. Leer mensajes.
6. Asignar ticket.
7. Cambiar estado a `en_atencion`.
8. Registrar cita virtual.
9. Registrar URL externa.
10. Cerrar ticket.
11. Confirmar documentos en Cosmos:
    - ticket en `tickets`.
    - mensajes en `ticket_messages`.
12. Confirmar que un usuario de otro campus recibe 403.

## 8. Recomendacion de siguiente fase

Antes de construir UI:

1. Corregir variables Cosmos y verificar contenedores reales.
2. Ejecutar smoke test backend contra Cosmos real.
3. Disenar e implementar identidad de alumno/Carnet Digital como fase pequena separada.
4. Solo despues iniciar UI interna SASU para bandeja profesional.
5. La UI de Carnet Digital debe esperar hasta ubicar el proyecto real y su mecanismo de autenticacion.

Decision recomendada:

- Continuar primero con infraestructura y smoke test backend.
- Despues implementar identidad de alumno.
- Despues UI profesional SASU.
- Finalmente portal/flujo del estudiante en Carnet Digital.
