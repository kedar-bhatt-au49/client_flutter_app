import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/gs_button.dart';
import '../../core/widgets/gs_card.dart';
import '../../core/widgets/solar_grid_divider.dart';
import '../../models/client.dart';
import '../../models/quote.dart';
import '../../providers/data_hub.dart';
import '../../services/pdf_service.dart';

/// Standalone screen to create a client quotation from scratch.
///
/// Collects client details (name, village, city, mobile, property type),
/// lets the user pick a solar package, generates a PDF quotation, and
/// shares it via WhatsApp to anyone.
class QuotationFormScreen extends StatefulWidget {
  const QuotationFormScreen({super.key});

  @override
  State<QuotationFormScreen> createState() => _QuotationFormScreenState();
}

class _QuotationFormScreenState extends State<QuotationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _villageController = TextEditingController();
  final _cityController = TextEditingController();
  final _mobileController = TextEditingController();

  String _propertyType = GSPropertyType.residential;
  String _selectedPackageId = 'p3';
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _villageController.dispose();
    _cityController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  GSPackage get _pkg => gsPackageById(_selectedPackageId) ?? gsPackages.first;
  bool get _isResidential => _propertyType == GSPropertyType.residential;
  int get _effectiveSubsidy => _isResidential ? GSTax.subsidyMax : 0;
  int get _afterSubsidy => _pkg.upfront - _effectiveSubsidy;
  int get _grandTotal => _pkg.upfront + GSTax.stampCharge;

  @override
  Widget build(BuildContext context) {
    final isCommercial = !_isResidential;

    return Scaffold(
      backgroundColor: GSColors.whiteBg,
      appBar: AppBar(
        title: const Text('Create Quotation'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Client details ──────────────────────────────────────
              _sectionHeading('Client Details'),
              GsCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Mobile number
                    TextFormField(
                      controller: _mobileController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        prefixText: '+91 ',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: (v) => v == null ||
                              v.trim().length < 10
                          ? 'Valid mobile number required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // City
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        hintText: 'e.g. Bhavnagar, Talaja',
                        prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Village
                    TextFormField(
                      controller: _villageController,
                      decoration: const InputDecoration(
                        labelText: 'Village',
                        hintText: 'Village name (if applicable)',
                        prefixIcon: Icon(Icons.home_outlined, size: 20),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Property type toggle
                    Text('Property Type',
                        style: GSTextStyles.bodySmall
                            .copyWith(color: GSColors.ink.withValues(alpha: 0.6))),
                    const SizedBox(height: 8),
                    ToggleButtons(
                      isSelected: [_isResidential, !_isResidential],
                      onPressed: (i) => setState(() => _propertyType = i == 0
                          ? GSPropertyType.residential
                          : GSPropertyType.commercial),
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
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Package selector ────────────────────────────────────
              _sectionHeading('Select Package'),
              Text(
                'Choose a solar package based on the client\'s needs.',
                style: GSTextStyles.bodySmall
                    .copyWith(color: GSColors.ink.withValues(alpha: 0.6)),
              ),
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
                                color: selected
                                    ? GSColors.navy900
                                    : GSColors.ink)),
                        Text('${pkg.panels} panels',
                            style: TextStyle(
                                fontSize: 11,
                                color: selected
                                    ? GSColors.navy900
                                    : GSColors.ink.withValues(alpha: 0.7))),
                      ],
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedPackageId = pkg.id),
                    backgroundColor: GSColors.white,
                    selectedColor: GSColors.gold500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: selected
                              ? GSColors.gold500
                              : GSColors.ink.withValues(alpha: 0.2)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Price breakdown ─────────────────────────────────────
              _sectionHeading('Price Breakdown'),
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
                            style: GSTextStyles.labelMedium
                                .copyWith(color: GSColors.navy900)),
                      ),
                    const SizedBox(height: 8),
                    Text('${_pkg.kw} kW Solar System',
                        style: GSTextStyles.headlineSmall
                            .copyWith(color: GSColors.navy900)),
                    if (isCommercial)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('Subsidy not applicable for commercial.',
                            style: GSTextStyles.bodySmall
                                .copyWith(color: GSColors.statusLost)),
                      ),
                    const SizedBox(height: 16),
                    _priceRow('Upfront (pre-subsidy)', _pkg.upfront),
                    _priceRow('Subsidy (PM Surya Ghar)', -_effectiveSubsidy,
                        color: _isResidential ? GSColors.green600 : GSColors.statusLost),
                    _priceRow('Structure Cost', _pkg.structureCost),
                    _priceRow('Stamp Charge', GSTax.stampCharge),
                    const SolarGridDivider(height: 1, margin: EdgeInsets.only(top: 8)),
                    _priceRow('After Subsidy', _afterSubsidy,
                        isBold: true, color: GSColors.green600),
                    _priceRow('Total (incl. stamp)', _grandTotal,
                        isBold: true, color: GSColors.navy900),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Prices last updated: ${GSTax.pricesLastUpdated}\n'
                'Note: "Final quote after free site survey"',
                style: GSTextStyles.bodySmall
                    .copyWith(color: GSColors.ink.withValues(alpha: 0.6)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ── Generate & Share ────────────────────────────────────
              _sectionHeading('Generate & Share'),
              Text(
                'Tap below to generate a PDF quotation and share it on WhatsApp.',
                style: GSTextStyles.bodySmall
                    .copyWith(color: GSColors.ink.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 16),

              GsButton(
                text: 'Generate PDF & Share',
                onPressed: _loading ? null : _generateAndShare,
                isLoading: _loading,
                icon: Icons.picture_as_pdf,
              ),
              const SizedBox(height: 16),

              GsOutlinedButton(
                text: 'Open WhatsApp (Text)',
                onPressed: _shareTextToWhatsApp,
                icon: Icons.chat_bubble_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeading(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: GSTextStyles.headlineSmall
                .copyWith(color: GSColors.navy900)),
      );

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

  Future<void> _generateAndShare() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final hub = context.read<DataHub>();
    final now = DateTime.now();

    try {
      // Build the client model from form values
      final area = _cityController.text.trim().isNotEmpty
          ? GSArea.bhavnagar
          : (_villageController.text.trim().isNotEmpty
              ? GSArea.village
              : GSArea.talaja);

      final client = ClientModel(
        id: hub.generateId(),
        name: _nameController.text.trim(),
        phone: _mobileController.text.trim(),
        area: area,
        village: _villageController.text.trim().isNotEmpty
            ? _villageController.text.trim()
            : null,
        city: _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
        propertyType: _propertyType,
        monthlyBill: 0,
        preferredPackage: _pkg.kw.toString(),
        source: GSSource.whatsapp,
        status: GSClientStatus.quoted,
        ownerUid: GSUsers.founderUid,
        createdAt: now,
        updatedAt: now,
      );

      // Build the quote model
      final quote = QuoteModel(
        id: hub.generateId(),
        clientId: client.id,
        packageId: _pkg.id,
        kw: _pkg.kw,
        panels: _pkg.panels,
        upfront: _pkg.upfront,
        afterSubsidy: _afterSubsidy,
        structureCost: _pkg.structureCost,
        total: _pkg.upfront,
        status: GSQuoteStatus.sent,
        sentAt: now,
        isResidential: _isResidential,
      );

      // Persist so the client + quote appear in the list
      await hub.addClient(client);
      await hub.saveQuote(quote);

      // Generate the PDF
      final bytes = await PdfService.generateQuotation(
        client: client,
        quote: quote,
      );

      final fileName =
          'GS_Quotation_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      // Share via system sheet (includes WhatsApp target)
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path,
                mimeType: 'application/pdf', name: fileName),
          ],
          subject: 'Global Solar 2.0 — Solar Quotation',
          text: _shareText,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF generated and shared via WhatsApp')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _shareText =>
      'Hello ${_nameController.text.trim()},\n\n'
      'Here is your solar quotation from Global Solar 2.0:\n\n'
      '${_pkg.kw} kW System (${_pkg.panels} panels)\n'
      'Upfront: ₹${_pkg.upfront.formatWithComma()}\n'
      'After subsidy: ₹${_afterSubsidy.formatWithComma()}\n'
      'Structure cost: ₹${_pkg.structureCost.formatWithComma()}\n'
      'Stamp charge: ₹${GSTax.stampCharge}\n'
      '─────────────────\n'
      'TOTAL (incl. stamp): ₹${_grandTotal.formatWithComma()}\n\n'
      'Final quote after free site survey.\n'
      'Price valid for 1 week.\n\n'
      '- Jayrajsinh S. Umat & Gopalsinh J. Parmar\n'
      'Global Solar 2.0';

  void _shareTextToWhatsApp() {
    final message = Uri.encodeComponent(_shareText);
    final phone = GSUsers.whatsappNumber;
    final url = 'https://wa.me/$phone?text=$message';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
