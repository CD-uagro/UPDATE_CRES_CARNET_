import 'package:flutter/material.dart';

import '../app_environment.dart';
import '../institution_config.dart';

const loyolaDemoConfig = InstitutionConfig(
  variant: AppVariant.loyolaDemo,
  systemName: 'Sistema de Atencion en Salud Digital',
  shortName: 'LOYOLA Salud Digital',
  institutionName: 'LOYOLA',
  institutionalSubtitle: 'Entorno educativo de demostracion',
  environmentName: 'Demostracion',
  environmentBanner: 'Entorno de demostracion - datos ficticios',
  clinicalDisclaimer:
      'Sistema de demostracion. Toda la informacion mostrada es ficticia y no debe utilizarse para atencion clinica real.',
  backendBaseUrl: String.fromEnvironment('LOYOLA_API_BASE_URL'),
  updatesBaseUrl: String.fromEnvironment('LOYOLA_UPDATES_BASE_URL'),
  supportEmail: 'gvalenzuela@somoseduk.org',
  supportWhatsApp: '7442161616',
  technologyRepresentative: 'Dr. Gilberto Valenzuela Herrera',
  windowTitle: 'LOYOLA | Sistema de Atencion en Salud Digital',
  executableName: 'SASU_LOYOLA_Demo.exe',
  internalId: 'sasu_loyola_demo',
  storageNamespace: 'sasu_loyola_demo',
  sqliteFileName: 'sasu_loyola_demo.sqlite',
  logoText: 'LOYOLA',
  iconText: 'DEMO',
  colors: InstitutionColors(
    primary: Color(0xFF123D75),
    primaryDark: Color(0xFF0A2545),
    secondary: Color(0xFFFFFFFF),
    accent: Color(0xFF2E7D59),
    background: Color(0xFFF5F7FA),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF26313D),
    outline: Color(0xFFD5DCE5),
  ),
  features: FeatureFlags(
    updatesEnabled: false,
    remoteOperationsEnabled: false,
    localDemoModeEnabled: true,
  ),
  demoCredentials: DemoCredentials(
    username: 'demo.loyola',
    password: 'LoyolaDemo2026!',
  ),
);
