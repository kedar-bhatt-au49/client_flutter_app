/// ---------------------------------------------------------------------------
/// Roof Top Solar Proposal + Quotation — 7-page PDF generator
///
/// Renders [SolarProposalData] into a multi-page PDF that follows the exact
/// layout spec:
///
///   Page 1 — Cover (hero image + company details)
///   Page 2 — Solar Plant Design Showcase
/// Page 3 — Estimate Creation Form (4-step wizard: Lead Details, Estimate Details,
///   Structure Details, Financial Details)
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
    // 5 panels → solar_pannel_5.jpg, 6 → solar_pannel_6.jpg,
    // 7 → solar_pannel_7.jpg, 8 → solar_pannel_8.jpg,
    // 9 → solar_pannel_9.jpg, 10 → solar_pannel_10.jpg,
    // any other count → default overview image.
    String panelImageAsset;
    switch (data.panelCount) {
      case 5:
        panelImageAsset = 'assets/images/solar_pannel_5.jpg';
        break;
      case 6:
        panelImageAsset = 'assets/images/solar_pannel_6.jpg';
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
    doc.addPage(r._estimateForm());
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
    try {
      final bytes = await rootBundle.load('assets/fonts/sans_serif.ttf');
      return pw.Font.ttf(bytes);
    } catch (_) {
      return pw.Font.helvetica();
    }
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

  // ── Form palette (matches create_estimate_screen.dart + proposal template) ────
  static final PdfColor _gsTeal = PdfColor.fromHex('#2BBFA4');
  static final PdfColor _gsInk = PdfColor.fromHex('#0F1B3D');
  static final PdfColor _gsError = PdfColor.fromHex('#ED1C24');
  static final PdfColor _gsBorder = PdfColor.fromHex('#D1D5DB');
  static final PdfColor _gsMuted = PdfColor.fromHex('#6B7280');

  late final pw.LinearGradient _goldGrad = pw.LinearGradient(
    colors: [gold, _gsError],
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
      height: height,
      letterSpacing: letterSpacing,
    );
  }

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
  // PAGE 3 — Estimate Creation Form (4-step wizard)
  // Mirrors create_estimate_screen.dart from the main branch:
  //   Step 1: Lead Details  (type toggle, name, mobile, WhatsApp, lead stage, desc)
  //   Step 2: Estimate Details (estimate #, reference, expiry, currency, capacity,
  //           tax mode, price calculator, item list, price breakdown)
  //   Step 3: Structure Details (pipe quantities)
  //   Step 4: Financial Details (discount, GST profile, insurance, system size)
  // =============================================================================================

  // ── Bilingual helper: returns Hindi label when [d.useHinglish] is true ──
  String _t2(String en, String hi) => d.useHinglish ? hi : en;

  pw.Page _estimateForm() {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 36, 28, 48),
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header(),
          pw.SizedBox(height: 18),

          // Title
          pw.Center(child: pw.Text(
            _t2('CREATE ESTIMATE', 'अनुमान बनाएं'),
            style: _t(18, bold: true, color: navy),
          )),
          pw.SizedBox(height: 6),
          pw.Center(child: pw.Container(
            width: 40, height: 4,
            decoration: pw.BoxDecoration(
              color: gold,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          )),
          pw.SizedBox(height: 16),

          // Progress bar — 4 steps, step 1 active
          _estimateProgressBar(4, 1),
          pw.SizedBox(height: 6),

          // ── Step 1: Lead Details ──
          _formSection('👤', _t2('Lead Details', 'लीड विवरण'), [
            _formRadioGroup(_t2('TYPE', 'प्रकार'), [
              _t2('व्यक्तिगत (Individual)', 'Individual'),
              _t2('व्यवसाय (Business)', 'Business'),
            ], 0),
            _formInputCard(_t2('COMPANY NAME *', 'कंपनी का नाम *'), _s(d.companyName)),
            _formInputCard(_t2('NAME *', 'नाम *'), _s(d.customerName)),
            _formPhoneInput(_t2('MOBILE NUMBER *', 'मोबाइल नंबर *'), _s(d.customerMobile)),
            _formPhoneInput(_t2('WHATSAPP NUMBER', 'व्हाट्सऐप नंबर'), _s(d.customerMobile)),
            _formToggle(_t2('Auto-fill WhatsApp from mobile', 'व्हाट्सऐप ऑटो-भरें'), true),
            _formSelectorTile(_t2('LEAD STAGE', 'लीड स्टेज'), _s(d.leadName)),
            _formTextarea(_t2('DESCRIPTION', 'विवरण'),
              _t2('e.g. Customer is a regular buyer', 'जैसे Customer is a regular buyer')),
          ]),

          // ── Step 2: Estimate Details ──
          _formSection('📊', _t2('Estimate Details', 'अनुमान विवरण'), [
            _formInputCard(_t2('ESTIMATE NUMBER *', 'अनुमान संख्या *'), _s(d.quotationId)),
            _formInputCard(_t2('REFERENCE NO.', 'रेफ़रेंस नंबर'), ''),
            _formInputCard(_t2('EXPIRY DATE', 'समाप्ति तारीख'), _s(d.expiryDate), readonly: true),
            _formSelectCard(_t2('CURRENCY *', 'मुद्रा *'), ['INR - भारतीय रुपया (₹)']),
            _formInputCard(_t2('CAPACITY KW', 'क्षमता kW'),
              d.plantCapacityKw, suffix: 'kW'),
            _formRadioGroup(_t2('ITEM RATES', 'आइटम दरें'), [
              _t2('कर अलग (Tax Exclusive)', 'Tax Exclusive'),
              _t2('कर समावेश (Tax Inclusive)', 'Tax Inclusive'),
            ], 0),
            _formActionBtn('💰 ${_t2('PRICE CALCULATOR', 'मूल्य गणक')}'),
            _formCard(
              _t2('Item Details (0)', 'आइटम विवरण (0)'),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _t2('No items yet. Use the Price Calculator or tap + Add Item.',
                        'कोई आइटम नहीं हैं। Price Calculator का उपयोग करें या + Add Item दबाएँ।'),
                    style: _t(7, color: _gsMuted),
                  ),
                ],
              ),
            ),
          ]),

          // ── Step 3: Structure Details ──
          _formSection('🛠', _t2('Structure Details', 'संरचना विवरण'), [
            _formInputCard(_t2('TOP HAT (MTR)', 'टॉप हैट (MTR)'), '', suffix: 'm'),
            _formInputCard(_t2('RAFTER (MTR)', 'राफ़्टर (MTR)'), '', suffix: 'm'),
            _formInputCard(_t2('PURIN (MTR)', 'पर्लिन (MTR)'), '', suffix: 'm'),
          ]),

          // ── Step 4: Financial Details ──
          _formSection('₹', _t2('Financial Details', 'वित्तीय विवरण'), [
            _formInputCard(_t2('DISCOUNT PER KW', 'प्रति kW छूट'),
              _t2('0', '0'), prefix: '₹', suffix: '/kW'),
            _formSelectCard(_t2('TAX (GST) *', 'कर (GST) *'),
              [_t2('GST 12% (CGAT 6% + SGST 6%)', 'GST 12% (CGST 6% + SGST 6%)')]),
            _formCard(
              _t2('INSURANCE', 'बीमा'),
              _formToggle(_t2('Click to include insurance', 'बीमा शामिल करने के लिए क्लिक करें'), false),
            ),
            _formInputCard(_t2('SYSTEM SIZE', 'सिस्टम साइज़'),
              d.plantCapacityKw, suffix: 'kW', readonly: true),
          ]),

          // Navigation buttons
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              pw.Expanded(child: _formNavBtn(_t2('Close', 'बंद करें'))),
              pw.SizedBox(width: 12),
              pw.Expanded(child: _formNextBtn(_t2('Next', 'अगला'))),
            ],
          ),
          pw.Spacer(),
          _footer(3),
        ],
      ),
    );
  }

  // ── Form helper widgets ──────────────────────────────────────────────────

  /// 4-step segmented progress bar. [current] is 1-indexed.
  pw.Widget _estimateProgressBar(int steps, int current) {
    return pw.Container(
      height: 8,
      child: pw.Row(children: [
        for (int i = 0; i < steps; i++)
          pw.Expanded(
            child: pw.Container(
              height: 8,
              margin: const pw.EdgeInsets.symmetric(horizontal: 1),
              decoration: pw.BoxDecoration(
                color: i < current ? _gsTeal : _gsBorder,
                borderRadius: pw.BorderRadius.circular(4),
              ),
            ),
          ),
      ]),
    );
  }

  /// Section header: icon chip + bold title, followed by [children].
  pw.Widget _formSection(String icon, String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(children: [
          pw.Container(
            width: 32, height: 32,
            decoration: pw.BoxDecoration(
              color: const PdfColor(0.03, 0.08, 0.25, 0.12),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Center(child: pw.Text(icon, style: _t(16))),
          ),
          pw.SizedBox(width: 8),
          pw.Text(title, style: _t(12, bold: true, color: navy)),
        ]),
        pw.SizedBox(height: 12),
        ...children,
      ],
    );
  }

  /// Labelled bordered input card.
  pw.Widget _formInputCard(String label, String value, {
    bool readonly = false,
    String? prefix,
    String? suffix,
    String? placeholder,
  }) {
    final effectiveValue = value.isNotEmpty ? value : (placeholder ?? '');
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: _t(8.5, bold: true, color: navy)),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              color: readonly ? PdfColors.grey100 : PdfColors.white,
              border: pw.Border.all(color: _gsBorder, width: 0.75),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(children: [
              if (prefix != null) ...[
                pw.Text(prefix, style: _t(9, color: _gsMuted)),
                pw.SizedBox(width: 6),
              ],
              pw.Expanded(
                child: pw.Text(
                  effectiveValue,
                  style: _t(9, color: readonly ? _gsMuted : _gsInk),
                  maxLines: 1,
                ),
              ),
              if (suffix != null) ...[
                pw.SizedBox(width: 6),
                pw.Text(suffix, style: _t(9, color: _gsMuted)),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  /// Input card with +91 prefix (phone number).
  pw.Widget _formPhoneInput(String label, String value) =>
    _formInputCard(label, value, prefix: '+91 ');

  /// Textarea-style labelled card.
  pw.Widget _formTextarea(String label, String placeholder) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: _t(8.5, bold: true, color: navy)),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: _gsBorder, width: 0.75),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              placeholder,
              style: _t(8, color: _gsMuted),
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  /// Horizontal radio-group row.
  pw.Widget _formRadioGroup(String label, List<String> options, int selected) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: _t(8.5, bold: true, color: navy)),
          pw.SizedBox(height: 4),
          pw.Row(children: [
            for (int i = 0; i < options.length; i++)
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: i == selected ? _gsTeal : PdfColors.white,
                    border: pw.Border.all(
                      color: i == selected ? _gsTeal : _gsBorder,
                      width: 0.75,
                    ),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Center(child: pw.Text(
                    options[i],
                    style: _t(8.5, color: i == selected ? PdfColors.white : _gsMuted),
                    textAlign: pw.TextAlign.center,
                    maxLines: 1,
                  )),
                ),
              ),
          ]),
        ],
      ),
    );
  }

  /// Selector tile — dot + value + chevron.
  pw.Widget _formSelectorTile(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: _t(8.5, bold: true, color: navy)),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: _gsBorder, width: 0.75),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(children: [
              pw.Container(
                width: 8, height: 8,
                decoration: const pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: PdfColor(0.13, 0.58, 0.95),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(value.isNotEmpty ? value : label,
                style: _t(9, color: _gsMuted)),
              pw.Spacer(),
              pw.Text('›', style: _t(12, color: PdfColors.grey400)),
            ]),
          ),
        ],
      ),
    );
  }

  /// Toggle switch row — label on left, switch on right.
  pw.Widget _formToggle(String label, bool value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: _t(9, color: _gsMuted)),
          pw.Container(
            width: 40, height: 22,
            decoration: pw.BoxDecoration(
              color: value ? _gsTeal : PdfColors.grey300,
              borderRadius: pw.BorderRadius.circular(22),
            ),
            child: pw.Align(
              alignment: value ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
              child: pw.Container(
                width: 18, height: 18,
                decoration: const pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gold-gradient action button.
  pw.Widget _formActionBtn(String text) {
    return pw.Container(
      width: double.infinity,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      decoration: pw.BoxDecoration(
        gradient: _goldGrad,
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Text(text, style: _t(9, bold: true, color: PdfColors.white)),
    );
  }

  /// Generic white card with a title and child content.
  pw.Widget _formCard(String title, pw.Widget child) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: _gsBorder, width: 0.75),
          borderRadius: pw.BorderRadius.circular(16),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: _t(9.5, bold: true, color: navy)),
            pw.SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }

  /// Select dropdown card.
  pw.Widget _formSelectCard(String label, List<String> options) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: _t(8.5, bold: true, color: navy)),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: _gsBorder, width: 0.75),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(children: [
              pw.Expanded(child: pw.Text(
                options.isNotEmpty ? options[0] : '',
                style: _t(9, color: _gsInk),
              )),
              pw.SizedBox(width: 6),
              pw.Text('▼', style: _t(8, color: _gsMuted)),
            ]),
          ),
        ],
      ),
    );
  }

  /// Back / Close button (outline style).
  pw.Widget _formNavBtn(String text) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 14),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _gsBorder, width: 0.75),
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Text(text, style: _t(10, bold: true, color: navy)),
    );
  }

  /// Next / Create button (solid navy).
  pw.Widget _formNextBtn(String text) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 14),
      decoration: pw.BoxDecoration(
        color: navy,
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Text(text, style: _t(10, bold: true, color: PdfColors.white)),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PAGE 4 — Terms & Bill of Materials
  // ════════════════════════════════════════════════════════════════════════════

  pw.Page _termsBom() {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 36, 28, 48),
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
                padding: const pw.EdgeInsets.all(5),
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
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(currentCategory!,
                  style: _t(7.5, bold: true, color: navy)),
            ),
            pw.Center(child: pw.Text('', style: _t(7.5))),
            pw.Center(child: pw.Text('', style: _t(7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('', style: _t(7.5))),
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
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.item, style: _t(7.5))),
          pw.Center(child: pw.Text(item.qty, style: _t(7.5), textAlign: pw.TextAlign.center)),
          pw.Center(child: pw.Text(item.unit, style: _t(7.5), textAlign: pw.TextAlign.center)),
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.brand, style: _t(7.5))),
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
      margin: const pw.EdgeInsets.fromLTRB(28, 36, 28, 48),
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
      margin: const pw.EdgeInsets.fromLTRB(28, 36, 28, 48),
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
