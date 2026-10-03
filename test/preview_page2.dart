import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:vector_graphics/vector_graphics_compiler.dart';

void main() async {
  final doc = pw.Document();

  // Sample data
  const panelCount = 9;
  const companyName = 'Ecliptic Solar';
  const companyTagline = 'Clean Energy, Bright Future';
  const brandColor = PdfColor.fromHex('#2D1B5E');
  const gold = PdfColor(0.93, 0.11, 0.14);
  const navy = PdfColor(0.08, 0.08, 0.25);
  const green = PdfColor(0.50, 0.70, 0.40);
  const brown = PdfColor(0.55, 0.35, 0.20);
  const tileGray = PdfColor(0.75, 0.75, 0.78);
  const parapetBrown = PdfColor(0.45, 0.28, 0.15);
  const panelDark = PdfColor(0.10, 0.15, 0.40);
  const panelStroke = PdfColor.fromHex('#6A89CC');
  const workerBlue = PdfColor(0.15, 0.35, 0.85);
  const darkNavy = PdfColor.fromHex('#2D1B5E');

  // Helper functions (mirrors the real code)
  pw.TextStyle _t(double s, {bool bold = false, PdfColor? color}) {
    return pw.TextStyle(
      fontSize: s,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color ?? PdfColors.black,
      font: bold ? pw.Font.helveticaBold() : pw.Font.helvetica(),
    );
  }

  pw.Widget _panelCell(double w, double h) {
    return pw.Container(
      width: w,
      height: h,
      decoration: pw.BoxDecoration(
        color: panelDark,
        border: pw.Border.all(color: panelStroke, width: 0.5),
      ),
      alignment: pw.Alignment.center,
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Container(height: 0.5, width: double.infinity, color: panelStroke),
          pw.Container(height: 0.5, width: double.infinity, color: panelStroke),
          pw.Container(height: 0.5, width: double.infinity, color: panelStroke),
        ],
      ),
    );
  }

  pw.Widget _waterTank(PdfColor tankColor) {
    return pw.Container(
      width: 34,
      height: 20,
      decoration: pw.BoxDecoration(
        color: tankColor,
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.SizedBox(height: 3),
          pw.Container(width: double.infinity, height: 1.5, color: PdfColors.black.withOpacity(0.2)),
          pw.SizedBox(height: 10),
          pw.Container(width: double.infinity, height: 1.5, color: PdfColors.black.withOpacity(0.2)),
          pw.SizedBox(height: 10),
          pw.Container(width: double.infinity, height: 1.5, color: PdfColors.black.withOpacity(0.2)),
          pw.SizedBox(height: 2),
        ],
      ),
    );
  }

  pw.Widget _meterWheel(PdfColor color) {
    return pw.Container(
      width: 16,
      height: 16,
      decoration: pw.BoxDecoration(
        color: color,
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: PdfColors.white, width: 1.5),
      ),
      child: pw.CustomPaint(
        painter: _SpokePainter(),
      ),
    );
  }

  pw.Widget _tree() {
    return pw.Container(
      width: 80,
      height: 100,
      child: pw.Stack(
        children: [
          // Trunk
          pw.Positioned(
            left: 32,
            top: 50,
            child: pw.Container(width: 12, height: 45, color: brown),
          ),
          // Canopy (non-positioned circle to avoid NaN)
          pw.Container(
            width: 80,
            height: 55,
            decoration: pw.BoxDecoration(
              color: PdfColor(0.20, 0.55, 0.20),
              shape: pw.BoxShape.circle,
            ),
          ),
          // Inner canopy highlight
          pw.Positioned(
            left: 10,
            top: 5,
            child: pw.Container(
              width: 50,
              height: 35,
              decoration: pw.BoxDecoration(
                color: PdfColor(0.30, 0.65, 0.25),
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _compassRose(PdfColor bg, PdfColor accent) {
    return pw.Container(
      width: 32,
      height: 32,
      decoration: pw.BoxDecoration(
        color: bg,
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: accent, width: 1),
      ),
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          // N-S line
          pw.Positioned(
            top: 2,
            child: pw.Container(width: 0.5, height: 12, color: accent),
          ),
          pw.Positioned(
            bottom: 2,
            child: pw.Container(width: 0.5, height: 12, color: accent),
          ),
          // E-W line
          pw.Positioned(
            left: 2,
            child: pw.Container(width: 12, height: 0.5, color: accent),
          ),
          pw.Positioned(
            right: 2,
            child: pw.Container(width: 12, height: 0.5, color: accent),
          ),
          // N text
          pw.Positioned(
            top: 0,
            child: pw.Text('N', style: _t(5, bold: true, color: accent)),
          ),
          pw.Positioned(
            bottom: 0,
            child: pw.Text('S', style: _t(5, bold: true, color: accent)),
          ),
          pw.Positioned(
            left: 0,
            child: pw.Text('W', style: _t(5, bold: true, color: accent)),
          ),
          pw.Positioned(
            right: 0,
            child: pw.Text('E', style: _t(5, bold: true, color: accent)),
          ),
        ],
      ),
    );
  }

  pw.Widget _workerIcon(PdfColor uniform) {
    return pw.Container(
      width: 14,
      height: 20,
      child: pw.Column(
        children: [
          // Helmet
          pw.Container(width: 10, height: 6, color: PdfColors.white),
          // Head
          pw.Container(width: 9, height: 8, decoration: pw.BoxDecoration(color: uniform, shape: pw.BoxShape.circle)),
          // Body
          pw.Container(width: 12, height: 6, color: uniform),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PAGE 2
  // ═══════════════════════════════════════════════════════════════
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 50, 40, 0),
      build: (pw.Context ctx) => pw.Stack(
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.SizedBox(height: 70),
              // Title
              pw.Text('Solar Plants Designs You Have Previously',
                  style: _t(20, bold: true, color: PdfColors.black),
                  textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 6),
              // Subtitle
              pw.Text('Solar Plant Photos',
                  style: _t(12, color: PdfColors.grey500),
                  textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 8),
              pw.Divider(height: 1, thickness: 1, color: gold),
              pw.SizedBox(height: 24),
              // ── Rooftop Diagram ──
              _rooftopDiagram(panelCount, green, brown, tileGray, parapetBrown,
                  panelDark, panelStroke, navy, darkNavy, gold, workerBlue),
              // ── Isometric Thumbnails ──
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _isometricThumb(
                      'Installed', panelCount, green, brown, tileGray,
                      parapetBrown, panelDark, panelStroke, navy, darkNavy,
                      gold, workerBlue, PdfColors.grey400),
                  ),
                  pw.Container(width: 2, color: PdfColors.white),
                  pw.Expanded(
                    child: _isometricThumb(
                      'Structure Only', panelCount, green, brown, tileGray,
                      parapetBrown, panelDark, panelStroke, navy, darkNavy,
                      gold, workerBlue, PdfColors.grey400),
                  ),
                ],
              ),
              pw.Spacer(),
              // ── Footer ──
              _footer(2, companyName, brandColor, gold),
            ],
          ),
          // ── Logo badge ──
          pw.Positioned(
            top: 20,
            right: 20,
            child: _page2Logo(companyName, companyTagline, gold),
          ),
        ],
      ),
    ),
  );

  final bytes = await doc.save();
  final file = File('C:/Users/bhatt/Videos/Global_solar_20/proposal_page2_preview.pdf');
  await file.writeAsBytes(bytes);
  print('PDF saved: ${bytes.length} bytes');
}

pw.Widget _page2Logo(String companyName, String tagline, PdfColor gold) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.end,
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(
        width: 55,
        height: 55,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          gradient: pw.LinearGradient(
            colors: [gold, PdfColor(0.93, 0.11, 0.14)],
            begin: pw.Alignment.topLeft,
            end: pw.Alignment.bottomRight,
          ),
        ),
        child: pw.Center(
          child: pw.Text('ES', style: _t(20, bold: true, color: PdfColors.white)),
        ),
      ),
      pw.SizedBox(width: 8),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(companyName, style: _t(13, bold: true, color: gold)),
          pw.Text(tagline, style: _t(7, color: PdfColors.grey500)),
        ],
      ),
    ],
  );
}

pw.Widget _rooftopDiagram(
  int panelCount,
  PdfColor green,
  PdfColor brown,
  PdfColor tileGray,
  PdfColor parapetBrown,
  PdfColor panelDark,
  PdfColor panelStroke,
  PdfColor navy,
  PdfColor darkNavy,
  PdfColor gold,
  PdfColor workerBlue,
) {
  final cols = (panelCount * 1.4).sqrt().round();
  final rows = (panelCount / cols).ceil();
  final panelW = 18.0;
  final panelH = 14.0;
  final rowGap = 3.0;
  final panelBlockW = cols * panelW;
  final panelBlockH = rows * panelH + (rows - 1) * rowGap;

  return pw.Container(
    width: double.infinity,
    height: 280,
    color: green,
    child: pw.Stack(
      children: [
        // Tree (top-left)
        pw.Positioned(top: 8, left: 8, child: _tree()),
        // Main roof trace
        pw.Positioned(
          top: 60,
          left: 40,
          right: 20,
          bottom: 80,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              color: tileGray,
              border: pw.Border.all(color: parapetBrown, width: 4),
            ),
            child: pw.Stack(
              children: [
                // Water tank (top-left zone)
                pw.Positioned(
                  top: 4,
                  left: 4,
                  child: _waterTank(PdfColors.white),
                ),
                // Bushes below tank
                pw.Positioned(top: 26, left: 2, child: _bush()),
                pw.Positioned(top: 34, left: 14, child: _bush()),
                // Vent pipe (left wall)
                pw.Positioned(
                  top: 4,
                  left: -5,
                  child: pw.Container(width: 4, height: 16, color: PdfColors.grey600),
                ),
                // Solar panel array (right side, flush to edge)
                pw.Positioned(
                  top: 8,
                  right: 4,
                  child: pw.Container(
                    width: panelBlockW,
                    height: panelBlockH,
                    decoration: pw.BoxDecoration(
                      color: panelDark,
                      border: pw.Border.all(color: panelStroke, width: 0.5),
                    ),
                    child: pw.Column(
                      children: List.generate(rows, (r) {
                        final colsInRow = (r < rows - 1) ? cols : (panelCount - r * cols).clamp(1, cols);
                        return pw.Row(
                          children: List.generate(cols, (c) {
                            if (c < colsInRow) {
                              return pw.Container(
                                width: panelW,
                                height: panelH,
                                decoration: pw.BoxDecoration(
                                  color: panelDark,
                                  border: pw.Border.all(color: panelStroke, width: 0.5),
                                ),
                                child: pw.Column(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Container(height: 0.5, width: double.infinity, color: panelStroke),
                                    pw.Container(height: 0.5, width: double.infinity, color: panelStroke),
                                    pw.Container(height: 0.5, width: double.infinity, color: panelStroke),
                                  ],
                                ),
                              );
                            }
                            return pw.Container(width: panelW, height: panelH);
                          }),
                        );
                      }),
                    ),
                  ),
                ),
                // White panel count overlay
                pw.Positioned(
                  right: 4,
                  bottom: 4,
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(2),
                    child: pw.Text('$panelCount',
                        style: _t(16, bold: true, color: PdfColors.white)),
                  ),
                ),
                // Compass rose (center-bottom)
                pw.Positioned(
                  bottom: 4,
                  left: (panelBlockW + 40) / 2 - 16,
                  child: _compassRose(darkNavy, gold),
                ),
                // Worker icon (near panels)
                pw.Positioned(
                  bottom: 30,
                  left: panelBlockW + 50,
                  child: _workerIcon(workerBlue),
                ),
              ],
            ),
          ),
        ),
        // Lower extension/terrace
        pw.Positioned(
          bottom: 8,
          left: 80,
          right: 60,
          child: pw.Container(
            height: 28,
            decoration: pw.BoxDecoration(
              color: tileGray,
              border: pw.Border.all(color: parapetBrown, width: 2),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (i) => _meterWheel(PdfColors.white)),
            ),
          ),
        ),
        // Meter wheels on main roof edge (bottom-right)
        pw.Positioned(
          bottom: 36,
          right: 4,
          child: pw.Row(
            children: [_meterWheel(PdfColors.white), pw.SizedBox(width: 6), _meterWheel(PdfColors.white)],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _bush() {
  return pw.Container(
    width: 10,
    height: 8,
    decoration: pw.BoxDecoration(
      color: PdfColor(0.20, 0.55, 0.20),
      shape: pw.BoxShape.circle,
    ),
  );
}

pw.Widget _isometricThumb(
  String caption,
  int panelCount,
  PdfColor green,
  PdfColor brown,
  PdfColor tileGray,
  PdfColor parapetBrown,
  PdfColor panelDark,
  PdfColor panelStroke,
  PdfColor navy,
  PdfColor darkNavy,
  PdfColor gold,
  PdfColor workerBlue,
  PdfColor grey400,
) {
  final cols = (panelCount * 1.4).sqrt().round();
  final rows = (panelCount / cols).ceil();
  final panelW = 14.0;
  final panelH = 10.0;

  return pw.Container(
    height: 120,
    decoration: pw.BoxDecoration(
      borderRadius: pw.BorderRadius.circular(12),
      border: pw.Border.all(color: gold, width: 1),
    ),
    child: pw.Stack(
      children: [
        // Background (green grass with house silhouette)
        pw.Positioned.fill(
          child: pw.Container(color: green),
        ),
        // House walls (gray concrete below roof line)
        pw.Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          height: 50,
          child: pw.Container(color: PdfColors.grey400),
        ),
        // Roof line (isometric angle suggestion)
        pw.Positioned(
          top: 10,
          left: 10,
          right: 10,
          height: 30,
          child: pw.Container(color: tileGray),
        ),
        // Water tanks (left wall)
        pw.Positioned(
          left: 22,
          bottom: 22,
          child: pw.Column(
            children: List.generate(3, (_) => pw.Container(width: 8, height: 12, margin: pw.EdgeInsets.only(bottom: 2), color: PdfColors.white)),
          ),
        ),
        // AC unit
        pw.Positioned(
          left: 22,
          bottom: 60,
          child: pw.Container(width: 12, height: 8, color: PdfColors.grey600),
        ),
        // Bush
        pw.Positioned(
          left: 40,
          bottom: 22,
          child: _bush(),
        ),
        // Panels (center-right, tilted frame suggestion)
        pw.Positioned(
          top: 14,
          right: 20,
          child: pw.Container(
            width: cols * panelW + 4,
            height: rows * panelH + (rows - 1) * 2 + 4,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey300,
              border: pw.Border.all(color: PdfColors.grey600, width: 1),
            ),
            child: pw.Positioned(
              top: 2,
              left: 2,
              child: pw.Container(
                width: cols * panelW,
                height: rows * panelH + (rows - 1) * 2,
                child: pw.Column(
                  children: List.generate(rows, (r) {
                    final colsInRow = (r < rows - 1) ? cols : (panelCount - r * cols).clamp(1, cols);
                    return pw.Row(
                      children: List.generate(cols, (c) {
                        if (c < colsInRow) {
                          return pw.Container(
                            width: panelW,
                            height: panelH,
                            decoration: pw.BoxDecoration(
                              color: panelDark,
                              border: pw.Border.all(color: panelStroke, width: 0.5),
                            ),
                          );
                        }
                        return pw.Container(width: panelW, height: panelH);
                      }),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
        // White panel count
        pw.Positioned(
          right: 6,
          bottom: 6,
          child: pw.Container(
            padding: pw.EdgeInsets.all(2),
            child: pw.Text('$panelCount', style: _t(14, bold: true, color: PdfColors.white)),
          ),
        ),
        // Compass rose (top-left)
        pw.Positioned(
          top: 6,
          left: 6,
          child: _compassRose(darkNavy, gold),
        ),
        // Worker icon (bottom-left)
        pw.Positioned(
          bottom: 6,
          left: 6,
          child: _workerIcon(workerBlue),
        ),
        // Caption label bar (top)
        pw.Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: pw.Container(
            padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
            decoration: pw.BoxDecoration(
              color: navy,
            ),
            child: pw.Text(
              caption,
              style: _t(7, bold: true, color: PdfColors.white),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _footer(int pageNumber, String companyName, PdfColor brandColor, PdfColor gold) {
  return pw.Container(
    height: 40,
    color: brandColor,
    padding: pw.EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Left — company name
        pw.Text(companyName, style: _t(9, bold: true, color: PdfColors.white)),
        // Center — page number
        pw.Text('2/7', style: _t(8, color: PdfColors.white)),
        // Right — social icons (colored circles)
        pw.Row(
          children: List.generate(6, (i) {
            final colors = [
              PdfColor(0.24, 0.44, 0.73), // Facebook blue
              PdfColor(0.85, 0.34, 0.11), // Instagram orange
              PdfColor(0.00, 0.52, 0.81), // LinkedIn blue
              PdfColors.black,             // Twitter/X
              PdfColor(0.15, 0.70, 0.30), // Phone green
              PdfColor(0.20, 0.70, 0.40), // WhatsApp green
            ];
            return pw.Container(
              width: 20,
              height: 20,
              margin: pw.EdgeInsets.only(left: i == 0 ? 0 : 4),
              decoration: pw.BoxDecoration(
                color: colors[i],
                shape: pw.BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    ),
  );
}

// Spoke painter for meter wheel
class _SpokePainter extends pw.CustomPainter {
  @override
  void paint(pw.Canvas canvas, pw.Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;
    final paint = pw.Paint()
      ..color = PdfColors.grey600
      ..strokeWidth = 0.5
      ..style = pw.PaintingStyle.stroke;
    for (var i = 0; i < 6; i++) {
      final angle = i * 60 * 3.14159 / 180;
      canvas.drawLine(
        pw.Offset(cx, cy),
        pw.Offset(cx + r * pw.cos(angle), cy + r * pw.sin(angle)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant pw.CustomPainter oldDelegate) => false;
}
