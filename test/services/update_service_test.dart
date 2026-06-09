import 'package:cres_carnets_ibmcloud/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VersionInfo.fromJson', () {
    test('reads sha256 metadata into checksum field', () {
      final versionInfo = VersionInfo.fromJson({
        'version': '2.4.36',
        'buildNumber': 36,
        'releaseDate': '2026-06-08',
        'downloadUrl': 'https://example.com/CRES_Carnets_Setup_v2.4.36.exe',
        'fileSize': 123,
        'sha256': 'ABC123',
        'isMandatory': false,
        'changelog': ['test'],
      });

      expect(versionInfo.checksum, 'ABC123');
      expect(versionInfo.buildNumber, 36);
      expect(versionInfo.downloadUrl, contains('2.4.36'));
    });

    test('keeps compatibility with legacy checksum metadata', () {
      final versionInfo = VersionInfo.fromJson({
        'version': '2.4.36',
        'build_number': 36,
        'release_date': '2026-06-08',
        'download_url': 'https://example.com/CRES_Carnets_Setup_v2.4.36.exe',
        'file_size': 123,
        'checksum': 'def456',
        'is_mandatory': false,
        'changelog': ['test'],
      });

      expect(versionInfo.checksum, 'def456');
      expect(versionInfo.buildNumber, 36);
    });
  });
}
