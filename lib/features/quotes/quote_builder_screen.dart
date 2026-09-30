import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/gs_button.dart';
import '../../core/widgets/gs_card.dart';
import '../../core/widgets/solar_grid_divider.dart';
import '../../models/client.dart';
import '../../models/quote.dart';
import '../../providers/data_hub.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/pdf_service.dart';

/// Quote builder — select a package, see prices, save & share on WhatsApp.
class QuoteBuilderScreen extends StatefulWidget {
  final ClientModel? client;
  final QuoteModel? existing;

  const QuoteBuilderScreen({super.key, this.client, this.existing});

  @override
  State<QuoteBuilderScreen> createState() => _QuoteBuilderScreenState();
}

class _QuoteBuilderScreenState extends State<QuoteBuilderScreen> {
  String _selectedPackageId = 'p3';
  bool _residential = true;
  String _status = 'draft';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _selectedPackageId = widget.existing!.packageId;
      _residential = widget.existing!.isResidential;
      _status = widget.existing!.status;
    }
    if (widget.client?.propertyType == GSPropertyType.commercial) {
      _residential = false;
    }
  }

  GSPackage get _pkg => gsPackageById(_selectedPackageId) ?? gsPackages.first;
  bool get _isEdit => widget.existing != null;

  int get _effectiveSubsidy => _residential ? GSTax.subsidyMax : 0;
  int get _afterSubsidy => _pkg.upfront - _effectiveSubsidy;
  int get _grandTotal => _pkg.upfront + GSTax.stampCharge;

  @override
  Widget build(BuildContext context) {
    final isCommercial = _residential == false;

    return Scaffold(
      backgroundColor: GSColors.whiteBg,
      appBar: AppBar(title: Text(_isEdit ? 'Edit Quote' : 'Create Quote')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Property type ─────────────────────────────────────
            if (widget.client == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ToggleButtons(
                  isSelected: [_residential, !_residential],
                  onPressed: (i) => setState(() => _residential = i == 0),
                  borderRadius: BorderRadius.circular(12),
                  selectedColor: GSColors.navy900,
                  fillColor: GSColors.gold500,
                  color: GSColors.ink.withValues(alpha: 0.7),
                  children: const [
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Residential')),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Commercial')),
                  ],
                ),
              ),

            // ── Package selector ────────────────────────────────────
            Text('Select Package',
                style: GSTextStyles.headlineSmall.copyWith(color: GSColors.navy900)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: gsPackages.map((pkg) {
                final selected = _selectedPackageId == pkg.id;
                return ChoiceChip(
                  label: Column(
                    children: [
                      Text('${pkg.kw} kW',
                          style: GSTextStyles.labelLarge.copyWith(
                              color: selected ? GSColors.navy900 : GSColors.ink)),
                      Text('${pkg.panels} panels',
                          style: TextStyle(
                              fontSize: 11,
                              color: selected ? GSColors.navy900 : GSColors.ink.withValues(alpha: 0.7))),
                    ],
                  ),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedPackageId = pkg.id),
                  backgroundColor: GSColors.white,
                  selectedColor: GSColors.gold500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                        color: selected ? GSColors.gold500 : GSColors.ink.withValues(alpha: 0.2)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Price breakdown ────────────────────────────────────
            GsCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_pkg.tag != null && _pkg.tag!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: GSColors.gold500.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_pkg.tag!,
                          style: GSTextStyles.labelMedium.copyWith(color: GSColors.navy900)),
                    ),
                  const SizedBox(height: 8),
                  Text('${_pkg.kw} kW Solar System',
                      style: GSTextStyles.headlineSmall.copyWith(color: GSColors.navy900)),
                  if (isCommercial)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('Subsidy not applicable for commercial.',
                          style: GSTextStyles.bodySmall.copyWith(color: GSColors.statusLost)),
                    ),
                  const SizedBox(height: 16),
                  _priceRow('Upfront (pre-subsidy)', _pkg.upfront),
                  _priceRow('Subsidy (PM Surya Ghar)', -_effectiveSubsidy,
                      color: _residential ? GSColors.green600 : GSColors.statusLost),
                  _priceRow('Structure Cost', _pkg.structureCost),
                  _priceRow('Stamp Charge', GSTax.stampCharge),
                  const SolarGridDivider(height: 1, margin: EdgeInsets.only(top: 8)),
                  _priceRow('After Subsidy', _afterSubsidy, isBold: true,
                      color: GSColors.green600),
                  _priceRow('Total (incl. stamp)', _grandTotal, isBold: true,
                      color: GSColors.navy900),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Status selector ────────────────────────────────────
            if (_isEdit)
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Quote Status'),
                items: GSQuoteStatus.all
                    .map((s) => DropdownMenuItem(value: s, child: Text(GSQuoteStatus.labelOf(s))))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? 'draft'),
              ),
            if (_isEdit) const SizedBox(height: 16),

            // ── Notes ──────────────────────────────────────────────
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Special Notes (optional)',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // ── Save & Share ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: GsButton(
                    text: _isEdit ? 'Update Quote' : 'Save Quote',
                    onPressed: _loading ? null : _saveQuote,
                    isLoading: _loading,
                  ),
                ),
                const SizedBox(width: 12),
                if (!_isEdit)
                  Expanded(
                    child: GsOutlinedButton(
                      text: 'Share WhatsApp',
                      onPressed: () => _shareToWhatsApp(),
                      icon: Icons.chat_bubble_outline,
                    ),
                  ),
                if (!_isEdit)
                  const SizedBox(width: 12),
                if (!_isEdit)
                  Expanded(
                    child: GsOutlinedButton(
                      text: 'Share PDF',
                      onPressed: _loading ? null : _sharePdf,
                      icon: Icons.picture_as_pdf,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Prices last updated: ${GSTax.pricesLastUpdated}\n'
              'Note: "Final quote after free site survey"',
              style: GSTextStyles.bodySmall.copyWith(color: GSColors.ink.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, int amount,
      {Color? color, bool isBold = false}) {
    final isNegative = amount.isNegative;
    final displayAmount = isNegative ? amount.abs() : amount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: (isBold ? GSTextStyles.bodyMediumSemiBold : GSTextStyles.bodyMedium)
                  .copyWith(color: GSColors.ink)),
          Text(
            '${isNegative ? '-' : ''}₹${displayAmount.formatWithComma()}',
            style: (isBold ? GSTextStyles.bodyLargeSemiBold : GSTextStyles.bodyMedium)
                .copyWith(color: color ?? GSColors.navy900),
          ),
        ],
      ),
    );
  }

  void _saveQuote() async {
    setState(() => _loading = true);
    final hub = context.read<DataHub>();
    final now = DateTime.now();

    final quote = QuoteModel(
      id: _isEdit ? widget.existing!.id : hub.generateId(),
      clientId: widget.client?.id ?? widget.existing?.clientId ?? '',
      packageId: _selectedPackageId,
      kw: _pkg.kw,
      panels: _pkg.panels,
      upfront: _pkg.upfront,
      afterSubsidy: _afterSubsidy,
      structureCost: _pkg.structureCost,
      total: _pkg.upfront,
      status: _status,
      sentAt: now,
      isResidential: _residential,
    );

    await hub.saveQuote(quote);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote saved')),
    );
  }

  void _shareToWhatsApp() {
    final pkg = _pkg;
    final message = Uri.encodeComponent(
      'Hello,\n\n'
      'Here is your solar quote from Global Solar 2.0:\n\n'
      '${pkg.kw} kW System (${pkg.panels} panels)\n'
      'Total (pre-subsidy): ₹${pkg.upfront.formatWithComma()}\n'
      'After subsidy: ₹${_afterSubsidy.formatWithComma()}\n'
      'Structure cost: ₹${pkg.structureCost.formatWithComma()}\n'
      'Stamp charge: ₹${GSTax.stampCharge}\n'
      '─────────────────\n'
      'TOTAL (incl. stamp): ₹${_grandTotal.formatWithComma()}\n\n'
      'Final quote after free site survey.\n'
      'Price valid for 1 week.\n\n'
      'WhatsApp us at ${GSUsers.founderEmail.split('@').first} for any questions.',
    );
    final url = 'https://wa.me/${GSUsers.whatsappNumber}?text=$message';
    launchUrl(Uri.parse(url));
  }

  Future<void> _sharePdf() async {
    setState(() => _loading = true);
    try {
      final hub = context.read<DataHub>();
      final quote = QuoteModel(
        id: hub.generateId(),
        clientId: widget.client?.id ?? '',
        packageId: _selectedPackageId,
        kw: _pkg.kw,
        panels: _pkg.panels,
        upfront: _pkg.upfront,
        afterSubsidy: _afterSubsidy,
        structureCost: _pkg.structureCost,
        total: _pkg.upfront,
        status: 'draft',
        sentAt: DateTime.now(),
        isResidential: _residential,
      );

      final bytes = await PdfService.generateQuotation(
        client: widget.client,
        quote: quote,
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/gs_quotation_${quote.id}.pdf');
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'Global Solar 2.0 — Solar Quotation',
          text: '${_pkg.kw} kW System • ${_pkg.panels} panels\n'
              'After subsidy: ₹${_afterSubsidy.formatWithComma()}\n'
              'Total (incl. stamp): ₹${_grandTotal.formatWithComma()}',
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF shared via WhatsApp')),
      );
    } catch (e) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
