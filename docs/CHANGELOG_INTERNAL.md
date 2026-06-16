# CHANGELOG interno

## 2026-06-16 - Hotfix 2.5.2

Estado: hotfix estable preparado.

Incluye:

- Correccion de notas duplicadas entre almacenamiento local y nube.
- Correccion de horarios clinicos usando UTC interno y hora local en interfaz.
- Identidad estable de notas mediante clientId compartido entre SQLite y Cosmos.
- Mejora de deduplicacion en timeline clinico.
- Migracion segura de base local a schema v7.
- Actividad reciente permite quitar accesos rapidos individuales o limpiar toda la lista sin borrar datos clinicos.

Alcance congelado:

- No incluye chat institucional.
- No incluye notificaciones.
- No incluye recuperacion de contrasena.
- No incluye videollamadas.
- No incluye seguimiento integrado.

## 2026-06-08 - Cierre de release 2.4.36

Estado: estable publicada.

La version 2.4.36 queda congelada como release activa para usuarios reales mediante el sistema de actualizacion automatica.

Artefacto publicado:

- Instalador: CRES_Carnets_Setup_v2.4.36.exe
- Version: 2.4.36
- Build: 36
- SHA256: 0E1ACBBE6BEA4BD2AF4BC893AAFAC4A3630B7BD2D1A40E8D940838D5865BEB6C
- fileSize: 13865834
- Backend de updates: activo en 2.4.36
- GitHub Release: activo en v2.4.36

Incluye:

- Campos escuelaUnidadAcademica y grupo.
- Guardia anti-downgrade.
- Fuente unica de version basada en version.json.
- Validacion SHA256 real antes de ejecutar instalador.
- Prueba integral segura del flujo de actualizacion.
- Proteccion de scripts legacy.

Nota de cierre:

- No se reempaquetara la release 2.4.36 por el bug visual menor del fallback de version del dashboard.
- La correccion local de version mostrada en UI se acumula para la siguiente fase visual 2.5.0.
- Cualquier cambio nuevo debe preparar una version posterior; no modificar los artefactos publicados de 2.4.36.
