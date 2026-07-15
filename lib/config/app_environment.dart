enum AppVariant {
  cres,
  loyolaDemo,
  multitenant,
}

extension AppVariantName on AppVariant {
  String get defineValue {
    switch (this) {
      case AppVariant.cres:
        return 'CRES';
      case AppVariant.loyolaDemo:
        return 'LOYOLA_DEMO';
      case AppVariant.multitenant:
        return 'MULTITENANT';
    }
  }
}

AppVariant parseAppVariant(String value) {
  switch (value.trim().toUpperCase()) {
    case 'LOYOLA_DEMO':
    case 'LOYOLA':
      return AppVariant.loyolaDemo;
    case 'MULTITENANT':
    case 'GENERIC':
      return AppVariant.multitenant;
    case 'CRES':
    default:
      return AppVariant.cres;
  }
}
