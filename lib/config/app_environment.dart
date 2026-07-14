enum AppVariant {
  cres,
  loyolaDemo,
}

extension AppVariantName on AppVariant {
  String get defineValue {
    switch (this) {
      case AppVariant.cres:
        return 'CRES';
      case AppVariant.loyolaDemo:
        return 'LOYOLA_DEMO';
    }
  }
}

AppVariant parseAppVariant(String value) {
  switch (value.trim().toUpperCase()) {
    case 'LOYOLA_DEMO':
    case 'LOYOLA':
      return AppVariant.loyolaDemo;
    case 'CRES':
    default:
      return AppVariant.cres;
  }
}
