import 'package:cres_carnets_ibmcloud/services/version_service.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _baseVersionJson({Object? changelog = const []}) {
  final json = <String, dynamic>{
    'version': '2.4.36',
    'buildNumber': 36,
    'releaseDate': '2026-06-08',
    'channel': 'internal',
    'minimumVersion': '2.0.0',
  };

  if (changelog != null) {
    json['changelog'] = changelog;
  }

  return json;
}

void main() {
  group('AppVersionInfo.fromJson', () {
    test('loads version and build when changelog is a list of strings', () {
      final info = AppVersionInfo.fromJson(_baseVersionJson(
        changelog: ['Cambio 1', 'Cambio 2'],
      ));

      expect(info.version, '2.4.36');
      expect(info.buildNumber, 36);
      expect(info.changelog, hasLength(2));
      expect(info.changelog.first.changes, ['Cambio 1']);
    });

    test('loads version and build when changelog is a list of objects', () {
      final info = AppVersionInfo.fromJson(_baseVersionJson(
        changelog: [
          {'title': 'Cambio 1', 'description': 'Detalle'},
        ],
      ));

      expect(info.version, '2.4.36');
      expect(info.buildNumber, 36);
      expect(info.changelog, hasLength(1));
      expect(info.changelog.first.changes, ['Cambio 1', 'Detalle']);
    });

    test('loads version and build when changelog is absent', () {
      final info = AppVersionInfo.fromJson(_baseVersionJson(changelog: null));

      expect(info.version, '2.4.36');
      expect(info.buildNumber, 36);
      expect(info.changelog, isEmpty);
    });

    test('ignores unexpected changelog entries without failing version parsing',
        () {
      final info = AppVersionInfo.fromJson(_baseVersionJson(
        changelog: [
          {'unknown': 'format'},
          123,
        ],
      ));

      expect(info.version, '2.4.36');
      expect(info.buildNumber, 36);
      expect(info.changelog, hasLength(1));
      expect(info.changelog.single.changes, ['123']);
    });
  });
}
