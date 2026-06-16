# SASU 2.6.0 - Backend tickets listo para Render

Fecha de preparacion: 2026-06-15

Estado: listo para despliegue manual en Render cuando se autorice. No se desplego y no se hizo push durante esta preparacion.

## Configuracion final Render

Servicio:

- Nombre: `fastapi-backend-o7ks`
- Runtime: Python
- Build Command: `pip install -r temp_backend/requirements.txt`
- Start Command: `cd temp_backend && gunicorn -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:$PORT`
- Health Check Path: `/health`

Archivos de configuracion preparados:

- `render.yaml`
- `temp_backend/render.yaml`
- `temp_backend/Procfile`
- `temp_backend/cosmos_helper.py`
- `temp_backend/main.py`

El arranque ya no depende de `python main.py`. Render debe iniciar la app ASGI `main:app` con Gunicorn y `uvicorn.workers.UvicornWorker`, escuchando explicitamente en `0.0.0.0:$PORT`.

## Compatibilidad Cosmos

El backend ahora acepta estas dos formas para el endpoint de Cosmos:

- `COSMOS_URL`, nombre usado por el codigo y recomendado para dejar en Render.
- `COSMOS_ENDPOINT`, fallback compatible con la configuracion previa.

`render.yaml` define `COSMOS_URL` usando el secreto existente `COSMOS_ENDPOINT` y conserva `COSMOS_ENDPOINT` para compatibilidad.

## Variables requeridas

Minimas para arrancar sin romper modulos existentes:

- `COSMOS_URL` o `COSMOS_ENDPOINT`
- `COSMOS_KEY`
- `COSMOS_DB` o `COSMOS_DATABASE`
- `COSMOS_CONTAINER_CARNETS`
- `COSMOS_CONTAINER_NOTAS`
- `COSMOS_CONTAINER_CITAS`
- `COSMOS_PK_CITAS`
- `COSMOS_CONTAINER_TICKETS`
- `COSMOS_CONTAINER_TICKET_MESSAGES`
- `JWT_SECRET_KEY`

Valores declarados en `render.yaml`:

- `COSMOS_DB=SASU`
- `COSMOS_CONTAINER_CARNETS=carnets_id`
- `COSMOS_CONTAINER_NOTAS=notas`
- `COSMOS_CONTAINER_CITAS=citas_id`
- `COSMOS_PK_CITAS=/id`
- `COSMOS_CONTAINER_TICKETS=tickets`
- `COSMOS_CONTAINER_TICKET_MESSAGES=ticket_messages`

Secretos esperados en Render:

- `COSMOS_ENDPOINT`
- `COSMOS_KEY`
- `JWT_SECRET_KEY`

Variables opcionales que deben preservarse si produccion las usa:

- `COSMOS_CONTAINER_PROMOCIONES_SALUD`
- `COSMOS_CONTAINER_VACUNACION`
- `COSMOS_CONTAINER_USUARIOS`
- `COSMOS_CONTAINER_AUDITORIA`
- `SUPERVISOR_KEY`
- `DEBUG_CITAS=false`
- `GCAL_ENABLED`
- `GCAL_SA_JSON`
- `GCAL_CALENDAR_ID`
- `APP_TZ`

## Comando de arranque

Comando final:

```bash
cd temp_backend && gunicorn -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:$PORT
```

Motivo:

- Render requiere un servicio HTTP escuchando en `0.0.0.0`.
- Render inyecta `PORT`; el comando lo usa explicitamente.
- `main.py` define `app = FastAPI()`, pero no ejecuta servidor por si solo.

## Endpoints esperados

OpenAPI debe exponer:

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

## Validaciones locales ejecutadas

Tests:

```powershell
cd temp_backend
$env:PYTHONIOENCODING='utf-8'
python -m unittest tests.test_ticket_models
python -m unittest tests.test_ticket_routes
```

Resultado:

- `tests.test_ticket_models`: 4 tests, OK.
- `tests.test_ticket_routes`: 5 tests, OK.

OpenAPI:

- Se importo `main.app` con doble local de Cosmos para no tocar produccion.
- OpenAPI siguio exponiendo 8 paths `/tickets`.

Compatibilidad Cosmos:

- Se verifico que `cosmos_helper.COSMOS_URL` puede resolverse desde `COSMOS_ENDPOINT` cuando `COSMOS_URL` no existe.

Arranque equivalente:

- El entorno local de Python no tiene Gunicorn instalado, aunque `temp_backend/requirements.txt` si lo declara.
- Se valido import ASGI/OpenAPI localmente; la validacion completa de Gunicorn ocurre en Render despues de `pip install -r temp_backend/requirements.txt`.

## Checklist de despliegue

No ejecutar hasta tener autorizacion explicita.

1. Confirmar estado Git local.

```powershell
git status --short
git log --oneline -3
```

2. Confirmar que no hay cambios fuera del alcance.

Alcance permitido:

- Configuracion Render.
- Compatibilidad de variables `COSMOS_URL`/`COSMOS_ENDPOINT`.
- Documentacion de despliegue.

Fuera de alcance:

- Logica de tickets.
- Modelos.
- Cosmos data/containers.
- Flutter.
- Produccion.

3. Confirmar variables en Render.

- `COSMOS_ENDPOINT` existe y apunta al endpoint correcto.
- `COSMOS_KEY` existe.
- `JWT_SECRET_KEY` existe y es estable.
- `COSMOS_CONTAINER_TICKETS=tickets`.
- `COSMOS_CONTAINER_TICKET_MESSAGES=ticket_messages`.

4. Confirmar Cosmos antes del deploy.

- Database esperada: `SASU`.
- `tickets` existe con partition key `/campus`.
- `ticket_messages` existe con partition key `/ticketId`.
- Contenedores existentes de carnets/notas/citas no se modifican.

5. Confirmar configuracion Render.

- Build Command: `pip install -r temp_backend/requirements.txt`
- Start Command: `cd temp_backend && gunicorn -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:$PORT`
- Health Check Path: `/health`

6. Ejecutar deploy manual en Render.

7. Vigilar logs.

Logs esperados:

- Dependencias instaladas, incluyendo `gunicorn`, `uvicorn`, `fastapi` y `email-validator`.
- `FASTAPI APP CREATED SUCCESSFULLY`.
- Worker Uvicorn iniciado por Gunicorn.
- Sin `KeyError` de variables.
- Sin error de puerto.

8. Validar remoto.

```powershell
$BASE = "https://fastapi-backend-o7ks.onrender.com"
Invoke-RestMethod "$BASE/health"
$openapi = Invoke-RestMethod "$BASE/openapi.json"
$openapi.paths.PSObject.Properties.Name | Where-Object { $_ -like "/tickets*" } | Sort-Object
```

9. Validar autenticacion y tickets con usuario canary.

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
- `GET /tickets/my` responde `200`.
- Respuesta JSON lista, aunque este vacia.

## Checklist de rollback

Rollback inmediato si ocurre cualquiera de estos puntos:

- `/health` no responde sano.
- Login deja de funcionar.
- OpenAPI no muestra `/tickets`.
- Rutas existentes de carnets, notas o citas fallan.
- Logs muestran `KeyError` por variables.
- Logs muestran error de Cosmos 401/403.
- Render reporta timeout o falta de puerto.

Pasos:

1. En Render, abrir `fastapi-backend-o7ks`.
2. Seleccionar el ultimo deploy exitoso anterior.
3. Ejecutar rollback desde Render.
4. Restaurar variables si se cambiaron manualmente.
5. Verificar:

```powershell
$BASE = "https://fastapi-backend-o7ks.onrender.com"
Invoke-RestMethod "$BASE/health"
Invoke-WebRequest "$BASE/docs" -UseBasicParsing | Select-Object StatusCode
```

6. No borrar contenedores `tickets` ni `ticket_messages`.
7. Registrar:

- commit desplegado
- hora del fallo
- error exacto de logs
- accion correctiva
- estado posterior al rollback

## Estado final esperado

Con estos cambios, Render queda preparado para un despliegue manual seguro del backend de tickets. Falta solamente la autorizacion explicita para push y deploy.

