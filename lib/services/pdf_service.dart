import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../core/constants.dart';
import '../models/client.dart';
import '../models/quote.dart';

/// Brand color constants for the PDF — maps to GSColors in the app theme.
abstract class _PdfColors {
  static final PdfColor navy900 = PdfColor.fromHex('#071440');
  static final PdfColor navy700 = PdfColor.fromHex('#0B1F5C');
  static final PdfColor gold500 = PdfColor.fromHex('#F9B417');
  static final PdfColor gold300 = PdfColor.fromHex('#FFD86B');
  static final PdfColor green600 = PdfColor.fromHex('#1E8E3E');
  static final PdfColor blue500 = PdfColor.fromHex('#1E5BD8');
  static final PdfColor sky100 = PdfColor.fromHex('#EAF4FF');
  static final PdfColor ink = PdfColor.fromHex('#0F1B3D');
  static final PdfColor white = PdfColors.white;
}

/// Generates quotation PDFs in the Global Solar 2.0 brand style.
class PdfService {
  /// Loads the Global Solar 2.0 logo from app assets.
  /// Returns null if the asset is not available.
  static Future<Uint8List?> _loadLogo() async {
    try {
      final data = await rootBundle.load('assets/images/logo.jpg');
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// Builds a professional quotation PDF as a [Uint8List] ready for sharing /
  /// saving. Includes the company logo, client details, system specs, a
  /// full cost-breakdown table, included items, and terms.
  static Future<Uint8List> generateQuotation({
    required ClientModel? client,
    required QuoteModel quote,
  }) async {
    final pkg = gsPackageById(quote.packageId) ?? gsPackages.first;
    final numberFmt = NumberFormat.currency(locale: 'en_IN', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMM yyyy');

    final logoBytes = await _loadLogo();

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(32),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          final isRes = quote.isResidential;
          final subsidy = isRes ? GSTax.subsidyMax : 0;
          final afterSubsidyVal = quote.upfront - subsidy;
          final grandTotal = quote.upfront + GSTax.stampCharge;

          final includedItems = <String>[
            'Design & Engineering',
            '${pkg.kw} kW Solar System (${pkg.panels} panels)',
            'Inverters (String / Micro)',
            'DC/AC Combiner Box',
            'MC4 Connectors',
            'Module Mounting Structure (roof/elevated)',
            'AC & DC Cables (Copper, 4 sq.mm / 6 sq.mm)',
            'Net Meter Application Support',
            'MCWC Earth & Lightning Protection',
            if (isRes) 'PM Surya Ghar Subsidy Claim Support (₹78,000)',
          ];

          final termsList = <String>[
            'Final quote is subject to a free site survey.',
            'Price is valid for 7 days from the date of issue.',
            'PM Surya Ghar residential subsidy of ₹78,000 is applicable '
                'only for residential rooftop solar '
                '(₹78,000 per connection, up to 10 kW).',
            'Commercial installations are not eligible for the subsidy.',
            'Prices last updated: ${GSTax.pricesLastUpdated}.',
          ];

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header (navy with logo + brand) ────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 12),
                decoration: pw.BoxDecoration(
                  color: _PdfColors.navy900,
                  borderRadius: pw.BorderRadius.vertical(
                    top: pw.Radius.circular(8),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Logo
                    if (logoBytes != null)
                      pw.Image(
                        pw.MemoryImage(logoBytes),
                        width: 56,
                        height: 56,
                        fit: pw.BoxFit.contain,
                      )
                    else
                      pw.Container(
                        width: 56,
                        height: 56,
                        decoration: pw.BoxDecoration(
                          color: _PdfColors.gold500,
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Center(
                          child: pw.Text('☀',
                              style: pw.TextStyle(
                                  fontSize: 28, color: _PdfColors.navy900)),
                        ),
                      ),

                    pw.SizedBox(width: 16),

                    // Brand text
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Global Solar 2.0',
                            style: pw.TextStyle(
                              color: _PdfColors.white,
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 0.5,
                            )),
                        pw.Text('Rooftop Solar Solutions',
                            style: pw.TextStyle(
                              color: _PdfColors.gold300,
                              fontSize: 10,
                            )),
                      ],
                    ),

                    // Quotation title
                    pw.Text('Quotation',
                        style: pw.TextStyle(
                          color: _PdfColors.gold300,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        )),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // ── Meta info ────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: pw.BoxDecoration(
                  color: _PdfColors.sky100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    _metaItem('Quotation No.', quote.id),
                    _metaItem('Date', dateFmt.format(DateTime.now())),
                    _metaItem('Validity', '15 days'),
                    _metaItem('Type', isRes ? 'Residential' : 'Commercial'),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // ── Bill To ─────────────────────────────────────────────
              pw.Text('Quotation To',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _PdfColors.navy900,
                  )),
              pw.SizedBox(height: 6),
              pw.Text(
                client?.name ?? 'Valued Customer',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: _PdfColors.navy900,
                ),
              ),
              if (client != null) ...[
                pw.SizedBox(height: 4),
                pw.Text('Phone: +91-${client.phone}',
                    style: pw.TextStyle(
                        fontSize: 11, color: _PdfColors.ink)),
                if (client.village != null && client.village!.isNotEmpty)
                  pw.Text('Village: ${client.village!}',
                      style: pw.TextStyle(
                          fontSize: 11, color: _PdfColors.ink)),
                if (client.city != null && client.city!.isNotEmpty)
                  pw.Text('City: ${client.city!}',
                      style: pw.TextStyle(
                          fontSize: 11, color: _PdfColors.ink)),
                pw.Text('Area: ${client.area}',
                    style: pw.TextStyle(
                        fontSize: 11, color: _PdfColors.ink)),
                pw.Text('Property Type: ${client.propertyType}',
                    style: pw.TextStyle(
                        fontSize: 11, color: _PdfColors.ink)),
              ],

              pw.SizedBox(height: 24),

              // ── System details ──────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: _PdfColors.white,
                  border: pw.Border.all(color: _PdfColors.sky100, width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Solar System Details',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: _PdfColors.navy700,
                        )),
                    pw.SizedBox(height: 8),
                    _detailRow('System Size', '${pkg.kw} kW'),
                    _detailRow('Solar Panels', '${pkg.panels} panels'),
                    _detailRow('Package', pkg.tag ?? 'Standard'),
                    _detailRow('Property Type',
                        isRes ? 'Residential' : 'Commercial'),
                    _detailRow('Technology', 'Adani TOPCon'),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // ── Cost breakdown table ────────────────────────────────
              pw.Text('Cost Breakdown',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _PdfColors.navy900,
                  )),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(
                    color: _PdfColors.navy900, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: _PdfColors.navy700),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Text('Description',
                            style: pw.TextStyle(
                                fontSize: 10,
                                color: _PdfColors.white,
                                fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Text('Amount (₹)',
                            style: pw.TextStyle(
                                fontSize: 10,
                                color: _PdfColors.white,
                                fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  // Rows
                  _costRow('Upfront (pre-subsidy)',
                      numberFmt.format(quote.upfront), _PdfColors.navy900),
                  _costRow(
                    'Subsidy (PM Surya Ghar)',
                    isRes
                        ? '-${numberFmt.format(subsidy)}'
                        : 'Not applicable',
                    isRes ? _PdfColors.green600 : _PdfColors.ink,
                  ),
                  _costRow('Structure Cost',
                      numberFmt.format(quote.structureCost), _PdfColors.ink),
                  _costRow('Stamp Charge',
                      numberFmt.format(GSTax.stampCharge), _PdfColors.ink),
                  // After subsidy (emphasized)
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                        color: _PdfColors.sky100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Text('After Subsidy',
                            style: pw.TextStyle(
                                fontSize: 11,
                                color: _PdfColors.navy900,
                                fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Text(
                            '₹${numberFmt.format(afterSubsidyVal)}',
                            style: pw.TextStyle(
                                fontSize: 11,
                                color: _PdfColors.green600,
                                fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  // Grand total (gold accent)
                  pw.TableRow(
                    decoration:
                        pw.BoxDecoration(color: _PdfColors.gold300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Text('TOTAL (incl. stamp charge)',
                            style: pw.TextStyle(
                                fontSize: 13,
                                color: _PdfColors.navy900,
                                fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Text('₹${numberFmt.format(grandTotal)}',
                            style: pw.TextStyle(
                                fontSize: 14,
                                color: _PdfColors.navy900,
                                fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // ── What's included ────────────────────────────────────
              pw.Text('What is Included',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _PdfColors.navy900,
                  )),
              pw.SizedBox(height: 8),
              ...includedItems.map((item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('• ',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: _PdfColors.green600,
                              fontWeight: pw.FontWeight.bold,
                            )),
                        pw.Expanded(
                          child: pw.Text(item,
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: _PdfColors.ink,
                              )),
                        ),
                      ],
                    ),
                  )),

              pw.SizedBox(height: 24),

              // ── Terms & conditions ──────────────────────────────────
              pw.Text('Terms & Conditions',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _PdfColors.navy900,
                  )),
              pw.SizedBox(height: 8),
              ...termsList.map((term) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('• ',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: _PdfColors.blue500,
                              fontWeight: pw.FontWeight.bold,
                            )),
                        pw.Expanded(
                          child: pw.Text(term,
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: _PdfColors.ink,
                                height: 1.4,
                              )),
                        ),
                      ],
                    ),
                  )),

              // ── Footer ─────────────────────────────────────────────
              pw.Container(
                margin: pw.EdgeInsets.only(top: 32),
                padding: pw.EdgeInsets.only(top: 12),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(
                      color: _PdfColors.navy900,
                      width: 1,
                    ),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Prepared by',
                        style: pw.TextStyle(
                            fontSize: 10, color: _PdfColors.ink)),
                    pw.Row(
                      mainAxisAlignment:
                          pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment:
                              pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Global Solar 2.0',
                                style: pw.TextStyle(
                                    fontSize: 13,
                                    fontWeight: pw.FontWeight.bold,
                                    color: _PdfColors.navy900)),
                            pw.Text(
                                'Powered by Adani TOPCon technology',
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    color: _PdfColors.ink)),
                            pw.SizedBox(height: 4),
                            pw.Text(
                                '📞 +91-${GSUsers.founderPhone}  '
                                '📧 ${GSUsers.founderEmail}\n'
                                'Talaja, Bhavnagar, Gujarat, India',
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    color: _PdfColors.ink,
                                    height: 1.4)),
                          ],
                        ),
                        pw.Text(dateFmt.format(DateTime.now()),
                            style: pw.TextStyle(
                                fontSize: 10, color: _PdfColors.ink)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _metaItem(
    String label,
    String value,
  ) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                fontSize: 9,
                color: _PdfColors.navy700,
                fontWeight: pw.FontWeight.bold,
              )),
          pw.Text(value,
              style: pw.TextStyle(
                fontSize: 10,
                color: _PdfColors.ink,
              )),
        ],
      );

  static pw.Widget _detailRow(
    String label,
    String value,
  ) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 100,
              child: pw.Text(label,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: _PdfColors.ink,
                  )),
            ),
            pw.Text(value,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _PdfColors.navy900,
                )),
          ],
        ),
      );

  static pw.TableRow _costRow(
    String label,
    String amount,
    PdfColor color,
  ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Text(label,
              style: pw.TextStyle(
                fontSize: 10,
                color: color,
              )),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Text(amount,
              style: pw.TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.right),
        ),
      ],
    );
  }
}
