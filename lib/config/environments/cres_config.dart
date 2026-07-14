import 'package:flutter/material.dart';

import '../app_environment.dart';
import '../institution_config.dart';

const cresConfig = InstitutionConfig(
  variant: AppVariant.cres,
  systemName: 'CRES Carnets - UAGro',
  shortName: 'CRES',
  institutionName: 'Universidad Autonoma de Guerrero',
  institutionalSubtitle: 'Sistema de Atencion en Salud Universitaria',
  environmentName: 'Produccion',
  environmentBanner: '',
  clinicalDisclaimer: '',
  backendBaseUrl: String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://fastapi-backend-o7ks.onrender.com',
  ),
  updatesBaseUrl: String.fromEnvironment(
    'UPDATES_BASE_URL',
    defaultValue: 'https://fastapi-backend-o7ks.onrender.com',
  ),
  supportEmail: 'innovasalud@uagro.mx',
  supportWhatsApp: '',
  technologyRepresentative: 'Direccion de Innovacion en Salud',
  windowTitle: 'CENTRO REGIONAL DE EDUCACION SUPERIOR LLANO LARGO',
  executableName: 'cres_carnets_ibmcloud.exe',
  internalId: 'sasu_cres',
  storageNamespace: 'sasu_cres',
  sqliteFileName: 'cres_carnets.sqlite',
  logoText: 'UAGro',
  iconText: 'SASU',
  colors: InstitutionColors(
    primary: Color(0xFF0E2A66),
    primaryDark: Color(0xFF041D4D),
    secondary: Color(0xFFB00020),
    accent: Color(0xFFF2B705),
    background: Color(0xFFFAFBFF),
    surface: Color(0xFFF6F7FB),
    onSurface: Color(0xFF44474F),
    outline: Color(0xFFC4C7C5),
  ),
  features: FeatureFlags(
    updatesEnabled: true,
    remoteOperationsEnabled: true,
    localDemoModeEnabled: false,
  ),
);
