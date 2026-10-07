import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/estimate.dart';
import '../../providers/data_hub.dart';
import '../../services/quotation_archive_service.dart';
import 'quotation_preview_screen.dart';

/// Quotation History — lists every saved quotation (estimate) with
/// customer name, date, capacity, total, and PDF status, plus per-entry
/// preview / share / download / delete actions.
class QuotationHistoryScreen extends StatefulWidget {
  const QuotationHistoryScreen({super.key});

  @override
  State<QuotationHistoryScreen> createState() => _QuotationHistoryScreenState();
}

class _QuotationHistoryScreenState extends State<QuotationHistoryScreen> {
  String _search = '';

  Future<void> _openPreview(
      BuildContext context, EstimateRecord record,
      {PreviewAutoAction? autoAction}) async {
    final master = await MasterData.load();
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuotationPreviewScreen(
        record: record,
        master: master,
        autoAction: autoAction,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hub = context.watch<DataHub>();
    final all = hub.estimates;
    final filtered = _search.trim().isEmpty
        ? all
        : all.where((r) =>
            r.data.leadName.toLowerCase().contains(_search.toLowerCase()) ||
            r.data.estimateNumber
                .toLowerCase()
                .contains(_search.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: GSColors.sky100,
      appBar: AppBar(
        backgroundColor: GSColors.navy900,
        foregroundColor: GSColors.white,
        elevation: 0,
        title: const Text('Quotation History',
            style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          if (all.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Refresh',
                onPressed: () => hub.init(),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by client name or estimate number',
                hintStyle:
                    const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: GSColors.blue500, width: 1.2)),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          // ── Count chip ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: GSColors.gold500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: GSColors.gold500.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    "${filtered.length} ${filtered.length == 1 ? 'quotation' : 'quotations'}",
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF78350F)),
                  ),
                ),
              ],
            ),
          ),
          // ── List ──
          Expanded(
            child: filtered.isEmpty
                ? _emptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final record = filtered[i];
                      return _QuotationTile(
                        record: record,
                        onPreview: () => _openPreview(context, record),
                        onShare: () => _openPreview(context, record,
                            autoAction: PreviewAutoAction.share),
                        onDownload: () => _openPreview(context, record,
                            autoAction: PreviewAutoAction.download),
                        onDelete: () =>
                            _confirmDelete(context, hub, record),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GSColors.gold500.withValues(alpha: 0.1),
                border:
                    Border.all(color: GSColors.gold500.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.history_rounded,
                  size: 32, color: GSColors.gold500),
            ),
            const SizedBox(height: 16),
            Text(
              _search.trim().isEmpty
                  ? 'No quotations created yet'
                  : 'No matching quotations',
              style: TextStyle(
                  fontSize: _search.trim().isEmpty ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F1B3D))),
            if (_search.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Try clearing the search',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, DataHub hub, EstimateRecord record) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Quotation?'),
        content: Text(
            'This will remove quotation ${record.data.estimateNumber} for '
            '${record.data.leadName} and its archived PDF. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await QuotationArchiveService.deletePdf(record);
              await hub.deleteEstimate(record.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quotation deleted')),
                );
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: GSColors.followupMissed)),
          ),
        ],
      ),
    );
  }
}

// ── Per-entry tile ──────────────────────────────────────────────────

class _QuotationTile extends StatelessWidget {
  final EstimateRecord record;
  final VoidCallback onPreview;
  final VoidCallback onShare;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _QuotationTile({
    required this.record,
    required this.onPreview,
    required this.onShare,
    required this.onDownload,
    required this.onDelete,
  });

  static final DateFormat _dateFmt = DateFormat('dd MMM yyyy');

  String _formatCurrency(int amount) {
    return '₹${NumberFormat.decimalPattern('en_IN').format(amount)}';
  }

  int _grandTotal(EstimateModel e) {
    final system =
        e.systemId != null ? gsQuoteSystemById(e.systemId!) : null;
    if (system != null) {
      final base = e.totalPayableOverride ?? system.totalPayable;
      final subsidy = e.clientType == 'individual' ? GSTax.subsidyMax : 0;
      return base - subsidy;
    }
    return e.priceBreakdown?.grandTotal ?? 0;
  }

  String _capacityLabel(EstimateModel e) {
    final cap = e.capacityKw;
    if (cap != null && cap > 0) return '${cap.toStringAsFixed(2)} kW';
    final system =
        e.systemId != null ? gsQuoteSystemById(e.systemId!) : null;
    if (system != null) {
      return '${system.kw.toStringAsFixed(2)} kW (${system.panels} panels)';
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final e = record.data;
    final total = _grandTotal(e);
    final capacity = _capacityLabel(e);
    final date = _dateFmt.format(record.createdAt);

    return FutureBuilder<bool>(
      future: QuotationArchiveService.hasPdf(record),
      builder: (context, snapshot) {
        final hasPdf = snapshot.data ?? false;
        final system =
            e.systemId != null ? gsQuoteSystemById(e.systemId!) : null;

        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: InkWell(
            onTap: onPreview,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row: client name + status ──
                  Row(children: [
                    Expanded(
                      child: Text(
                        e.leadName.isNotEmpty ? e.leadName : 'Unnamed Client',
                        style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F1B3D)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: hasPdf
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: hasPdf
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFFFE0B2),
                        ),
                      ),
                      child: Row(children: [
                        Icon(
                          hasPdf
                              ? Icons.check_circle_rounded
                              : Icons.pending_rounded,
                          size: 12,
                          color: hasPdf
                              ? GSColors.green600
                              : const Color(0xFFB45309)),
                        const SizedBox(width: 4),
                        Text(
                          hasPdf ? 'PDF Ready' : 'Generate PDF',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: hasPdf
                                  ? GSColors.green600
                                  : const Color(0xFFB45309)),
                        ),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  // ── Secondary row: estimate number + date ──
                  Text('${e.estimateNumber}  •  $date',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 10),
                  // ── Details row: capacity + brand + total ──
                  Row(children: [
                    Expanded(
                      child: _detailChip(Icons.wb_sunny_outlined, capacity,
                          const Color(0xFF0F1B3D)),
                    ),
                    if (system != null)
                      Expanded(
                        child: _detailChip(Icons.business_rounded,
                            system.brandEn, GSColors.blue500),
                      ),
                    Expanded(
                      child: _detailChip(Icons.currency_rupee_rounded,
                          _formatCurrency(total), GSColors.green600),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  // ── Footer: actions ──
                  Row(children: [
                    Expanded(
                      child: _quickAction(
                        icon: Icons.open_in_new_rounded,
                        label: 'Preview',
                        onTap: onPreview,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _quickAction(
                        icon: Icons.share_rounded,
                        label: 'Share',
                        onTap: onShare,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _quickAction(
                        icon: Icons.download_rounded,
                        label: 'Download',
                        onTap: onDownload,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _actionCircle(
                      icon: Icons.delete_outline_rounded,
                      color: GSColors.followupMissed,
                      onTap: onDelete,
                    ),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailChip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: const Color(0xFF0F1B3D)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F1B3D))),
            ],
          ),
        ),
      );

  Widget _actionCircle({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.08),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
      );
}
