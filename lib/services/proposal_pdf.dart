/// ---------------------------------------------------------------------------
/// Roof Top Solar Proposal + Quotation — 7-page PDF generator.
/// Matches the "Global Solar 2.0 — Solar Quotation & Proposal (7-Page PDF Set)"
/// design (split-view cover, 2D plan + 3D axonometric page 2, quotation, terms
/// + BOM, warranty x2, UPI payment).
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
final _blue = PdfColor.fromHex('#1D4ED8');
final _blueDark = PdfColor.fromHex('#1E3A8A');

// 3D axonometric SVG (matching the reference design).
const String _isoSvg = '''
<svg viewBox="0 0 420 220" xmlns="http://www.w3.org/2000/svg" fill="none">
<path d="M70 120 L210 180 L350 120 L210 65 Z" fill="#E2E8F0" stroke="#94A3B8" stroke-width="1.5"/>
<path d="M70 120 L70 145 L210 205 L210 180 Z" fill="#CBD5E1" stroke="#94A3B8" stroke-width="1.5"/>
<path d="M210 180 L210 205 L350 145 L350 120 Z" fill="#94A3B8" stroke="#64748B" stroke-width="1.5"/>
<path d="M60 115 L210 178 L360 115 L210 58 Z" fill="none" stroke="#64748B" stroke-width="3"/>
<ellipse cx="320" cy="110" rx="14" ry="7" fill="#38BDF8" stroke="#0284C7"/>
<path d="M306 110 V122 C306 126 334 126 334 122 V110 Z" fill="#0284C7" stroke="#0369A1"/>
<rect x="290" y="85" width="18" height="12" rx="1" fill="#F59E0B" stroke="#B45309"/>
<line x1="140" y1="125" x2="140" y2="70" stroke="#475569" stroke-width="2.5"/>
<line x1="180" y1="142" x2="180" y2="85" stroke="#475569" stroke-width="2.5"/>
<line x1="240" y1="142" x2="240" y2="85" stroke="#475569" stroke-width="2.5"/>
<line x1="280" y1="125" x2="280" y2="70" stroke="#475569" stroke-width="2.5"/>
<g transform="translate(0,-10)">
<polygon points="120,68 210,32 300,68 210,105" fill="#1E3A8A" stroke="#3B82F6" stroke-width="2"/>
<polygon points="126,67 142,60 160,67 144,74" fill="#1D4ED8" stroke="#93C5FD" stroke-width="0.75"/>
<polygon points="144,60 160,53 178,60 162,67" fill="#2563EB" stroke="#93C5FD" stroke-width="0.75"/>
<polygon points="162,53 178,46 196,53 180,60" fill="#1D4ED8" stroke="#93C5FD" stroke-width="0.75"/>
<polygon points="180,46 196,39 214,46 198,53" fill="#2563EB" stroke="#93C5FD" stroke-width="0.75"/>
<polygon points="198,39 214,32 232,39 216,46" fill="#1D4ED8" stroke="#93C5FD" stroke-width="0.75"/>
<polygon points="144,76 160,69 178,76 162,83" fill="#1E40AF" stroke="#93C5FD" stroke-width="0.75"/>
<polygon points="162,69 178,62 196,69 180,76" fill="#1D4ED8" stroke="#93C5FD" stroke-width="0.75"/>
<polygon points="180,62 196,55 214,62 198,69" fill="#1E40AF" stroke="#93C5FD" stroke-width="0.75"/>
<polygon points="198,55 214,48 232,55 216,62" fill="#1D4ED8" stroke="#93C5FD" stroke-width="0.75"/>
<polygon points="216,48 232,41 250,48 234,55" fill="#1E40AF" stroke="#93C5FD" stroke-width="0.75"/>
<circle cx="210" cy="62" r="10" fill="#3B82F6" stroke="white" stroke-width="2"/>
</g>
<line x1="250" y1="42" x2="310" y2="28" stroke="#071440" stroke-width="1"/>
<line x1="310" y1="28" x2="330" y2="28" stroke="#071440" stroke-width="1"/>
<circle cx="250" cy="42" r="2" fill="#071440"/>
<text x="333" y="30" fill="#071440" font-family="Helvetica" font-size="7.5" font-weight="700">SOLAR PV ARRAY (2x5)</text>
<line x1="240" y1="95" x2="305" y2="52" stroke="#071440" stroke-width="1"/>
<line x1="305" y1="52" x2="325" y2="52" stroke="#071440" stroke-width="1"/>
<circle cx="240" cy="95" r="2" fill="#071440"/>
<text x="328" y="54" fill="#071440" font-family="Helvetica" font-size="7.5" font-weight="700">GI ELEVATED STRUCTURE</text>
<line x1="320" y1="120" x2="340" y2="150" stroke="#071440" stroke-width="1"/>
<line x1="340" y1="150" x2="355" y2="150" stroke="#071440" stroke-width="1"/>
<circle cx="320" cy="120" r="2" fill="#071440"/>
<text x="358" y="152" fill="#071440" font-family="Helvetica" font-size="7" font-weight="700">WATER TANK</text>
<line x1="300" y1="95" x2="320" y2="168" stroke="#071440" stroke-width="1"/>
<line x1="320" y1="168" x2="340" y2="168" stroke="#071440" stroke-width="1"/>
<circle cx="300" cy="95" r="2" fill="#071440"/>
<text x="343" y="170" fill="#071440" font-family="Helvetica" font-size="7" font-weight="700">SOLAR WATER HEATER</text>
<line x1="210" y1="190" x2="310" y2="185" stroke="#071440" stroke-width="1"/>
<line x1="310" y1="185" x2="330" y2="185" stroke="#071440" stroke-width="1"/>
<circle cx="210" cy="190" r="2" fill="#071440"/>
<text x="333" y="187" fill="#071440" font-family="Helvetica" font-size="7" font-weight="700">PARAPET WALL</text>
</svg>
''';

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
      height: height ?? 1.12,
      letterSpacing: spacing,
    );
  }

  String _s(String? v) => (v == null || v.isEmpty) ? '-' : v;

  double get _capKw =>
      double.tryParse(d.plantCapacityKw.replaceAll(RegExp(r'[^0-9.]'), '')) ??
          0;

  // ── Shared footer ──────────────────────────────────────────────────────
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

  pw.Widget _navyHeader(String sub) {
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
                    ? pw.DecorationImage(
                        image: pw.MemoryImage(logo), fit: pw.BoxFit.cover)
                    : null,
              ),
              child: logo.isEmpty
                  ? pw.Center(
                      child: pw.Text('GS', style: _t(8, bold: true, color: _navy)))
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

  pw.Page _page(pw.Widget body, int n, String sub) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _navyHeader(sub),
          pw.Expanded(child: body),
          _footer(n),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title) => pw.Row(children: [
        pw.Container(width: 8, height: 8, color: _gold),
        pw.SizedBox(width: 6),
        pw.Text(title, style: _t(11, bold: true, color: _navy, spacing: 0.3)),
      ]);

  // ══════════════════════════════════════════════════════════════════════
  // PAGE 1 — COVER (split view)
  // ══════════════════════════════════════════════════════════════════════
  pw.Page cover() {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Left visual column (52%)
                pw.Expanded(
                  flex: 52,
                  child: pw.Stack(children: [
                    pw.Positioned.fill(
                        child: pw.Container(
                      color: _navy,
                      child: hero.isNotEmpty
                          ? pw.Image(pw.MemoryImage(hero), fit: pw.BoxFit.cover)
                          : null,
                    )),
                    pw.Positioned(
                      left: 16,
                      top: 16,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: pw.BoxDecoration(
                            color: _white,
                            borderRadius: pw.BorderRadius.circular(10)),
                        child: pw.Row(children: [
                          pw.Container(
                            width: 24,
                            height: 24,
                            decoration: pw.BoxDecoration(
                                shape: pw.BoxShape.circle,
                                gradient: pw.LinearGradient(
                                    colors: [_gold, _goldLight])),
                            child: pw.Center(
                                child: pw.Text('GS',
                                    style: _t(8, bold: true, color: _navy))),
                          ),
                          pw.SizedBox(width: 6),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Global Solar 2.0',
                                  style: _t(11, bold: true, color: _navy)),
                              pw.Text('SOLAR EPC SOLUTIONS',
                                  style: _t(5.5,
                                      bold: true, color: _s500, spacing: 0.5)),
                            ],
                          ),
                        ]),
                      ),
                    ),
                    pw.Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: pw.BoxDecoration(
                          color: _navy,
                          borderRadius: pw.BorderRadius.circular(10),
                          border: pw.Border.all(color: _gold, width: 0.5),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Adani TOPCon Bi-Facial',
                                style: _t(8, bold: true, color: _white)),
                            pw.Text('30-YR WARRANTY',
                                style: _t(7,
                                    bold: true, color: _goldLight, spacing: 0.4)),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
                // Right content column (48%)
                pw.Expanded(
                  flex: 48,
                  child: pw.Container(
                    color: _navy,
                    padding: const pw.EdgeInsets.all(22),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: _goldSoft,
                            border: pw.Border.all(color: _gold, width: 0.5),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text('TURNKEY ENGINEERING PROPOSAL',
                              style: _t(6,
                                  bold: true, color: _navy, spacing: 0.6)),
                        ),
                        pw.SizedBox(height: 10),
                        pw.RichText(
                          text: pw.TextSpan(children: [
                            pw.TextSpan(
                                text: 'Roof Top\n',
                                style: _t(22, bold: true, color: _white)),
                            pw.TextSpan(
                                text: 'Solar',
                                style: _t(22, bold: true, color: _goldLight)),
                            pw.TextSpan(
                                text: ' Proposal',
                                style: _t(22, bold: true, color: _white)),
                          ]),
                        ),
                        pw.Text(
                            'PM Surya Ghar: Muft Bijli Yojana Central Scheme',
                            style: _t(8, color: _sky)),
                        pw.SizedBox(height: 12),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(14),
                          decoration: pw.BoxDecoration(
                            color: _white,
                            border: pw.Border(
                                left: pw.BorderSide(color: _gold, width: 4)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('PREPARED EXCLUSIVELY FOR',
                                  style: _t(6,
                                      bold: true, color: _s400, spacing: 0.5)),
                              pw.SizedBox(height: 2),
                              pw.Text(d.customerName.toUpperCase(),
                                  style: _t(18, bold: true, color: _navy)),
                              pw.SizedBox(height: 3),
                              pw.Text('${d.state}  |  ${d.customerLocation}',
                                  style: _t(8, color: _s600)),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 12),
                        pw.Text('Global Solar 2.0',
                            style: _t(13, bold: true, color: _white)),
                        pw.SizedBox(height: 3),
                        pw.Text(d.companyAddress, style: _t(7, color: _s400)),
                        pw.SizedBox(height: 6),
                        pw.Container(height: 0.6, color: _s500),
                        pw.SizedBox(height: 6),
                        pw.Row(children: [
                          pw.Expanded(child: _metaCompact('LEAD', d.leadName)),
                          pw.Expanded(child: _metaCompact('ID', d.quotationId)),
                        ]),
                        pw.SizedBox(height: 6),
                        pw.Row(children: [
                          pw.Expanded(
                              child: _metaCompact('DATE', d.quotationDate)),
                          pw.Expanded(
                              child: _metaCompact(
                                  'PLANT CAPACITY',
                                  '${_capKw.toStringAsFixed(2)} kW')),
                        ]),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: pw.BoxDecoration(
                              color: _green,
                              borderRadius: pw.BorderRadius.circular(6)),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Direct DBT Subsidy:',
                                  style: _t(8, bold: true, color: _white)),
                              pw.Text('Rs. 78,000 Guaranteed',
                                  style: _t(9, bold: true, color: _goldLight)),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: _white,
                            borderRadius: pw.BorderRadius.circular(8),
                            border: pw.Border.all(color: _border),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Bank Details',
                                  style: _t(7, bold: true, color: _navy, spacing: 0.3)),
                              pw.SizedBox(height: 5),
                              _kv('Bank Name:', d.bankDetails.bankName),
                              _kv('Account Name:', d.bankDetails.accountName),
                              _kv('Account No:', d.bankDetails.accountNo),
                              _kv('IFSC:', d.bankDetails.ifsc),
                              _kv('Branch:', d.bankDetails.branch),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _footer(1),
        ],
      ),
    );
  }

  pw.Widget _metaCompact(String label, String value) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: _t(6, bold: true, color: _s400, spacing: 0.4)),
          pw.Text(value, style: _t(8.5, bold: true, color: _goldLight)),
        ],
      );

  // ══════════════════════════════════════════════════════════════════════
  // PAGE 2 — PLANT DESIGN SHOWCASE (2D plan + 3D axonometric)
  // ══════════════════════════════════════════════════════════════════════
  pw.Page designShowcase() {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            color: _white,
            padding: const pw.EdgeInsets.fromLTRB(26, 14, 26, 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                    pw.Container(
                      width: 26,
                      height: 26,
                      decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          gradient: pw.LinearGradient(
                              colors: [_gold, _goldLight])),
                      child: pw.Center(
                          child:
                              pw.Text('GS', style: _t(8, bold: true, color: _navy))),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('GLOBAL SOLAR 2.0',
                            style: _t(9, bold: true, color: _gold)),
                        pw.Text('Serving Talaja, Bhavnagar and nearby villages',
                            style: _t(6, color: _s400)),
                      ],
                    ),
                  ]),
                ),
                pw.SizedBox(height: 6),
                pw.Text('Solar Plants Designs You Have Previously',
                    textAlign: pw.TextAlign.center,
                    style: _t(16, bold: true, color: _s800)),
                pw.Text('Solar Plant Photos & 3D Engineering Layout',
                    textAlign: pw.TextAlign.center,
                    style: _t(7.5, color: _s400)),
                pw.SizedBox(height: 6),
                pw.Container(height: 2, color: _gold),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              color: _s100,
              padding: const pw.EdgeInsets.fromLTRB(26, 10, 26, 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: _white,
                      borderRadius: pw.BorderRadius.circular(12),
                      border: pw.Border.all(color: _s200),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Expanded(flex: 5, child: _plan2D()),
                        pw.SizedBox(width: 10),
                        pw.Expanded(flex: 7, child: _iso3D()),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _sectionTitle('CORE ENGINEERING BILL OF HARDWARE'),
                  pw.SizedBox(height: 6),
                  _specGrid(),
                ],
              ),
            ),
          ),
          _footer(2),
        ],
      ),
    );
  }

  pw.Widget _plan2D() {
    return pw.Container(
      height: 240,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _skySoft,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _s200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('N', style: _t(8, bold: true, color: _s600)),
              pw.Text('18.5 FT WIDTH',
                  style: _t(6, color: _s400, spacing: 0.4)),
            ],
          ),
          pw.SizedBox(height: 4),
          // Rooftop panel array (5 x 2)
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              color: _white,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _s700, width: 1),
            ),
            child: pw.Column(children: [
              pw.Row(children: [
                for (var i = 0; i < 5; i++) ...[
                  pw.Expanded(
                      child: pw.Container(
                          height: 34,
                          color: _blue,
                          margin: const pw.EdgeInsets.all(1))),
                ],
              ]),
              pw.Row(children: [
                for (var i = 0; i < 5; i++) ...[
                  pw.Expanded(
                      child: pw.Container(
                          height: 34,
                          color: _blueDark,
                          margin: const pw.EdgeInsets.all(1))),
                ],
              ]),
            ]),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Container(
              width: 22,
              height: 22,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: _white,
                border: pw.Border.all(color: _navyDeep, width: 1.5),
              ),
              child:
                  pw.Text('${d.panelCount}', style: _t(9, bold: true, color: _navyDeep)),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('PARAPET BOUNDARY', style: _t(6, color: _s400)),
              pw.Text('28.0 FT LENGTH', style: _t(6, color: _s400)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text('2D ROOFTOP CIVIL PLAN VIEW',
              textAlign: pw.TextAlign.center,
              style: _t(8, bold: true, color: _navy)),
        ],
      ),
    );
  }

  pw.Widget _iso3D() {
    return pw.Container(
      height: 240,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
            colors: [_s100, _white],
            begin: pw.Alignment.topLeft,
            end: pw.Alignment.bottomRight),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _s200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: _navy,
                child: pw.Text('3D AXONOMETRIC STRUCTURAL MODEL',
                    style: _t(6, bold: true, color: _goldLight, spacing: 0.4)),
              ),
              pw.Text('SCALE 1:50 • ELEVATED GI',
                  style: _t(6, color: _s500)),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.SizedBox(
            height: 150,
            child: pw.Center(
              child: pw.SvgImage(svg: _isoSvg, width: 300, height: 150),
            ),
          ),
          pw.Row(children: [
            pw.Expanded(child: _metric('CLEARANCE', '8.5 FT Walkway', _navy)),
            pw.SizedBox(width: 4),
            pw.Expanded(child: _metric('WIND LOAD', '160 km/h Tested', _navyDeep)),
            pw.SizedBox(width: 4),
            pw.Expanded(child: _metric('AZIMUTH/TILT', '22° True South', _green)),
          ]),
        ],
      ),
    );
  }

  pw.Widget _metric(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _s200),
      ),
      child: pw.Column(children: [
        pw.Text(label.toUpperCase(),
            style: _t(5.5, bold: true, color: _s400, spacing: 0.3)),
        pw.Text(value, style: _t(7.5, bold: true, color: color)),
      ]),
    );
  }

  pw.Widget _specGrid() {
    final cards = <List<String>>[
      ['TOTAL SYSTEM CAPACITY', '${_capKw.toStringAsFixed(2)} kWp', '#071440'],
      ['SOLAR PV MODULES', 'Adani TOPCon ${d.panelWattpeak} Wp', '#0B1F5C'],
      ['GRID-TIED SMART INVERTER', d.inverterKwValue, '#071440'],
      ['MOUNTING STRUCTURE', 'Elevated Hot-Dip GI (8.5ft)', '#0B1F5C'],
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
                      pw.Text(d.companyAddress, style: _t(6.5, color: _s600)),
                      pw.SizedBox(height: 2),
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
                      style:
                          _t(7.5, bold: true, color: PdfColor.fromHex('#78350F'))),
                  pw.Text(_s(d.amountInWords),
                      style: _t(8, bold: true, color: _navy)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
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
    final heads = [
      '#',
      'Item & Technical Description',
      'Qty',
      'Rate (Rs.)',
      'Disc.',
      'CGST',
      'SGST',
      'Total (Rs.)'
    ];
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: _navy),
        children: [
          for (var c = 0; c < heads.length; c++)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
              child: pw.Text(heads[c],
                  textAlign: (c == 1) ? pw.TextAlign.left : pw.TextAlign.center,
                  style: _t(6.8,
                      bold: true,
                      color: c == 7 ? _goldLight : _white,
                      spacing: 0.3)),
            ),
        ],
      ),
    ];
    for (var i = 0; i < d.lineItems.length; i++) {
      final it = d.lineItems[i];
      final subsidy = it.rate < 0;
      rows.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: i.isEven ? _white : _s100),
        verticalAlignment: pw.TableCellVerticalAlignment.top,
        children: [
          _cell('${i + 1}'.padLeft(2, '0'),
              align: pw.TextAlign.center, color: _s400),
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
          _cell(ProposalPdf._fmt.format(it.rate), align: pw.TextAlign.right),
          _cell(it.discount == 0 ? 'Rs. 0' : ProposalPdf.money(it.discount),
              align: pw.TextAlign.right),
          _cell('${_g(it.cgstPercent)}%', align: pw.TextAlign.right),
          _cell('${_g(it.sgstPercent)}%', align: pw.TextAlign.right),
          _cell(ProposalPdf._fmt.format(it.total),
              align: pw.TextAlign.right,
              bold: true,
              color: subsidy ? _green : _navy),
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

  pw.Widget _cell(String text,
      {pw.TextAlign align = pw.TextAlign.left,
      bool bold = false,
      PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(text,
          textAlign: align, style: _t(7, bold: bold, color: color ?? _s700)),
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
                  style: _t(big ? 9 : 7.5,
                      bold: true, color: dark ? _navy : _white)),
              pw.Text(sub, style: _t(6, color: dark ? _s500 : _s400)),
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
              width: 74, child: pw.Text(k, style: _t(6.5, color: _s500))),
          pw.Expanded(
              child: pw.Text(v, style: _t(6.8, bold: true, color: _navy))),
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
        pw.Text('Jayrajsinh S. Umat', style: _t(11, bold: true, color: _navy)),
        pw.Container(
            width: 120,
            margin: const pw.EdgeInsets.symmetric(vertical: 3),
            decoration: pw.BoxDecoration(
                border: pw.Border(
                    bottom: pw.BorderSide(
                        color: _s400,
                        width: 0.7,
                        style: pw.BorderStyle.dashed)))),
        pw.Text('Founder & Chief Technical Officer',
            style: _t(6.8, bold: true, color: _navy)),
        pw.Text('Authorized EPC Signatory & Stamp', style: _t(6, color: _s500)),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // PAGE 4 — TERMS + BOM
  // ══════════════════════════════════════════════════════════════════════
  pw.Page termsBom() {
    final terms = [
      [
        'Payment Milestones:',
        '10% booking token, 70% on material dispatch, 20% post PGVCL net-meter inspection.'
      ],
      [
        'Subsidy Disbursal:',
        'Rs. 78,000 processed via the National PM Surya Ghar portal to the Aadhaar-linked bank account.'
      ],
      [
        'Statutory Clearances:',
        'Global Solar 2.0 manages 100% of PGVCL documentation, CEIG approval and meter testing.'
      ],
      [
        'Installation Lead Time:',
        'Mechanical & electrical installation completed within 5-7 days of site readiness.'
      ],
      [
        'Client Scope:',
        'Shadow-free rooftop terrace, raw water connection and internet WiFi for inverter monitoring.'
      ],
      [
        'Price Validity:',
        'Quoted prices guaranteed for 15 calendar days from issuance.'
      ],
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

  pw.Widget _pageHeading(String title, String right,
      {PdfColor? barColor}) {
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
            decoration:
                pw.BoxDecoration(color: _navy, shape: pw.BoxShape.circle),
            child: pw.Text('${i + 1}',
                style: _t(6, bold: true, color: _goldLight)),
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
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start, children: children);
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
    final slice =
        all.sublist(start.clamp(0, all.length), end.clamp(0, all.length));
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
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        color: _sky,
                        child: pw.Text(tag.toUpperCase(),
                            style: _t(6,
                                bold: true, color: _navyDeep, spacing: 0.5)),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(title, style: _t(15, bold: true, color: _navy)),
                    ]),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            pw.SizedBox(height: 12),
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
              child: pw.Text('$n',
                  style: _t(7, bold: true, color: _goldLight)),
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
                  pw.Expanded(child: pw.Text(b, style: _t(7, color: _s600))),
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
                    child: pw.Text('NPCI Verified Merchant Account',
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
                    padding:
                        const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                    padding:
                        const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                style: _t(6.5,
                                    bold: true, color: _goldLight, spacing: 0.4)),
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
