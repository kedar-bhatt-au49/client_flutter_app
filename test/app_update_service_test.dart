import 'package:flutter_test/flutter_test.dart';
import 'package:global_solar_client_app/services/app_update_service.dart';

void main() {
  group('parseVersion', () {
    test('strips leading v', () {
      expect(AppUpdateService.parseVersion('v1.2.3'), [1, 2, 3]);
    });

    test('ignores build metadata and pre-release suffixes', () {
      expect(AppUpdateService.parseVersion('1.0.1+2'), [1, 0, 1]);
      expect(AppUpdateService.parseVersion('1.2.3-rc1'), [1, 2, 3]);
    });

    test('pads missing components and survives junk', () {
      expect(AppUpdateService.parseVersion('2'), [2, 0, 0]);
      expect(AppUpdateService.parseVersion(''), [0, 0, 0]);
    });
  });

  group('version comparison', () {
    test('Scenario A — same version means no update', () {
      expect(AppUpdateService.isNewerVersion('1.0.1', '1.0.1'), isFalse);
    });

    test('Scenario B — newer version means update available', () {
      expect(AppUpdateService.isNewerVersion('1.0.1', '1.0.0'), isTrue);
    });

    test('older release is not an update', () {
      expect(AppUpdateService.isNewerVersion('1.0.0', '1.0.1'), isFalse);
    });

    test('compares components numerically, not lexically', () {
      expect(AppUpdateService.isNewerVersion('1.10.0', '1.9.9'), isTrue);
      expect(AppUpdateService.isNewerVersion('2.0.0', '10.0.0'), isFalse);
    });

    test('handles v-prefixed tags', () {
      expect(AppUpdateService.isNewerVersion('v1.0.2', '1.0.1'), isTrue);
    });
  });

  group('validateApkUrl', () {
    const good =
        'https://github.com/kedar-bhatt-au49/client_flutter_app/releases/download/v1.0.1/global-solar-2.0-v1.0.1.apk';

    test('accepts this repo release download over https', () {
      expect(AppUpdateService.validateApkUrl(good), good);
    });

    test('rejects plain http', () {
      expect(
        AppUpdateService.validateApkUrl(
            good.replaceFirst('https://', 'http://')),
        isNull,
      );
    });

    test('rejects a different host', () {
      expect(
        AppUpdateService.validateApkUrl(
            'https://evil.example.com/kedar-bhatt-au49/client_flutter_app/releases/download/v1.0.1/a.apk'),
        isNull,
      );
    });

    test('rejects a different repository', () {
      expect(
        AppUpdateService.validateApkUrl(
            'https://github.com/other/repo/releases/download/v1.0.1/a.apk'),
        isNull,
      );
    });

    test('rejects a non-release path on github.com', () {
      expect(
        AppUpdateService.validateApkUrl(
            'https://github.com/kedar-bhatt-au49/client_flutter_app/raw/main/a.apk'),
        isNull,
      );
    });
  });

  group('parseLatestRelease', () {
    Map<String, dynamic> release(String tag, List<Object> assets) => {
          'tag_name': tag,
          'body': 'Fixes',
          'assets': assets,
        };

    const apkUrl =
        'https://github.com/kedar-bhatt-au49/client_flutter_app/releases/download/v1.0.1/global-solar-2.0-v1.0.1.apk';

    test('picks the first trusted .apk asset', () {
      final info = AppUpdateService.parseLatestRelease(release('v1.0.1', [
        {
          'name': 'notes.txt',
          'browser_download_url':
              'https://github.com/kedar-bhatt-au49/client_flutter_app/releases/download/v1.0.1/notes.txt',
          'size': 10,
        },
        {'name': 'global-solar-2.0-v1.0.1.apk', 'browser_download_url': apkUrl, 'size': 12345678},
      ]));

      expect(info, isNotNull);
      expect(info!.versionName, '1.0.1');
      expect(info.tagName, 'v1.0.1');
      expect(info.apkUrl, apkUrl);
      expect(info.apkSizeBytes, 12345678);
      expect(info.releaseNotes, 'Fixes');
      expect(info.apkSizeLabel, '11.8 MB');
    });

    test('skips an apk served from an untrusted url', () {
      final info = AppUpdateService.parseLatestRelease(release('v1.0.1', [
        {
          'name': 'update.apk',
          'browser_download_url': 'https://evil.example.com/update.apk',
          'size': 5,
        },
      ]));
      expect(info, isNull);
    });

    test('returns null when no apk asset exists', () {
      final info = AppUpdateService.parseLatestRelease(release('v1.0.1', [
        {
          'name': 'source.zip',
          'browser_download_url':
              'https://github.com/kedar-bhatt-au49/client_flutter_app/releases/download/v1.0.1/source.zip',
          'size': 5,
        },
      ]));
      expect(info, isNull);
    });

    test('returns null without a tag name', () {
      expect(AppUpdateService.parseLatestRelease(release('', [])), isNull);
    });
  });
}
