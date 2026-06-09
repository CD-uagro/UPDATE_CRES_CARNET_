import 'dart:io';

import 'package:cres_carnets_ibmcloud/services/update_downloader.dart';
import 'package:cres_carnets_ibmcloud/services/update_manager.dart';
import 'package:cres_carnets_ibmcloud/services/update_service.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';

class FakeUpdateDownloader extends UpdateDownloader {
  FakeUpdateDownloader(this.artifactPath);

  final String artifactPath;
  int downloadCalls = 0;
  int verifyCalls = 0;
  int executeCalls = 0;

  @override
  Future<String> downloadUpdate({
    required String downloadUrl,
    ProgressCallback? onProgress,
  }) async {
    downloadCalls++;
    onProgress?.call(1, 1);
    return artifactPath;
  }

  @override
  Future<bool> verifyChecksum(String filePath, String expectedChecksum) {
    verifyCalls++;
    return super.verifyChecksum(filePath, expectedChecksum);
  }

  @override
  Future<void> executeInstaller(String installerPath,
      {bool closeApp = true}) async {
    executeCalls++;
  }
}

void main() {
  group('UpdateManager safe update preparation', () {
    late Directory tempDir;
    late File artifact;
    late FakeUpdateDownloader downloader;
    late UpdateManager manager;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sasu_update_flow_test_');
      artifact = File('${tempDir.path}${Platform.pathSeparator}setup.exe');
      await artifact.writeAsString('SASU simulated installer 2.4.36');
      downloader = FakeUpdateDownloader(artifact.path);
      manager = UpdateManager(
        currentVersion: '2.4.35',
        currentBuild: 35,
        downloader: downloader,
      );
    });

    tearDown(() async {
      downloader.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    VersionInfo versionInfo({
      required String version,
      required String checksum,
    }) {
      return VersionInfo(
        version: version,
        buildNumber: 36,
        releaseDate: '2026-06-08',
        downloadUrl: 'file://${artifact.path}',
        checksum: checksum,
        isMandatory: false,
        changelog: const ['test update'],
      );
    }

    String artifactSha256() {
      final bytes = artifact.readAsBytesSync();
      return crypto.sha256.convert(bytes).toString();
    }

    test('validates a 2.4.36 update and stops before executing installer',
        () async {
      final preparedPath = await manager.prepareUpdateForInstall(
        versionInfo(version: '2.4.36', checksum: artifactSha256()),
      );

      expect(preparedPath, artifact.path);
      expect(await artifact.exists(), isTrue);
      expect(downloader.downloadCalls, 1);
      expect(downloader.verifyCalls, 1);
      expect(downloader.executeCalls, 0);
    });

    test('deletes downloaded artifact and does not execute when checksum fails',
        () async {
      await expectLater(
        manager.prepareUpdateForInstall(
          versionInfo(
            version: '2.4.36',
            checksum:
                '0000000000000000000000000000000000000000000000000000000000000000',
          ),
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Checksum'),
          ),
        ),
      );

      expect(await artifact.exists(), isFalse);
      expect(downloader.downloadCalls, 1);
      expect(downloader.verifyCalls, 1);
      expect(downloader.executeCalls, 0);
    });

    test('blocks older remote version before downloading or executing',
        () async {
      await expectLater(
        manager.prepareUpdateForInstall(
          versionInfo(version: '2.4.20', checksum: artifactSha256()),
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('versión anterior'),
          ),
        ),
      );

      expect(await artifact.exists(), isTrue);
      expect(downloader.downloadCalls, 0);
      expect(downloader.verifyCalls, 0);
      expect(downloader.executeCalls, 0);
    });
  });
}
