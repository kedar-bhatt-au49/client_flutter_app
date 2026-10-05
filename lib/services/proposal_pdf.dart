/// ---------------------------------------------------------------------------
/// Roof Top Solar Proposal + Quotation — 7-page PDF generator
///
/// Renders [SolarProposalData] into a multi-page PDF that follows the exact
/// layout spec:
///
///   Page 1 — Cover (hero image + company details)
///   Page 2 — Solar Plant Design Showcase
///   Page 3 — Quotation Table (line items w/ CGST/SGST, totals, notes, bank)
///   Page 4 — Terms & Conditions + Bill of Materials
///   Page 5 — Warranty Terms (Part 1)
///   Page 6 — Warranty Terms (Part 2)
///   Page 7 — Payment / UPI QR + Contact strip
///
/// Every page carries a branded navy header and a footer with company name,
/// page number (X/7) and social links.
///
/// Uses only packages already in the dependency tree:
///   * pdf (pw)        — document & widget rendering
///   * intl            — Indian-number formatting (₹1,40,800)
///   * barcode         — re-exported by `pdf`, used for QR rendering
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../models/proposal_data.dart';

class ProposalPdf {
  ProposalPdf._();

  static final NumberFormat _fmt = NumberFormat.decimalPattern('en_IN');

  /// Formats an integer as Indian-style currency, e.g. `₹1,40,800` or `-₹78,000`.
  static String money(int amount) {
    final s = 'Rs. ${_fmt.format(amount.abs())}';
    return amount < 0 ? '-$s' : s;
  }

  /// Formats an amount with Indian digit grouping and the `/-` suffix.
  /// e.g. `moneyINR(180000)` → `Rs. 1,80,000/-`.
  static String moneyINR(int amount) {
    final s = 'Rs. ${_fmt.format(amount.abs())}/-';
    return amount < 0 ? '-$s' : s;
  }

  /// Generates the full 7-page proposal PDF and returns the raw bytes.
  static Future<Uint8List> generate(SolarProposalData data) async {
    final logo = data.logoImage ?? await _loadAssetLogo();
    final heroImage = data.heroImage ?? await _loadAssetImage(
      'assets/images/hero_installation.jpg',
    );

    // Panel-count-specific design image for page 2.
    // 5 → solar_pannel_5.jpg, 6 → solar_pannel_6.png, 7 → solar_pannel_7.jpg,
    // 8 → solar_pannel_8.jpg, 9 → solar_pannel_9.jpg, 10 → solar_pannel_10.jpg,
    // any other count → default overview image.
    String panelImageAsset;
    switch (data.panelCount) {
      case 5:
        panelImageAsset = 'assets/images/solar_pannel_5.jpg';
        break;
      case 6:
        panelImageAsset = 'assets/images/solar_pannel_6.png';
        break;
      case 7:
        panelImageAsset = 'assets/images/solar_pannel_7.jpg';
        break;
      case 8:
        panelImageAsset = 'assets/images/solar_pannel_8.jpg';
        break;
      case 9:
        panelImageAsset = 'assets/images/solar_pannel_9.jpg';
        break;
      case 10:
        panelImageAsset = 'assets/images/solar_pannel_10.jpg';
        break;
      default:
        panelImageAsset = 'assets/images/solar_rooftop_overview.jpg';
    }
    final designImageTop = data.designImageTop ??
        await _loadAssetImage(panelImageAsset);

    // Load Unicode TTF font for proper character rendering (Gujarati, ₹, em-dash, etc.)
    final unicodeFont = await _loadFont();

    final r = _Renderer(data, logo, heroImage, designImageTop, unicodeFont);
    final doc = pw.Document();
    doc.addPage(r._cover());
    doc.addPage(r._designShowcase());
    doc.addPage(r._quotation());
    doc.addPage(r._termsBom());
    doc.addPage(r._warrantyA());
    doc.addPage(r._warrantyB());
    doc.addPage(r._payment());
    return doc.save();
  }

  /// Loads an image from the bundled assets and returns it as raw bytes.
  static Future<Uint8List> _loadAssetImage(String assetPath) async {
    try {
      final b = await rootBundle.load(assetPath);
      return b.buffer.asUint8List();
    } catch (_) {
      return Uint8List(0);
    }
  }

  /// Loads the company logo from the bundled asset.
  static Future<Uint8List> _loadAssetLogo() async {
    try {
      final b = await rootBundle.load('assets/images/logo.png');
      return b.buffer.asUint8List();
    } catch (_) {
      return Uint8List(0);
    }
  }

  /// Loads a Unicode TTF font that supports Gujarati, ₹, em-dash, and other
  /// characters that the built-in Helvetica (Type 1) font cannot render.
  /// Falls back to Helvetica if the asset fails to load (e.g. in tests).
  static Future<pw.Font> _loadFont() async {
    // NOTE: the bundled sans_serif.ttf has oversized line metrics that make
    // every text line very tall and overflow the A4 pages (clipping the
    // financial summary / bank / signature / BOM). The PDF built-in font
    // renders correctly; ₹ is shown as "Rs." via the money formatter.
    return pw.Font.helvetica();
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Internal renderer — holds shared state (fonts, colours, data) and builds
// each of the 7 pages plus the shared header / footer.
// ──────────────────────────────────────────────────────────────────────────────

class _Renderer {
  final SolarProposalData d;
  final Uint8List logo;
  final Uint8List heroImage;
  final Uint8List designImageTop;

  late final PdfColor navy = PdfColor.fromHex(d.brandColorHex);
  late final PdfColor gold = PdfColor.fromHex(d.accentColorHex);

  // ── Financial Summary Block palette ────────────────────────────────────────
  static final PdfColor _fsNavyStart = PdfColor.fromHex('#14286B');
  static final PdfColor _fsNavyEnd = PdfColor.fromHex('#1E3A8A');
  static final PdfColor _fsYellowStart = PdfColor.fromHex('#FFC400');
  static final PdfColor _fsYellowEnd = PdfColor.fromHex('#F5B000');
  static final PdfColor _fsGreenStart = PdfColor.fromHex('#2E8B2E');
  static final PdfColor _fsGreenEnd = PdfColor.fromHex('#5CB233');
  static final PdfColor _fsLightGreenStart = PdfColor.fromHex('#DAF3D3');
  static final PdfColor _fsLightGreenEnd = PdfColor.fromHex('#C1E3AF');
  static final PdfColor _fsDarkGreen = PdfColor.fromHex('#1B4E1B');
  static final PdfColor _fsLightBlue = PdfColor.fromHex('#E8F4FB');
  static final PdfColor _fsLightBlueBorder = PdfColor.fromHex('#B3DFF7');

  static final pw.LinearGradient _navyGrad = pw.LinearGradient(
    colors: [_fsNavyStart, _fsNavyEnd],
    begin: pw.Alignment.topLeft,
    end: pw.Alignment.bottomRight,
  );
  static final pw.LinearGradient _yellowGrad = pw.LinearGradient(
    colors: [_fsYellowStart, _fsYellowEnd],
    begin: pw.Alignment.topLeft,
    end: pw.Alignment.bottomRight,
  );
  static final pw.LinearGradient _greenGrad = pw.LinearGradient(
    colors: [_fsGreenStart, _fsGreenEnd],
    begin: pw.Alignment.topLeft,
    end: pw.Alignment.bottomRight,
  );
  static final pw.LinearGradient _lightGreenGrad = pw.LinearGradient(
    colors: [_fsLightGreenStart, _fsLightGreenEnd],
    begin: pw.Alignment.topLeft,
    end: pw.Alignment.bottomRight,
  );

  // Unicode TTF font supporting Gujarati, ₹, em-dash, and other
  // characters that Helvetica (Type 1) cannot render.
  // Falls back to Helvetica if the asset fails to load (e.g. in tests).
  final pw.Font _font;

  _Renderer(
    this.d,
    this.logo,
    this.heroImage,
    this.designImageTop,
    this._font,
  );

  // ── Text style helper ──────────────────────────────────────────────────────

  pw.TextStyle _t(
    double size, {
    bool bold = false,
    PdfColor? color,
    double? height,
    double? letterSpacing,
  }) {
    return pw.TextStyle(
      font: _font,
      fontSize: size,
      color: color ?? PdfColors.black,
      height: height ?? 1.05,
      letterSpacing: letterSpacing,
    );
  }

  // ── Financial Summary Block (Page 3) constants ───────────────────────────────

  // SVG icon badges — used inside [pw.SvgImage] for the row icons.
  static const String _iconRupee =
      '<svg width="28" height="28" viewBox="0 0 28 28" fill="none" '
      'xmlns="http://www.w3.org/2000/svg">'
      '<circle cx="14" cy="14" r="12" fill="#F7B015"/>'
      '<text x="14" y="19" text-anchor="middle" font-size="10" '
      'font-weight="bold" fill="#071440">Rs.</text></svg>';

  static const String _iconHandCoin =
      '<svg width="28" height="28" viewBox="0 0 28 28" fill="none" '
      'xmlns="http://www.w3.org/2000/svg">'
      '<circle cx="14" cy="14" r="12" fill="#88D675"/>'
      '<path d="M9 8 C8 9 7 11 7 14 C7 17 9 19 12 19 C12 18 12 17 12 15 '
      'C12 16 13 16 14 16 C15 16 16 15 16 14 C16 12 15 10 13 9 C13 8 12 8 '
      '11 8 Z" fill="#1B4E1B"/>'
      '<circle cx="16" cy="16" r="4" fill="#1B4E1B"/>'
      '</svg>';

  static const String _iconPerson =
      '<svg width="28" height="28" viewBox="0 0 28 28" fill="none" '
      'xmlns="http://www.w3.org/2000/svg">'
      '<circle cx="14" cy="14" r="12" fill="#F7B015"/>'
      '<path d="M14 8 C12 8 10.5 9.5 10.5 11.5 C10.5 13 11.5 14.5 13 15.5 '
      'L13 17 L15 17 L15 15.5 C16.5 14.5 17.5 13 17.5 11.5 C17.5 9.5 16 8 '
      '14 8 Z" fill="#071440"/>'
      '</svg>';

  static const String _iconCheque =
      '<svg width="28" height="28" viewBox="0 0 28 28" fill="none" '
      'xmlns="http://www.w3.org/2000/svg">'
      '<rect x="4" y="7" width="20" height="14" rx="2" fill="#7CB9E8" '
      'stroke="#071440" stroke-width="1"/>'
      '<line x1="4" y1="11" x2="24" y2="11" stroke="#071440" stroke-width="1"/>'
      '<rect x="10" y="13" width="6" height="4" rx="1" fill="#071440"/>'
      '<circle cx="16" cy="15" r="1.5" fill="#ffffff"/>'
      '</svg>';

  // ── Shared header / footer ─────────────────────────────────────────────────

  pw.Widget _header() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: navy,
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          // Circular orange-red gradient logo icon
          pw.Container(
            width: 34,
            height: 34,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              gradient: pw.LinearGradient(
                colors: [gold, PdfColor(0.93, 0.11, 0.14)], // #F7941D → #ED1C24
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              image: logo.isNotEmpty
                  ? pw.DecorationImage(
                      image: pw.MemoryImage(logo),
                      fit: pw.BoxFit.cover,
                    )
                  : null,
            ),
            child: logo.isEmpty
                ? pw.Center(child: pw.Text('GS', style: _t(13, bold: true, color: PdfColors.white)))
                : null,
          ),
          pw.SizedBox(width: 6),
          pw.Text(d.companyName,
              style: _t(10, bold: true, color: PdfColors.white)),
        ],
      ),
    );
  }

  pw.Widget _footer(int pageNumber, {
    String? leftText,
    double iconSize = 16,
    double iconGap = 1.5,
  }) {
    final links = d.socialLinks;
    return pw.Container(
      height: 40, // ~40px tall footer bar
      decoration: pw.BoxDecoration(
        color: navy,
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Left — company name
          pw.Text(leftText ?? d.companyName,
              style: _t(7, bold: true, color: PdfColors.white)),
          // Centre — page number
          pw.Text('$pageNumber/7',
              style: _t(7, color: PdfColors.white)),
          // Right — circular coloured social icons, evenly spaced
          pw.Row(
            children: [
              for (int i = 0; i < links.length; i++)
                ...[
                  if (i > 0) pw.SizedBox(width: iconGap),
                  pw.Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: _socialIconColor(links[i].name),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        _socialIconInitial(links[i].name),
                        style: _t(5,
                            bold: true, color: PdfColors.white),
                      ),
                    ),
                  ),
                ],
            ],
          ),
        ],
      ),
    );
  }

  /// Returns the brand colour for each social platform.
  PdfColor _socialIconColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('facebook')) return PdfColor.fromHex('#1877F2');
    if (n.contains('instagram')) return PdfColor.fromHex('#E44053');
    if (n.contains('linkedin')) return PdfColor.fromHex('#0A66C2');
    if (n.contains('twitter') || n.contains('x')) {
      return PdfColor.fromHex('#1DA1F2');
    }
    if (n.contains('phone')) return PdfColor.fromHex('#25D36E');
    if (n.contains('email')) return PdfColor.fromHex('#EA4335');
    if (n.contains('whatsapp')) return PdfColor.fromHex('#25D36E');
    return gold;
  }

  String _socialIconInitial(String name) {
    final n = name.toLowerCase();
    if (n.contains('facebook')) return 'f';
    if (n.contains('instagram')) return 'IG';
    if (n.contains('linkedin')) return 'in';
    if (n.contains('twitter') || n.contains('x')) return 'X';
    if (n.contains('whatsapp')) return 'WA';
    if (n.contains('phone')) return 'Ph';
    if (n.contains('email')) return 'EM';
    return name.substring(0, 1).toUpperCase();
  }

  /// Replaces Unicode glyphs not supported by the bundled font (₹, ×, —, etc.)
  /// with ASCII equivalents so they render correctly instead of showing as □.
  String _s(String text) {
    return text
      .replaceAll('\u{20B9}', 'Rs. ')   // ₹
      .replaceAll('\u{00D7}', 'x')       // ×
      .replaceAll('\u{2014}', '-')       // em-dash
      .replaceAll('\u{2013}', '-')       // en-dash
      .replaceAll('\u{2026}', '...')     // ellipsis
      .replaceAll('\u{2018}', "'")       // '
      .replaceAll('\u{2019}', "'")       // '
      .replaceAll('\u{201C}', '"')       // "
      .replaceAll('\u{201D}', '"');      // "
  }

  // ── Image / placeholder helper ─────────────────────────────────────────────

  pw.Widget _img(Uint8List? bytes, double w, double h, String label,
      {pw.BoxFit fit = pw.BoxFit.cover}) {
    if (bytes != null && bytes.isNotEmpty) {
      return pw.Container(
        width: w,
        height: h,
        decoration: pw.BoxDecoration(
          image: pw.DecorationImage(
            image: pw.MemoryImage(bytes),
            fit: fit,
          ),
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
      );
    }
    return pw.Container(
      width: w,
      height: h,
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Center(
        child: label.isNotEmpty
            ? pw.Text(label,
                style: _t(7.5, color: PdfColors.grey500))
             : null,
       ),
     );
   }

  // ── Bullet helper (avoids Unicode • which Helvetica can't render) ──────────

  pw.Widget _bullet(String text, pw.TextStyle style, PdfColor color,
      {double size = 2.5, double gap = 4, double top = 2}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: size,
          height: size,
          margin: pw.EdgeInsets.only(right: gap, top: top),
          decoration: pw.BoxDecoration(
            color: color,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.Expanded(child: pw.Text(text, style: style)),
      ],
    );
  }

  /// Certain line items (Meter Charge, GEDA Registration, Stamp Charge) are
  /// administrative fees that should not show a Rate or Total value.
  static bool _hideRateTotal(String description) {
    final d = description.toLowerCase();
    return d.contains('meter charge') ||
        d.contains('geda') ||
        d.contains('stamp charge');
  }


  // ════════════════════════════════════════════════════════════════════════════
  // PAGE 1 — Cover (split: left hero photo / right details)
  // ════════════════════════════════════════════════════════════════════════════

  pw.Page _cover() {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (pw.Context ctx) => pw.Stack(
        children: [
          // ── Split: left image (50%) + right sections (50%) ──
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  height: double.infinity,
                  decoration: pw.BoxDecoration(
                    image: heroImage.isNotEmpty
                        ? pw.DecorationImage(
                            image: pw.MemoryImage(heroImage),
                            fit: pw.BoxFit.cover,
                          )
                        : null,
                    gradient: heroImage.isEmpty
                        ? pw.LinearGradient(
                            colors: [navy, gold],
                            begin: pw.Alignment.topLeft,
                            end: pw.Alignment.bottomRight,
                          )
                        : null,
                  ),
                ),
              ),
              // ── RIGHT HALF: 3 horizontal bands ──
              pw.Expanded(
                child: pw.Column(
                  children: [
                    // Top band (27%) — brand color, title right-aligned
                    pw.Expanded(
                      flex: 27,
                      child: pw.Container(
                        color: navy,
                        alignment: pw.Alignment.centerRight,
                        padding: const pw.EdgeInsets.only(right: 36),
                        child: pw.Text(
                          d.useHinglish
                              ? 'रूफ टॉप\nसोलर प्रपोजल'
                              : 'Roof Top\nSolar Proposal',
                          style: _t(36,
                              bold: true,
                              color: PdfColors.white,
                              height: 1.1),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ),
                    // Middle band (28%) — white, client name
                    pw.Expanded(
                      flex: 28,
                      child: pw.Container(
                        color: PdfColors.white,
                        alignment: pw.Alignment.centerLeft,
                        padding: const pw.EdgeInsets.only(left: 36),
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              d.customerName.toUpperCase(),
                              style: _t(30,
                                  bold: true, color: PdfColors.black),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              '${d.state} | ${d.customerLocation}',
                              style: _t(15, color: PdfColors.grey600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Bottom band (45%) — brand color, company info
                    pw.Expanded(
                      flex: 45,
                      child: pw.Container(
                        color: navy,
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 36, vertical: 28),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(d.companyName,
                                style: _t(22,
                                    bold: true, color: PdfColors.white)),
                            pw.SizedBox(height: 8),
                            pw.Text(d.companyAddress,
                                style: _t(12,
                                    color: PdfColor(1, 1, 1, 0.8)),
                                textAlign: pw.TextAlign.center),
                            pw.SizedBox(height: 10),
                            pw.Container(
                              width: 60,
                              height: 1,
                              color: PdfColors.white,
                            ),
                            pw.SizedBox(height: 12),
                            _coverDetailWhite('Lead', d.leadName),
                            _coverDetailWhite('ID', d.quotationId),
                            _coverDetailWhite(
                                'Date', d.quotationDate),
                            _coverDetailWhite('By', d.preparedBy),
                            _coverDetailWhite(
                                'Plant Capacity',
                                '${d.plantCapacityKw} kW'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // ── LOGO BADGE — top-left, floating over split ──
          pw.Positioned(
            top: 16,
            left: 16,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(12),
                boxShadow: [
                  pw.BoxShadow(
                    color: PdfColor(0, 0, 0, 0.15),
                    blurRadius: 8,
                    offset: const PdfPoint(0, 2),
                  ),
                ],
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 22,
                    height: 22,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      gradient: pw.LinearGradient(
                        colors: [gold, PdfColor(0.93, 0.11, 0.14)],
                      ),
                      image: logo.isNotEmpty
                          ? pw.DecorationImage(
                              image: pw.MemoryImage(logo),
                              fit: pw.BoxFit.cover,
                            )
                          : null,
                    ),
                    child: logo.isEmpty
                        ? pw.Center(
                            child: pw.Text('GS',
                                style: _t(9,
                                    bold: true, color: PdfColors.white)))
                        : null,
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(d.companyName,
                      style: _t(13,
                          bold: true, color: navy)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Label:value pair rendered in the purple details block (white text).
  pw.Widget _coverDetailWhite(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 76,
            child: pw.Text('$label:',
                style: _t(8, bold: true, color: PdfColor(1, 1, 1, 0.7)),
            )),
            pw.SizedBox(width: 6),
            pw.SizedBox(
              width: 170,
              child: pw.Text(value, style: _t(8, color: PdfColors.white)),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PAGE 2 — Solar Plant Designs Showcase
  // ════════════════════════════════════════════════════════════════════════════

  pw.Page _designShowcase() {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 50, 40, 0),
      build: (pw.Context ctx) => pw.Stack(
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.SizedBox(height: 70), // space for logo badge at top
              // Title — bold, black, ~20pt
              pw.Text('Solar Plants Designs You Have Previously',
                  style: _t(20, bold: true, color: PdfColors.black),
                  textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 6), // ~6-8px gap to subtitle
              // Subtitle — regular, gray, ~12pt
              pw.Text('Solar Plant Photos',
                  style: _t(12, color: PdfColors.grey500),
                  textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 8),
              pw.Divider(height: 1, thickness: 1, color: gold),
              pw.SizedBox(height: 24),
              // Panel-count-specific design photo (5 to 10 panels)
              if (d.panelCount >= 5 && d.panelCount <= 10)
                _img(
                  designImageTop,
                  double.infinity,
                  320,
                  d.useHinglish ? 'પેનલ ડિઝાઇન' : 'Panel Design',
                  fit: pw.BoxFit.cover,
                ),
              pw.Spacer(),
              _footer(2, iconSize: 20, iconGap: 8),
            ],
          ),
          // ── LOGO — fixed at top-right corner, 20px from top / right edges ──
          pw.Positioned(
            top: 20,
            right: 20,
            child: _page2Logo(),
          ),
        ],
      ),
    );
  }

  /// Top-right badge on Page 2: circular logo (~55px) + company name (bold
  /// orange / brand colour) + tagline (small gray), positioned ~20px from
  /// the top and right edges.
  pw.Widget _page2Logo() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Circular company logo (~55px)
        pw.Container(
          width: 55,
          height: 55,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            gradient: logo.isNotEmpty
                ? null
                : pw.LinearGradient(
                    colors: [gold, PdfColor(0.93, 0.11, 0.14)],
                  ),
            image: logo.isNotEmpty
                ? pw.DecorationImage(
                    image: pw.MemoryImage(logo),
                    fit: pw.BoxFit.cover,
                  )
                : null,
          ),
          child: logo.isEmpty
              ? pw.Center(
                  child: pw.Text('GS',
                      style: _t(20,
                          bold: true, color: PdfColors.white)))
              : null,
        ),
        pw.SizedBox(width: 8),
        // Company name (bold orange) + tagline (small gray)
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(d.companyName,
                style: _t(13, bold: true, color: gold)),
            pw.Text(d.companyTagline,
                style: _t(7, color: PdfColors.grey500)),
          ],
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PAGE 3 — Quotation Table
  // ════════════════════════════════════════════════════════════════════════════

  pw.Page _quotation() {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(22, 24, 22, 32),
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _header(),
          pw.SizedBox(height: 18),
          pw.Text('Quotation', style: _t(18, bold: true, color: navy)),
          pw.SizedBox(height: 6),
          pw.Divider(height: 4, thickness: 1, color: gold),
          pw.SizedBox(height: 8),
          _quotationHeaderBlock(),
          pw.SizedBox(height: 12),
          _lineItemsTable(),
          pw.SizedBox(height: 14),
          _quotationBottom(),
          pw.Spacer(),
          _footer(3),
        ],
      ),
    );
  }

  /// From / Bill To / Meta block above the table.
  pw.Widget _quotationHeaderBlock() {
    final metaLabels = ['Date', 'Expiry', 'Estimate#', 'Created by', 'Contact'];
    final metaValues = [
      d.quotationDate,
      d.expiryDate,
      d.quotationId,
      d.preparedBy,
      d.contactNumbers
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: _billToColumn('From', [
              d.companyName,
              d.companyAddress,
              'GSTIN: ${d.companyGstin}',
            ]),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: _billToColumn('Bill To', [
              d.customerName,
              d.customerLocation,
              'Mobile: ${d.customerMobile}',
            ]),
          ),
          pw.SizedBox(
            width: 170,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < metaLabels.length; i++)
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('${metaLabels[i]}: ', style: _t(7, bold: true, color: PdfColors.grey700)),
                        pw.Text(metaValues[i], style: _t(7, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _billToColumn(String label, List<String> lines) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: _t(7.5, bold: true, color: navy)),
        for (final l in lines)
          pw.Text(l, style: _t(7.5, color: PdfColors.black)),
      ],
    );
  }

  /// The 8-column line-items table.
  pw.Widget _lineItemsTable() {
    final headerCells = [
      '#', 'Item & Description', 'Qty', 'Rate',
      'Discount', 'CGST', 'SGST', 'Total'
    ];

    final tableRows = <pw.TableRow>[
      // Header row
      pw.TableRow(
        decoration: pw.BoxDecoration(color: navy),
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          for (int c = 0; c < headerCells.length; c++)
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(2),
                child: pw.Text(headerCells[c],
                   textAlign: pw.TextAlign.center,
                   style: _t(
                     c == 7 ? 8 : 7.5,
                     bold: true,
                     color: c == 7 ? gold : PdfColors.white,
                   )),
              ),
            ),
        ],
      ),
    ];

    for (int i = 0; i < d.lineItems.length; i++) {
      final item = d.lineItems[i];
      final isAlt = i.isEven;
      tableRows.add(pw.TableRow(
        decoration: pw.BoxDecoration(
          color: isAlt ? PdfColors.white : PdfColors.grey100,
        ),
        verticalAlignment: pw.TableCellVerticalAlignment.top,
        children: [
          // 0 — #
          pw.Center(child: pw.Padding(
            padding: const pw.EdgeInsets.all(2),
            child: pw.Text('${i + 1}', style: _t(8), textAlign: pw.TextAlign.center),
          )),
          // 1 — Description
          pw.Padding(
            padding: const pw.EdgeInsets.all(2),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(_s(item.description), style: _t(8, bold: true)),
                for (final spec in item.specs)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1.5),
                    child: _bullet(_s(spec), _t(7), navy),
                  ),
              ],
            ),
          ),
          // 2 — Qty
          pw.Center(child: pw.Text(item.qty, style: _t(8.5), textAlign: pw.TextAlign.center)),
          // 3 — Rate
          pw.Center(child: pw.Text(_hideRateTotal(item.description) ? '-' : ProposalPdf.money(item.rate), style: _t(8.5), textAlign: pw.TextAlign.center)),
          // 4 — Discount
          pw.Center(child: pw.Text(item.discount == 0 ? '-' : ProposalPdf.money(item.discount), style: _t(8.5), textAlign: pw.TextAlign.center)),
          // 5 — CGST
          pw.Center(child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('${item.cgstPercent}%', style: _t(7.5)),
              pw.Text(ProposalPdf.money(item.cgstAmount), style: _t(7.5)),
            ],
          )),
          // 6 — SGST
          pw.Center(child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('${item.sgstPercent}%', style: _t(7.5)),
              pw.Text(ProposalPdf.money(item.sgstAmount), style: _t(7.5)),
            ],
          )),
          // 7 — Total
          pw.Center(child: pw.Text(_hideRateTotal(item.description) ? '-' : ProposalPdf.money(item.total), style: _t(8, bold: true, color: navy), textAlign: pw.TextAlign.center)),
        ],
      ));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
      columnWidths: {
        0: pw.FixedColumnWidth(20),
        1: pw.FlexColumnWidth(2.5),
        2: pw.FixedColumnWidth(28),
        3: pw.FixedColumnWidth(50),
        4: pw.FixedColumnWidth(46),
        5: pw.FixedColumnWidth(44), // CGST — wider for 'Rs. X,XXX' amounts
        6: pw.FixedColumnWidth(44), // SGST — wider for 'Rs. X,XXX' amounts
        7: pw.FixedColumnWidth(50),
      },
      children: tableRows,
    );
  }

  /// Bottom section of the quotation page: amount-in-words + notes (left),
  /// totals + bank details + signature (right).
  pw.Widget _quotationBottom() {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── Amount in words ──
          pw.Text(_s(d.amountInWords), style: _t(8.5, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),

          // ── Financial Summary Block (full-width, page 3) ──
          _financialSummary(),
          pw.SizedBox(height: 8),

          // ── Notes + Bank Details (side by side) ──
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _notesBox()),
              pw.SizedBox(width: 18),
              pw.Expanded(child: _bankBox()),
            ],
          ),
          pw.SizedBox(height: 10),

          // ── Signature ──
          _signatureBlock(),
        ],
      ),
    );
  }

  pw.Widget _notesBox() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: gold, width: 0.75),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Notes & Required Documents',
              style: _t(7.5, bold: true, color: navy)),
          pw.SizedBox(height: 4),
          for (final note in d.notes)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1.5),
              child: _bullet(_s(note), _t(6.5), gold),
            ),
        ],
      ),
    );
  }

  /// ── Financial Summary Block (replaces totals box, page 3) ─────────────────
  /// Renders the 4-row angled-divider summary that mirrors the HTML template:
  /// 1. System Amount w/ GST  (navy/yellow, highlighted total)
  /// 2. Government Subsidy    (green, NOT highlighted — hidden when 0)
  /// 3. Net Cost After Subsidy (navy/yellow, highlighted total)
  /// 4. Payment Mode          (light-blue, no yellow block)
  pw.Widget _financialSummary() {
    final totalBeforeSubsidy = d.grandTotal + d.subsidyAmount;
    final hasSubsidy = d.subsidyAmount > 0;
    String tl(String en, String hinglish) => d.useHinglish ? hinglish : en;

    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Caption
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              'Financial Summary (Inclusive of GST)',
              style: _t(7.5, bold: true, color: navy),
              textAlign: pw.TextAlign.center,
            ),
          ),

          // Row 1 — System Amount w/ GST (navy / yellow)
          _fsRow(
            leftGradient: _navyGrad,
            rightGradient: _yellowGrad,
            leftTextColor: PdfColors.white,
            rightTextColor: _fsNavyStart,
            iconSvg: _iconRupee,
            label: tl('कुल मूल्य (System Amount w/ GST)', 'System Amount w/ GST'),
            amount: ProposalPdf.moneyINR(totalBeforeSubsidy),
          ),

          // Row 2 — Subsidy (green, NOT highlighted), hidden when 0
          if (hasSubsidy)
            _fsRow(
              leftGradient: _greenGrad,
              rightGradient: _lightGreenGrad,
              leftTextColor: PdfColors.white,
              rightTextColor: _fsDarkGreen,
              iconSvg: _iconHandCoin,
              label: tl('सरकारी सब्सिडी (Government Subsidy)',
                  'Government Subsidy (PM Surya Ghar)'),
              amount: ProposalPdf.moneyINR(d.subsidyAmount),
            ),

          // Row 3 — Net Cost After Subsidy (navy / yellow)
          _fsRow(
            leftGradient: _navyGrad,
            rightGradient: _yellowGrad,
            leftTextColor: PdfColors.white,
            rightTextColor: _fsNavyStart,
            iconSvg: _iconPerson,
            label: tl('अंतिम लागत (Net Cost After Subsidy)',
                'Net Cost After Subsidy'),
            amount: ProposalPdf.moneyINR(d.grandTotal),
          ),

          // Row 4 — Payment Mode (light-blue, no yellow block)
          _fsRow(
            leftColor: _fsLightBlue,
            rightColor: _fsLightBlue,
            leftBorderColor: _fsLightBlueBorder,
            rightBorderColor: _fsLightBlueBorder,
            leftTextColor: _fsNavyStart,
            rightTextColor: _fsNavyStart,
            iconSvg: _iconCheque,
            label: tl('नेट पेबेबल (Net payable by cheque/cash)',
                'Net payable by cheque/cash'),
            amount: ProposalPdf.moneyINR(totalBeforeSubsidy),
            noDiagonal: true,
          ),
        ],
      ),
    );
  }

  /// Builds a single financial-summary row with the 60/40 angled divider.
  /// When [noDiagonal] is `true` a flat light-blue row is produced (Row 4).
  pw.Widget _fsRow({
    pw.LinearGradient? leftGradient,
    pw.LinearGradient? rightGradient,
    PdfColor? leftColor,
    PdfColor? rightColor,
    PdfColor? leftBorderColor,
    PdfColor? rightBorderColor,
    required PdfColor leftTextColor,
    required PdfColor rightTextColor,
    required String iconSvg,
    required String label,
    required String amount,
    bool noDiagonal = false,
  }) {
    // ── Left half content: icon badge + bilingual label ──
    final leftContent = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 8),
          child: pw.SvgImage(svg: iconSvg, width: 24, height: 24),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(right: 10),
            child: pw.Text(
              label,
              style: _t(7.5, bold: true, color: leftTextColor),
              maxLines: 2,
            ),
          ),
        ),
      ],
    );

    // ── Right half content: very large amount ──
    final rightContent = pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(right: 14),
      child: pw.Text(
        amount,
        style: _t(15, bold: true, color: rightTextColor),
      ),
    );

    if (noDiagonal) {
      // Row 4 — flat light-blue with thin border, no gradient
      return pw.Container(
        height: 34,
        margin: const pw.EdgeInsets.only(bottom: 4),
        decoration: pw.BoxDecoration(
          color: leftColor,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border(
            top: pw.BorderSide(color: leftBorderColor ?? _fsLightBlueBorder, width: 0.7),
            bottom: pw.BorderSide(color: leftBorderColor ?? _fsLightBlueBorder, width: 0.7),
            left: pw.BorderSide(color: leftBorderColor ?? _fsLightBlueBorder, width: 0.7),
            right: pw.BorderSide(color: rightBorderColor ?? _fsLightBlueBorder, width: 0.7),
          ),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(flex: 60, child: leftContent),
            pw.Expanded(flex: 40, child: rightContent),
          ],
        ),
      );
    }

    // Rows 1–3 — simple two-tone split with gradient backgrounds
    return pw.Container(
      height: 34,
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.ClipRRect(
        horizontalRadius: 6,
        verticalRadius: 6,
        child: pw.Row(
          children: [
            pw.Expanded(
              flex: 60,
              child: pw.Container(
                decoration: pw.BoxDecoration(gradient: leftGradient),
                child: leftContent,
              ),
            ),
            pw.Expanded(
              flex: 40,
              child: pw.Container(
                decoration: pw.BoxDecoration(gradient: rightGradient),
                child: rightContent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _bankBox() {
    final b = d.bankDetails;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: navy, width: 0.75),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Bank Details',
              style: _t(7.5, bold: true, color: navy)),
          pw.SizedBox(height: 6),
          _kv('Bank Name', b.bankName),
          _kv('A/c Name', b.accountName),
          _kv('A/c No.', b.accountNo),
          _kv('IFSC', b.ifsc),
          _kv('Branch', b.branch),
        ],
      ),
    );
  }

  pw.Widget _kv(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 60,
              child: pw.Text('$k:', style: _t(7, bold: true, color: navy)),
            ),
            pw.Text(v, style: _t(7)),
          ],
        ),
      );

  pw.Widget _signatureBlock() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 160,
          height: 50,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColors.grey600,
              width: 0.75,
              style: pw.BorderStyle.dashed,
            ),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Center(
            child: pw.Text(
              'AUTHORIZED\nSIGNATURE & STAMP',
              textAlign: pw.TextAlign.center,
              style: _t(6, bold: true, color: PdfColors.grey600),
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(d.preparedBy, style: _t(8, bold: true)),
        pw.Text('For ${d.companyName}', style: _t(7, color: PdfColors.grey700)),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PAGE 4 — Terms & Bill of Materials
  // ════════════════════════════════════════════════════════════════════════════

  pw.Page _termsBom() {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(22, 24, 22, 32),
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header(),
          pw.SizedBox(height: 18),
          pw.Text('Terms & Conditions', style: _t(15, bold: true, color: navy)),
          pw.SizedBox(height: 6),
          pw.Divider(height: 4, thickness: 1, color: gold),
          pw.SizedBox(height: 8),
          pw.Wrap(
            runSpacing: 2,
            spacing: 6,
            children: [
              for (final note in d.notes)
                pw.SizedBox(
                  width: 210,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                    pw.Text('- ',
                          style: _t(7.5, bold: true, color: gold)),
                      pw.Expanded(
                        child: pw.Text(note,
                            style: _t(7.5, color: PdfColors.grey800, height: 1.3)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text('Bill of Material', style: _t(12, bold: true, color: navy)),
          pw.SizedBox(height: 6),
          pw.Divider(height: 4, thickness: 1, color: gold),
          pw.SizedBox(height: 6),
          _bomTable(),
          pw.Spacer(),
          _footer(4),
        ],
      ),
    );
  }

  pw.Widget _bomTable() {
    final headerCells = ['Sr No.', 'Item', 'Qty', 'Unit', 'Brand'];

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: navy),
        children: [
          for (final h in headerCells)
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(2.5),
                child: pw.Text(h,
                    textAlign: pw.TextAlign.center,
                    style: _t(7.5, bold: true, color: PdfColors.white)),
              ),
            ),
        ],
      ),
    ];

    // Group items by category for section headers
    String? currentCategory;
    int srNo = 0;

    for (int i = 0; i < d.bomItems.length; i++) {
      final item = d.bomItems[i];

      // Add category section header when category changes
      if (item.category != currentCategory) {
        currentCategory = item.category;
        rows.add(pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Center(child: pw.Text('', style: _t(7.5))),
            pw.Padding(
              padding: const pw.EdgeInsets.all(2.5),
              child: pw.Text(currentCategory!,
                  style: _t(7.5, bold: true, color: navy)),
            ),
            pw.Center(child: pw.Text('', style: _t(7.5))),
            pw.Center(child: pw.Text('', style: _t(7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(2.5), child: pw.Text('', style: _t(7.5))),
          ],
        ));
      }

      srNo++;
      final isAlt = srNo.isEven;
      rows.add(pw.TableRow(
        decoration: pw.BoxDecoration(
          color: isAlt ? PdfColors.white : PdfColors.grey100,
        ),
        children: [
          pw.Center(child: pw.Text('$srNo', style: _t(7.5), textAlign: pw.TextAlign.center)),
          pw.Padding(padding: const pw.EdgeInsets.all(2.5), child: pw.Text(item.item, style: _t(7.5))),
          pw.Center(child: pw.Text(item.qty, style: _t(7.5), textAlign: pw.TextAlign.center)),
          pw.Center(child: pw.Text(item.unit, style: _t(7.5), textAlign: pw.TextAlign.center)),
          pw.Padding(padding: const pw.EdgeInsets.all(2.5), child: pw.Text(item.brand, style: _t(7.5))),
        ],
      ));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: {
        0: pw.FixedColumnWidth(30),
        1: pw.FlexColumnWidth(3),
        2: pw.FixedColumnWidth(50),
        3: pw.FixedColumnWidth(48),
        4: pw.FlexColumnWidth(1),
      },
      children: rows,
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PAGES 5–6 — Warranty Terms
  // ════════════════════════════════════════════════════════════════════════════

  pw.Page _warrantyPage(int pageNumber, int start, int end) {
    final sections = d.warrantySections;
    final count = sections.length;
    final safeStart = start > count ? count : start;
    final safeEnd = end > count ? count : end;
    final slice = safeEnd > safeStart
        ? sections.sublist(safeStart, safeEnd)
        : <WarrantySection>[];

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(22, 24, 22, 32),
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header(),
          pw.SizedBox(height: 18),
          pw.Text('Warranty Terms', style: _t(18, bold: true, color: navy)),
          pw.SizedBox(height: 6),
          pw.Divider(height: 4, thickness: 1, color: gold),
          pw.SizedBox(height: 12),
          for (final section in slice) ...[
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6, bottom: 2),
              child: pw.Text(section.heading,
                  style: _t(8.5, bold: true, color: navy)),
            ),
            for (final bullet in section.bullets)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 0.5, left: 4),
                child: _bullet(_s(bullet), _t(7.5), gold, size: 2.2),
              ),
            pw.SizedBox(height: 4),
          ],
          pw.Spacer(),
          _footer(pageNumber),
        ],
      ),
    );
  }

  pw.Page _warrantyA() => _warrantyPage(5, 0, 6);
  pw.Page _warrantyB() => _warrantyPage(6, 6, 12);

  // ════════════════════════════════════════════════════════════════════════════
  // PAGE 7 — Payment / Contact
  // ════════════════════════════════════════════════════════════════════════════

  pw.Page _payment() {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(22, 24, 22, 32),
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _header(),
          pw.SizedBox(height: 18),
          pw.Text('Payment & Contact',
              style: _t(18, bold: true, color: navy)),
          pw.SizedBox(height: 6),
          pw.Divider(height: 4, thickness: 1, color: gold),
          pw.SizedBox(height: 16),
          pw.Spacer(),
          // Mint-colored rounded rectangle containing QR code
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.green100,
              borderRadius: pw.BorderRadius.circular(16),
              border: pw.Border.all(color: gold, width: 1.5),
            ),
            child: pw.Center(child: _qrCode(120, 120)),
          ),
          pw.SizedBox(height: 12),
          // Rounded card with company name + UPI ID
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: gold, width: 0.75),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(d.companyName, style: _t(10, bold: true, color: PdfColors.grey600)),
                pw.SizedBox(height: 2),
                pw.Text('UPI ID: ${d.upiId}', style: _t(8, color: navy)),
              ],
            ),
          ),
          pw.Spacer(),
          // Three-column contact strip
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 10),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(width: 0.7, color: PdfColors.grey300),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(d.companyName, style: _t(7.5, bold: true, color: navy)),
                    pw.Text(d.companyAddress,
                        textAlign: pw.TextAlign.center,
                        style: _t(6.5, color: PdfColors.grey700)),
                  ],
                ),
                 pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Phone', style: _t(6.5, bold: true, color: navy)),
                    pw.Text(d.companyPhone, style: _t(6.5, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Email', style: _t(6.5, bold: true, color: navy)),
                    pw.Text(d.companyEmail, style: _t(6.5, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
          ),
          _footer(7),
        ],
      ),
    );
  }

  /// QR code: pre-generated image if supplied, else generated from UPI ID,
  /// else a placeholder box.
  pw.Widget _qrCode(double w, double h) {
    if (d.upiQrImage != null && d.upiQrImage!.isNotEmpty) {
      return pw.Image(pw.MemoryImage(d.upiQrImage!), width: w, height: h, fit: pw.BoxFit.contain);
    }
    if (d.upiQrUpiId.isNotEmpty) {
      return pw.BarcodeWidget(
        data: d.upiQrUpiId,
        barcode: pw.Barcode.qrCode(),
        drawText: false,
        width: w,
        height: h,
      );
    }
    // Placeholder
    return _img(null, w, h, 'UPI QR Code');
  }
}
