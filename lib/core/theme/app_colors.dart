import 'package:flutter/material.dart';

/// Global Solar 2.0 colour tokens — "Sunrise over the rooftop".
abstract class GSColors {
  // Navy palette
  static const navy900 = Color(0xFF071440);
  static const navy700 = Color(0xFF0B1F5C);

  // Blues
  static const blue500 = Color(0xFF1E5BD8);

  // Sky
  static const sky100 = Color(0xFFEAF4FF);

  // Greens
  static const green600 = Color(0xFF1E8E3E);
  static const green400 = Color(0xFF4CC46A);

  // Gold / Solar
  static const gold500 = Color(0xFFF9B417);
  static const gold300 = Color(0xFFFFD86B);

  // Neutrals
  static const ink = Color(0xFF0F1B3D);
  static const white = Color(0xFFFFFFFF);
  static const whiteBg = Color(0xFFFAFAFA);
  static const pageBg = Color(0xFFF3F4F6); // light-gray page background for forms

  // Accent teal / green (wizard progress + radios)
  static const teal500 = Color(0xFF2BBFA4);

  // Medium navy (primary button fill)
  static const navy500 = Color(0xFF1E2A5E);

  // Error / required
  static const errorRed = Color(0xFFED1C24);

  // Status colours
  static const statusNew = Color(0xFF2196F3);
  static const statusContacted = Color(0xFF9C27B0);
  static const statusQuoted = Color(0xFFFF9800);
  static const statusBooked = Color(0xFFF44336);
  static const statusInstalled = Color(0xFF1E8E3E);
  static const statusLost = Color(0xFF9E9E9E);

  // Follow-up status colours
  static const followupPending = Color(0xFFF9B417); // gold
  static const followupDone = Color(0xFF1E8E3E); // green
  static const followupMissed = Color(0xFFF44336); // red

  // Shadows / overlays
  static const shadowLight = Color(0x1A071440);
  static const shadowMedium = Color(0x33071440);
  static const overlayDark = Color(0x66000000);

  // Glassmorphism
  static const glassWhite = Color(0x33FFFFFF);
  static const glassWhiteDark = Color(0x1AFFFFFF);
}
