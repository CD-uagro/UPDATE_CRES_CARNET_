import 'package:cres_carnets_ibmcloud/services/version_comparator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('compareSemanticVersions', () {
    test('orders patch versions numerically', () {
      expect(compareSemanticVersions('2.4.9', '2.4.10'), isNegative);
    });

    test('blocks server versions lower than the installed version', () {
      expect(compareSemanticVersions('2.4.20', '2.4.35'), isNegative);
    });

    test('treats equal versions as equal', () {
      expect(compareSemanticVersions('2.4.35', '2.4.35'), 0);
    });

    test('orders minor versions above larger patch versions', () {
      expect(compareSemanticVersions('2.5.0', '2.4.99'), isPositive);
    });
  });
}
