/// Compile-time build flavor for the app.
///
/// This file lives on the `demo` branch with [kDemoMode] = true; the production
/// branch keeps it false. It switches the app into demo behaviour:
///   * anonymous sign-in (no login screen),
///   * a time-boxed license gate with a remote kill switch,
///   * a "DEMO" banner,
///   * the in-app updater is disabled (so a demo can never pull the real APK).
const bool kDemoMode = true;

/// How long the demo stays usable when the remote license doc is unavailable
/// (offline fallback). The admin can also revoke instantly via `settings/license`.
const Duration kDemoTrialLength = Duration(days: 7);

/// Shown across demo builds.
const String kDemoAppName = 'Solar Client App';
