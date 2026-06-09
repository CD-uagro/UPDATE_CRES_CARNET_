# CHANGELOG interno

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
