import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_flavor.dart';

/// Result of a demo license check.
class LicenseStatus {
  /// True when the demo may be used.
  final bool licensed;

  /// Why it is not licensed: 'expired' | 'disabled' | null.
  final String? reason;

  /// When the demo expires (remote value or local trial end).
  final DateTime? expiresAt;

  /// True when the answer came from the local trial (server unreachable).
  final bool offline;

  const LicenseStatus({
    required this.licensed,
    this.reason,
    this.expiresAt,
    this.offline = false,
  });

  /// Always licensed — used for the production build.
  static const LicenseStatus licensedForever = LicenseStatus(licensed: true);

  /// Whole days remaining (never negative).
  int get daysLeft {
    final e = expiresAt;
    if (e == null) return 0;
    final d = e.difference(DateTime.now()).inHours / 24;
    return d <= 0 ? 0 : d.ceil();
  }
}

/// Time-boxed demo license with a **remote kill switch**.
///
/// The admin controls a Firestore document:
///   settings/license = { active: bool, expiresAt: <timestamp>, licensee: "..." }
///
/// - `active: false`  → the demo locks immediately (next launch).
/// - `expiresAt`      → the demo locks after that date.
/// - missing doc / offline → a local 7-day trial (from first run) applies.
///
/// The app can only *read* that document (Firestore rules deny client writes),
/// so the demo user cannot extend or re-enable it themselves.
class LicenseService {
  LicenseService._();
  static final LicenseService instance = LicenseService._();

  static const _firstRunKey = 'gs_demo_first_run';

  Future<LicenseStatus> check() async {
    if (!kDemoMode) return LicenseStatus.licensedForever;

    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    var firstRun = prefs.getInt(_firstRunKey);
    if (firstRun == null) {
      firstRun = now.millisecondsSinceEpoch;
      await prefs.setInt(_firstRunKey, firstRun);
    }
    final localExpiry =
        DateTime.fromMillisecondsSinceEpoch(firstRun).add(kDemoTrialLength);

    // Remote kill switch is authoritative when reachable.
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('license')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 6));

      final data = doc.data();
      if (doc.exists && data != null) {
        final active = data['active'] == true;
        final raw = data['expiresAt'];
        final expiresAt = raw is Timestamp ? raw.toDate() : null;

        if (!active) {
          return LicenseStatus(
              licensed: false, reason: 'disabled', expiresAt: expiresAt);
        }
        if (expiresAt != null && !now.isBefore(expiresAt)) {
          return LicenseStatus(
              licensed: false, reason: 'expired', expiresAt: expiresAt);
        }
        return LicenseStatus(
            licensed: true, expiresAt: expiresAt ?? localExpiry);
      }
      // No document → fall through to the local trial.
    } catch (_) {
      // Offline / rules → fall through to the local trial.
    }

    final licensed = now.isBefore(localExpiry);
    return LicenseStatus(
      licensed: licensed,
      reason: licensed ? null : 'expired',
      expiresAt: localExpiry,
      offline: true,
    );
  }
}
