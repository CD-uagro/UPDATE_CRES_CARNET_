# SASU 2.7.0 - Referencias y Contrarreferencias RC1 Test Plan

## Objetivo

Preparar una prueba funcional manual RC1 del modulo de Referencias y Contrarreferencias sin modificar funcionalidad, sin publicar cambios y sin afectar SASU 2.6.5+45.

## Alcance

Este plan valida el MVP local de Referencias:

- Backend FastAPI local con endpoints de referencias.
- SASU Windows local con bandeja, creacion, detalle, transiciones, contrarreferencia y notificaciones internas.
- Flujo interno SASU entre areas, sin Carnet Digital Web, sin Node y sin Agenda Integrada.

## Restricciones

- No hacer push.
- No hacer deploy.
- No crear release.
- No crear tag.
- No tocar Node.
- No tocar Carnet Digital Web.
- No tocar Agenda Integrada.
- No tocar Tickets.
- No tocar JWT.

## A. Backend Local

Checklist:

- [ ] Entrar a `temp_backend`.
- [ ] Ejecutar pruebas:

```powershell
python -m unittest discover
```

- [ ] Confirmar resultado esperado:

```text
Ran 37 tests
OK
```

- [ ] Iniciar backend local:

```powershell
uvicorn main:app --reload
```

- [ ] Abrir Swagger local:

```text
http://127.0.0.1:8000/docs
```

- [ ] Confirmar que aparecen endpoints:
  - [ ] `POST /referrals`
  - [ ] `GET /referrals`
  - [ ] `GET /referrals/{id}`
  - [ ] `PATCH /referrals/{id}/status`
  - [ ] `POST /referrals/{id}/counter-referral`
  - [ ] `GET /students/{matricula}/referrals`
  - [ ] `GET /referrals/pending`

## B. App Windows Local

Checklist:

- [ ] Entrar al repo raiz `C:\CRES_Carnets_UAGROPRO`.
- [ ] Ejecutar:

```powershell
flutter run -d windows
```

- [ ] Iniciar sesion con usuario interno SASU autorizado.
- [ ] Confirmar que el Dashboard carga correctamente.
- [ ] Confirmar que aparece el modulo `Referencias`.
- [ ] Confirmar que no se rompen Expedientes, Tickets, Agenda ni Dashboard.

## C. Flujo Completo

Crear referencia:

- [ ] Abrir `Referencias`.
- [ ] Presionar `Nueva Referencia`.
- [ ] Buscar y seleccionar estudiante.
- [ ] Capturar referencia:
  - [ ] Area origen: `medico`
  - [ ] Area destino: `psicologia`
  - [ ] Prioridad: `media` o `alta`
  - [ ] Motivo obligatorio
  - [ ] Observaciones opcionales
- [ ] Guardar.
- [ ] Confirmar mensaje `Referencia creada correctamente`.
- [ ] Confirmar que la referencia aparece en bandeja.

Detalle:

- [ ] Abrir detalle con el boton `Ver`.
- [ ] Confirmar datos de encabezado:
  - [ ] ID
  - [ ] Estado
  - [ ] Prioridad
  - [ ] Fecha
- [ ] Confirmar datos del estudiante:
  - [ ] Nombre
  - [ ] Matricula
  - [ ] Programa
  - [ ] Campus
- [ ] Confirmar datos de referencia:
  - [ ] Area origen
  - [ ] Area destino
  - [ ] Motivo
  - [ ] Observaciones
- [ ] Confirmar timeline inicial con estado `sent`.

Transiciones de estado:

- [ ] Cambiar `sent` -> `received`.
- [ ] Confirmar que el detalle se refresca.
- [ ] Confirmar que el timeline agrega el evento.
- [ ] Cambiar `received` -> `accepted`.
- [ ] Confirmar que el detalle se refresca.
- [ ] Confirmar que el timeline agrega el evento.
- [ ] Cambiar `accepted` -> `scheduled`.
- [ ] Confirmar que el detalle se refresca.
- [ ] Confirmar que el timeline agrega el evento.
- [ ] Cambiar `scheduled` -> `attended`.
- [ ] Confirmar que el detalle se refresca.
- [ ] Confirmar que el timeline agrega el evento.

Contrarreferencia:

- [ ] Con estado `attended`, confirmar que aparece accion de contrarreferencia.
- [ ] Abrir captura de contrarreferencia.
- [ ] Capturar resumen de atencion.
- [ ] Capturar recomendaciones.
- [ ] Guardar.
- [ ] Confirmar mensaje de exito.
- [ ] Confirmar que la contrarreferencia se visualiza en el detalle.
- [ ] Confirmar que no se muestran errores.

Cierre:

- [ ] Cambiar `attended` -> `closed`.
- [ ] Confirmar que el detalle se refresca.
- [ ] Confirmar que el timeline agrega el evento.
- [ ] Confirmar que ya no aparecen acciones de cambio de estado.

## D. Notificaciones Internas

Checklist:

- [ ] Dejar el Dashboard abierto con usuario autorizado para Referencias.
- [ ] Crear una referencia nueva dirigida al area del usuario.
- [ ] Esperar el siguiente ciclo de polling o refrescar sesion local si aplica.
- [ ] Confirmar toast:

```text
Nueva referencia recibida
```

- [ ] Confirmar que el toast muestra solo datos no sensibles:
  - [ ] Nombre del estudiante
  - [ ] Area origen
  - [ ] Boton `Ver referencia`
- [ ] Confirmar que NO muestra:
  - [ ] Motivo
  - [ ] Observaciones
  - [ ] Datos clinicos sensibles
- [ ] Presionar `Ver referencia`.
- [ ] Confirmar que abre directamente `ReferralDetailScreen`.
- [ ] Confirmar que no se duplican toasts para la misma referencia.
- [ ] Confirmar que no se muestran toasts si la pantalla de Referencias esta abierta.

## E. Validaciones Negativas

Creacion de referencia:

- [ ] Intentar crear referencia sin estudiante.
- [ ] Confirmar mensaje claro de validacion.
- [ ] Intentar crear referencia sin area destino.
- [ ] Confirmar mensaje claro de validacion.
- [ ] Intentar crear referencia sin prioridad.
- [ ] Confirmar mensaje claro de validacion.
- [ ] Intentar crear referencia sin motivo.
- [ ] Confirmar mensaje claro de validacion.

Contrarreferencia:

- [ ] Intentar crear contrarreferencia sin resumen.
- [ ] Confirmar mensaje claro de validacion.
- [ ] Intentar crear contrarreferencia sin recomendaciones.
- [ ] Confirmar mensaje claro de validacion.

Estados finales:

- [ ] Abrir una referencia `closed`.
- [ ] Confirmar que no muestra acciones de cambio de estado.
- [ ] Abrir una referencia `cancelled`.
- [ ] Confirmar que no muestra acciones de cambio de estado.

## Criterio de Aprobacion RC1

RC1 se considera apto para prueba controlada si:

- [ ] Backend local pasa pruebas.
- [ ] Swagger local muestra endpoints esperados.
- [ ] SASU Windows compila/analiza sin errores focalizados.
- [ ] La referencia puede crearse, listarse y abrirse.
- [ ] Las transiciones validas funcionan en orden.
- [ ] La contrarreferencia se captura y visualiza.
- [ ] El timeline se actualiza.
- [ ] Las notificaciones internas aparecen sin datos sensibles.
- [ ] Las validaciones negativas bloquean datos incompletos.
- [ ] No hay cambios fuera del MVP.

## Dictamen Manual

Marcar al terminar la prueba:

```text
APTO PARA RC1 CONTROLADO
```

o

```text
NO APTO PARA RC1
```
