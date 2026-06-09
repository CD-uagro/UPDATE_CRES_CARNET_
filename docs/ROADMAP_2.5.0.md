# Roadmap 2.5.0 - Fase visual SASU UAGro / CRES Carnets

## Estado actual de 2.4.36

La version 2.4.36 queda como version estable publicada.

- version.json: 2.4.36 / build 36.
- Instalador publicado: CRES_Carnets_Setup_v2.4.36.exe.
- GitHub Release: v2.4.36.
- Backend de updates: anuncia 2.4.36.
- SHA256 publicado: 0E1ACBBE6BEA4BD2AF4BC893AAFAC4A3630B7BD2D1A40E8D940838D5865BEB6C.
- fileSize publicado: 13865834.
- App validada en prueba piloto local.

La rama de trabajo 2.5.0 inicia como fase de mejora visual y limpieza acumulada. No implica cambiar version.json todavia.

## Que NO se tocara en esta fase inicial

- No reempaquetar 2.4.36.
- No regenerar instalador 2.4.36.
- No modificar backend productivo hasta que exista candidato 2.5.0 validado.
- No publicar GitHub hasta tener instalador 2.5.0 final.
- No cambiar SQLite ni rutas de datos locales.
- No cambiar accesos directos sin una tarea explicita.
- No modificar el flujo de descarga, cierre o ejecucion del actualizador salvo mejoras planificadas y testeadas.
- No cambiar version.json a 2.5.0 hasta iniciar formalmente el ciclo de release.

## Objetivos de 2.5.0

- Mejorar la claridad visual del dashboard.
- Eliminar textos legacy o inconsistentes en UI.
- Hacer mas robusta la presentacion de version instalada.
- Mejorar la lectura de expediente, escuela/unidad academica y grupo.
- Refinar la experiencia responsiva en desktop y pantallas pequenas.
- Revisar iconografia y consistencia visual.
- Pulir la experiencia de actualizacion para usuarios reales.

## Lista priorizada de cambios visuales

### Prioridad 1 - Correcciones visibles y consistencia

- Confirmar la correccion definitiva de version mostrada en dashboard usando VersionService.
- Evitar fallbacks con versiones hardcodeadas.
- Revisar textos de footer como "Version 1.0 - CRES UAGro 2025".
- Normalizar nombres visibles: SASU, CRES Carnets UAGro y Sistema de Atencion en Salud Universitaria.
- Revisar accesos del dashboard para que nombres, permisos e iconos comuniquen la accion real.

### Prioridad 2 - Dashboard

- Redisenar jerarquia visual del dashboard.
- Separar informacion de usuario, estado de conexion, sincronizacion y version.
- Mejorar densidad visual para trabajo diario.
- Evitar tarjetas excesivamente grandes en desktop.
- Mejorar comportamiento responsivo en pantallas pequenas.

### Prioridad 3 - Expediente y notas

- Mejorar presentacion de escuelaUnidadAcademica y grupo.
- Confirmar que registros viejos muestren "No especificada" y grupo vacio sin romper layout.
- Revisar orden, etiquetas y espaciado de Programa, Categoria, Escuela o Unidad Academica y Grupo.
- Mejorar lectura de notas y datos recuperados desde nube.

### Prioridad 4 - Iconos y lenguaje visual

- Revisar iconos de crear carnet, expedientes, promocion, vacunacion, sincronizacion y actualizaciones.
- Usar iconos consistentes con acciones reales.
- Reducir ruido visual y estados ambiguos.
- Mantener identidad UAGro sin saturar la interfaz.

### Prioridad 5 - Experiencia de actualizacion

- Revisar textos del flujo de actualizacion.
- Mostrar version actual, version disponible, tamano y estado de validacion SHA256 de forma clara.
- Evitar que usuarios abran accesos directos obsoletos cuando sea posible en una fase posterior.
- Documentar estrategia segura antes de tocar accesos directos.

## Riesgos

- Cambios visuales pueden afectar flujos criticos si se mezclan con logica de sincronizacion.
- Ajustes responsivos pueden romper pantallas pequenas si no se prueban con tamanos reales.
- Textos de version pueden volver a divergir si se introduce otra fuente distinta a VersionService.
- La coexistencia de accesos directos antiguos puede confundir pruebas manuales.
- El instalador 2.4.36 publicado no incluye la correccion local del fallback visual; esto es aceptado y se corrige en la siguiente version.

## Criterios para publicar 2.5.0

- version.json actualizado formalmente a 2.5.0 solo al entrar en fase release.
- sync_version.ps1 valida assets/version.json, pubspec.yaml e installer/setup_script.iss.
- build_installer.ps1 -ValidateOnly pasa.
- Tests unitarios y de flujo de actualizacion pasan.
- Dashboard muestra version real desde VersionService.
- Expediente muestra escuelaUnidadAcademica y grupo correctamente.
- Pruebas manuales pasan: login, busqueda expediente, notas, sincronizacion basica y actualizaciones.
- Instalador 2.5.0 generado con SHA256 y fileSize reales.
- Metadata local generada en dry-run antes de publicar.
- Publicacion GitHub validada por descarga publica y SHA256.
- Backend productivo publicado solo despues de validar que version remota anterior sea menor.
