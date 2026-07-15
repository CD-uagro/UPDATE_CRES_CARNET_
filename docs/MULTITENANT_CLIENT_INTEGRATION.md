# Generic Multitenant Client

## Variant

```text
APP_VARIANT=MULTITENANT
```

Visible name:

```text
Sistema de Atencion en Salud Digital
```

The default remains CRES. LOYOLA_DEMO local remains available.

## Staging URL

The generic client requires:

```text
MULTITENANT_API_BASE_URL=https://staging-url
```

If omitted, the app shows a configuration error and does not use the CRES API.

## Login Flow

1. Enter institutional code.
2. Resolve institution at `/v2/public/institution/resolve`.
3. Show branding, demo status, and modules.
4. Login at `/v2/auth/login`.
5. Store access and refresh tokens in Windows secure storage under `sasu_multitenant`.

The client never sends `tenant_id` to choose data after login.

## Build

```powershell
.\tool\build_multitenant_windows.ps1 -MultitenantApiBaseUrl https://staging-url
```

Output:

```text
releases/multitenant/SaludDigitalInstitucional/
```

Installer script:

```text
installer/setup_multitenant.iss
```
