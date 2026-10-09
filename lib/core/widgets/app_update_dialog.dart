import 'package:flutter/material.dart';

import '../../services/app_update_service.dart';
import '../theme/app_colors.dart';

/// Update dialogs shared by the Settings screen and the launch auto-check.
///
/// Android's package installer always shows its own confirmation — this never
/// installs silently.
abstract class AppUpdateDialogs {
  static const _gold = GSColors.gold500;
  static const _goldDark = Color(0xFFC98A1B);
  static const _navy = GSColors.navy900;
  static const _slate = Color(0xFF627193);
  static const _dark = Color(0xFF0A1A44);
  static const _skyCard = Color(0xFFF0F7FF);
  static const _skyBorder = Color(0xFFD8E9FE);

  static RoundedRectangleBorder get _shape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(24));

  /// Keeps auto-generated release notes from overflowing the dialog.
  static String _shorten(String text, [int max = 400]) {
    final t = text.trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max).trimRight()}…';
  }

  /// Shows the "update available" dialog, then drives download + install.
  static Future<void> showAvailable(
      BuildContext context, AppUpdateInfo info) async {
    final start = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: _shape,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [_gold, _goldDark]),
              ),
              child: const Icon(Icons.system_update_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Update Available',
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      color: _navy)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Version ${info.versionName} is available.',
                  style: const TextStyle(fontSize: 13, color: _dark)),
              if (info.apkSizeLabel.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Download size: ${info.apkSizeLabel}',
                    style: const TextStyle(fontSize: 12, color: _slate)),
              ],
              if (info.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _skyCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x99DBEAFE)),
                  ),
                  child: Text(_shorten(info.releaseNotes),
                      style: const TextStyle(
                          fontSize: 12, color: _dark, height: 1.4)),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Later', style: TextStyle(color: _slate)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _gold, foregroundColor: Colors.white),
            child: const Text('Download & Install'),
          ),
        ],
      ),
    );
    if (start == true && context.mounted) {
      await _downloadAndInstall(context, info);
    }
  }

  static Future<void> _downloadAndInstall(
      BuildContext context, AppUpdateInfo info) async {
    // Android requires a per-app "install unknown apps" grant.
    if (!await AppUpdateService.instance.canInstall()) {
      if (!context.mounted) return;
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: _shape,
          title: const Text('Allow installs',
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  color: _navy)),
          content: const Text(
            'Android needs your permission before it can install the update.\n\n'
            'On the next screen, turn on "Allow from this source" for '
            'Global Solar 2.0, then tap Download & Install again.',
            style: TextStyle(fontSize: 13, height: 1.5, color: _slate),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: _slate)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _gold, foregroundColor: Colors.white),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (open == true) {
        await AppUpdateService.instance.openInstallSettings();
      }
      return;
    }

    if (!context.mounted) return;

    final progress = ValueNotifier<double>(0);
    var dialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: _shape,
          title: const Text('Downloading update…',
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  color: _navy)),
          content: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (_, value, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: value > 0 ? value : null,
                  backgroundColor: _skyBorder,
                  color: _gold,
                  minHeight: 8,
                ),
                const SizedBox(height: 10),
                Text(
                    value > 0
                        ? '${(value * 100).toStringAsFixed(0)}%'
                        : 'Starting…',
                    style: const TextStyle(fontSize: 12, color: _slate)),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => dialogOpen = false);

    String? path;
    String? error;
    try {
      path = await AppUpdateService.instance.downloadApk(
        info,
        onProgress: (received, total) {
          if (total > 0) progress.value = (received / total).clamp(0.0, 1.0);
        },
      );
    } on AppUpdateException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'The download failed. Please try again.';
    }

    if (context.mounted && dialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      dialogOpen = false;
    }
    if (!context.mounted) return;

    if (error != null || path == null) {
      final retry = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: _shape,
          title: const Text('Update failed',
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  color: _navy)),
          content: Text(error ?? 'The download failed. Please try again.',
              style:
                  const TextStyle(fontSize: 13, height: 1.5, color: _slate)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Close', style: TextStyle(color: _slate)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _gold, foregroundColor: Colors.white),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
      if (retry == true && context.mounted) {
        await _downloadAndInstall(context, info);
      }
      return;
    }

    final launched = await AppUpdateService.instance.installApk(path);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open the installer. Please try again.')));
    }
  }
}
