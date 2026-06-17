# SASU 2.7.0 - Diagnostico Tecnico

## Referencias y Contrarreferencias

Version base estable: `SASU 2.6.5+45`

Este documento define la arquitectura propuesta para el modulo institucional de Referencias y Contrarreferencias SASU.

No se modifica codigo en esta etapa.
No se hacen commits.
No se hace deploy.
No se hace release.

---

## 1. Problema

Actualmente las referencias entre areas se realizan por medios informales:

- comunicacion verbal
- WhatsApp
- mensajes personales
- correos aislados

Esto genera:

- falta de trazabilidad
- ausencia de evidencia institucional
- perdida de seguimiento
- dificultad para saber si el estudiante fue atendido
- imposibilidad de generar historial clinico-administrativo completo

---

## 2. Objetivo

Crear un modulo institucional de Referencias y Contrarreferencias entre areas SASU:

- Medico
- Psicologia
- Nutricion
- Odontologia
- Atencion Estudiantil
- futuras areas

El modulo debe permitir que un area refiera formalmente a un estudiante, que el area destino reciba notificacion interna, atienda, emita contrarreferencia y cierre el ciclo.

---

## 3. Flujo propuesto

```text
Alumno
-> Consulta inicial
-> Area origen detecta necesidad
-> Genera referencia
-> Area destino recibe notificacion interna
-> Area destino acepta o agenda atencion
-> Se genera cita en Agenda Integrada
-> Se atiende al estudiante
-> Area destino genera contrarreferencia
-> Area origen visualiza resultado
-> Cierre institucional
```

---

## 4. Arquitectura propuesta

Se mantiene la arquitectura actual:

```text
Flutter Windows SASU
Flutter Web Carnet Digital
FastAPI SASU
Node Carnet Digital
Cosmos DB
JWT actual
Agenda Integrada
Tickets
```

El modulo principal debe vivir en FastAPI y Cosmos DB.

Carnet Digital Web puede visualizar referencias propias del alumno en una etapa posterior, pero el nucleo operativo debe iniciar en SASU Windows.

---

## 5. Coleccion Cosmos sugerida

Crear un nuevo contenedor:

```text
referrals
```

Partition key sugerida:

```text
/student/matricula
```

Justificacion:

- permite consultar historial completo por estudiante
- facilita integracion con expediente
- agrupa referencias, contrarreferencias y citas relacionadas
- evita dependencia directa del area como particion primaria

---

## 6. Modelo JSON propuesto

```json
{
  "id": "ref_20260617_abc123",
  "type": "referral",
  "student": {
    "matricula": "12345678",
    "nombre": "Nombre del estudiante",
    "correo": "alumno@uagro.mx",
    "programa": "Licenciatura",
    "campus": "CRES Llano Largo"
  },
  "origin": {
    "area": "medico",
    "userId": "user_001",
    "userName": "Dr. Nombre",
    "role": "medico"
  },
  "destination": {
    "area": "psicologia",
    "assignedUserId": null,
    "assignedUserName": null
  },
  "priority": "media",
  "reason": "Se detecta necesidad de valoracion psicologica.",
  "observations": "Estudiante refiere ansiedad y dificultad para dormir.",
  "status": "sent",
  "createdAt": "2026-06-17T10:00:00-06:00",
  "updatedAt": "2026-06-17T10:00:00-06:00",
  "receivedAt": null,
  "acceptedAt": null,
  "scheduledAt": null,
  "attendedAt": null,
  "closedAt": null,
  "cancelledAt": null,
  "appointmentId": null,
  "counterReferral": null,
  "statusHistory": [
    {
      "status": "sent",
      "at": "2026-06-17T10:00:00-06:00",
      "byUserId": "user_001",
      "byUserName": "Dr. Nombre",
      "note": "Referencia enviada a Psicologia."
    }
  ]
}
```

---

## 7. Contrarreferencia

La contrarreferencia debe guardarse dentro del documento de referencia.

```json
{
  "counterReferral": {
    "responseArea": "psicologia",
    "responseUserId": "user_010",
    "responseUserName": "Psic. Nombre",
    "summary": "Estudiante valorado en primera sesion.",
    "recommendations": "Continuar seguimiento psicologico semanal durante 4 semanas.",
    "createdAt": "2026-06-18T12:00:00-06:00"
  }
}
```

---

## 8. Estados

Estados permitidos:

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
- `received`: area destino ya la visualizo
- `accepted`: area destino acepto la referencia
- `scheduled`: referencia convertida en cita
- `attended`: estudiante fue atendido
- `closed`: ciclo cerrado con contrarreferencia o resolucion
- `cancelled`: referencia cancelada

---

## 9. Prioridades

Valores sugeridos:

```text
baja
media
alta
urgente
```

La prioridad `urgente` no debe sustituir protocolos clinicos o de emergencia. Solo debe funcionar como prioridad operativa interna.

---

## 10. Permisos propuestos

### Medico

Puede:

- crear referencias
- ver referencias enviadas
- ver contrarreferencias recibidas
- cerrar referencias originadas por su area

### Psicologia / Nutricion / Odontologia / Atencion Estudiantil

Puede:

- recibir referencias dirigidas a su area
- aceptar referencias
- convertir referencia en cita
- registrar atencion
- generar contrarreferencia
- cerrar referencia atendida

### Administrador

Puede:

- ver todas las referencias
- filtrar por area, estado, estudiante y prioridad
- reasignar area destino si hay error
- cancelar referencias
- auditar historial

### Alumno

En esta etapa no es obligatorio que genere referencias.

En fase posterior podria visualizar:

- referencia recibida
- cita derivada
- estado general

Sin mostrar detalles clinicos sensibles.

---

## 11. Integracion con Agenda Integrada

Una referencia debe poder convertirse en cita sin recapturar datos.

Relacion propuesta:

```text
referrals.appointmentId -> appointments.id
appointments.sourceType = "referral"
appointments.sourceId = referral.id
```

Ejemplo de cita generada desde referencia:

```json
{
  "id": "appt_20260617_xyz789",
  "sourceType": "referral",
  "sourceId": "ref_20260617_abc123",
  "student": {
    "matricula": "12345678",
    "nombre": "Nombre del estudiante",
    "correo": "alumno@uagro.mx"
  },
  "area": "psicologia",
  "status": "requested",
  "createdFromReferral": true
}
```

Al generar cita:

- la referencia cambia a `scheduled`
- se guarda `appointmentId`
- se agrega evento en `statusHistory`
- Agenda Integrada conserva su flujo actual

No se debe romper la Agenda existente.

---

## 12. Notificaciones internas

Cuando se genere una referencia en estado `sent`, SASU Windows debe mostrar notificacion tipo Messenger:

```text
Nueva referencia recibida
```

Condiciones:

- solo al area destino
- solo usuarios autorizados
- sin correo
- sin WhatsApp
- sin sonido obligatorio
- sin datos sensibles en el toast

Ejemplo:

```text
Nueva referencia recibida
Psicologia tiene una nueva referencia pendiente.
[Ver referencia]
```

Debe reutilizarse el patron ya implementado para:

- nuevas citas pendientes
- recordatorio horario
- ventana tipo Messenger

---

## 13. Historial del estudiante

El expediente debe mostrar una linea de tiempo:

```text
Consulta medica
Referencia a Psicologia
Cita generada
Atencion psicologica
Contrarreferencia emitida
Cierre
```

Vista sugerida:

```text
Referencias y Contrarreferencias
- Fecha
- Area origen
- Area destino
- Estado
- Prioridad
- Cita relacionada
- Contrarreferencia
```

---

## 14. Endpoints FastAPI sugeridos

No implementar todavia. Solo diseno.

```text
POST   /referrals
GET    /referrals
GET    /referrals/{id}
PATCH  /referrals/{id}/status
POST   /referrals/{id}/accept
POST   /referrals/{id}/schedule
POST   /referrals/{id}/counter-referral
GET    /students/{matricula}/referrals
GET    /referrals/pending
```

---

## 15. Reutilizacion de componentes existentes

Se recomienda reutilizar:

- autenticacion JWT actual
- adaptador de alumno si se requiere consulta desde Carnet
- servicios Cosmos existentes
- patron de `statusHistory` usado en Tickets/Agenda
- polling del dashboard SASU
- toast tipo Messenger
- filtros de Agenda Integrada
- componentes visuales de detalle
- busqueda de estudiante ya existente
- modelo de cita ya publicado

---

## 16. Riesgos

### Riesgo 1: Exposicion de datos sensibles

Mitigacion:

- no mostrar motivo clinico completo en notificaciones
- limitar acceso por area y rol
- mantener detalle dentro del modulo protegido

### Riesgo 2: Duplicidad con Agenda

Mitigacion:

- Agenda no debe absorber la referencia
- referencia y cita deben estar relacionadas, no mezcladas

### Riesgo 3: Estados inconsistentes

Mitigacion:

- usar transiciones controladas
- registrar `statusHistory`
- impedir saltos invalidos

### Riesgo 4: Ruptura de JWT

Mitigacion:

- no modificar JWT en esta fase
- extender permisos desde backend sin romper roles existentes

### Riesgo 5: Saturacion de notificaciones

Mitigacion:

- mostrar solo nuevas referencias pendientes
- evitar repetir antes de cierto intervalo
- no mostrar si el modulo de referencias esta abierto

---

## 17. Decision tecnica inicial

El modulo SASU 2.7.0 debe iniciar en Windows SASU y FastAPI.

Carnet Digital Web debe quedar para fase posterior como visualizacion estudiantil limitada.

La coleccion Cosmos recomendada es:

```text
referrals
```

con partition key:

```text
/student/matricula
```

La referencia debe ser el documento rector.

La cita debe ser un documento relacionado en `appointments`.

La contrarreferencia debe vivir dentro de la referencia.

---

## 18. Alcance recomendado para MVP 2.7.0

Primera implementacion sugerida:

1. Crear modelo de referencia en FastAPI.
2. Crear contenedor Cosmos `referrals`.
3. Crear endpoints base.
4. Crear bandeja de referencias en SASU Windows.
5. Crear formulario de nueva referencia.
6. Crear notificacion interna.
7. Permitir convertir referencia en cita.
8. Permitir registrar contrarreferencia.
9. Mostrar linea de tiempo en expediente.
10. Documentar y publicar como SASU 2.7.0.

---

## 19. No hacer en esta etapa

No implementar:

- correo
- WhatsApp
- notificaciones push externas
- videollamada
- IA clinica
- cambios en JWT
- cambios en Agenda salvo integracion minima
- cambios en Tickets
- cambios en Carnet Digital Web salvo lectura futura

---

## 20. Conclusion

SASU 2.7.0 debe construir un modulo formal de Referencias y Contrarreferencias que permita trazabilidad institucional entre areas, integracion con Agenda y evidencia dentro del expediente del estudiante.

La arquitectura propuesta respeta lo ya publicado en SASU 2.6.5+45 y evita romper Agenda Integrada, Tickets, Carnet Digital, JWT o Cosmos actual.

Este diagnostico queda como base previa a la implementacion.
