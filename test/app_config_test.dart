import 'package:flutter_test/flutter_test.dart';
import 'package:cres_carnets_ibmcloud/config/app_config.dart';
import 'package:cres_carnets_ibmcloud/config/app_environment.dart';
import 'package:cres_carnets_ibmcloud/config/environments/cres_config.dart';
import 'package:cres_carnets_ibmcloud/config/environments/loyola_demo_config.dart';
import 'package:cres_carnets_ibmcloud/config/environments/multitenant_config.dart';

void main() {
  group('App variant configuration', () {
    test('defaults to CRES when no APP_VARIANT is provided', () {
      expect(parseAppVariant(''), AppVariant.cres);
      expect(parseAppVariant('CRES'), AppVariant.cres);
      expect(AppConfig.current.variant, AppVariant.cres);
    });

    test('selects LOYOLA_DEMO from dart-define value', () {
      expect(parseAppVariant('LOYOLA_DEMO'), AppVariant.loyolaDemo);
      expect(parseAppVariant('loyola'), AppVariant.loyolaDemo);
    });

    test('selects MULTITENANT from dart-define value', () {
      expect(parseAppVariant('MULTITENANT'), AppVariant.multitenant);
      expect(parseAppVariant('generic'), AppVariant.multitenant);
    });

    test('keeps CRES production defaults in the CRES config', () {
      expect(cresConfig.storageNamespace, 'sasu_cres');
      expect(cresConfig.sqliteFileName, 'cres_carnets.sqlite');
      expect(cresConfig.features.updatesEnabled, isTrue);
      expect(cresConfig.features.localDemoModeEnabled, isFalse);
      expect(cresConfig.demoCredentials, isNull);
      expect(cresConfig.backendBaseUrl, isNotEmpty);
    });

    test('keeps LOYOLA demo isolated from production defaults', () {
      expect(loyolaDemoConfig.variant, AppVariant.loyolaDemo);
      expect(loyolaDemoConfig.storageNamespace, 'sasu_loyola_demo');
      expect(loyolaDemoConfig.sqliteFileName, 'sasu_loyola_demo.sqlite');
      expect(loyolaDemoConfig.backendBaseUrl, isEmpty);
      expect(loyolaDemoConfig.hasBackend, isFalse);
      expect(loyolaDemoConfig.features.updatesEnabled, isFalse);
      expect(loyolaDemoConfig.features.localDemoModeEnabled, isTrue);
      expect(loyolaDemoConfig.demoCredentials?.username, 'demo.loyola');
      expect(loyolaDemoConfig.environmentBanner, contains('datos ficticios'));
    });

    test('scopes local keys per institution', () {
      expect(cresConfig.scopedKey('auth_token'), 'sasu_cres_auth_token');
      expect(
        loyolaDemoConfig.scopedKey('auth_token'),
        'sasu_loyola_demo_auth_token',
      );
      expect(
        loyolaDemoConfig.scopedKey('auth_token'),
        isNot(cresConfig.scopedKey('auth_token')),
      );
      expect(
        multitenantConfig.scopedKey('auth_token'),
        'sasu_multitenant_auth_token',
      );
    });

    test('multitenant variant never falls back to CRES API', () {
      expect(multitenantConfig.variant, AppVariant.multitenant);
      expect(multitenantConfig.storageNamespace, 'sasu_multitenant');
      expect(multitenantConfig.backendBaseUrl, isEmpty);
      expect(multitenantConfig.features.remoteOperationsEnabled, isTrue);
      expect(multitenantConfig.features.updatesEnabled, isFalse);
    });
  });
}
