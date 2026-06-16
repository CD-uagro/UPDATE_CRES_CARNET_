# SASU 2.6.0 - Diagnostico de integracion JWT Carnet Digital / Tickets

Fecha de diagnostico: 2026-06-16

Alcance: diagnostico solamente. No se modifico codigo, no se hizo push, no se hizo deploy y no se tocaron datos de produccion.

## Resumen

El backend de tickets desplegado ya expone `/tickets`, pero su autenticacion actual esta basada en el JWT interno de SASU emitido por `/auth/login`.

Conclusion:

- Usuarios internos SASU: compatibles directamente si usan el token emitido por el mismo backend y tienen permisos `tickets:*`.
- Alumno / Carnet Digital: no compatible directamente con el backend tickets actual.
- Se requiere un adaptador minimo para aceptar identidad de alumno con `matricula`, `nombre` y, opcionalmente, `email`, sin romper el flujo interno existente.

## Fuentes revisadas

Frontend Flutter SASU:

- `lib/screens/auth/login_screen.dart`
- `lib/data/auth_service.dart`
- `lib/data/api_service.dart`
- `lib/main.dart`
- `lib/security/auth_service.dart`

Backend:

- `temp_backend/auth_service.py`
- `temp_backend/auth_models.py`
- `temp_backend/main.py`
- `temp_backend/ticket_routes.py`
- `temp_backend/ticket_models.py`

Panel web admin:

- `temp_backend/admin_panel/app.js`

Busqueda adicional:

- No se encontro en este checkout un frontend separado tipo React/Next con `SessionProvider`, `AuthProvider`, `useSession` o un emisor JWT especifico de Carnet Digital.
- El `web/` del repo corresponde al shell web de Flutter, no a un portal de alumno con sesion propia.

## JWT usado por la app SASU interna

El login Flutter usa:

```text
POST https://fastapi-backend-o7ks.onrender.com/auth/login
```

Payload enviado:

```json
{
  "username": "<usuario>",
  "password": "<password>",
  "campus": "<campus>"
}
```

El token recibido se guarda en Flutter Secure Storage con key:

```text
auth_token
```

Los datos de usuario se guardan con key:

```text
auth_user
```

El modo offline genera un token local:

```text
offline_<timestamp>
```

Ese token offline no es JWT real y no sirve contra el backend.

El panel admin web usa el mismo endpoint `/auth/login` y guarda:

```text
localStorage.auth_token
localStorage.user_data
```

## Payload JWT emitido por el backend SASU

El backend crea el access token en `temp_backend/main.py` con estos claims:

```json
{
  "sub": "<username>",
  "rol": "<rol interno>",
  "campus": "<campus>",
  "exp": "<timestamp>"
}
```

Campos incluidos:

- `sub`: username interno.
- `rol`: rol interno SASU.
- `campus`: institucion/campus.
- `exp`: expiracion.

Campos no incluidos:

- `matricula`
- `nombre`
- `email`
- `role`

Nota: el backend usa `rol`, no `role`.

## JWT esperado por backend tickets

Todos los endpoints de `ticket_routes.py` usan:

```python
current_user: TokenData = Depends(get_current_user)
```

`get_current_user` decodifica el JWT con:

- algoritmo `HS256`
- secreto `JWT_SECRET_KEY`
- dependencia OAuth2 Bearer

Claims requeridos por el decoder actual:

```json
{
  "sub": "<username>",
  "rol": "<UserRole valido>",
  "campus": "<Campus valido>",
  "exp": "<timestamp>"
}
```

`TokenData` contiene:

- `username`
- `rol`
- `campus`
- `exp` opcional en el modelo, aunque el decoder no lo pasa explicitamente al construir `TokenData`.

Roles validos actuales:

- `admin`
- `medico`
- `nutricion`
- `psicologia`
- `odontologia`
- `enfermeria`
- `recepcion`
- `servicios_estudiantiles`
- `lectura`

No existe `alumno` en `UserRole`.

Permisos requeridos por tickets:

- `POST /tickets`: `tickets:create`
- `GET /tickets/my`: `tickets:read`
- `POST /tickets/{ticket_id}/messages`: permiso `tickets:reply` o ser creador del ticket
- `PATCH /tickets/{ticket_id}/assign`: `tickets:assign`
- `PATCH /tickets/{ticket_id}/status`: `tickets:update_status`
- `PATCH /tickets/{ticket_id}/appointment`: `tickets:update_status`
- `PATCH /tickets/{ticket_id}/videocall`: `tickets:update_status`

Los roles internos tienen permisos de tickets. `lectura` solo tiene `tickets:read`.

## JWT esperado para alumno / Carnet Digital

Para que un alumno use tickets, el backend necesita una identidad diferente a la de personal interno.

Claims minimos recomendados para alumno:

```json
{
  "sub": "alumno:<matricula>",
  "role": "alumno",
  "matricula": "<matricula>",
  "nombre": "<nombre completo>",
  "email": "<correo opcional>",
  "campus": "<campus>",
  "exp": "<timestamp>"
}
```

Variantes aceptables:

- Usar `rol: "alumno"` en vez de `role`, si se decide alinear todo al backend actual.
- Usar `studentId` como alias de `matricula`, pero normalizarlo antes de entrar a tickets.

Lo importante es que el backend pueda construir una identidad de alumno con:

- id estable: `matricula`
- nombre visible: `nombre`
- campus para aislamiento
- permisos limitados a tickets propios

## Comparacion

| Campo | JWT SASU interno actual | JWT alumno esperado | Compatibilidad |
| --- | --- | --- | --- |
| `sub` | username interno | alumno o matricula | Parcial |
| `exp` | si | si | Compatible |
| `rol` | rol interno enum `UserRole` | no existe o seria `alumno` | No compatible directo |
| `role` | no existe | comun en portales web | No compatible directo |
| `campus` | requerido y validado contra enum | requerido/recomendado | Compatible si usa los mismos valores |
| `matricula` | no existe | requerido | Falta |
| `nombre` | no existe | requerido para UI/mensajes | Falta |
| `email` | no existe en JWT | opcional | Falta |
| firma | `JWT_SECRET_KEY` backend SASU | desconocida en Carnet Digital externo | Solo compatible si comparte secreto/issuer |

## Veredicto

### A) Compatibles directamente

Solo si el cliente usa el token emitido por `/auth/login` del mismo backend SASU y el usuario es interno:

- `admin`
- `medico`
- `nutricion`
- `psicologia`
- `odontologia`
- `enfermeria`
- `recepcion`
- `servicios_estudiantiles`
- `lectura` para lectura

### B) Requieren adaptador

Para Carnet Digital / alumno, requieren adaptador.

Razones:

1. El backend actual no acepta `role=alumno` ni `rol=alumno`.
2. `TokenData` no modela `matricula`, `nombre` ni `email`.
3. `ticket_routes.py` usa permisos internos `tickets:*`; no hay politica de alumno.
4. `GET /tickets/my` lista por `username` y campus, no por `matricula`.
5. `POST /tickets` permite crear tickets con cualquier `matricula` del payload si el usuario tiene `tickets:create`; para alumno debe forzarse a su propia matricula.
6. `TicketSenderRole` ya contempla `alumno`, pero `_sender_role_for_user` nunca puede devolverlo porque `UserRole.ALUMNO` no existe.

## Solucion minima propuesta

Objetivo: aceptar JWT de alumno sin romper usuarios internos.

### 1. Crear modelo de identidad unificado para tickets

Agregar una identidad especifica de tickets, por ejemplo:

```python
class TicketPrincipal(BaseModel):
    kind: str  # "staff" o "student"
    username: str
    rol: str
    campus: str
    matricula: Optional[str] = None
    nombre: Optional[str] = None
    email: Optional[str] = None
```

### 2. Crear dependencia nueva solo para tickets

No reemplazar `get_current_user` global.

Crear algo como:

```python
async def get_ticket_principal(token: str = Depends(oauth2_scheme)) -> TicketPrincipal:
    ...
```

Esta dependencia debe:

- Decodificar JWT interno actual con `JWT_SECRET_KEY`.
- Aceptar staff actual: `sub`, `rol`, `campus`.
- Aceptar alumno: `sub`, `role` o `rol`, `matricula`, `nombre`, `email`, `campus`.
- Rechazar token sin `exp` valido.
- Rechazar campus desconocido o normalizarlo explicitamente.
- No imprimir token ni secretos.

### 3. Mantener permisos internos como estan

Para staff:

- Usar `has_permission` actual.
- Mantener `tickets:create`, `tickets:read`, `tickets:reply`, `tickets:assign`, `tickets:update_status`, `tickets:manage`.

### 4. Agregar politica de alumno solo en tickets

Para alumno:

- Puede crear ticket solo para su propia `matricula`.
- Puede leer solo tickets donde `ticket.matricula == principal.matricula`.
- Puede responder solo tickets propios.
- No puede asignar.
- No puede cambiar estado administrativo.
- No puede registrar videocall ni appointment salvo que se decida permitir solicitud, no confirmacion.

### 5. Cambiar rutas tickets a dependencia de tickets

Reemplazar en `ticket_routes.py` solo para endpoints `/tickets`:

```python
current_user: TokenData = Depends(get_current_user)
```

por:

```python
principal: TicketPrincipal = Depends(get_ticket_principal)
```

La logica interna puede adaptarse con helpers:

- `_principal_role_value`
- `_principal_campus_value`
- `_principal_username`
- `_principal_matricula`
- `_principal_can`

### 6. Forzar ownership para alumno

En `POST /tickets`, si principal es alumno:

- ignorar o validar `payload.matricula`.
- usar `principal.matricula` como fuente de verdad.
- usar `principal.nombre` si `nombrePaciente` viene vacio o inconsistente.
- guardar `createdBy = principal.username` o `createdBy = principal.matricula`.
- guardar `createdByRole = "alumno"`.

En `GET /tickets/my`, si principal es alumno:

- consultar por `campus` y `matricula`.
- no usar `assignedTo`.

### 7. Considerar endpoint separado si se quiere minimo riesgo

Alternativa de menor blast radius:

- Mantener `/tickets` actual para staff.
- Agregar endpoints alumno bajo `/student/tickets` o `/tickets/student`.

Ventaja:

- No se toca la semantica existente de personal interno.

Desventaja:

- El frontend de Carnet Digital tendria que apuntar a rutas diferentes.

## Riesgos

1. Firma/issuer desconocido del Carnet Digital.
   - Si el JWT de Carnet Digital lo emite otro sistema con otro secreto, el backend no lo validara con `JWT_SECRET_KEY`.
   - Se requiere conocer issuer, algoritmo y secreto/public key.

2. `role` vs `rol`.
   - El backend actual solo lee `rol`.
   - Muchos portales usan `role`.

3. `alumno` no existe en `UserRole`.
   - Si se envia `rol=alumno` al decoder actual, no pasa por el enum.

4. Faltan claims de estudiante.
   - Tickets necesita `matricula` para ownership real.

5. Riesgo de escalamiento horizontal.
   - Si se reutiliza `tickets:create` para alumno sin forzar matricula, un alumno podria crear ticket para otra matricula.

6. Errores no normalizados.
   - El decoder actual captura `JWTError`, pero conversiones como `UserRole(rol)` o `Campus(campus)` pueden fallar por `ValueError`.
   - Conviene devolver siempre 401/403 controlado.

7. Token offline Flutter.
   - `offline_<timestamp>` no debe enviarse a tickets.

## Plan de implementacion sugerido

### Fase 1 - Confirmar contrato real del Carnet Digital

Sin imprimir secretos ni tokens completos:

- Obtener un JWT real de alumno en entorno controlado.
- Decodificar solo payload localmente.
- Confirmar:
  - `sub`
  - `exp`
  - `role` o `rol`
  - `matricula`
  - `nombre`
  - `email`
  - `campus`
  - algoritmo en header
  - issuer/audience si existen

No registrar el token completo en logs ni docs.

### Fase 2 - Tests primero

Agregar tests backend para:

- staff actual sigue pasando.
- alumno con token valido puede crear ticket propio.
- alumno no puede crear ticket para otra matricula.
- alumno puede leer sus tickets.
- alumno no puede leer ticket de otra matricula.
- alumno no puede asignar ni cambiar estado administrativo.
- token sin `matricula` falla con 401/403.
- token `offline_` falla con 401.

### Fase 3 - Adaptador minimo

Implementar dependencia de autenticacion solo para tickets:

- `ticket_auth.py` o seccion acotada en `ticket_routes.py`.
- Modelo `TicketPrincipal`.
- Helpers de permisos acotados a tickets.

### Fase 4 - Integracion Carnet Digital

En el cliente Carnet Digital:

- Enviar `Authorization: Bearer <token_alumno>`.
- No enviar token offline.
- Usar `GET /tickets/my`.
- Para crear ticket, mandar payload sin confiar en `matricula` como fuente de seguridad; backend debe tomarla del JWT.

### Fase 5 - Deploy controlado

- Deploy backend.
- Validar `/openapi.json`.
- Validar `/tickets/my` sin token: 401.
- Validar `/tickets/my` con token alumno valido: 200.
- Validar POST canary de alumno solo con autorizacion.

## Decision recomendada

Usar adaptador B.

No conviene forzar al Carnet Digital a emitir tokens identicos a usuarios internos SASU porque mezclaria identidad de alumno con roles operativos internos. La opcion mas segura es aceptar un principal de alumno solo dentro de tickets, con permisos y ownership por matricula.

