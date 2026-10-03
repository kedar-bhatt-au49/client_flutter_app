import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../providers/data_hub.dart';

/// Reports & Analytics — exact design: navy header, filters, revenue banner,
/// key metrics, monthly chart, sales pipeline, fixed bottom bar.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _gold = Color(0xFFF9B417);
  static const _goldLight = Color(0xFFFFCA40);
  static const _goldDark = Color(0xFFD9980B);
  static const _navy = Color(0xFF071440);
  static const _navyDeep = Color(0xFF0B1F5C);
  static const _sky = Color(0xFFEAF4FF);
  static const _slate = Color(0xFF627193);
  static const _green = Color(0xFF059669);
  static const _greenLight = Color(0xFF10B981);
  static const _blue = Color(0xFF3B82F6);
  static const _indigo = Color(0xFF6366F1);
  static const _rose = Color(0xFFF43F5E);
  static const _teal = Color(0xFF0D9488);

  String _selectedArea = 'all';
  String _selectedMonth = _currentMonth;

  static String get _currentMonth =>
      DateFormat('yyyy-MM').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final hub = context.watch<DataHub>();
    final stats = _computeStats(hub, _selectedArea, _selectedMonth);

    return Scaffold(
      backgroundColor: _sky,
      body: Column(
        children: [
          _buildHeader(context, stats),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFilterBar(context),
                  const SizedBox(height: 14),
                  _buildRevenueBanner(stats),
                  const SizedBox(height: 14),
                  _buildKeyMetrics(stats),
                  const SizedBox(height: 14),
                  _buildChart(stats),
                  const SizedBox(height: 14),
                  _buildPipeline(hub),
                  const SizedBox(height: 10),
                  _buildFootnote(),
                ],
              ),
            ),
          ),
          _buildBottomBar(stats),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, _ReportStats stats) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_navy, _navyDeep],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.chevron_left_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Reports & Analytics',
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.4)),
                        SizedBox(width: 6),
                        _PulseDot(),
                      ],
                    ),
                    const Text('Bhavnagar & Talaja Hub',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xCCD0E6FF))),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _shareReport(stats),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_gold, _goldLight],
                    ),
                    boxShadow: [
                      BoxShadow(color: _gold.withValues(alpha: 0.45), blurRadius: 14),
                    ],
                  ),
                  child: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Filter bar ─────────────────────────────────────────────────
  Widget _buildFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0F2FE)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A071440), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _filterPill(
              icon: Icons.location_on_rounded,
              label: _selectedArea == 'all' ? 'All Areas' : _selectedArea,
              onTap: () => _pickArea(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _filterPill(
              icon: Icons.calendar_today_rounded,
              label: DateFormat('MMM yyyy')
                  .format(DateTime.parse('$_selectedMonth-01')),
              onTap: () => _pickMonth(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _sky,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: _navyDeep),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _navy)),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 14, color: _slate),
          ],
        ),
      ),
    );
  }

  void _pickArea(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Select Area',
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _navy)),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('All Areas'),
              trailing: _selectedArea == 'all'
                  ? const Icon(Icons.check_rounded, color: _green)
                  : null,
              onTap: () {
                setState(() => _selectedArea = 'all');
                Navigator.pop(sheetContext);
              },
            ),
            ...GSArea.all.map((a) => ListTile(
                  title: Text(a),
                  trailing: _selectedArea == a
                      ? const Icon(Icons.check_rounded, color: _green)
                      : null,
                  onTap: () {
                    setState(() => _selectedArea = a);
                    Navigator.pop(sheetContext);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _pickMonth(BuildContext context) {
    final now = DateTime.now();
    final months = <String>[];
    for (var i = 0; i < 12; i++) {
      months.add(DateFormat('yyyy-MM').format(DateTime(now.year, now.month - i, 1)));
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Select Month',
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _navy)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: months
                    .map((m) => ListTile(
                          title: Text(DateFormat('MMMM yyyy')
                              .format(DateTime.parse('$m-01'))),
                          trailing: _selectedMonth == m
                              ? const Icon(Icons.check_rounded, color: _green)
                              : null,
                          onTap: () {
                            setState(() => _selectedMonth = m);
                            Navigator.pop(sheetContext);
                          },
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Revenue banner ─────────────────────────────────────────────
  Widget _buildRevenueBanner(_ReportStats stats) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navyDeep, _navy],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x2E071440), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        border:
                            Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: const Center(
                        child: Text('₹',
                            style: TextStyle(
                                color: _gold,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('TOTAL REVENUE',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Color(0xCCD0E6FF))),
                    const Spacer(),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _greenLight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: _greenLight.withValues(alpha: 0.3)),
                      ),
                      child: const Text('↑ +24%',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6EE7B7))),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('₹${stats.revenue.formatWithComma()}',
                    style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _gold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('This month • ${stats.bookings} bookings closed',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _gold)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Talaja & Bhavnagar EPC',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xB3D0E6FF))),
                      Text('Live data',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
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

  // ── Key metrics ────────────────────────────────────────────────
  Widget _buildKeyMetrics(_ReportStats stats) {
    final conversionRate = stats.newLeads > 0
        ? (stats.conversions / stats.newLeads * 100).toStringAsFixed(1)
        : '0.0';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _iconTile(Icons.bar_chart_rounded),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Key Metrics',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _navy)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x99E2E8F0)),
                ),
                child: Text(
                    DateFormat('MMM yyyy')
                        .format(DateTime.parse('$_selectedMonth-01')),
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: _slate)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  icon: Icons.person_add_rounded,
                  value: '${stats.newLeads}',
                  label: 'New Leads',
                  badge: 'Inbound',
                  color: _blue,
                  tint: const Color(0xFFEFF6FF),
                  borderTint: const Color(0xFFDBEAFE),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricTile(
                  icon: Icons.swap_horiz_rounded,
                  value: '${stats.conversions}',
                  label: 'Conversions',
                  badge: '$conversionRate%',
                  color: _green,
                  tint: const Color(0xFFECFDF5),
                  borderTint: const Color(0xFFD1FAE5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  icon: Icons.description_rounded,
                  value: '${stats.bookings}',
                  label: 'Bookings',
                  badge: 'Token',
                  color: _rose,
                  tint: const Color(0xFFFFF1F2),
                  borderTint: const Color(0xFFFECDD3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricTile(
                  icon: Icons.verified_rounded,
                  value: '${stats.installed}',
                  label: 'Installed',
                  badge: 'PGVCL OK',
                  color: _teal,
                  tint: const Color(0xFFF0FDFA),
                  borderTint: const Color(0xFFCCFBF1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required IconData icon,
    required String value,
    required String label,
    required String badge,
    required Color color,
    required Color tint,
    required Color borderTint,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderTint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(badge,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _navy)),
          Text(label,
              style: const TextStyle(fontSize: 12, color: _slate)),
        ],
      ),
    );
  }

  // ── Monthly chart ──────────────────────────────────────────────
  Widget _buildChart(_ReportStats stats) {
    final conversionRate = stats.newLeads > 0
        ? (stats.conversions / stats.newLeads * 100).toStringAsFixed(0)
        : '0';
    final bars = [
      ('Leads', stats.newLeads, _blue),
      ('Convert', stats.conversions, _green),
      ('Booked', stats.bookings, _rose),
      ('Installed', stats.installed, _teal),
    ];
    final maxVal = bars.map((b) => b.$2).fold<int>(0, (a, b) => a > b ? a : b);
    final maxValD = maxVal > 0 ? maxVal.toDouble() : 1.0;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _iconTile(Icons.show_chart_rounded),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Monthly Overview',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _navy)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text('Conversion: $conversionRate%',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: _green)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 176,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars.map((b) {
                final (label, value, color) = b;
                final h = (value / maxValD) * 120;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('$value',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: color)),
                      const SizedBox(height: 4),
                      Container(
                        width: 36,
                        height: h < 4 ? 4 : h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [color, color.withValues(alpha: 0.6)],
                          ),
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(label,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(_blue, 'Leads'),
                SizedBox(width: 14),
                _LegendDot(_green, 'Convert'),
                SizedBox(width: 14),
                _LegendDot(_rose, 'Booked'),
                SizedBox(width: 14),
                _LegendDot(_teal, 'Installed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pipeline ───────────────────────────────────────────────────
  Widget _buildPipeline(DataHub hub) {
    final pipeline = hub.pipelineEntries;
    final total = pipeline.fold<int>(0, (s, e) => s + e.value);
    final totalActive =
        pipeline.where((e) => e.value > 0).fold<int>(0, (s, e) => s + e.value);

    final stageColors = <String, Color>{
      'New Lead': _blue,
      'Contacted': _indigo,
      'Site Visit': _gold,
      'Quoted': const Color(0xFFD97706),
      'Booked': _rose,
      'Installed': _green,
    };

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _iconTile(Icons.filter_alt_rounded),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Sales Pipeline',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _navy)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _sky,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Text('Active Deals ($totalActive)',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: _navyDeep)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...pipeline.map((e) {
            final pct = total > 0 ? (e.value / total) : 0.0;
            final color = stageColors[e.key] ?? _slate;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration:
                            BoxDecoration(shape: BoxShape.circle, color: color),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.key,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B))),
                      ),
                      Text('${e.value}',
                          style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _navy)),
                      const SizedBox(width: 4),
                      Text('(${(pct * 100).toStringAsFixed(1)}%)',
                          style: const TextStyle(fontSize: 11, color: _slate)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFootnote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_rounded, size: 14, color: _green),
        const SizedBox(width: 6),
        Flexible(
          child: Text('Live sync with PGVCL DISCOM & National Portal DBT Queue',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: _slate.withValues(alpha: 0.9))),
        ),
      ],
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────
  Widget _buildBottomBar(_ReportStats stats) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: _sky)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1FF9B417), blurRadius: 25, offset: Offset(0, -8)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => _shareReport(stats),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [_gold, _goldLight, _goldDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: _gold.withValues(alpha: 0.35), blurRadius: 16),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_rounded, size: 20, color: _navy),
                    SizedBox(width: 8),
                    Text('Share Summary on WhatsApp',
                        style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _navy)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Report generated from the Global Solar 2.0 client app',
                style: TextStyle(fontSize: 10, color: _slate)),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xB3E0F2FE)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D071440), blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _iconTile(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _sky,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 17, color: _navyDeep),
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

/// Pulsing gold dot.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 1400), vsync: this)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.5, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFF9B417),
          boxShadow: [BoxShadow(color: Color(0xFFF9B417), blurRadius: 8)],
        ),
      ),
    );
  }
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF627193))),
      ],
    );
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