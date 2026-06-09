import 'dart:io';

import 'package:cres_carnets_ibmcloud/services/update_downloader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpdateDownloader.verifyChecksum', () {
    late Directory tempDir;
    late File file;
    late UpdateDownloader downloader;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sasu_checksum_test_');
      file = File('${tempDir.path}${Platform.pathSeparator}update.bin');
      await file.writeAsString('hello');
      downloader = UpdateDownloader();
    });

    tearDown(() async {
      downloader.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns true when SHA256 matches', () async {
      const expected = '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e730'
          '43362938b9824';

      expect(await downloader.verifyChecksum(file.path, expected), isTrue);
    });

    test('compares checksum case-insensitively', () async {
      const expected = '2CF24DBA5FB0A30E26E83B2AC5B9E29E1B161E5C1FA7425E730'
          '43362938B9824';

      expect(await downloader.verifyChecksum(file.path, expected), isTrue);
    });

    test('returns false when SHA256 does not match', () async {
      const expected =
          '0000000000000000000000000000000000000000000000000000000000000000';

      expect(await downloader.verifyChecksum(file.path, expected), isFalse);
    });

    test('returns false when expected checksum is empty', () async {
      expect(await downloader.verifyChecksum(file.path, '   '), isFalse);
    });
  });
}
