import 'package:flutter/material.dart';

import '../app_environment.dart';
import '../institution_config.dart';

const String multitenantApiBaseUrl = String.fromEnvironment(
  'MULTITENANT_API_BASE_URL',
  defaultValue: '',
);

const multitenantConfig = InstitutionConfig(
  variant: AppVariant.multitenant,
  systemName: 'Sistema de Atencion en Salud Digital',
  shortName: 'Salud Digital',
  institutionName: 'Institucion',
  institutionalSubtitle: 'Plataforma multiinstitucion',
  environmentName: 'Staging multitenant',
  environmentBanner: 'Entorno de pruebas',
  clinicalDisclaimer: 'Entorno de pruebas con datos ficticios.',
  backendBaseUrl: multitenantApiBaseUrl,
  updatesBaseUrl: '',
  supportEmail: 'soporte@somoseduk.org',
  supportWhatsApp: '',
  technologyRepresentative: 'Eduk',
  windowTitle: 'Sistema de Atencion en Salud Digital',
  executableName: 'SaludDigitalInstitucional.exe',
  internalId: 'sasu_multitenant',
  storageNamespace: 'sasu_multitenant',
  sqliteFileName: 'sasu_multitenant.sqlite',
  logoText: 'SD',
  iconText: 'SD',
  colors: InstitutionColors(
    primary: Color(0xFF164E8A),
    primaryDark: Color(0xFF0B2F57),
    secondary: Color(0xFF1E8F5A),
    accent: Color(0xFFD8A21B),
    background: Color(0xFFF4F7FA),
    surface: Colors.white,
    onSurface: Color(0xFF17212B),
    outline: Color(0xFFCBD5E1),
  ),
  features: FeatureFlags(
    updatesEnabled: false,
    remoteOperationsEnabled: true,
    localDemoModeEnabled: false,
  ),
);
