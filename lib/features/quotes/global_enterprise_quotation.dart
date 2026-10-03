import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../models/quotation_model.dart';

// ── Brand colours ─────────────────────────────────────────────────────────
class _BrandColors {
  static const adani = Color(0xFF0A1E4A);
  static const polycab = Color(0xFFFF6B00);
  static const havells = Color(0xFF009E49);
  static const yellowCream = Color(0xFFFFF3D0);
  static const navyBorder = Color(0xFF1A2A6C);
}

// ── Solar-logo custom painter ───────────────────────────────────────────────
/// Draws a circular badge: sun rays (orange) at top, solar cells (blue grid)
/// at bottom, and a small green leaf on the right edge.
class SolarLogoPainter extends CustomPainter {
  final double sunRadius;
  final double panelSize;
  final double leafSize;

  SolarLogoPainter({
    this.sunRadius = 10,
    this.panelSize = 22,
    this.leafSize = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()..isAntiAlias = true;

    // Sun — yellow circle at top
    paint.color = const Color(0xFFFFD86B);
    canvas.drawCircle(Offset(cx, cy - 8), sunRadius, paint);

    // Sun rays
    paint.color = const Color(0xFFFFB400);
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    for (var i = 0; i < 8; i++) {
      canvas.save();
      canvas.translate(cx, cy - 8);
      canvas.rotate((i * 45) * (3.14159265 / 180));
      canvas.drawLine(
        Offset(0, -(sunRadius + 2)),
        Offset(0, -(sunRadius + 8)),
        paint,
      );
      canvas.restore();
    }

    // Solar panel — blue grid below sun
    final panelTop = cy + 2;
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF0B1F5C);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx - panelSize / 2,
          panelTop,
          panelSize,
          panelSize,
        ),
        const Radius.circular(2),
      ),
      paint,
    );

    // Solar cells — white grid lines
    paint.color = const Color(0x80FFFFFF);
    paint.strokeWidth = 1;
    paint.style = PaintingStyle.stroke;
    final cells = 4;
    final cellW = panelSize / cells;
    for (var i = 1; i < cells; i++) {
      canvas.drawLine(
        Offset(cx - panelSize / 2 + cellW * i, panelTop),
        Offset(cx - panelSize / 2 + cellW * i, panelTop + panelSize),
        paint,
      );
      canvas.drawLine(
        Offset(cx - panelSize / 2, panelTop + cellW * i),
        Offset(cx - panelSize / 2 + panelSize, panelTop + cellW * i),
        paint,
      );
    }

    // Green leaf — small, on right edge
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF1E8E3E);
    final path = Path();
    path.moveTo(cx + 12, cy - 2);
    path.quadraticBezierTo(
      cx + 16, cy - 6,
      cx + 18, cy - 2,
    );
    path.quadraticBezierTo(
      cx + 16, cy + 2,
      cx + 12, cy + 1,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SolarLogoPainter old) =>
      old.sunRadius != sunRadius ||
      old.panelSize != panelSize ||
      old.leafSize != leafSize;
}

// ── Brand badge ─────────────────────────────────────────────────────────────
/// Small coloured rectangle with the brand name — used in lieu of logo images
/// since the project doesn't bundle brand assets or flutter_svg.
class BrandBadge extends StatelessWidget {
  final String brand;
  final double height;
  final double fontSize;
  final double padding;

  const BrandBadge(
    this.brand, {
    super.key,
    this.height = 24,
    this.fontSize = 12,
    this.padding = 8,
  });

  Color get _bgColor {
    final b = brand.toUpperCase();
    if (b.contains('ADANI')) return _BrandColors.adani;
    if (b.contains('POLYCAB')) return _BrandColors.polycab;
    if (b.contains('HAVELLS')) return _BrandColors.havells;
    if (b.contains('STANDARD')) return const Color(0xFF666666);
    return GSColors.navy700;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          brand,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ── Main quotation widget ───────────────────────────────────────────────────
/// Renders the "GLOBAL ENTERPRISE" solar quotation in the exact layout of the
/// printed template.  All data is supplied via [data], making the widget fully
/// dynamic.
class GlobalEnterpriseQuotation extends StatelessWidget {
  final QuotationData data;

  const GlobalEnterpriseQuotation({super.key, required this.data});

  static GlobalEnterpriseQuotation withDefaultData({Key? key}) =>
      GlobalEnterpriseQuotation(
        key: key,
        data: QuotationData(
          date: DateTime.now(),
          consumerName: 'RAJDEPSINH',
          contactNumber: '9824963973',
          address: 'KATHAVA',
        ),
      );

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Container(
        width: 720,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: GSColors.blue500.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(data: data),
              const SizedBox(height: 16),
              _Title(),
              const SizedBox(height: 16),
              _CustomerInfoTable(data: data),
              _SolarInfoTable(data: data),
              _StructureNote(data: data),
              _PipeAndAccount(data: data),
              _NotesAndPricing(data: data),
              _Footer(data: data),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Header
// ════════════════════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final QuotationData data;

  const _Header({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black12, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Logo ──
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GSColors.gold300,
                  border: Border.all(
                    color: GSColors.navy700,
                    width: 3,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CustomPaint(
                    painter: SolarLogoPainter(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // ── Company name + address ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      data.companyName,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: _BrandColors.navyBorder,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      data.companyTagline,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.officeAddress,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      data.mobileNumbers,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Title
// ════════════════════════════════════════════════════════════════════════════
class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'QUOTATION:',
        style: GoogleFonts.playfairDisplay(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: _BrandColors.navyBorder,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Customer info table
// ════════════════════════════════════════════════════════════════════════════
class _CustomerInfoTable extends StatelessWidget {
  final QuotationData data;

  const _CustomerInfoTable({required this.data});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${data.date.day.toString().padLeft(2, '0')}-${data.date.month.toString().padLeft(2, '0')}-${data.date.year}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: _BrandColors.yellowCream,
        border: Border(
          bottom: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(2),
        },
        children: [
          _customerRow('Date :', dateStr),
          _customerRow(
            'Consumer Name :',
            data.consumerName,
            valueColor: GSColors.gold500,
            valueWeight: FontWeight.w800,
          ),
          _customerRow('Contact no :', data.contactNumber),
          _customerRow('Address :', data.address),
        ],
      ),
    );
  }

  TableRow _customerRow(
    String label,
    String value, {
    Color? valueColor,
    FontWeight? valueWeight,
  }) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black, width: 0.5),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: valueWeight ?? FontWeight.w700,
              color: valueColor ?? Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ON GRID SOLAR INFO — section header + 3-col table
// ════════════════════════════════════════════════════════════════════════════
class _SolarInfoTable extends StatelessWidget {
  final QuotationData data;

  const _SolarInfoTable({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Section header ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _BrandColors.yellowCream,
            ),
            child: Text(
              'ON GRID SOLAR INFO :',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _BrandColors.navyBorder,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // ── Specs table ──
          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            border: TableBorder.all(color: Colors.black, width: 0.5),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(3),
              2: FlexColumnWidth(2),
            },
            children: _buildRows(),
          ),
        ],
      ),
    );
  }

  List<TableRow> _buildRows() {
    return [
      // DC KW — has the panel-count box in col 2
      _specRow(
        'DC KW :',
        value: data.systemCapacity,
        extraWidget: _panelCountBox(data.solarPanelQuantity),
      ),
      // Solar Panel Manufacturer
      _specRow(
        'SOLAR PANEL COMPANY\nMANUFACTURER :',
        widget: BrandBadge(data.solarPanelBrand),
      ),
      _specRow('Wattpeak :', value: data.solarPanelWattpeak),
      // Inverter
      _specRow(
        'Available Inverter\nCOMPANY MANUFACTURER :',
        widget: BrandBadge(data.inverterBrand),
      ),
      _specRow(
        'Inverter - AC KW :',
        value: data.inverterKw,
        subLabel: 'COMPANY : GLOBAL ENTERPRISE',
      ),
      // Cables
      _specRow(
        'DC Cable :',
        rowChildren: [
          BrandBadge(data.dcCableBrand),
          const SizedBox(width: 4),
          Text('${data.dcCableSpecs},',
              style: _valueStyle),
        ],
        extra: data.dcCableLengthFt,
      ),
      _specRow(
        'AC Wire :',
        rowChildren: [
          BrandBadge(data.acWireBrand),
          const SizedBox(width: 4),
          Text('${data.acWireSpecs},', style: _valueStyle),
        ],
        extra: data.acWireLengthFt,
      ),
      _specRow(
        'Earthing Wire :',
        rowChildren: [
          BrandBadge(data.earthingWireBrand),
          const SizedBox(width: 4),
          Text('${data.earthingWireSpecs},', style: _valueStyle),
        ],
        extra: data.earthingWireLengthFt,
      ),
      _specRow(
        'LA (ALU.) Cable :',
        rowChildren: [Text(data.laCableSpecs, style: _valueStyle)],
        extra: data.laCableLengthFt,
      ),
      _specRow(
        'DC Side MCB :',
        widget: BrandBadge(data.dcSideMcb),
      ),
      _specRow(
        'AC Side MCB :',
        widget: BrandBadge(data.acSideMcb),
      ),
      _specRow(
        '20 MM Conduct\nPVC :',
        value: data.conduitPvc,
      ),
    ];
  }

  static final TextStyle _valueStyle = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );

  TableRow _specRow(
    String label, {
    String? value,
    String? subLabel,
    List<Widget>? rowChildren,
    Widget? widget,
    String? extra,
    Widget? extraWidget,
  }) {
    return TableRow(
      decoration: const BoxDecoration(
        color: _BrandColors.yellowCream,
      ),
      children: [
        // ── Column 1: label ──
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.2,
            ),
          ),
        ),
        // ── Column 2: value ──
        Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (rowChildren != null)
                Row(children: rowChildren)
              else if (widget != null)
                widget
              else if (value != null)
                Text(
                  value,
                  style: _valueStyle,
                ),
              if (subLabel != null)
                Text(
                  subLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
            ],
          ),
        ),
        // ── Column 3: extra / measurements / panel count ──
        Padding(
          padding: const EdgeInsets.all(6),
          child: Center(
            child: extraWidget ??
                (extra != null
                    ? Text(
                        extra,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      )
                    : const SizedBox.shrink()),
          ),
        ),
      ],
    );
  }

  Widget _panelCountBox(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        color: _BrandColors.yellowCream,
      ),
      child: Text(
        'NO. OF\nsolar PANEL\n$count',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _BrandColors.navyBorder,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Structure note
// ════════════════════════════════════════════════════════════════════════════
class _StructureNote extends StatelessWidget {
  final QuotationData data;

  const _StructureNote({required this.data});

  @override
  Widget build(BuildContext context) {
    // Parse "Up to 6.00 ft × 8.00 ft from bottom of terrace"
    // → "UPTO 6.00 FT X 8.00 FT FROM BOTTOM OF TARRACE"
    final note =
        'HEIGHT OF STRUCTURE IS INCLUDING UPTO ${_parseHeights(data.structureHeight)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        note,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _BrandColors.navyBorder,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  String _parseHeights(String input) {
    // "Up to 6.00 ft × 8.00 ft from bottom of terrace"
    // → "6.00 FT X 8.00 FT"
    final match = RegExp(r'([\d.]+)\s*ft\s*[×x]\s*([\d.]+)\s*ft', caseSensitive: false)
        .firstMatch(input);
    if (match != null) {
      return '${match.group(1)} FT X ${match.group(2)} FT';
    }
    return '6.00 FT X 8.00 FT';
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Two-column: pipe specs + account details
// ════════════════════════════════════════════════════════════════════════════
class _PipeAndAccount extends StatelessWidget {
  final QuotationData data;

  const _PipeAndAccount({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: pipe specs ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pipeLine('Pipe for Leg :', data.pipeForLeg),
                _pipeLine('Pipe for Rafter :', data.pipeForRafter),
                _pipeLine('Pipe for Purlin :', data.pipeForPurlin),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // ── Right: account details ──
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMPANY ACCOUNT DETAILS :',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _BrandColors.navyBorder,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.bankName,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Acc. No. : ${data.accountNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'IFSC Code : ${data.ifscCode}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pipeLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Notes + pricing
// ════════════════════════════════════════════════════════════════════════════
class _NotesAndPricing extends StatelessWidget {
  final QuotationData data;

  const _NotesAndPricing({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Disclaimer note ──
          Text(
            'All materials and items mentioned above are standard quality '
            'and will be provided as per the specifications. This quotation '
            'is valid for 15 days from the date of issue.',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF555555),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // ── Pricing ──
          _priceLine(
            'NET PAYABLE SYSTEM AMOUNT (WITH GST) :',
            data.formattedNetPayable,
            isTotal: true,
          ),
          _priceLine(
            'SUBSIDY GIVEN BY GOVERNMENT :',
            data.formattedSubsidy,
            color: GSColors.green600,
            isTotal: true,
          ),
          _priceLine(
            'AFTER SUBSIDY, NET COST TO CONSUMER :',
            data.formattedNetCost,
            color: _BrandColors.navyBorder,
            isTotal: true,
          ),
          const SizedBox(height: 12),
          // ── Cash payable box ──
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.5),
                color: _BrandColors.yellowCream,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Net payable by cheque/cash :',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    data.formattedCashPayable,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _BrandColors.navyBorder,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceLine(
    String label,
    String amount, {
    Color? color,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
              color: Colors.black,
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontSize: isTotal ? 13 : 12,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Footer
// ════════════════════════════════════════════════════════════════════════════
class _Footer extends StatelessWidget {
  final QuotationData data;

  const _Footer({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        // ── Page number ──
        Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            data.pageInfo,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF555555),
            ),
          ),
        ),
        // ── Top border ──
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          height: 1,
          color: Colors.black12,
        ),
        // ── Contact footer ──
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          child: Text(
            '${data.officeAddress}  |  ${data.mobileNumbers}',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF555555),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
