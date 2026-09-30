import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/gs_button.dart';
import '../../core/widgets/gs_card.dart';
import '../../providers/data_hub.dart';

/// Reports & analytics — monthly summary, area filter, bar charts, WhatsApp share.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedArea = 'all';
  String _selectedMonth = _currentMonth;

  static String get _currentMonth =>
      DateFormat('yyyy-MM').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final hub = context.watch<DataHub>();
    final stats = _computeStats(hub, _selectedArea, _selectedMonth);

    return Scaffold(
      backgroundColor: GSColors.whiteBg,
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: GSColors.white),
            onPressed: () => _shareReport(stats),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Filters ───────────────────────────────────────────
            _buildFilters(),
            const SizedBox(height: 16),

            // ── Summary cards ─────────────────────────────────────
            _buildSummaryCards(stats),
            const SizedBox(height: 16),

            // ── Bar chart ─────────────────────────────────────────
            _buildBarChart(stats),
            const SizedBox(height: 16),

            // ── Pipeline breakdown ────────────────────────────────
            _buildPipelineTable(hub),
            const SizedBox(height: 16),

            // ── Share button ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: GsButton(
                text: 'Share Summary on WhatsApp',
                onPressed: () => _shareReport(stats),
                icon: Icons.chat_bubble_outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Area',
            style: GSTextStyles.bodyMediumSemiBold
                .copyWith(color: GSColors.navy900)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedArea,
          items: [
            const DropdownMenuItem(value: 'all', child: Text('All Areas')),
            ...GSArea.all.map(
                (a) => DropdownMenuItem(value: a, child: Text(a))),
          ],
          onChanged: (v) => setState(() => _selectedArea = v ?? 'all'),
        ),
        const SizedBox(height: 12),
        Text('Month',
            style: GSTextStyles.bodyMediumSemiBold
                .copyWith(color: GSColors.navy900)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedMonth,
          items: _buildMonthOptions(),
          onChanged: (v) =>
              setState(() => _selectedMonth = v ?? _currentMonth),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _buildMonthOptions() {
    final items = <DropdownMenuItem<String>>[];
    final now = DateTime.now();
    for (var i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      items.add(DropdownMenuItem(
        value: DateFormat('yyyy-MM').format(date),
        child: Text(DateFormat('MMM yyyy').format(date)),
      ));
    }
    return items;
  }

  Widget _buildSummaryCards(_ReportStats stats) {
    final cards = [
      ('New Leads', '${stats.newLeads}', GSColors.statusNew, Icons.person_add),
      ('Conversions', '${stats.conversions}', GSColors.green600, Icons.ios_share),
      ('Bookings', '${stats.bookings}', GSColors.statusBooked, Icons.book),
      ('Installed', '${stats.installed}', GSColors.statusInstalled, Icons.bar_chart),
      ('Revenue', '₹${stats.revenue.formatWithComma()}', GSColors.gold500, Icons.payments),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = (constraints.maxWidth > 400) ? 3 : 2;
        final spacing = 8.0;
        final cardWidth =
            (constraints.maxWidth - (spacing * (crossCount - 1))) / crossCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((c) {
            final (label, value, color, icon) = c;
            return SizedBox(
              width: cardWidth,
              child: GsCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(height: 4),
                    Text(value,
                        style: GSTextStyles.headlineSmall
                            .copyWith(color: GSColors.navy900)),
                    Text(label,
                        style: GSTextStyles.bodySmall
                            .copyWith(color: GSColors.ink.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBarChart(_ReportStats stats) {
    final data = [
      ('New Leads', stats.newLeads, GSColors.statusNew),
      ('Conversions', stats.conversions, GSColors.green600),
      ('Bookings', stats.bookings, GSColors.statusBooked),
      ('Installed', stats.installed, GSColors.statusInstalled),
    ];

    return GsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'Monthly Overview — ${DateFormat('MMM yyyy').format(DateTime.parse('$_selectedMonth-01'))}',
              style: GSTextStyles.headlineSmall
                  .copyWith(color: GSColors.navy900)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _ChartCanvas(data: data),
              size: const Size(double.infinity, 180),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: data.map((d) {
              final (label, value, color) = d;
              return _LegendDot(color, '$label: $value');
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineTable(DataHub hub) {
    final pipeline = hub.pipelineEntries;
    final total = pipeline.fold<int>(0, (s, e) => s + e.value);

    return GsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Pipeline',
              style: GSTextStyles.headlineSmall
                  .copyWith(color: GSColors.navy900)),
          const SizedBox(height: 12),
          ...pipeline.map((e) {
            final pct = total > 0 ? (e.value / total * 100).toInt() : 0;
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(e.key,
                          style: GSTextStyles.bodyMedium
                              .copyWith(color: GSColors.navy900))),
                    Text('${e.value} ($pct%)',
                        style: GSTextStyles.bodyMediumSemiBold
                            .copyWith(color: GSColors.navy900)),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: total > 0 ? e.value / total : 0.0,
                  backgroundColor: GSColors.ink.withValues(alpha: 0.1),
                  color: GSColors.gold500,
                ),
                const SizedBox(height: 10),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _shareReport(_ReportStats stats) {
    final month =
        DateFormat('MMMM yyyy').format(DateTime.parse('$_selectedMonth-01'));
    final text = Uri.encodeComponent(
      '📊 Global Solar 2.0 — Report ($month)\n'
      '─────────────────\n'
      'New Leads: ${stats.newLeads}\n'
      'Conversions: ${stats.conversions}\n'
      'Bookings: ${stats.bookings}\n'
      'Installed: ${stats.installed}\n'
      '─────────────────\n'
      'Report generated from the Global Solar 2.0 client app.',
    );
    launchUrl(
        Uri.parse('https://wa.me/${GSUsers.whatsappNumber}?text=$text'));
  }
}

/// Computes report statistics for the selected area + month.
_ReportStats _computeStats(DataHub hub, String area, String month) {
  final clients = area == 'all'
      ? hub.clients
      : hub.clients
          .where((c) => c.area == area || c.displayArea == area)
          .toList();

  final inMonth = clients
      .where((c) => c.createdAt.toIso8601String().startsWith(month));

  final newLeads =
      inMonth.where((c) => c.status == 'new' || c.status == 'contacted').length;
  final bookings = inMonth.where((c) => c.status == 'booked').length;
  final installed = inMonth
      .where((c) => c.status == 'installed' || c.status == 'subsidized')
      .length;
  final conversions = bookings + installed;

  var revenue = 0;
  for (final c in inMonth) {
    final p = hub.getPaymentForClient(c.id);
    if (p != null && p.registrationPaid) {
      revenue += p.registrationAmount;
    }
  }

  return _ReportStats(
    totalClients: clients.length,
    newLeads: newLeads,
    conversions: conversions,
    bookings: bookings,
    installed: installed,
    revenue: revenue,
  );
}

class _ReportStats {
  final int totalClients;
  final int newLeads;
  final int conversions;
  final int bookings;
  final int installed;
  final int revenue;

  _ReportStats({
    required this.totalClients,
    required this.newLeads,
    required this.conversions,
    required this.bookings,
    required this.installed,
    required this.revenue,
  });
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: GSTextStyles.bodySmall
                .copyWith(color: GSColors.ink.withValues(alpha: 0.7))),
      ],
    );
  }
}

/// Custom bar chart painter.
class _ChartCanvas extends CustomPainter {
  final List<(String, int, Color)> data;

  _ChartCanvas({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal =
        data.map((d) => d.$2).fold<int>(0, (a, b) => a > b ? a : b);
    final maxValD = maxVal > 0 ? maxVal.toDouble() : 1.0;
    final barWidth = size.width / (data.length * 2);
    final chartHeight = size.height - 24;

    // Axis
    final axisPaint =
        Paint()..color = GSColors.ink.withValues(alpha: 0.2);
    canvas.drawLine(
        Offset(0, size.height - 12),
        Offset(size.width, size.height - 12),
        axisPaint);

    for (var i = 0; i < data.length; i++) {
      final (label, value, color) = data[i];
      final barHeight = (value / maxValD) * chartHeight;
      final x = size.width * 0.15 + (size.width * 0.7 / data.length) * i;

      final paint = Paint()..color = color;

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, size.height - 12 - barHeight, barWidth, barHeight),
          topLeft: Radius.circular(barWidth / 2),
          topRight: Radius.circular(barWidth / 2),
        ),
        paint,
      );

      if (value > 0) {
        _drawText(canvas, '$value', x + barWidth / 2 - 8,
            size.height - 16 - barHeight,
            color: GSColors.navy900, size: 11.0);
      }
    }
  }

  void _drawText(Canvas canvas, String text, double x, double y,
      {required Color color, required double size}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color,
              fontSize: size,
              fontWeight: FontWeight.w600)),
      textAlign: TextAlign.center,
    );
    tp.layout();
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant _ChartCanvas old) => old.data != data;
}
