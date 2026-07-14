import 'package:flutter/material.dart';

import 'app_environment.dart';

@immutable
class InstitutionColors {
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color onSurface;
  final Color outline;

  const InstitutionColors({
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.outline,
  });
}

@immutable
class DemoCredentials {
  final String username;
  final String password;

  const DemoCredentials({
    required this.username,
    required this.password,
  });
}

@immutable
class FeatureFlags {
  final bool updatesEnabled;
  final bool remoteOperationsEnabled;
  final bool localDemoModeEnabled;

  const FeatureFlags({
    required this.updatesEnabled,
    required this.remoteOperationsEnabled,
    required this.localDemoModeEnabled,
  });
}

@immutable
class InstitutionConfig {
  final AppVariant variant;
  final String systemName;
  final String shortName;
  final String institutionName;
  final String institutionalSubtitle;
  final String environmentName;
  final String environmentBanner;
  final String clinicalDisclaimer;
  final String backendBaseUrl;
  final String updatesBaseUrl;
  final String supportEmail;
  final String supportWhatsApp;
  final String technologyRepresentative;
  final String windowTitle;
  final String executableName;
  final String internalId;
  final String storageNamespace;
  final String sqliteFileName;
  final String logoText;
  final String iconText;
  final InstitutionColors colors;
  final FeatureFlags features;
  final DemoCredentials? demoCredentials;

  const InstitutionConfig({
    required this.variant,
    required this.systemName,
    required this.shortName,
    required this.institutionName,
    required this.institutionalSubtitle,
    required this.environmentName,
    required this.environmentBanner,
    required this.clinicalDisclaimer,
    required this.backendBaseUrl,
    required this.updatesBaseUrl,
    required this.supportEmail,
    required this.supportWhatsApp,
    required this.technologyRepresentative,
    required this.windowTitle,
    required this.executableName,
    required this.internalId,
    required this.storageNamespace,
    required this.sqliteFileName,
    required this.logoText,
    required this.iconText,
    required this.colors,
    required this.features,
    this.demoCredentials,
  });

  bool get isDemo => variant == AppVariant.loyolaDemo;
  bool get hasBackend => backendBaseUrl.trim().isNotEmpty;
  bool get hasUpdatesBackend => updatesBaseUrl.trim().isNotEmpty;

  String scopedKey(String key) => '${storageNamespace}_$key';
}
