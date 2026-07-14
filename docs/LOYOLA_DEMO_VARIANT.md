# Variante institucional LOYOLA Demo

## Objetivo

La variante `LOYOLA_DEMO` permite presentar el sistema como `Sistema de Atencion en Salud Digital` para la institucion LOYOLA sin usar sesiones, base local, actualizaciones ni backend de CRES/UAGro.

## Arquitectura

La configuracion institucional vive en:

- `lib/config/app_environment.dart`
- `lib/config/institution_config.dart`
- `lib/config/app_config.dart`
- `lib/config/environments/cres_config.dart`
- `lib/config/environments/loyola_demo_config.dart`

`APP_VARIANT` selecciona la variante por `--dart-define`. Si no se define, el default sigue siendo `CRES`.

## Archivos creados

- `lib/config/app_environment.dart`
- `lib/config/institution_config.dart`
- `lib/config/app_config.dart`
- `lib/config/environments/cres_config.dart`
- `lib/config/environments/loyola_demo_config.dart`
- `lib/data/demo/loyola_demo_data.dart`
- `test/app_config_test.dart`
- `tool/build_loyola_demo.ps1`
- `installer/setup_loyola_demo.iss`
- `.env.example`
- `docs/LOYOLA_DEMO_VARIANT.md`

## Archivos modificados

- `lib/main.dart`
- `lib/data/api_service.dart`
- `lib/data/auth_service.dart`
- `lib/data/db.dart`
- `lib/data/offline_manager.dart`
- `lib/data/recent_activity_service.dart`
- `lib/services/update_service.dart`
- `lib/services/update_manager.dart`
- `lib/ui/brand.dart`
- `lib/screens/auth/login_screen.dart`
- `lib/screens/dashboard_screen.dart`
- `lib/screens/vaccination_screen.dart`

## Ejecutar CRES

```powershell
flutter run -d windows --dart-define=APP_VARIANT=CRES
```

Tambien funciona sin `APP_VARIANT`, porque `CRES` es el valor predeterminado.

## Ejecutar LOYOLA

Modo local seguro, sin backend demo:

```powershell
flutter run -d windows --dart-define=APP_VARIANT=LOYOLA_DEMO
```

Con backend demo:

```powershell
flutter run -d windows --dart-define=APP_VARIANT=LOYOLA_DEMO --dart-define=LOYOLA_API_BASE_URL=https://backend-loyola-demo.example.invalid
```

## Compilar ambas variantes

CRES:

```powershell
flutter build windows --release --dart-define=APP_VARIANT=CRES
```

LOYOLA:

```powershell
flutter build windows --release `
  --dart-define=APP_VARIANT=LOYOLA_DEMO `
  --dart-define=LOYOLA_API_BASE_URL=https://backend-loyola-demo.example.invalid
```

Paquete LOYOLA con ejecutable renombrado:

```powershell
.\tool\build_loyola_demo.ps1
```

Con backend demo:

```powershell
.\tool\build_loyola_demo.ps1 -LoyolaApiBaseUrl "https://backend-loyola-demo.example.invalid"
```

El paquete queda en `releases\loyola_demo\SASU_LOYOLA_Demo\` y el ejecutable se llama `SASU_LOYOLA_Demo.exe`.

## Backend demo

LOYOLA lee su backend desde `LOYOLA_API_BASE_URL`. Si no se proporciona, no usa la API productiva y arranca en modo local de demostracion.

Las URLs de CRES que estaban fijas en servicios criticos fueron parametrizadas desde `AppConfig`; no se copian secretos ni credenciales reales.

## Modo local

Cuando `APP_VARIANT=LOYOLA_DEMO` y `LOYOLA_API_BASE_URL` esta vacio:

- se habilita login local demo
- se usa SQLite local `sasu_loyola_demo.sqlite`
- se insertan alumnos y notas ficticias
- las operaciones remotas no tienen backend productivo
- las actualizaciones quedan desactivadas

Credenciales:

- Usuario: `demo.loyola`
- Contrasena: `LoyolaDemo2026!`

Estas credenciales solo estan previstas para `LOYOLA_DEMO`; CRES no define usuario demo.

## Identidad visual

La demo usa un placeholder tipografico `LOYOLA`, no un logo oficial inventado. Para reemplazarlo, ajustar `loyola_demo_config.dart` y/o sustituir `maybeUAGroLogo` por un asset real cuando LOYOLA entregue marca autorizada.

Colores iniciales:

- azul institucional
- blanco
- gris claro
- acento verde discreto

## Nueva variante futura

Para otra institucion:

1. Crear `lib/config/environments/<institucion>_config.dart`.
2. Agregar el valor al enum `AppVariant`.
3. Registrar la seleccion en `AppConfig.current`.
4. Definir `storageNamespace`, `sqliteFileName`, URLs, soporte, textos y feature flags.
5. Agregar pruebas equivalentes en `test/app_config_test.dart`.

## Medidas contra mezcla de datos

- Namespace de storage CRES: `sasu_cres`.
- Namespace de storage LOYOLA: `sasu_loyola_demo`.
- SQLite CRES: `cres_carnets.sqlite`.
- SQLite LOYOLA: `sasu_loyola_demo.sqlite`.
- Llaves de `SharedPreferences` y `FlutterSecureStorage` se prefijan con el namespace.
- LOYOLA no cae silenciosamente al backend CRES.
- Actualizaciones LOYOLA desactivadas por default.
- Instalador LOYOLA con `AppId` y ruta de instalacion separados.

## Limitaciones pendientes

- Algunas pantallas internas conservan nombres historicos en comentarios o textos secundarios. El login, dashboard, auth, API, updates y almacenamiento ya estan aislados.
- El nombre interno del ejecutable que genera Flutter sigue siendo el del proyecto; el script copia el build y renombra solo la copia demo.
- Para una demo conectada real falta desplegar un backend LOYOLA separado y pasar su URL por `LOYOLA_API_BASE_URL`.

## Validacion

Comandos recomendados:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build windows --release --dart-define=APP_VARIANT=CRES
flutter build windows --release --dart-define=APP_VARIANT=LOYOLA_DEMO
```

## Advertencia clinica

La demo no es para atencion clinica real:

`Sistema de demostracion. Toda la informacion mostrada es ficticia y no debe utilizarse para atencion clinica real.`
