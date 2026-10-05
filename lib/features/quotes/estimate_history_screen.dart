/// ---------------------------------------------------------------------------
/// Estimate History — every quotation/estimate PDF created, newest first.
///
/// Each row shows the date, the customer it was created for, the estimate
/// number and the total. Tapping a row opens the archived PDF; the row actions
/// can share it on WhatsApp or delete the entry.
/// ---------------------------------------------------------------------------
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/estimate.dart';
import '../../providers/data_hub.dart';
import '../../services/estimate_archive.dart';

class EstimateHistoryScreen extends StatefulWidget {
  const EstimateHistoryScreen({super.key});

  @override
  State<EstimateHistoryScreen> createState() => _EstimateHistoryScreenState();
}

class _EstimateHistoryScreenState extends State<EstimateHistoryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<EstimateRecord> _filter(List<EstimateRecord> all) {
    if (_query.trim().isEmpty) return all;
    final q = _query.trim().toLowerCase();
    return all.where((e) {
      return e.data.leadName.toLowerCase().contains(q) ||
          (e.data.companyName?.toLowerCase().contains(q) ?? false) ||
          e.data.estimateNumber.toLowerCase().contains(q) ||
          e.data.mobileNumber.contains(q) ||
          (e.data.referenceNo?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<DataHub>().estimates;
    final items = _filter(all);

    return Scaffold(
      backgroundColor: GSColors.pageBg,
      appBar: AppBar(
        backgroundColor: GSColors.navy900,
        foregroundColor: GSColors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ESTIMATE HISTORY',
                style: GSTextStyles.headlineSmall
                    .copyWith(color: GSColors.white, letterSpacing: 0.5)),
            Text('${all.length} quotation${all.length == 1 ? '' : 's'} created',
                style: GSTextStyles.bodySmall
                    .copyWith(color: GSColors.white.withValues(alpha: 0.7))),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearch(),
          Expanded(
            child: items.isEmpty
                ? _buildEmpty(all.isEmpty)
                : RefreshIndicator(
                    onRefresh: () => context.read<DataHub>().init(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _buildRow(items[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Search ────────────────────────────────────────────────────────

  Widget _buildSearch() {
    return Container(
      color: GSColors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Search name, number or estimate no.',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: GSColors.pageBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(bool noDataAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined,
                size: 56, color: GSColors.ink.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(
              noDataAtAll
                  ? 'No estimates yet'
                  : 'No matching estimates',
              style: GSTextStyles.headlineSmall.copyWith(
                  color: GSColors.navy900, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              noDataAtAll
                  ? 'Create a quotation from the dashboard and it will appear here.'
                  : 'Try a different name, number or estimate number.',
              textAlign: TextAlign.center,
              style: GSTextStyles.bodySmall
                  .copyWith(color: GSColors.ink.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Row ────────────────────────────────────────────────────────────

  Widget _buildRow(EstimateRecord record) {
    final d = record.data;
    final grandTotal = d.priceBreakdown?.grandTotal;
    final archived = EstimateArchive.hasArchivedPdf(record);

    return Container(
      decoration: BoxDecoration(
        color: GSColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x0A071440), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dateBadge(record.createdAt),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.clientType == 'business' && d.companyName != null
                      ? d.companyName!
                      : d.leadName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GSTextStyles.bodyLargeSemiBold.copyWith(
                    color: GSColors.navy900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(d.estimateNumber,
                        style: GSTextStyles.bodySmall
                            .copyWith(color: GSColors.navy700, fontWeight: FontWeight.w700)),
                    if (d.capacityKw != null) ...[
                      Text('  •  ',
                          style: GSTextStyles.bodySmall
                              .copyWith(color: GSColors.ink.withValues(alpha: 0.3))),
                      Text('${d.capacityKw!.toStringAsFixed(2)} kW',
                          style: GSTextStyles.bodySmall
                              .copyWith(color: GSColors.ink.withValues(alpha: 0.7))),
                    ],
                  ],
                ),
                if (grandTotal != null && grandTotal > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatMoney(grandTotal),
                      style: GSTextStyles.bodyLargeSemiBold.copyWith(
                        color: const Color(0xFFB45309),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded,
                color: GSColors.ink.withValues(alpha: 0.5), size: 20),
            color: GSColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (v) => _handleAction(v, record),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'preview',
                child: Row(children: [
                  const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  const SizedBox(width: 10),
                  Text(archived ? 'Preview PDF' : 'Generate & Preview',
                      style: GSTextStyles.bodyMedium),
                ]),
              ),
              PopupMenuItem(
                value: 'whatsapp',
                child: Row(children: [
                  const Icon(Icons.chat_rounded, size: 18, color: Color(0xFF25D366)),
                  const SizedBox(width: 10),
                  Text('Send on WhatsApp', style: GSTextStyles.bodyMedium),
                ]),
              ),
              PopupMenuItem(
                value: 'download',
                child: Row(children: [
                  const Icon(Icons.download_outlined, size: 18),
                  const SizedBox(width: 10),
                  Text('Download', style: GSTextStyles.bodyMedium),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  const Icon(Icons.delete_outline_rounded, size: 18, color: GSColors.statusNew),
                  const SizedBox(width: 10),
                  Text('Delete', style: GSTextStyles.bodyMedium.copyWith(color: GSColors.statusNew)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Date chip — day on top, month + year below.
  Widget _dateBadge(DateTime date) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF9B417), Color(0xFFFFCA28)],
        ),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(color: GSColors.gold500.withValues(alpha: 0.35), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Text(
            date.day.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF050E26),
              height: 1.1,
            ),
          ),
          Text(
            DateFormat('MMM').format(date).toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF050E26),
              letterSpacing: 0.5,
            ),
          ),
          Text(
            '${date.year}',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 9,
              color: Color(0x99050E26),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────

  Future<void> _handleAction(String action, EstimateRecord record) async {
    switch (action) {
      case 'preview':
        await _preview(record);
        break;
      case 'whatsapp':
        await _shareOnWhatsApp(record);
        break;
      case 'download':
        await _download(record);
        break;
      case 'delete':
        await _confirmDelete(record);
        break;
    }
  }

  Future<File> _resolvePdf(EstimateRecord record) async {
    final hub = context.read<DataHub>();
    final file = await EstimateArchive.resolve(record);
    if (record.pdfPath != file.path) {
      await hub.setEstimatePdfPath(record.id, file.path);
    }
    return file;
  }

  Future<void> _preview(EstimateRecord record) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    File file;
    try {
      file = await _resolvePdf(record);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not build PDF: $e')));
      return;
    }
    navigator.push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PdfPreview(
        canChangePageFormat: false,
        canChangeOrientation: false,
        pdfFileName: file.uri.pathSegments.last,
        build: (_) => file.readAsBytes(),
      ),
    ));
  }

  Future<void> _shareOnWhatsApp(EstimateRecord record) async {
    final messenger = ScaffoldMessenger.of(context);
    File file;
    try {
      file = await _resolvePdf(record);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not build PDF: $e')));
      return;
    }
    final text =
        'Hello ${record.data.leadName}, here is your solar estimate ${record.data.estimateNumber} from Global Solar 2.0.';

    // Share sheet is the only reliable way to attach a file to a chat; the
    // user then picks WhatsApp and the contact.
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Solar Estimate ${record.data.estimateNumber}',
        text: text,
      ),
    );
  }

  Future<void> _download(EstimateRecord record) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await _resolvePdf(record);
      final saved = await EstimateArchive.saveCopy(
        await file.readAsBytes(),
        'GS_Estimate_${record.id}.pdf',
      );
      messenger.showSnackBar(SnackBar(content: Text('Downloaded to ${saved.path}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  Future<void> _confirmDelete(EstimateRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: GSColors.white,
        title: Text('Delete estimate?',
            style: GSTextStyles.headlineSmall.copyWith(color: GSColors.navy900)),
        content: Text(
          '${record.data.estimateNumber} for ${record.data.leadName} and its saved PDF will be removed. This cannot be undone.',
          style: GSTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text('Cancel', style: GSTextStyles.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text('Delete',
                style: GSTextStyles.bodyMedium.copyWith(color: GSColors.statusNew)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await EstimateArchive.deletePdf(record);
    if (!mounted) return;
    await context.read<DataHub>().deleteEstimate(record.id);
    messenger.showSnackBar(
      SnackBar(content: Text('${record.data.estimateNumber} deleted')),
    );
  }

  String _formatMoney(int amount) {
    final symbol = '₹';
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '$symbol$buf';
  }
}