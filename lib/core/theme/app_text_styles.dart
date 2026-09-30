import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography — Outfit (headings), Inter (body), Noto Sans Gujarati (Gujarati).
abstract class GSTextStyles {
  // ── Headings (Outfit) ──────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: Colors.white,
      );

  static TextStyle get displayMedium => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: Colors.white,
      );

  static TextStyle get displaySmall => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: Colors.white,
      );

  static TextStyle get headlineLarge => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.2,
      );

  static TextStyle get headlineMedium => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.25,
      );

  static TextStyle get headlineSmall => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  // ── Body (Inter) ───────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static TextStyle get bodyLargeSemiBold => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
      );

  static TextStyle get bodyMediumSemiBold => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
      );

  // ── Labels & buttons ───────────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.2,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        height: 1.3,
      );

  // ── Gujarati text ──────────────────────────────────────────────
  static TextStyle get gujaratiHeading => GoogleFonts.notoSansGujarati(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.5,
      );

  static TextStyle get gujaratiBody => GoogleFonts.notoSansGujarati(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );
}
