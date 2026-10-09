import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Thrown for any user-facing update failure (network, HTTP, blocked URL...).
class AppUpdateException implements Exception {
  final String message;
  const AppUpdateException(this.message);
  @override
  String toString() => message;
}

/// The installed app version, read from Android's PackageManager.
class AppVersion {
  final String versionName;
  final int versionCode;
  const AppVersion({required this.versionName, required this.versionCode});
}

/// A newer release available on GitHub.
class AppUpdateInfo {
  final String versionName; // e.g. 1.0.1
  final String tagName; // e.g. v1.0.1
  final String apkUrl; // validated HTTPS url on github.com
  final int apkSizeBytes;
  final String releaseNotes;

  const AppUpdateInfo({
    required this.versionName,
    required this.tagName,
    required this.apkUrl,
    required this.apkSizeBytes,
    required this.releaseNotes,
  });

  String get apkSizeLabel {
    if (apkSizeBytes <= 0) return '';
    final mb = apkSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Checks GitHub Releases for a newer build of this app and downloads it.
///
/// Security notes:
/// - The repository is public, so no token is embedded here. A token would be
///   extractable from the APK and would grant access to the whole repository.
/// - The APK URL must be HTTPS on github.com under this repository's
///   `releases/download/` path. Anything else is refused.
/// - TLS certificate verification is left at Dart's default (enabled). It is
///   never disabled, and GitHub's redirect to its own CDN is followed over TLS.
class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  static const String owner = 'kedar-bhatt-au49';
  static const String repo = 'client_flutter_app';

  /// Used only when the platform channel is unavailable (desktop/dev runs).
  static const String fallbackVersionName = '1.0.0';

  static const MethodChannel _channel = MethodChannel('global_solar/updater');

  // ── Platform channel ───────────────────────────────────────────────

  Future<AppVersion> installedVersion() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('getVersion');
      final name = (res?['versionName'] as String?)?.trim() ?? '';
      final code = (res?['versionCode'] as num?)?.toInt() ?? 0;
      return AppVersion(
        versionName: name.isEmpty ? fallbackVersionName : name,
        versionCode: code,
      );
    } on MissingPluginException {
      return const AppVersion(versionName: fallbackVersionName, versionCode: 0);
    }
  }

  Future<bool> canInstall() async {
    try {
      return (await _channel.invokeMethod<bool>('canInstall')) ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> openInstallSettings() async {
    try {
      await _channel.invokeMethod('openInstallSettings');
    } on MissingPluginException {
      // Non-Android platform — nothing to open.
    }
  }

  Future<bool> installApk(String path) async {
    try {
      return (await _channel.invokeMethod<bool>('installApk', {'path': path})) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  // ── Pure logic (unit-tested) ───────────────────────────────────────

  /// Parses "v1.2.3", "1.2.3+build", "1.2.3-rc1" into [major, minor, patch].
  static List<int> parseVersion(String version) {
    var s = version.trim();
    if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
    s = s.split('+').first.split('-').first;
    final parts = s.split('.');
    final out = <int>[0, 0, 0];
    for (var i = 0; i < out.length && i < parts.length; i++) {
      out[i] = int.tryParse(parts[i].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    return out;
  }

  /// Positive when [a] is newer than [b], 0 when equal, negative when older.
  static int compareVersions(String a, String b) {
    final pa = parseVersion(a);
    final pb = parseVersion(b);
    for (var i = 0; i < pa.length; i++) {
      final diff = pa[i].compareTo(pb[i]);
      if (diff != 0) return diff;
    }
    return 0;
  }

  static bool isNewerVersion(String latest, String current) =>
      compareVersions(latest, current) > 0;

  /// Allows only HTTPS github.com URLs under this repo's release downloads.
  /// Returns the URL when acceptable, otherwise null.
  static String? validateApkUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
    if (uri.scheme.toLowerCase() != 'https') return null;
    if (uri.host.toLowerCase() != 'github.com') return null;
    final prefix = '/$owner/$repo/releases/download/';
    if (!uri.path.startsWith(prefix)) return null;
    return uri.toString();
  }

  /// Extracts the APK asset from a GitHub `releases/latest` JSON payload.
  static AppUpdateInfo? parseLatestRelease(Map<String, dynamic> json) {
    final tag = (json['tag_name'] as String?)?.trim();
    if (tag == null || tag.isEmpty) return null;

    final assets = json['assets'];
    if (assets is! List) return null;

    for (final asset in assets) {
      if (asset is! Map) continue;
      final name = (asset['name'] as String?) ?? '';
      if (!name.toLowerCase().endsWith('.apk')) continue;
      final rawUrl = asset['browser_download_url'] as String?;
      if (rawUrl == null) continue;
      final safeUrl = validateApkUrl(rawUrl);
      if (safeUrl == null) continue;

      return AppUpdateInfo(
        versionName: tag.replaceFirst(RegExp(r'^[vV]'), ''),
        tagName: tag,
        apkUrl: safeUrl,
        apkSizeBytes: (asset['size'] as num?)?.toInt() ?? 0,
        releaseNotes: (json['body'] as String?)?.trim() ?? '',
      );
    }
    return null;
  }

  // ── Network ────────────────────────────────────────────────────────

  /// Returns update info when a strictly newer release with an APK exists.
  /// Returns null when already up to date (or no release/APK yet).
  Future<AppUpdateInfo?> checkForUpdate({
    required String currentVersionName,
  }) async {
    final uri = Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      req.headers.set(HttpHeaders.userAgentHeader, 'GlobalSolar2.0-Updater');
      final res = await req.close().timeout(const Duration(seconds: 15));

      // 404 simply means no release has been published yet.
      if (res.statusCode == HttpStatus.notFound) return null;
      if (res.statusCode != HttpStatus.ok) {
        throw AppUpdateException('GitHub returned HTTP ${res.statusCode}.');
      }

      final body = await res.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;

      final info = parseLatestRelease(decoded);
      if (info == null) return null;
      if (!isNewerVersion(info.versionName, currentVersionName)) return null;
      return info;
    } on SocketException {
      throw const AppUpdateException(
          'Could not reach GitHub. Check your internet connection.');
    } on TimeoutException {
      throw const AppUpdateException('The update check timed out. Try again.');
    } on FormatException {
      throw const AppUpdateException('Received an unexpected response from GitHub.');
    } finally {
      client.close(force: true);
    }
  }

  /// Downloads the APK to the app cache and returns its local path.
  Future<String> downloadApk(
    AppUpdateInfo info, {
    void Function(int received, int total)? onProgress,
  }) async {
    final safeUrl = validateApkUrl(info.apkUrl);
    if (safeUrl == null) {
      throw const AppUpdateException('Blocked an unexpected download URL.');
    }

    final tempDir = await getTemporaryDirectory();
    final updatesDir = Directory('${tempDir.path}/updates');
    if (!await updatesDir.exists()) {
      await updatesDir.create(recursive: true);
    }
    final file = File('${updatesDir.path}/global-solar-${info.versionName}.apk');
    if (await file.exists()) {
      await file.delete();
    }

    final client = HttpClient();
    IOSink? sink;
    try {
      final req = await client.getUrl(Uri.parse(safeUrl));
      req.headers.set(HttpHeaders.userAgentHeader, 'GlobalSolar2.0-Updater');
      final res = await req.close().timeout(const Duration(seconds: 30));
      if (res.statusCode != HttpStatus.ok) {
        throw AppUpdateException('Download failed (HTTP ${res.statusCode}).');
      }

      final total = res.contentLength > 0 ? res.contentLength : info.apkSizeBytes;
      sink = file.openWrite();
      var received = 0;
      await for (final chunk in res) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.flush();
      await sink.close();
      sink = null;

      if (received == 0) {
        throw const AppUpdateException('The downloaded file was empty.');
      }
      return file.path;
    } on SocketException {
      throw const AppUpdateException(
          'Download failed — network error. Please try again.');
    } on TimeoutException {
      throw const AppUpdateException('The download timed out. Please try again.');
    } finally {
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      client.close(force: true);
    }
  }
}
