# SASU 2.6.0 - Checklist de despliegue Render para tickets

Fecha de preparacion: 2026-06-15

Objetivo: preparar el despliegue real del backend de tickets en Render con el menor riesgo posible, sin desplegar, sin push y sin tocar produccion durante esta fase.

## Resumen ejecutivo

El backend local de tickets esta registrado en FastAPI:

- `temp_backend/main.py` importa `ticket_routes.router`.
- `temp_backend/main.py` ejecuta `app.include_router(tickets_router)`.
- `temp_backend/ticket_routes.py` define `APIRouter(prefix="/tickets", tags=["tickets"])`.
- OpenAPI local, verificado con doble aislado de Cosmos, expone 8 paths `/tickets`.
- Los tests unitarios existentes de rutas de tickets pasan: `python -m unittest tests.test_ticket_routes`.

No obstante, el despliegue no debe ejecutarse hasta resolver estos gates:

1. `render.yaml` usa `startCommand: cd temp_backend && python main.py`, pero `main.py` no contiene `uvicorn.run(...)` ni bloque `if __name__ == "__main__"`. Ese comando importa la app y termina; no deja un servidor HTTP corriendo.
2. `Procfile` usa Gunicorn, pero no declara `--bind 0.0.0.0:$PORT`. Render requiere que el servicio web escuche en `0.0.0.0` y recomienda usar la variable `PORT`.
3. `render.yaml` declara `COSMOS_ENDPOINT`, pero el codigo usa `COSMOS_URL` en `temp_backend/cosmos_helper.py`. Render debe tener `COSMOS_URL` definido o el backend fallara al importar.
4. `main.py` requiere `COSMOS_CONTAINER_CARNETS` y `COSMOS_CONTAINER_NOTAS` en importacion. No basta con variables de tickets.

## Archivos revisados

- `render.yaml`
- `temp_backend/render.yaml`
- `temp_backend/Procfile`
- `temp_backend/main.py`
- `temp_backend/ticket_routes.py`
- `temp_backend/ticket_repository.py`
- `temp_backend/cosmos_helper.py`
- `temp_backend/requirements.txt`
- `temp_backend/.env.example`
- `temp_backend/README_TICKETS.md`
- `docs/SASU_2_6_0_COMUNICACION_INFRA.md`

Nota: en este checkout no se encontro `docs/SASU_2_6_0_TICKETS_DEPLOYMENT_PLAN.md` con ese nombre exacto.

## Estado actual de rutas FastAPI

Registro encontrado:

```python
from ticket_routes import router as tickets_router

app.include_router(updates_router)
app.include_router(tickets_router)
```

Router de tickets:

```python
router = APIRouter(prefix="/tickets", tags=["tickets"])
```

Paths esperados en OpenAPI:

- `/tickets`
- `/tickets/my`
- `/tickets/{ticket_id}`
- `/tickets/{ticket_id}/appointment`
- `/tickets/{ticket_id}/assign`
- `/tickets/{ticket_id}/messages`
- `/tickets/{ticket_id}/status`
- `/tickets/{ticket_id}/videocall`

Metodos esperados:

- `POST /tickets`
- `GET /tickets/my`
- `GET /tickets/{ticket_id}`
- `POST /tickets/{ticket_id}/messages`
- `GET /tickets/{ticket_id}/messages`
- `PATCH /tickets/{ticket_id}/assign`
- `PATCH /tickets/{ticket_id}/status`
- `PATCH /tickets/{ticket_id}/appointment`
- `PATCH /tickets/{ticket_id}/videocall`

Todos requieren autenticacion JWT mediante `get_current_user`.

## Comando de arranque recomendado para Render

No usar para produccion:

```bash
cd temp_backend && python main.py
```

No depender del `Procfile` actual sin ajustar bind:

```bash
gunicorn -k uvicorn.workers.UvicornWorker main:app
```

Start Command recomendado en Render:

```bash
cd temp_backend && gunicorn -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:$PORT
```

Alternativa aceptable con Uvicorn directo:

```bash
cd temp_backend && uvicorn main:app --host 0.0.0.0 --port $PORT
```

Preferencia: Gunicorn + UvicornWorker para produccion.

Build Command actual:

```bash
pip install -r temp_backend/requirements.txt
```

Este build command es compatible con el layout actual porque el backend vive en `temp_backend`.

## Variables requeridas en Render

Criticas para que `main.py` importe y arranque:

- `COSMOS_URL`: endpoint real de Azure Cosmos DB. Obligatoria por codigo.
- `COSMOS_KEY`: llave de Azure Cosmos DB.
- `COSMOS_DB`: recomendado, valor esperado `SASU`.
- `COSMOS_DATABASE`: respaldo aceptado por codigo si no existe `COSMOS_DB`.
- `COSMOS_CONTAINER_CARNETS`: contenedor existente de carnets.
- `COSMOS_CONTAINER_NOTAS`: contenedor existente de notas.
- `JWT_SECRET_KEY`: debe ser fijo y secreto; no dejar que se regenere por arranque.

Criticas para tickets:

- `COSMOS_CONTAINER_TICKETS`: recomendado `tickets`.
- `COSMOS_CONTAINER_TICKET_MESSAGES`: recomendado `ticket_messages`.

Requeridas para conservar funcionalidades existentes:

- `COSMOS_CONTAINER_CITAS`: nombre actual del contenedor de citas.
- `COSMOS_PK_CITAS`: partition key actual de citas, normalmente `/id`.
- `COSMOS_CONTAINER_PROMOCIONES_SALUD`: si produccion ya usa promociones.
- `COSMOS_CONTAINER_VACUNACION`: si produccion ya usa vacunacion.
- `COSMOS_CONTAINER_USUARIOS`: default `usuarios`, confirmar si produccion usa otro.
- `COSMOS_CONTAINER_AUDITORIA`: default `auditoria`, confirmar si produccion usa otro.
- `SUPERVISOR_KEY`: si se usan endpoints protegidos por supervisor.

Opcionales / segun entorno:

- `DEBUG_CITAS=false` en produccion.
- `GCAL_ENABLED`
- `GCAL_SA_JSON`
- `GCAL_CALENDAR_ID`
- `APP_TZ`
- `INIT_ADMIN_API_BASE_URL`
- `INIT_ADMIN_PASSWORD`

Gate de variables:

- Si Render solo tiene `COSMOS_ENDPOINT`, agregar tambien `COSMOS_URL` con el mismo valor antes del despliegue.
- No eliminar ni renombrar variables ya existentes del servicio actual.
- Guardar captura o export manual de variables actuales antes de cualquier cambio.

## Cosmos requerido

Base:

- Database: `SASU` o el valor real usado por produccion.

Contenedores existentes necesarios para no romper lo que ya funciona:

- Carnets: valor de `COSMOS_CONTAINER_CARNETS`, partition key esperada por uso actual `/id`.
- Notas: valor de `COSMOS_CONTAINER_NOTAS`, partition key esperada por uso actual `/matricula`.
- Usuarios: valor de `COSMOS_CONTAINER_USUARIOS` o `usuarios`, partition key `/id`.
- Auditoria: valor de `COSMOS_CONTAINER_AUDITORIA` o `auditoria`, partition key `/id`.
- Citas: valor de `COSMOS_CONTAINER_CITAS`, partition key segun `COSMOS_PK_CITAS`.

Contenedores de tickets:

- `tickets`, o valor de `COSMOS_CONTAINER_TICKETS`, con partition key `/campus`.
- `ticket_messages`, o valor de `COSMOS_CONTAINER_TICKET_MESSAGES`, con partition key `/ticketId`.

Validacion previa de Cosmos, desde un entorno con credenciales correctas:

```powershell
cd temp_backend
python -c "from azure.cosmos import CosmosClient; import os; client=CosmosClient(os.environ['COSMOS_URL'], credential=os.environ['COSMOS_KEY']); db=client.get_database_client(os.environ.get('COSMOS_DB') or os.environ.get('COSMOS_DATABASE')); names=[c['id'] for c in db.list_containers()]; required=[os.environ['COSMOS_CONTAINER_CARNETS'], os.environ['COSMOS_CONTAINER_NOTAS'], os.environ.get('COSMOS_CONTAINER_USUARIOS','usuarios'), os.environ.get('COSMOS_CONTAINER_AUDITORIA','auditoria'), os.environ.get('COSMOS_CONTAINER_TICKETS','tickets'), os.environ.get('COSMOS_CONTAINER_TICKET_MESSAGES','ticket_messages')]; print({name: name in names for name in required})"
```

No crear contenedores automaticamente durante el despliegue real si no se aprobo antes. Si faltan `tickets` o `ticket_messages`, crearlos en una ventana separada y validarlos antes del deploy.

## CORS requerido

Estado actual:

```python
allow_origins=["*"]
allow_credentials=True
allow_methods=["*"]
allow_headers=["*"]
```

Para este despliegue de tickets, CORS no bloquea el uso desde Flutter o web porque esta abierto. No cambiar CORS durante este despliegue. Endurecer origenes debe ser una tarea separada, con pruebas de login, carnets, notas, citas y tickets.

## Checklist antes de desplegar

1. Confirmar que no se va a desplegar automaticamente.

```powershell
git status --short
git rev-parse --short HEAD
```

2. Confirmar que los cambios pendientes son solo los esperados para el despliegue de tickets.

```powershell
git diff --name-only
git diff --stat
```

3. Confirmar rutas locales de tickets.

```powershell
cd temp_backend
$env:PYTHONIOENCODING='utf-8'
python -m unittest tests.test_ticket_routes
```

Resultado esperado:

```text
Ran 5 tests
OK
```

4. Confirmar OpenAPI local.

Si el entorno local tiene dependencias instaladas y Cosmos accesible:

```powershell
cd temp_backend
$env:PYTHONIOENCODING='utf-8'
python -c "import main; print('\n'.join(sorted([p for p in main.app.openapi()['paths'] if p.startswith('/tickets')])))"
```

Resultado esperado: los 8 paths listados en "Estado actual de rutas FastAPI".

5. Confirmar start command en Render antes de deploy.

Valor requerido:

```bash
cd temp_backend && gunicorn -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:$PORT
```

6. Confirmar health check.

Valor requerido:

```text
/health
```

7. Confirmar variables en Render.

Minimo bloqueante:

- `COSMOS_URL`
- `COSMOS_KEY`
- `COSMOS_DB` o `COSMOS_DATABASE`
- `COSMOS_CONTAINER_CARNETS`
- `COSMOS_CONTAINER_NOTAS`
- `COSMOS_CONTAINER_TICKETS`
- `COSMOS_CONTAINER_TICKET_MESSAGES`
- `JWT_SECRET_KEY`

8. Confirmar contenedores Cosmos.

- `tickets` existe con partition key `/campus`.
- `ticket_messages` existe con partition key `/ticketId`.
- No se va a reutilizar un contenedor de carnets/notas/citas para tickets.

9. Confirmar URLs que se revisaran al terminar.

- `https://fastapi-backend-o7ks.onrender.com/health`
- `https://fastapi-backend-o7ks.onrender.com/openapi.json`
- `https://fastapi-backend-o7ks.onrender.com/docs`
- `https://fastapi-backend-o7ks.onrender.com/auth/login`
- `https://fastapi-backend-o7ks.onrender.com/tickets/my`

10. Congelar plan de rollback antes de presionar deploy.

- Identificar ultimo deploy exitoso actual en Render.
- Guardar commit SHA actual de produccion.
- Guardar start command actual.
- Guardar snapshot manual de variables de entorno.
- Confirmar quien autoriza rollback si falla postdeploy.

## Pasos exactos para el despliegue real cuando se autorice

No ejecutar en esta fase. Este es el procedimiento futuro.

1. Preparar rama/commit de despliegue.

```powershell
git status --short
git rev-parse --short HEAD
```

2. Si se decide corregir configuracion versionada, preparar un commit separado que ajuste `render.yaml` y, opcionalmente, `temp_backend/Procfile`.

Valores esperados:

```yaml
startCommand: cd temp_backend && gunicorn -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:$PORT
```

```text
web: gunicorn -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:$PORT
```

3. Push solo cuando el responsable autorice.

4. En Render, abrir servicio `fastapi-backend-o7ks`.

5. Confirmar antes de deploy:

- Build Command: `pip install -r temp_backend/requirements.txt`
- Start Command: `cd temp_backend && gunicorn -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:$PORT`
- Health Check Path: `/health`
- Variables requeridas completas.

6. Ejecutar deploy manual del commit autorizado.

7. Vigilar logs hasta ver servidor activo.

Senales esperadas:

- Instalacion de dependencias sin error.
- Import de `main.py` sin `KeyError`.
- No error por `COSMOS_URL`.
- No error por `email-validator`.
- Gunicorn arranca worker Uvicorn.
- Servicio queda escuchando en `0.0.0.0:$PORT`.
- Health check pasa.

Senales de fallo y accion inmediata:

- `KeyError: COSMOS_URL`: falta variable; agregarla o rollback.
- `KeyError: COSMOS_CONTAINER_CARNETS` o `COSMOS_CONTAINER_NOTAS`: faltan variables existentes; restaurar env o rollback.
- `ImportError: email-validator`: build no instalo `requirements.txt`; revisar build command y logs.
- Deploy termina despues de `python main.py`: start command incorrecto; corregir o rollback.
- Port scan/timeout: falta bind a `0.0.0.0:$PORT`; corregir start command o rollback.
- Error Cosmos 401/403: credenciales incorrectas; rollback si afecta rutas existentes.
- Error Cosmos 404 en tickets: contenedores o database faltantes; rollback si afecta salud general.

## Validaciones posteriores al deploy

Primero pruebas read-only.

```powershell
$BASE = "https://fastapi-backend-o7ks.onrender.com"
Invoke-RestMethod "$BASE/health"
```

Resultado esperado:

- HTTP 200.
- `status` igual a `healthy`.
- `cosmos_connected` igual a `true`.

Confirmar OpenAPI remoto:

```powershell
$BASE = "https://fastapi-backend-o7ks.onrender.com"
$openapi = Invoke-RestMethod "$BASE/openapi.json"
$openapi.paths.PSObject.Properties.Name | Where-Object { $_ -like "/tickets*" } | Sort-Object
```

Resultado esperado:

```text
/tickets
/tickets/my
/tickets/{ticket_id}
/tickets/{ticket_id}/appointment
/tickets/{ticket_id}/assign
/tickets/{ticket_id}/messages
/tickets/{ticket_id}/status
/tickets/{ticket_id}/videocall
```

Confirmar que rutas existentes siguen vivas:

```powershell
$BASE = "https://fastapi-backend-o7ks.onrender.com"
Invoke-RestMethod "$BASE/health"
Invoke-WebRequest "$BASE/docs" -UseBasicParsing | Select-Object StatusCode
```

Prueba autenticada read-only:

```powershell
$BASE = "https://fastapi-backend-o7ks.onrender.com"
$loginBody = @{
  username = "USUARIO_CANARY"
  password = "PASSWORD_CANARY"
  campus = "cres-llano-largo"
} | ConvertTo-Json
$login = Invoke-RestMethod "$BASE/auth/login" -Method POST -ContentType "application/json" -Body $loginBody
$TOKEN = $login.access_token
Invoke-RestMethod "$BASE/tickets/my" -Headers @{ Authorization = "Bearer $TOKEN" }
```

Resultado esperado:

- Login exitoso.
- `GET /tickets/my` devuelve `200` y lista JSON, aunque este vacia.

Prueba write canary, solo si se autoriza dejar un registro real de prueba:

```powershell
$ticketBody = @{
  matricula = "CANARY-DEPLOY-2-6-0"
  nombrePaciente = "Canary Deploy SASU"
  campus = "cres-llano-largo"
  categoria = "psicologia"
  prioridad = "baja"
  titulo = "Prueba controlada de despliegue SASU 2.6.0"
  descripcionInicial = "Ticket canary para validar despliegue Render."
} | ConvertTo-Json
$ticket = Invoke-RestMethod "$BASE/tickets" -Method POST -ContentType "application/json" -Headers @{ Authorization = "Bearer $TOKEN" } -Body $ticketBody
$ticket.id
```

Cerrar canary despues de validar:

```powershell
$closeBody = @{ estado = "cerrado" } | ConvertTo-Json
Invoke-RestMethod "$BASE/tickets/$($ticket.id)/status" -Method PATCH -ContentType "application/json" -Headers @{ Authorization = "Bearer $TOKEN" } -Body $closeBody
```

Validar Cosmos despues del canary:

- Documento existe en `tickets`.
- `campus` coincide con la partition key `/campus`.
- Mensajes, si se prueban, existen en `ticket_messages` con `ticketId`.

## Rollback

Rollback inmediato si falla cualquiera de estos puntos:

- `/health` no vuelve a `healthy`.
- Login falla para usuarios que antes funcionaban.
- OpenAPI no muestra `/tickets`.
- Rutas existentes de carnets/notas/citas fallan despues del deploy.
- Logs muestran errores de importacion, variables faltantes, Cosmos auth o puerto.

Procedimiento:

1. En Render, seleccionar el ultimo deploy exitoso anterior y ejecutar rollback.
2. Si el problema fue solo de variables, restaurar el snapshot de variables anterior.
3. Restaurar start command anterior si el cambio de start command causo el fallo; si el anterior era `python main.py`, preferir rollback de commit y corregir fuera de produccion antes de reintentar.
4. No borrar contenedores `tickets` ni `ticket_messages`; dejarlos intactos para evitar perdida de informacion.
5. Verificar despues del rollback:

```powershell
$BASE = "https://fastapi-backend-o7ks.onrender.com"
Invoke-RestMethod "$BASE/health"
$openapi = Invoke-RestMethod "$BASE/openapi.json"
$openapi.paths.PSObject.Properties.Name | Sort-Object
```

6. Registrar causa del rollback:

- commit desplegado
- hora
- error exacto de logs
- variable o comando implicado
- decision tomada

## Evidencia local de esta preparacion

Validaciones ejecutadas en esta fase:

- `git status --short`: limpio antes de crear este documento.
- `python -m unittest tests.test_ticket_routes`: 5 tests, OK.
- OpenAPI local aislado de Cosmos: 8 paths `/tickets`.

Hallazgos criticos:

- `ticket_routes` si esta incluido en `app`.
- `render.yaml` y `temp_backend/render.yaml` tienen la misma configuracion.
- `render.yaml` actual no es seguro para arranque web porque usa `python main.py`.
- `Procfile` actual usa Gunicorn con UvicornWorker, pero le falta bind explicito a `$PORT`.
- Render debe usar `COSMOS_URL`, no solo `COSMOS_ENDPOINT`, para coincidir con el codigo actual.

## Fuentes externas verificadas

- Render Web Services: `https://render.com/docs/web-services`
- Render Blueprint YAML Reference: `https://render.com/docs/blueprint-spec`

