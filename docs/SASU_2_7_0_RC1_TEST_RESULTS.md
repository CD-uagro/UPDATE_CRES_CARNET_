# SASU 2.7.0 - Referencias y Contrarreferencias RC1 Test Results

## Resultado General

Dictamen:

```text
PENDIENTE
```

Fecha de prueba:

```text
Pendiente
```

Responsable:

```text
Pendiente
```

## Evidencia Tecnica

| Componente | Validacion | Resultado | Evidencia | Observaciones |
| --- | --- | --- | --- | --- |
| Backend local | `python -m unittest discover` | Pendiente | Pendiente | Pendiente |
| Backend local | `uvicorn main:app --reload` | Pendiente | Pendiente | Pendiente |
| Backend local | Swagger `/docs` | Pendiente | Pendiente | Pendiente |
| SASU Windows | `flutter run -d windows` | Pendiente | Pendiente | Pendiente |
| SASU Windows | Dashboard carga | Pendiente | Pendiente | Pendiente |
| SASU Windows | Modulo Referencias visible | Pendiente | Pendiente | Pendiente |

## Flujo Funcional

| Prueba | Resultado | Evidencia | Observaciones |
| --- | --- | --- | --- |
| Crear referencia Medico -> Psicologia | Pendiente | Pendiente | Pendiente |
| Referencia aparece en bandeja | Pendiente | Pendiente | Pendiente |
| Abrir detalle | Pendiente | Pendiente | Pendiente |
| Cambiar `sent` -> `received` | Pendiente | Pendiente | Pendiente |
| Cambiar `received` -> `accepted` | Pendiente | Pendiente | Pendiente |
| Cambiar `accepted` -> `scheduled` | Pendiente | Pendiente | Pendiente |
| Cambiar `scheduled` -> `attended` | Pendiente | Pendiente | Pendiente |
| Crear contrarreferencia en `attended` | Pendiente | Pendiente | Pendiente |
| Contrarreferencia visible en detalle | Pendiente | Pendiente | Pendiente |
| Cambiar `attended` -> `closed` | Pendiente | Pendiente | Pendiente |
| Timeline actualizado | Pendiente | Pendiente | Pendiente |

## Notificaciones Internas

| Prueba | Resultado | Evidencia | Observaciones |
| --- | --- | --- | --- |
| Dashboard muestra toast `Nueva referencia recibida` | Pendiente | Pendiente | Pendiente |
| Boton `Ver referencia` abre detalle | Pendiente | Pendiente | Pendiente |
| Toast no muestra motivo | Pendiente | Pendiente | Pendiente |
| Toast no muestra observaciones | Pendiente | Pendiente | Pendiente |
| No se duplican toasts | Pendiente | Pendiente | Pendiente |
| No aparece toast si Referencias esta abierta | Pendiente | Pendiente | Pendiente |

## Validaciones Negativas

| Prueba | Resultado | Evidencia | Observaciones |
| --- | --- | --- | --- |
| No crear referencia sin estudiante | Pendiente | Pendiente | Pendiente |
| No crear referencia sin motivo | Pendiente | Pendiente | Pendiente |
| No crear contrarreferencia sin resumen | Pendiente | Pendiente | Pendiente |
| No crear contrarreferencia sin recomendaciones | Pendiente | Pendiente | Pendiente |
| No mostrar acciones cuando esta `closed` | Pendiente | Pendiente | Pendiente |
| No mostrar acciones cuando esta `cancelled` | Pendiente | Pendiente | Pendiente |

## Bugs Encontrados

| ID | Descripcion | Severidad | Estado | Observaciones |
| --- | --- | --- | --- | --- |
| RC1-001 | Pendiente | Pendiente | Pendiente | Pendiente |

## Conclusiones

Pendiente de ejecucion manual.
