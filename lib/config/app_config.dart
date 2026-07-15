import 'app_environment.dart';
import 'environments/cres_config.dart';
import 'environments/loyola_demo_config.dart';
import 'environments/multitenant_config.dart';
import 'institution_config.dart';

class AppConfig {
  AppConfig._();

  static const String _variantDefine = String.fromEnvironment(
    'APP_VARIANT',
    defaultValue: 'CRES',
  );

  static final AppVariant variant = parseAppVariant(_variantDefine);

  static final InstitutionConfig current = switch (variant) {
    AppVariant.loyolaDemo => loyolaDemoConfig,
    AppVariant.multitenant => multitenantConfig,
    AppVariant.cres => cresConfig,
  };

  static bool get isLoyolaDemo => variant == AppVariant.loyolaDemo;
  static bool get isMultitenant => variant == AppVariant.multitenant;
  static bool get isCres => variant == AppVariant.cres;

  static String scopedKey(String key) => current.scopedKey(key);
}
