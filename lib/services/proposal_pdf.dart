/// ---------------------------------------------------------------------------
/// Roof Top Solar Proposal + Quotation — 7-page PDF generator.
///
/// Matches the "Global Solar 2.0 — Solar Quotation & Proposal (7-Page PDF Set)"
/// design:
///   Page 1 — Cover (hero + meta + highlights)
///   Page 2 — Plant Design Showcase (design image + spec cards + generation)
///   Page 3 — Official Quotation (from/bill-to, line items, financial summary,
///            bank details, signature)
///   Page 4 — Terms & Conditions + Comprehensive Bill of Material
///   Page 5 — Warranty Terms (Sections 1–6)
///   Page 6 — Warranty Terms (Sections 7–12)
///   Page 7 — UPI Payment QR + Leadership contacts
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/proposal_data.dart';

class ProposalPdf {
  ProposalPdf._();

  static final NumberFormat _fmt = NumberFormat.decimalPattern('en_IN');

  /// Indian-style currency, e.g. `Rs. 1,40,800` or `-Rs. 78,000`.
  static String money(int amount) {
    final s = 'Rs. ${_fmt.format(amount.abs())}';
    return amount < 0 ? '-$s' : s;
  }

  static String moneyINR(int amount) {
    final s = 'Rs. ${_fmt.format(amount.abs())}/-';
    return amount < 0 ? '-$s' : s;
  }

  static Future<Uint8List> generate(SolarProposalData data) async {
    final logo = data.logoImage ?? await _asset('assets/images/logo.png');
    final hero =
        data.heroImage ?? await _asset('assets/images/hero_installation.jpg');

    // Panel-count-specific design image for page 2.
    // 6 panels uses the corrected PNG; others are JPGs.
    String panelAsset;
    switch (data.panelCount) {
      case 5:
        panelAsset = 'assets/images/solar_pannel_5.jpg';
        break;
      case 6:
        panelAsset = 'assets/images/solar_pannel_6.png';
        break;
      case 7:
        panelAsset = 'assets/images/solar_pannel_7.jpg';
        break;
      case 8:
        panelAsset = 'assets/images/solar_pannel_8.jpg';
        break;
      case 9:
        panelAsset = 'assets/images/solar_pannel_9.jpg';
        break;
      case 10:
        panelAsset = 'assets/images/solar_pannel_10.jpg';
        break;
      default:
        panelAsset = 'assets/images/solar_rooftop_overview.jpg';
    }
    final design = data.designImageTop ?? await _asset(panelAsset);

    final r = _Renderer(data, logo, hero, design);
    final doc = pw.Document();
    doc.addPage(r.cover());
    doc.addPage(r.designShowcase());
    doc.addPage(r.quotation());
    doc.addPage(r.termsBom());
    doc.addPage(r.warrantyA());
    doc.addPage(r.warrantyB());
    doc.addPage(r.payment());
    return doc.save();
  }

  static Future<Uint8List> _asset(String path) async {
    try {
      final b = await rootBundle.load(path);
      return b.buffer.asUint8List();
    } catch (_) {
      return Uint8List(0);
    }
  }
}

// ── Palette ────────────────────────────────────────────────────────────────
final _navy = PdfColor.fromHex('#071440');
final _navyDeep = PdfColor.fromHex('#0B1F5C');
final _gold = PdfColor.fromHex('#F9B417');
final _goldLight = PdfColor.fromHex('#FFCA40');
final _goldSoft = PdfColor.fromHex('#FEF3D6');
final _sky = PdfColor.fromHex('#EAF4FF');
final _skySoft = PdfColor.fromHex('#F4F9FF');
final _border = PdfColor.fromHex('#D1E3F8');
final _green = PdfColor.fromHex('#1E8E3E');
final _greenDark = PdfColor.fromHex('#167031');
final _greenLight = PdfColor.fromHex('#E6F4EA');
final _s900 = PdfColor.fromHex('#0F172A');
final _s800 = PdfColor.fromHex('#1E293B');
final _s700 = PdfColor.fromHex('#334155');
final _s600 = PdfColor.fromHex('#475569');
final _s500 = PdfColor.fromHex('#64748B');
final _s400 = PdfColor.fromHex('#94A3B8');
final _s200 = PdfColor.fromHex('#E2E8F0');
final _s100 = PdfColor.fromHex('#F1F5F9');
final _white = PdfColors.white;

// ── Renderer ───────────────────────────────────────────────────────────────
class _Renderer {
  final SolarProposalData d;
  final Uint8List logo;
  final Uint8List hero;
  final Uint8List design;

  _Renderer(this.d, this.logo, this.hero, this.design);

  pw.TextStyle _t(double size,
      {bool bold = false,
      PdfColor? color,
      double? height,
      double spacing = 0}) {
    return pw.TextStyle(
      font: pw.Font.helvetica(),
      fontBold: pw.Font.helveticaBold(),
      fontSize: size,
      color: color ?? _s800,
      height: height ?? 1.1,
      letterSpacing: spacing,
    );
  }

  String _s(String? v) => (v == null || v.isEmpty) ? '-' : v;

  double get _capKw =>
      double.tryParse(d.plantCapacityKw.replaceAll(RegExp(r'[^0-9.]'), '')) ??
          0;

  // ── Shared header / footer ─────────────────────────────────────────────
  pw.Widget _header(String sub) {
    return pw.Container(
      color: _navy,
      padding: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(children: [
            pw.Container(
              width: 26,
              height: 26,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                gradient: pw.LinearGradient(
                    colors: [_gold, _goldLight],
                    begin: pw.Alignment.topLeft,
                    end: pw.Alignment.bottomRight),
                image: logo.isNotEmpty
                    ? pw.DecorationImage(image: pw.MemoryImage(logo), fit: pw.BoxFit.cover)
                    : null,
              ),
              child: logo.isEmpty
                  ? pw.Center(
                      child: pw.Text('GS',
                          style: _t(8, bold: true, color: _navy)))
                  : null,
            ),
            pw.SizedBox(width: 7),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('GLOBAL SOLAR 2.0',
                    style: _t(10, bold: true, color: _white, spacing: 0.5)),
                pw.Text('ENGINEERING & EPC SOLUTIONS',
                    style: _t(5.5, color: _s400, spacing: 0.8)),
              ],
            ),
          ]),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('ROOFTOP SOLAR PROPOSAL',
                  style: _t(8, bold: true, color: _goldLight, spacing: 0.5)),
              pw.Text(sub, style: _t(5.5, color: _s400)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(int page) {
    return pw.Container(
      color: _navy,
      padding: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Global Solar 2.0 • Sukhsagar Complex, Kaliyabid, Bhavnagar',
              style: _t(6, color: _s400)),
          pw.Text('Page $page / 7',
              style: _t(8, bold: true, color: _goldLight, spacing: 0.5)),
          pw.Text('+91 84888 07797 • contact@globalsolar2.in',
              style: _t(6, color: _s400)),
        ],
      ),
    );
  }

  pw.Page _page(pw.Widget body, int n, String sub) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _header(sub),
          pw.Expanded(child: body),
          _footer(n),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title) => pw.Row(children: [
        pw.Container(width: 8, height: 8, color: _gold),
        pw.SizedBox(width: 6),
        pw.Text(title,
            style: _t(11, bold: true, color: _navy, spacing: 0.3)),
      ]);

  // ══════════════════════════════════════════════════════════════════════
  // PAGE 1 — COVER
  // ══════════════════════════════════════════════════════════════════════
  pw.Page cover() {
    return _page(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Hero
          pw.Container(
            height: 250,
            color: _navy,
            child: pw.Stack(children: [
              if (hero.isNotEmpty)
                pw.Positioned.fill(
                    child: pw.Image(pw.MemoryImage(hero), fit: pw.BoxFit.cover)),
              pw.Positioned.fill(
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      begin: pw.Alignment.topCenter,
                      end: pw.Alignment.bottomCenter,
                      colors: [
                        PdfColor.fromHex('#071440'),
                        PdfColor.fromHex('#071440')
                      ],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),
              ),
              pw.Positioned(
                top: 12,
                right: 22,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: _navy,
                    borderRadius: pw.BorderRadius.circular(999),
                    border: pw.Border.all(color: _gold, width: 0.6),
                  ),
                  child: pw.Text('Adani TOPCon Bi-Facial  •  30-Yr Warranty',
                      style: _t(7, bold: true, color: _goldLight)),
                ),
              ),
            ]),
          ),
          // Title band
          pw.Container(
            color: _navyDeep,
            padding: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: _gold,
                  child: pw.Text('OFFICIAL TURNKEY PROPOSAL SET',
                      style: _t(6, bold: true, color: _navy, spacing: 0.6)),
                ),
                pw.SizedBox(height: 4),
                pw.RichText(
                  text: pw.TextSpan(children: [
                    pw.TextSpan(
                        text: 'Solar Power ',
                        style: _t(24, bold: true, color: _white)),
                    pw.TextSpan(
                        text: 'Proposal',
                        style: _t(24, bold: true, color: _goldLight)),
                  ]),
                ),
                pw.Text(
                    'PM Surya Ghar 2.0 — Rooftop Solar Scheme • Engineering Design & Financial Plan',
                    style: _t(8, color: _sky)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              color: _skySoft,
              padding: const pw.EdgeInsets.fromLTRB(30, 16, 30, 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Meta card
                  pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: _white,
                      borderRadius: pw.BorderRadius.circular(10),
                      border: pw.Border.all(color: _s200),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('DOCUMENT IDENTIFIER',
                                    style: _t(6, bold: true, color: _s400, spacing: 0.5)),
                                pw.Text(d.quotationId,
                                    style: _t(11, bold: true, color: _navy)),
                              ],
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: pw.BoxDecoration(
                                color: _sky,
                                borderRadius: pw.BorderRadius.circular(4),
                                border: pw.Border.all(color: _border),
                              ),
                              child: pw.Text('Residential Grid-Tied System',
                                  style: _t(8, bold: true, color: _navyDeep)),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        pw.Divider(color: _s200, height: 8, thickness: 0.6),
                        pw.SizedBox(height: 4),
                        _metaGrid([
                          ['Proposal Date:', d.quotationDate, null],
                          ['Valid Until (Expiry):', d.expiryDate, _green],
                          ['Prepared By:', d.preparedBy, null],
                          ['Authorized Channel:', 'Adani Solar Authorized Partner', null],
                          ['Customer Name:', d.customerName, _navy],
                          ['Contact Number:', d.customerMobile, null],
                          ['Installation Site:', d.customerLocation, null],
                          [
                            'Proposed Capacity:',
                            '${_capKw.toStringAsFixed(2)} kW (${d.panelCount} × ${d.panelWattpeak} Wp)',
                            _navyDeep
                          ],
                        ]),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  // Highlights
                  pw.Row(children: [
                    _highlight('Government Subsidy', 'Rs. 78,000 Direct DBT', _green),
                    pw.SizedBox(width: 8),
                    _highlight('Est. Monthly Bill', 'Reduced to Rs. 0', _navy),
                    pw.SizedBox(width: 8),
                    _highlight('PGVCL Net-Meter', 'Fast-Track Liaison', _navyDeep),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
      1,
      'PM Surya Ghar: Muft Bijli Yojana',
    );
  }

  pw.Widget _metaGrid(List<List<Object?>> rows) {
    final children = <pw.Widget>[];
    for (var i = 0; i < rows.length; i += 2) {
      final left = rows[i];
      final right = i + 1 < rows.length ? rows[i + 1] : null;
      children.add(pw.Row(children: [
        pw.Expanded(child: _metaCell(left)),
        pw.SizedBox(width: 18),
        pw.Expanded(
            child: right != null
                ? _metaCell(right)
                : pw.SizedBox()),
      ]));
      if (i + 2 < rows.length) children.add(pw.SizedBox(height: 6));
    }
    return pw.Column(children: children);
  }

  pw.Widget _metaCell(List<Object?> row) {
    final color = row[2] as PdfColor?;
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 3),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _s100, width: 0.6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(row[0] as String, style: _t(7, color: _s500)),
          pw.SizedBox(height: 1),
          pw.Text(row[1] as String,
              style: _t(9, bold: true, color: color ?? _s800)),
        ],
      ),
    );
  }

  pw.Widget _highlight(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: pw.BoxDecoration(
          color: _white,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: _sky),
        ),
        child: pw.Column(children: [
          pw.Text(label.toUpperCase(),
              textAlign: pw.TextAlign.center,
              style: _t(6, bold: true, color: _s400, spacing: 0.4)),
          pw.SizedBox(height: 3),
          pw.Text(value,
              textAlign: pw.TextAlign.center,
              style: _t(9, bold: true, color: color)),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // PAGE 2 — PLANT DESIGN SHOWCASE
  // ══════════════════════════════════════════════════════════════════════
  pw.Page designShowcase() {
    return _page(
      pw.Container(
        color: _white,
        padding: const pw.EdgeInsets.fromLTRB(26, 12, 26, 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Title
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: _greenLight,
                    child: pw.Text('ARCHITECTURAL & ELECTRICAL LAYOUT',
                        style: _t(6, bold: true, color: _green, spacing: 0.5)),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Solar Plant Design & Technical Specifications',
                      style: _t(16, bold: true, color: _navy)),
                ]),
                pw.Text('${_capKw.toStringAsFixed(2)} kW Config',
                    style: _t(8, bold: true, color: _navyDeep)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Divider(color: _s200, height: 6, thickness: 0.6),
            pw.SizedBox(height: 8),
            // Design image card
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _sky,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: _border),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Your Solar Plant Design',
                          style: _t(11, bold: true, color: _navy)),
                      pw.Container(
                        padding:
                            const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: _white,
                          borderRadius: pw.BorderRadius.circular(999),
                          border: pw.Border.all(color: _border),
                        ),
                        child: pw.Text('Computer-Aided 3D Shadow Analysis',
                            style: _t(6.5, bold: true, color: _navyDeep)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    height: 180,
                    decoration: pw.BoxDecoration(
                      color: _white,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: _s200),
                    ),
                    child: pw.Stack(children: [
                      if (design.isNotEmpty)
                        pw.Positioned.fill(
                            child: pw.Image(pw.MemoryImage(design),
                                fit: pw.BoxFit.cover)),
                      pw.Positioned(
                        left: 8,
                        top: 8,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          color: _navy,
                          child: pw.Text(
                              'ORIENTATION: SOUTH-FACING (AZIMUTH 180° / TILT 22°)',
                              style: _t(6, color: _white)),
                        ),
                      ),
                      pw.Positioned(
                        right: 8,
                        top: 8,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          color: _green,
                          child: pw.Text('OPTIMAL ANNUAL SOLAR IRRADIATION',
                              style: _t(6, bold: true, color: _white)),
                        ),
                      ),
                      pw.Positioned(
                        left: 0,
                        right: 0,
                        bottom: 8,
                        child: pw.Center(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: pw.BoxDecoration(
                              color: _navy,
                              border: pw.Border.all(color: _gold, width: 0.6),
                              borderRadius: pw.BorderRadius.circular(6),
                            ),
                            child: pw.Column(children: [
                              pw.Text('ELEVATED G2G FRAMING GUARANTEE',
                                  style: _t(6, bold: true, color: _goldLight)),
                              pw.Text(
                                  '8.5 ft Walkway Head Clearance • 100% Terrace Walkability Preserved',
                                  style: _t(6.5, bold: true, color: _white)),
                            ]),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                          '*Note: Actual layout may vary slightly post physical site survey.',
                          style: _t(6, color: _s500)),
                      pw.Text('Wind Resistance Certified: Up to 160 km/h',
                          style: _t(6, bold: true, color: _navy)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            _sectionTitle('CORE ENGINEERING BILL OF HARDWARE'),
            pw.SizedBox(height: 6),
            _specGrid(),
            pw.Spacer(),
            // Generation strip
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                    colors: [_navy, _navyDeep],
                    begin: pw.Alignment.centerLeft,
                    end: pw.Alignment.centerRight),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Expected Daily Generation: 14.5 – 18.0 Units (kWh) per day',
                      style: _t(7.5, bold: true, color: _goldLight)),
                  pw.Text('Annual CO₂ Offset: 4.2 Metric Tons / Year',
                      style: _t(7.5, bold: true, color: _white)),
                ],
              ),
            ),
          ],
        ),
      ),
      2,
      'Technical Plant Blueprint',
    );
  }

  pw.Widget _specGrid() {
    final cards = <List<String>>[
      ['TOTAL SYSTEM CAPACITY', '${_capKw.toStringAsFixed(2)} kWp', '#071440'],
      ['SOLAR PV MODULES', 'Adani TOPCon ${d.panelWattpeak} Wp', '#0B1F5C'],
      ['GRID-TIED SMART INVERTER', d.inverterKwValue, '#071440'],
      ['MOUNTING STRUCTURE', 'Elevated Hot-Dip GI', '#0B1F5C'],
      ['DC & AC SOLAR CABLING', '${d.dcCableSpecs} UV Tinned Copper', '#071440'],
      ['PROTECTION & EARTHING', '3-Point Chemical Earthing + LA', '#0B1F5C'],
    ];
    final rows = <pw.Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      rows.add(pw.Row(children: [
        pw.Expanded(child: _specCard(cards[i])),
        pw.SizedBox(width: 8),
        pw.Expanded(child: _specCard(cards[i + 1])),
      ]));
      if (i + 2 < cards.length) rows.add(pw.SizedBox(height: 8));
    }
    return pw.Column(children: rows);
  }

  pw.Widget _specCard(List<String> c) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _s200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(c[0], style: _t(6, bold: true, color: _s400, spacing: 0.4)),
          pw.SizedBox(height: 2),
          pw.Text(c[1],
              style: _t(9, bold: true, color: PdfColor.fromHex(c[2]))),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // PAGE 3 — OFFICIAL QUOTATION
  // ══════════════════════════════════════════════════════════════════════
  pw.Page quotation() {
    return _page(
      pw.Container(
        color: _white,
        padding: const pw.EdgeInsets.fromLTRB(26, 10, 26, 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // From / Bill To / Meta
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Expanded(
                flex: 4,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: _skySoft,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: _border),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('FROM (EPC CONTRACTOR)',
                          style: _t(6, bold: true, color: _navyDeep, spacing: 0.5)),
                      pw.SizedBox(height: 2),
                      pw.Text('Global Solar 2.0',
                          style: _t(9, bold: true, color: _navy)),
                      pw.SizedBox(height: 2),
                      pw.Text(d.companyAddress,
                          style: _t(6.5, color: _s600)),
                      pw.SizedBox(height: 2),
                      pw.Text('GSTIN: ${d.companyGstin}',
                          style: _t(6.5, bold: true, color: _s900)),
                      pw.Text('DISCOM: PGVCL Empanelled',
                          style: _t(6.5, color: _s600)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                flex: 4,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: _white,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: _s200),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILL TO (CLIENT)',
                          style: _t(6, bold: true, color: _s400, spacing: 0.5)),
                      pw.SizedBox(height: 2),
                      pw.Text(d.customerName,
                          style: _t(9, bold: true, color: _navy)),
                      pw.SizedBox(height: 2),
                      pw.Text(d.customerLocation, style: _t(6.5, color: _s600)),
                      pw.SizedBox(height: 2),
                      pw.Text('Mobile: ${d.customerMobile}',
                          style: _t(6.5, color: _s700)),
                      pw.Text('State: ${d.state}', style: _t(6.5, color: _s600)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                flex: 4,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: _navy,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: _gold, width: 0.6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      _metaLine('Estimate No:', d.quotationId, _goldLight),
                      _metaLine('Quotation Date:', d.quotationDate, _white),
                      _metaLine('Price Validity:', d.expiryDate, _goldLight),
                      _metaLine('Created By:', d.preparedBy, _white),
                    ],
                  ),
                ),
              ),
            ]),
            pw.SizedBox(height: 8),
            _lineItemsTable(),
            pw.SizedBox(height: 8),
            _financialSummary(),
            pw.SizedBox(height: 6),
            // Amount in words
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: pw.BoxDecoration(
                color: _goldSoft,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: _gold, width: 0.6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Amount in Words (Effective Cost):',
                      style: _t(7.5, bold: true, color: PdfColor.fromHex('#78350F'))),
                  pw.Text(_s(d.amountInWords),
                      style: _t(8, bold: true, color: _navy)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            // Bank + signature
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Expanded(flex: 7, child: _bankBox()),
              pw.SizedBox(width: 8),
              pw.Expanded(flex: 5, child: _signatureBox()),
            ]),
          ],
        ),
      ),
      3,
      'Official Commercial Quotation',
    );
  }

  pw.Widget _metaLine(String label, String value, PdfColor vc) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: _t(6.5, color: _s400)),
          pw.Text(value, style: _t(7, bold: true, color: vc)),
        ],
      ),
    );
  }

  pw.Widget _lineItemsTable() {
    final heads = ['#', 'Item & Technical Description', 'Qty', 'Rate (Rs.)', 'Disc.', 'CGST', 'SGST', 'Total (Rs.)'];
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: _navy),
        children: [
          for (var c = 0; c < heads.length; c++)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
              child: pw.Text(heads[c],
                  textAlign: (c == 1) ? pw.TextAlign.left : pw.TextAlign.center,
                  style: _t(6.8, bold: true, color: c == 7 ? _goldLight : _white, spacing: 0.3)),
            ),
        ],
      ),
    ];
    for (var i = 0; i < d.lineItems.length; i++) {
      final it = d.lineItems[i];
      final hide = _hideRateTotal(it.description);
      final subsidy = it.rate < 0;
      rows.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: i.isEven ? _white : _s100),
        verticalAlignment: pw.TableCellVerticalAlignment.top,
        children: [
          _cell('${i + 1}'.padLeft(2, '0'), align: pw.TextAlign.center, color: _s400),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(_s(it.description),
                    style: _t(7.5, bold: true, color: subsidy ? _green : _navy)),
                if (it.specs.isNotEmpty)
                  pw.Text(it.specs.join(' '),
                      style: _t(6.2, color: subsidy ? _greenDark : _s500)),
              ],
            ),
          ),
          _cell(it.qty, align: pw.TextAlign.center),
          _cell(hide ? '-' : ProposalPdf._fmt.format(it.rate.abs()), align: pw.TextAlign.right),
          _cell(it.discount == 0 ? 'Rs. 0' : ProposalPdf.money(it.discount), align: pw.TextAlign.right),
          _cell('${_g(it.cgstPercent)}%', align: pw.TextAlign.right),
          _cell('${_g(it.sgstPercent)}%', align: pw.TextAlign.right),
          _cell(hide ? '-' : ProposalPdf._fmt.format(it.total.abs()),
              align: pw.TextAlign.right, bold: true, color: subsidy ? _green : _navy),
        ],
      ));
    }
    return pw.Table(
      border: pw.TableBorder.all(color: _s200, width: 0.4),
      columnWidths: {
        0: pw.FixedColumnWidth(20),
        1: pw.FlexColumnWidth(3.2),
        2: pw.FixedColumnWidth(34),
        3: pw.FixedColumnWidth(50),
        4: pw.FixedColumnWidth(40),
        5: pw.FixedColumnWidth(34),
        6: pw.FixedColumnWidth(34),
        7: pw.FixedColumnWidth(54),
      },
      children: rows,
    );
  }

  String _g(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  static bool _hideRateTotal(String description) {
    final x = description.toLowerCase();
    return x.contains('stamp') || x.contains('meter') || x.contains('geda');
  }

  pw.Widget _cell(String text,
      {pw.TextAlign align = pw.TextAlign.left,
      bool bold = false,
      PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(text,
          textAlign: align,
          style: _t(7, bold: bold, color: color ?? _s700)),
    );
  }

  pw.Widget _financialSummary() {
    final totalBefore = d.grandTotal + d.subsidyAmount;
    final rows = <pw.Widget>[
      _fsRow(
        '1. System Gross Amount (Inclusive of Hardware, Elevation & GST)',
        'Turnkey EPC',
        ProposalPdf.moneyINR(totalBefore),
        _navy,
        _navyDeep,
        _goldLight,
      ),
      _fsRow(
        '2. Central Government Subsidy (PM Surya Ghar 2.0 DBT)',
        'Direct Bank Credit',
        '- ${ProposalPdf.moneyINR(d.subsidyAmount)}',
        _green,
        _greenDark,
        _white,
      ),
      _fsRow(
        '3. EFFECTIVE NET COST TO CUSTOMER (After DBT Subsidy)',
        'Realized cost after subsidy disbursement',
        ProposalPdf.moneyINR(d.grandTotal),
        _navyDeep,
        _navy,
        _goldLight,
        big: true,
      ),
      _fsRow(
        '4. Total Turnkey Payable to EPC (By Cheque / RTGS / Loan)',
        'As per Milestone Schedule',
        ProposalPdf.moneyINR(totalBefore),
        _sky,
        _border,
        _navy,
        dark: true,
      ),
    ];
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _navyDeep, width: 1.4),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(children: rows),
    );
  }

  pw.Widget _fsRow(String label, String sub, String amount, PdfColor leftBg,
      PdfColor rightBg, PdfColor amountColor,
      {bool big = false, bool dark = false}) {
    return pw.Row(children: [
      pw.Expanded(
        flex: 8,
        child: pw.Container(
          color: leftBg,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: _t(big ? 9 : 7.5, bold: true,
                      color: dark ? _navy : _white)),
              pw.Text(sub,
                  style: _t(6, color: dark ? _s500 : _s400)),
            ],
          ),
        ),
      ),
      pw.Expanded(
        flex: 4,
        child: pw.Container(
          color: rightBg,
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text(amount,
              style: _t(big ? 11 : 9, bold: true, color: amountColor)),
        ),
      ),
    ]);
  }

  pw.Widget _bankBox() {
    final b = d.bankDetails;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _skySoft,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('OFFICIAL BANK RTGS / NEFT PARTICULARS',
              style: _t(7, bold: true, color: _navy, spacing: 0.3)),
          pw.SizedBox(height: 5),
          _kv('Bank Name:', b.bankName),
          _kv('Account Type:', 'Current Account'),
          _kv('Account Name:', b.accountName),
          _kv('Account Number:', b.accountNo),
          _kv('IFSC Code:', b.ifsc),
          _kv('Branch:', b.branch),
        ],
      ),
    );
  }

  pw.Widget _kv(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.2),
        child: pw.Row(children: [
          pw.SizedBox(
              width: 74,
              child: pw.Text(k, style: _t(6.5, color: _s500))),
          pw.Expanded(
              child: pw.Text(v,
                  style: _t(6.8, bold: true, color: _navy))),
        ]),
      );

  pw.Widget _signatureBox() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _s200),
      ),
      child: pw.Column(children: [
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('For Global Solar 2.0',
              style: _t(6, bold: true, color: _s400, spacing: 0.4)),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Jayrajsinh S. Umat',
            style: _t(11, bold: true, color: _navy)),
        pw.Container(
            width: 120,
            margin: const pw.EdgeInsets.symmetric(vertical: 3),
            decoration: pw.BoxDecoration(
                border: pw.Border(
                    bottom: pw.BorderSide(
                        color: _s400, width: 0.7, style: pw.BorderStyle.dashed)))),
        pw.Text('Founder & Chief Technical Officer',
            style: _t(6.8, bold: true, color: _navy)),
        pw.Text('Authorized EPC Signatory & Stamp',
            style: _t(6, color: _s500)),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // PAGE 4 — TERMS + BOM
  // ══════════════════════════════════════════════════════════════════════
  pw.Page termsBom() {
    final terms = [
      ['Payment Milestones:', '10% booking token, 70% on material dispatch, 20% post PGVCL net-meter inspection.'],
      ['Subsidy Disbursal:', 'Rs. 78,000 processed via the National PM Surya Ghar portal to the Aadhaar-linked bank account.'],
      ['Statutory Clearances:', 'Global Solar 2.0 manages 100% of PGVCL documentation, CEIG approval and meter testing.'],
      ['Installation Lead Time:', 'Mechanical & electrical installation completed within 5-7 days of site readiness.'],
      ['Client Scope:', 'Shadow-free rooftop terrace, raw water connection and internet WiFi for inverter monitoring.'],
      ['Price Validity:', 'Quoted prices guaranteed for 15 calendar days from issuance.'],
    ];
    return _page(
      pw.Container(
        color: _white,
        padding: const pw.EdgeInsets.fromLTRB(26, 12, 26, 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _pageHeading('Commercial Terms & Project Conditions',
                'Applicable to Quotation ${d.quotationId}'),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _skySoft,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: _border),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: _termCol(terms.sublist(0, 3))),
                  pw.SizedBox(width: 12),
                  pw.Expanded(child: _termCol(terms.sublist(3))),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            _pageHeading('Comprehensive Bill of Material (BOM)',
                'MNRE / ALMM Approved Component List',
                barColor: _gold),
            pw.SizedBox(height: 8),
            _bomTable(),
          ],
        ),
      ),
      4,
      'Scope of Work & BOM',
    );
  }

  pw.Widget _pageHeading(String title, String right, {PdfColor? barColor}) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(children: [
            pw.Container(width: 10, height: 10, color: barColor ?? _navyDeep),
            pw.SizedBox(width: 6),
            pw.Text(title, style: _t(13, bold: true, color: _navy)),
          ]),
          pw.Text(right, style: _t(7, color: _s500)),
        ],
      ),
      pw.SizedBox(height: 3),
      pw.Divider(color: _s200, height: 4, thickness: 0.6),
    ]);
  }

  pw.Widget _termCol(List<List<String>> items) {
    final children = <pw.Widget>[];
    for (var i = 0; i < items.length; i++) {
      children.add(pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 13,
            height: 13,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(color: _navy, shape: pw.BoxShape.circle),
            child: pw.Text('${i + 1}', style: _t(6, bold: true, color: _goldLight)),
          ),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(children: [
                pw.TextSpan(
                    text: '${items[i][0]} ',
                    style: _t(7.5, bold: true, color: _s900)),
                pw.TextSpan(text: items[i][1], style: _t(7.5, color: _s600)),
              ]),
            ),
          ),
        ],
      ));
      if (i != items.length - 1) children.add(pw.SizedBox(height: 6));
    }
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: children);
  }

  pw.Widget _bomTable() {
    final heads = ['Sr No.', 'Item Description', 'Qty', 'Unit', 'Approved Brand'];
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: _navy),
        children: [
          for (final h in heads)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: pw.Text(h,
                  style: _t(6.8, bold: true, color: _white, spacing: 0.3)),
            ),
        ],
      ),
    ];
    String? cat;
    var sr = 0;
    for (final b in d.bomItems) {
      if (b.category != cat) {
        cat = b.category;
        rows.add(pw.TableRow(
          decoration: pw.BoxDecoration(color: _s200),
          children: [
            pw.SizedBox(),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: pw.Text((cat ?? '').toUpperCase(),
                  style: _t(6.8, bold: true, color: _s800)),
            ),
            pw.SizedBox(),
            pw.SizedBox(),
            pw.SizedBox(),
          ],
        ));
      }
      sr++;
      rows.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: sr.isEven ? _s100 : _white),
        children: [
          _cell('$sr', align: pw.TextAlign.center, color: _s500),
          _cell(b.item),
          _cell(b.qty, align: pw.TextAlign.center, bold: true),
          _cell(b.unit, align: pw.TextAlign.center, color: _s600),
          _cell(b.brand, bold: true, color: _navyDeep),
        ],
      ));
    }
    return pw.Table(
      border: pw.TableBorder.all(color: _s200, width: 0.4),
      columnWidths: {
        0: pw.FixedColumnWidth(40),
        1: pw.FlexColumnWidth(3.2),
        2: pw.FixedColumnWidth(40),
        3: pw.FixedColumnWidth(45),
        4: pw.FlexColumnWidth(1.6),
      },
      children: rows,
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // PAGES 5–6 — WARRANTY
  // ══════════════════════════════════════════════════════════════════════
  pw.Page warrantyA() => _warrantyPage(
        5,
        'Warranty Policy (Part I)',
        'Tier-1 Warranty Policy & Performance Guarantees',
        'Comprehensive Asset Security',
        'Sections 1 to 6 of 12',
        0,
        6,
        'All warranties are backed by OEM certificates + Global Solar 2.0 direct contractor bond.',
      );

  pw.Page warrantyB() => _warrantyPage(
        6,
        'Warranty Policy (Part II)',
        'Warranty Scope, Exclusions & Claim SLA',
        'Service Protocol & Liability',
        'Sections 7 to 12 of 12',
        6,
        12,
        'ISO 9001:2015 Quality Certified Rooftop Solar Engineering Execution',
      );

  pw.Page _warrantyPage(int page, String sub, String title, String tag,
      String count, int start, int end, String banner) {
    final all = d.warrantySections;
    final slice = all.sublist(
        start.clamp(0, all.length), end.clamp(0, all.length));
    return _page(
      pw.Container(
        color: _white,
        padding: const pw.EdgeInsets.fromLTRB(26, 12, 26, 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: _sky,
                    child: pw.Text(tag.toUpperCase(),
                        style: _t(6, bold: true, color: _navyDeep, spacing: 0.5)),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(title, style: _t(15, bold: true, color: _navy)),
                ]),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: _greenLight,
                    borderRadius: pw.BorderRadius.circular(999),
                    border: pw.Border.all(color: _green, width: 0.5),
                  ),
                  child: pw.Text(count, style: _t(7, bold: true, color: _green)),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Divider(color: _s200, height: 6, thickness: 0.6),
            pw.SizedBox(height: 6),
            for (var i = 0; i < slice.length; i++) ...[
              _warrantyCard(start + i + 1, slice[i]),
              if (i != slice.length - 1) pw.SizedBox(height: 7),
            ],
            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: pw.BoxDecoration(
                color: _navy,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: _gold, width: 0.5),
              ),
              child: pw.Text(banner,
                  style: _t(7.5, bold: true, color: _goldLight)),
            ),
          ],
        ),
      ),
      page,
      sub,
    );
  }

  pw.Widget _warrantyCard(int n, WarrantySection sec) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _s200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(children: [
            pw.Container(
              width: 15,
              height: 15,
              alignment: pw.Alignment.center,
              decoration:
                  pw.BoxDecoration(color: _navy, shape: pw.BoxShape.circle),
              child: pw.Text('$n', style: _t(7, bold: true, color: _goldLight)),
            ),
            pw.SizedBox(width: 6),
            pw.Expanded(
              child: pw.Text(_s(sec.heading),
                  style: _t(9, bold: true, color: _navy)),
            ),
          ]),
          pw.SizedBox(height: 3),
          pw.Container(height: 0.6, color: _s100),
          pw.SizedBox(height: 3),
          for (final b in sec.bullets)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 1.5),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('•  ', style: _t(7, color: _gold)),
                  pw.Expanded(
                      child: pw.Text(b, style: _t(7, color: _s600))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // PAGE 7 — PAYMENT & CONTACT
  // ══════════════════════════════════════════════════════════════════════
  pw.Page payment() {
    return _page(
      pw.Container(
        color: _skySoft,
        padding: const pw.EdgeInsets.fromLTRB(26, 12, 26, 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Column(children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: _greenLight,
                child: pw.Text('INSTANT ZERO-CONTACT BOOKING',
                    style: _t(6, bold: true, color: _green, spacing: 0.5)),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Scan & Pay via Unified Payments Interface (UPI)',
                  textAlign: pw.TextAlign.center,
                  style: _t(15, bold: true, color: _navy)),
              pw.Text(
                  'Compatible with Google Pay, PhonePe, Paytm, BHIM and all banking UPI apps',
                  textAlign: pw.TextAlign.center,
                  style: _t(7.5, color: _s500)),
            ]),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Container(
                width: 330,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: _white,
                  borderRadius: pw.BorderRadius.circular(14),
                  border: pw.Border.all(color: _border, width: 1.4),
                ),
                child: pw.Column(children: [
                  pw.Container(
                    padding:
                        const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: _greenLight,
                      borderRadius: pw.BorderRadius.circular(999),
                    ),
                    child: pw.Text('✓  NPCI Verified Merchant Account',
                        style: _t(7, bold: true, color: _green)),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: _white,
                      border: pw.Border.all(color: _s800, width: 1.2),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: d.upiQrUpiId.isNotEmpty
                          ? d.upiQrUpiId
                          : 'upi://pay?pa=global.solar.2.0@oksbi&pn=Global Solar 2.0&cu=INR',
                      width: 130,
                      height: 130,
                      color: _navy,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: _skySoft,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: _border),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Merchant UPI VPA:', style: _t(7, color: _s500)),
                        pw.Text(d.upiId,
                            style: _t(8.5, bold: true, color: _navy)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: pw.BoxDecoration(
                      gradient: pw.LinearGradient(
                          colors: [_navy, _navyDeep],
                          begin: pw.Alignment.centerLeft,
                          end: pw.Alignment.centerRight),
                      borderRadius: pw.BorderRadius.circular(10),
                      border: pw.Border.all(color: _gold, width: 0.6),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('BOOKING REGISTRATION ADVANCE',
                                style: _t(6.5, bold: true, color: _goldLight, spacing: 0.4)),
                            pw.Text('Token for Site Survey & Liaison',
                                style: _t(7, color: _s400)),
                          ],
                        ),
                        pw.Text('Rs. 10,000.00',
                            style: _t(15, bold: true, color: _goldLight)),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            pw.SizedBox(height: 10),
            // Contacts
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: _navy,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: _gold, width: 0.5),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                      child: _contactCol('FOUNDERS DIRECT HELPLINE', [
                    'Jayrajsinh S. Umat — +91 84888 07797',
                    'Gopalsinh J. Parmar — +91 88665 68543',
                  ])),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                      child: _contactCol('ONLINE & PORTAL SUPPORT', [
                    'WhatsApp: +91 84888 07797',
                    'Email: contact@globalsolar2.in',
                    'Website: www.globalsolar2.in',
                  ])),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                      child: _contactCol('REGIONAL PHYSICAL OFFICES', [
                    'Bhavnagar HQ: Shop 4A, Sukhsagar Complex, Kaliyabid.',
                    'Talaja Desk: Main Market Highway Rd, Opp. PGVCL Sub-station.',
                  ])),
                ],
              ),
            ),
          ],
        ),
      ),
      7,
      'Payment Gateway & Helpdesk',
    );
  }

  pw.Widget _contactCol(String title, List<String> lines) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: _t(6.5, bold: true, color: _goldLight, spacing: 0.4)),
        pw.SizedBox(height: 3),
        for (final l in lines)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 1.5),
            child: pw.Text(l, style: _t(7, color: _s400)),
          ),
      ],
    );
  }
}
