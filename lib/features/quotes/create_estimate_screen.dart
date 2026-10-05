/// ---------------------------------------------------------------------------
/// Create Estimate — multi-step wizard (Steps 1-4).
///
/// Step 1: Lead Details  (👤)
/// Step 2: Estimate Details (📊) — opens Price Calculator (Step 2a)
/// Step 3: Structure Details (🛠)
/// Step 4: Financial Details (₹)
///
/// State is held in the [EstimateModel] and survives back/forth navigation.
/// Master data is loaded from `assets/data/estimate_master.json`.
/// ---------------------------------------------------------------------------
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/estimate_widgets.dart';
import '../../core/widgets/gs_card.dart';
import '../../core/widgets/searchable_selector_sheet.dart';
import '../../models/estimate.dart';
import '../../providers/data_hub.dart';
import '../../services/estimate_pdf.dart';

class CreateEstimateScreen extends StatefulWidget {
  const CreateEstimateScreen({super.key});

  @override
  State<CreateEstimateScreen> createState() => _CreateEstimateScreenState();
}

class _CreateEstimateScreenState extends State<CreateEstimateScreen> {
  // ── Master data (loaded async from JSON) ───
  MasterData? _master;
  bool _ready = false;
  String? _loadError;

  // ── Wizard state ───
  int _currentStep = 0;
  final EstimateModel _estimate = EstimateModel();

  // ── Controllers: Step 1 — Lead Details ───
  final _companyCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _autoFillWhatsApp = false;
  bool _showAdvanced = false;
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // ── Controllers: Step 2 — Estimate Details ───
  final _estimateNumberCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _wiringCtrl = TextEditingController();
  final _inverterKwCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  // ── Controllers: Step 3 — Structure Details ───
  final Map<String, TextEditingController> _structureCtrls = {};

  // ── Controllers: Step 4 — Financial Details ───
  final _discountCtrl = TextEditingController();
  final _insPercentCtrl = TextEditingController();
  final _insAmountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMaster();
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _whatsappCtrl.dispose();
    _descriptionCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _estimateNumberCtrl.dispose();
    _referenceCtrl.dispose();
    _capacityCtrl.dispose();
    _wiringCtrl.dispose();
    _inverterKwCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _insPercentCtrl.dispose();
    _insAmountCtrl.dispose();
    _structureCtrls.forEach((_, c) => c.dispose());
    super.dispose();
  }

  // ── Master data loading ──────────────────────────────────────────

  Future<void> _loadMaster() async {
    _loadError = null;
    try {
      _master = await MasterData.load();

      // Generate sequential estimate number from existing estimates
      final hub = context.read<DataHub>();
      final index = hub.estimateCount;
      _estimate.estimateNumber =
          EstimateModel.generateNumber(_master!.estimateNumberPrefix, index);
      _estimateNumberCtrl.text = _estimate.estimateNumber;

      // Defaults from master
      _estimate.currency = _master!.defaultCurrency;
      _estimate.leadStage = _master!.defaultLeadStage;
      _estimate.expiryDate =
          DateTime.now().add(Duration(days: _master!.expiryDays));
      _estimate.gstProfileLabel =
          _master!.gstProfiles.isNotEmpty ? _master!.gstProfiles.last.label : '';
      _discountCtrl.text = '0';

      // Initialize structure controllers
      for (final pipe in _master!.structurePipes) {
        _structureCtrls[pipe.label] = TextEditingController();
      }

      setState(() => _ready = true);
    } catch (e) {
      setState(() {
        _ready = false;
        _loadError = e.toString();
      });
    }
  }

  // ── Step 1 helpers ──

  void _toggleAutoFillWhatsApp(bool? v) {
    setState(() {
      _autoFillWhatsApp = v ?? false;
      if (_autoFillWhatsApp) {
        _whatsappCtrl.text = _mobileCtrl.text;
      } else {
        _whatsappCtrl.clear();
      }
    });
  }

  void _openLeadStageSelector() {
    SearchableSelectorSheet.show<LeadStageOpt>(
      context: context,
      title: 'Lead Stage',
      hint: 'Search stages...',
      items: _master!.leadStages,
      labelBuilder: (s) => s.label,
      initialValue: _master!.stageById(_estimate.leadStage),
      onSelected: (s) => setState(() => _estimate.leadStage = s.id),
    );
  }

  // ── Step 2 helpers ──

  GSQuoteSystem? get _selectedSystem => _estimate.systemId != null
      ? gsQuoteSystemById(_estimate.systemId!)
      : null;

  void _selectSystem(GSQuoteSystem s) {
    setState(() {
      _estimate.systemId = s.id;
      _estimate.capacityKw = s.kw;
      _capacityCtrl.text = s.kw.toStringAsFixed(2);
    });
  }

  void _openSystemSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select Solar System',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F1B3D))),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: gsQuoteSystems
                    .map((s) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: GSColors.sky100,
                            child: Text('${s.panels}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: GSColors.navy900)),
                          ),
                          title: Text(s.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              'Total ₹${s.totalPayable}  •  After subsidy ₹${s.afterSubsidy}',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF627193))),
                          trailing: _estimate.systemId == s.id
                              ? const Icon(Icons.check_circle,
                                  color: GSColors.green600)
                              : null,
                          onTap: () {
                            _selectSystem(s);
                            Navigator.pop(sheetContext);
                          },
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Step 3 helpers ──

  TextEditingController _getStructureCtrl(String label) {
    var c = _structureCtrls[label];
    if (c == null) {
      c = TextEditingController(
          text: _estimate.structureQuantities[label]?.toString() ?? '');
      _structureCtrls[label] = c;
    }
    return c;
  }

  // ── Step 4 helpers ──

  void _setGstProfile(String? label) {
    setState(() => _estimate.gstProfileLabel = label ?? '');
  }

  void _toggleInsurance(bool v) {
    setState(() => _estimate.insuranceIncluded = v);
  }

  void _setInsuranceType(String? t) {
    setState(() => _estimate.insuranceType = t ?? 'percent');
  }

  // ── Validation ──

  bool _validateStep(int step) {
    if (step == 0) {
      if (_nameCtrl.text.trim().isEmpty) return _error('Name is required');
      if (_mobileCtrl.text.trim().isEmpty ||
          _mobileCtrl.text.trim().length < 10) {
        return _error('Valid mobile number is required');
      }
      if (_estimate.clientType == 'business' &&
          _companyCtrl.text.trim().isEmpty) {
        return _error('Company name is required');
      }
    }
    if (step == 1) {
      if (_estimateNumberCtrl.text.trim().isEmpty) {
        return _error('Estimate number is required');
      }
      if (_estimate.systemId == null) {
        return _error('Please select a solar system');
      }
      if (_estimate.currency.isEmpty) return _error('Currency is required');
    }
    return true;
  }

  bool _error(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
    return false;
  }

  // ── Navigation ──

  void _onBack() {
    if (_currentStep == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _currentStep--);
    }
  }

  void _onNext() {
    if (!_validateStep(_currentStep)) return;

    if (_currentStep < 1) {
      setState(() => _currentStep++);
    } else {
      _saveEstimate();
    }
  }

  Future<void> _saveEstimate() async {
    final hub = context.read<DataHub>();

    // Sync all controller values into the model
    _estimate
      ..companyName = _companyCtrl.text.trim().isEmpty
          ? null
          : _companyCtrl.text.trim()
      ..leadName = _nameCtrl.text.trim()
      ..mobileNumber = _mobileCtrl.text.trim()
      ..whatsappNumber = _whatsappCtrl.text.trim().isEmpty
          ? null
          : _whatsappCtrl.text.trim()
      ..autoFillWhatsApp = _autoFillWhatsApp
      ..description = _descriptionCtrl.text.trim().isNotEmpty
          ? _descriptionCtrl.text.trim()
          : null
      ..estimateNumber = _estimateNumberCtrl.text.trim()
      ..referenceNo = _referenceCtrl.text.trim().isNotEmpty
          ? _referenceCtrl.text.trim()
          : null
      ..capacityKw = double.tryParse(_capacityCtrl.text)
      ..discountPerKw = double.tryParse(_discountCtrl.text.trim()) ?? 0
      ..insurancePercent =
          double.tryParse(_insPercentCtrl.text.trim()) ?? 0
      ..insuranceAmount =
          int.tryParse(_insAmountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
              0;

    // ── Save the estimate ──
    late EstimateRecord record;
    try {
      record = await hub.addEstimate(_estimate);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save estimate: $e')),
      );
      return;
    }
    if (!mounted) return;

    // ── Generate the estimate PDF and save it to a temp file ──
    File? pdfFile;
    try {
      final pdfBytes = await EstimatePdf.generate(
        record: record,
        master: _master!,
      );
      final dir = await getTemporaryDirectory();
      pdfFile = File('${dir.path}/GS_Estimate_${record.id}.pdf');
      await pdfFile.writeAsBytes(pdfBytes, flush: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
      return;
    }

    // Show a dialog with preview / share options for the 7-page PDF
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: GSColors.white,
        title: Text('${_estimate.estimateNumber} saved!',
            style: GSTextStyles.headlineSmall.copyWith(color: GSColors.navy900)),
        content: const Text('7-page estimate PDF generated. '
            'Preview, share, or go back to the dashboard.'),
        actions: [
          TextButton(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.visibility_outlined, size: 18),
                SizedBox(width: 8),
                Text('View PDF'),
              ],
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              Printing.layoutPdf(
                onLayout: (_) => EstimatePdf.generate(
                  record: record,
                  master: _master!,
                ),
              );
            },
          ),
          TextButton(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.share_outlined, size: 18),
                SizedBox(width: 8),
                Text('Share PDF'),
              ],
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final f = pdfFile;
              if (f != null) {
                await SharePlus.instance.share(
                  ShareParams(
                    files: [
                      XFile(
                        f.path,
                        mimeType: 'application/pdf',
                        name: 'GS_Estimate_${record.id}.pdf',
                      ),
                    ],
                    subject: 'Global Solar 2.0 — Solar Estimate',
                    text: '${_estimate.estimateNumber} • '
                        '${_estimate.capacityKw?.toStringAsFixed(2) ?? '-'} kW',
                  ),
                );
              }
              if (!mounted) return;
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
          TextButton(
            child: const Text('Done'),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              if (mounted) {
                Navigator.of(context).popUntil((r) => r.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        backgroundColor: GSColors.pageBg,
        appBar: AppBar(
          backgroundColor: GSColors.navy900,
          foregroundColor: GSColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('CREATE ESTIMATE',
              style: GSTextStyles.headlineMedium.copyWith(color: GSColors.white)),
          centerTitle: true,
        ),
        body: Center(
          child: _loadError != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: GSColors.statusNew),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load estimate data.',
                        textAlign: TextAlign.center,
                        style: GSTextStyles.bodyMedium
                            .copyWith(color: GSColors.navy900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _loadError!,
                        textAlign: TextAlign.center,
                        style: GSTextStyles.bodySmall
                            .copyWith(color: GSColors.ink.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadError != null ? _loadMaster : null,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GSColors.navy500,
                          foregroundColor: GSColors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : const CircularProgressIndicator(color: GSColors.teal500),
        ),
      );
    }

    return Scaffold(
      backgroundColor: GSColors.pageBg,
      body: Column(
        children: [
          // Top app bar
          Container(
            color: GSColors.navy900,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close (X)
                IconButton(
                  icon: const Icon(Icons.close, color: GSColors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                // Centered title
                Text(
                  'CREATE ESTIMATE',
                  style: GSTextStyles.headlineMedium.copyWith(color: GSColors.white),
                ),
                // Status label "Draft" on right
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    'Draft',
                    style: GSTextStyles.labelMedium.copyWith(
                      color: GSColors.gold500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Progress bar
          EstimateProgressBar(stepCount: 2, currentStep: _currentStep),
          // Step content
          Expanded(
            child: SingleChildScrollView(
              child: _buildStepContent(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ActionBarButtonBar(
        backText: _currentStep == 0 ? 'Close' : 'Back',
        nextText: _currentStep == 1 ? 'Create Quotation' : 'Next',
        onBack: _onBack,
        onNext: _onNext,
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildLeadDetails();
      case 1:
        return _buildEstimateDetails();
      case 2:
        return _buildStructureDetails();
      case 3:
        return _buildFinancialDetails();
      default:
        return _buildLeadDetails();
    }
  }

  // ── Step 1: Lead Details ─────────────────────────────────────────

  Widget _buildLeadDetails() {
    final stage = _master!.stageById(_estimate.leadStage);
    final showAdvanced =
        _estimate.clientType == 'individual' && _showAdvanced;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Type toggle: Individual / Business
        EstimateSectionHeader(icon: Icons.person, title: 'Lead Details'),
        GsCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type',
                  style: GSTextStyles.labelMedium
                      .copyWith(color: GSColors.navy900)),
              const SizedBox(height: 8),
              GsRadioGroup(
                groupValue: _estimate.clientType,
                onChanged: (v) => setState(() {
                  _estimate.clientType = v ?? 'individual';
                  _showAdvanced = false;
                }),
                options: [
                  RadioOption(label: 'Individual', value: 'individual'),
                  RadioOption(label: 'Business', value: 'business'),
                ],
              ),
            ],
          ),
        ),

        // Company Name (Business only, appears above Name)
        if (_estimate.clientType == 'business')
          _fieldCard(
            label: 'Company Name',
            required: true,
            hint: 'e.g. Priya & Co.',
            input: _textField(
              controller: _companyCtrl,
              errorText: _estimate.clientType == 'business'
                  ? (_companyCtrl.text.trim().isEmpty ? 'Required' : null)
                  : null,
            ),
          ),

        // Name
        _fieldCard(
          label: 'Name',
          required: true,
          hint: 'Full Name',
          input: _textField(
            controller: _nameCtrl,
            errorText: _nameCtrl.text.trim().isEmpty ? 'Required' : null,
          ),
        ),

        // Mobile Number
        _fieldCard(
          label: 'Mobile Number',
          required: true,
          hint: '10-digit mobile number',
          input: _textField(
            controller: _mobileCtrl,
            prefixText: '+91 ',
            keyboardType: TextInputType.phone,
            onChanged: (v) {
              if (_autoFillWhatsApp && _mobileCtrl.text.trim().isNotEmpty) {
                _whatsappCtrl.text = _mobileCtrl.text;
              }
              // Trigger rebuild for error text
              if (mounted) setState(() {});
            },
            errorText: _mobileCtrl.text.trim().isNotEmpty &&
                    _mobileCtrl.text.trim().length >= 10
                ? null
                : (_mobileCtrl.text.trim().isNotEmpty
                    ? 'Invalid number'
                    : null),
          ),
        ),

        // WhatsApp Number
        _fieldCard(
          label: 'WhatsApp Number',
          required: false,
          hint: 'Same as mobile (toggle below)',
          input: _textField(
            controller: _whatsappCtrl,
            prefixText: '+91 ',
            keyboardType: TextInputType.phone,
            suffixIcon: Icon(Icons.chat,
                color: _whatsappCtrl.text.trim().isNotEmpty
                    ? const Color(0xFF25D36E)
                    : GSColors.ink.withValues(alpha: 0.3),
                size: 22),
          ),
        ),
        // Auto-fill WhatsApp toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Auto-fill from mobile',
                  style: GSTextStyles.bodySmall
                      .copyWith(color: GSColors.ink.withValues(alpha: 0.6))),
              Switch(
                value: _autoFillWhatsApp,
                onChanged: _toggleAutoFillWhatsApp,
                activeColor: GSColors.teal500,
                activeTrackColor: GSColors.teal500.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),

        // Lead Stage (tappable selector)
        _fieldCard(
          label: 'Lead Stage',
          required: false,
          input: GsSelectorTile(
            value: stage.label,
            valueColor: GSColors.navy900,
            leading: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hexToColor(stage.dotColorHex),
              ),
            ),
            onTap: _openLeadStageSelector,
          ),
        ),

        // Description
        _fieldCard(
          label: 'Description',
          required: false,
          hint: 'e.g. Customer is a regular buyer',
          input: _textField(
            controller: _descriptionCtrl,
            maxLines: 3,
            hint: 'e.g. Customer is a regular buyer',
          ),
        ),

        // Show Advanced Options (Individual only)
        if (_estimate.clientType == 'individual')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GsCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Show Advanced Options',
                            style: GSTextStyles.labelMedium.copyWith(
                                color: GSColors.navy900)),
                        Icon(
                          _showAdvanced
                              ? Icons.expand_more
                              : Icons.chevron_right,
                          size: 20,
                          color: GSColors.ink.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                  if (showAdvanced) ...[
                    const SizedBox(height: 12),
                    _fieldCard(
                      label: 'Email',
                      required: false,
                      hint: 'customer@email.com',
                      input: _textField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    _fieldCard(
                      label: 'Address',
                      required: false,
                      hint: 'Full address',
                      input: _textField(
                        controller: _addressCtrl,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  // ── Step 2: Estimate Details ─────────────────────────────────────

  Widget _buildEstimateDetails() {
    final currency = _master!.currencyByCode(_estimate.currency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EstimateSectionHeader(icon: Icons.bar_chart_rounded, title: 'Estimate Details'),

        // Estimate Number
        _fieldCard(
          label: 'Estimate Number',
          required: true,
          hint: 'e.g. EST-004',
          input: _textField(
            controller: _estimateNumberCtrl,
            onChanged: (v) => _estimate.estimateNumber = v,
          ),
        ),

        // Reference No.
        _fieldCard(
          label: 'Reference No.',
          required: false,
          hint: 'Optional',
          input: _textField(
            controller: _referenceCtrl,
            onChanged: (v) => _estimate.referenceNo = v.isNotEmpty ? v : null,
          ),
        ),

        // Expiry Date
        _fieldCard(
          label: 'Expiry Date',
          required: false,
          input: _buildDateField(),
        ),

        // Currency
        _fieldCard(
          label: 'Currency',
          required: true,
          input: _buildDropdown<String>(
            items: _master!.currencies.map((c) => c.code).toList(),
            value: _estimate.currency,
            itemLabel: (code) =>
                '${_master!.currencyByCode(code).name} (${_master!.currencyByCode(code).symbol})',
            onChanged: (v) => setState(() => _estimate.currency = v ?? 'INR'),
          ),
        ),

        // Solar System (drives capacity, pricing & panel-count image)
        _fieldCard(
          label: 'Solar System',
          required: true,
          input: GsSelectorTile(
            value: _selectedSystem?.label ?? 'Select a system',
            valueColor: _selectedSystem != null
                ? GSColors.navy900
                : GSColors.ink.withValues(alpha: 0.4),
            onTap: _openSystemSelector,
          ),
        ),

        // Panel-count design image preview (existing assets/images/solar_pannel_N.jpg)
        if (_selectedSystem != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                _selectedSystem!.panelImageAsset,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 170,
                  color: GSColors.sky100,
                  alignment: Alignment.center,
                  child: Text('Image for ${_selectedSystem!.panels} panels',
                      style: GSTextStyles.bodySmall),
                ),
              ),
            ),
          ),

        // Wiring size (manual)
        _fieldCard(
          label: 'Wiring Size',
          required: false,
          hint: 'e.g. 4',
          input: _textField(
            controller: _wiringCtrl,
            suffixText: 'sq.mm',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) =>
                _estimate.wiringSqMm = v.trim().isNotEmpty ? '${v.trim()} sq.mm' : null,
          ),
        ),

        // Inverter kW capacity (manual)
        _fieldCard(
          label: 'Inverter Capacity',
          required: false,
          hint: 'e.g. 3.6',
          input: _textField(
            controller: _inverterKwCtrl,
            suffixText: 'kW',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => _estimate.inverterKwManual = double.tryParse(v.trim()),
          ),
        ),

        // Total Payable price (manual override)
        _fieldCard(
          label: 'Total Payable',
          required: false,
          hint: _selectedSystem != null
              ? 'Default: ₹${_selectedSystem!.totalPayable}'
              : 'Auto from system',
          input: _textField(
            controller: _priceCtrl,
            prefixText: '₹ ',
            keyboardType: TextInputType.number,
            onChanged: (v) =>
                _estimate.totalPayableOverride = int.tryParse(v.trim()),
          ),
        ),

        // GST (fixed for rooftop solar: CGST 4.45% + SGST 4.45%)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: GsCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, size: 18, color: GSColors.teal500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('GST — CGST 4.45% + SGST 4.45%  (8.9% incl.)',
                      style: GSTextStyles.bodySmall.copyWith(color: GSColors.ink)),
                ),
              ],
            ),
          ),
        ),

        // Capacity (kW) — driven by the selected system
        _fieldCard(
          label: 'Capacity',
          required: false,
          input: _textField(
            controller: _capacityCtrl,
            readOnly: true,
            hint: 'Select a system above',
            suffixText: 'kW',
          ),
        ),

        // Tax mode toggle
        _fieldCard(
          label: 'Item Rates',
          required: false,
          input: GsRadioGroup(
            groupValue: _estimate.taxMode,
            onChanged: (v) =>
                setState(() => _estimate.taxMode = v ?? 'exclusive'),
            options: [
              RadioOption(label: 'Tax Exclusive', value: 'exclusive'),
              RadioOption(label: 'Tax Inclusive', value: 'inclusive'),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  // ── Step 3: Structure Details ───────────────────────────────────

  Widget _buildStructureDetails() {
    if (_master == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EstimateSectionHeader(icon: Icons.build, title: 'Structure Details'),
        ..._master!.structurePipes.map((pipe) {
          return _fieldCard(
            label: pipe.label,
            required: false,
            hint: 'Meters',
            input: _buildNumberFieldWithSuffix(
              controller: _getStructureCtrl(pipe.label),
              hint: '0',
              suffix: 'm',
              onChanged: (v) {
                final val = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                _estimate.structureQuantities[pipe.label] = val;
              },
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

   Widget _buildNumberFieldWithSuffix({
    required TextEditingController controller,
    required String hint,
    required String suffix,
    required void Function(String) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: GSInputTheme.fieldDecoration(
              hint: hint,
            ),
            style: GSTextStyles.bodyMedium.copyWith(color: GSColors.navy900),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: onChanged,
          ),
        ),
        Text(suffix,
            style: GSTextStyles.bodyMedium
                .copyWith(color: GSColors.ink.withValues(alpha: 0.6))),
      ],
    );
  }

  // ── Step 4: Financial Details ───────────────────────────────────

  Widget _buildFinancialDetails() {
    final cap = _estimate.capacityKw;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EstimateSectionHeader(icon: Icons.currency_rupee, title: 'Financial Details'),

        // Discount per KW
        _fieldCard(
          label: 'Discount per KW',
          required: false,
          hint: '0',
          input: _buildCurrencyField(
            controller: _discountCtrl,
            hint: '0',
            currencySymbol: '\u20B9',
            suffix: '/kW',
            errorText:
                (double.tryParse(_discountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0) >
                    _master!.discountCapPerKw
                ? 'Exceeds max'
                : null,
            onChanged: (v) {
              final val = double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
              _estimate.discountPerKw = val;
            },
          ),
          helperText: 'Max: \u20B9${_master!.discountCapPerKw.toInt()}/kW',
        ),

        // GST Profile
        _fieldCard(
          label: 'Tax (GSTIN)',
          required: true,
          hint: 'Select profile',
          input: _buildDropdown<String>(
            items: _master!.gstProfiles.map((g) => g.label).toList(),
            value: _estimate.gstProfileLabel.isEmpty
                ? null
                : _estimate.gstProfileLabel,
            itemLabel: (l) => l,
            onChanged: _setGstProfile,
          ),
        ),

        // Insurance toggle card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: GSColors.white,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: GSColors.ink.withValues(alpha: 0.08), width: 1),
            boxShadow: [
              BoxShadow(
                color: GSColors.shadowLight,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _toggleInsurance(!_estimate.insuranceIncluded),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Insurance',
                              style: GSTextStyles.labelMedium
                                  .copyWith(color: GSColors.navy900)),
                          Text('Click to include insurance',
                              style: GSTextStyles.bodySmall.copyWith(
                                  color:
                                      GSColors.ink.withValues(alpha: 0.5))),
                        ],
                      ),
                      Switch(
                        value: _estimate.insuranceIncluded,
                        onChanged: _toggleInsurance,
                        activeColor: GSColors.teal500,
                        activeTrackColor:
                            GSColors.teal500.withValues(alpha: 0.4),
                        inactiveThumbColor:
                            GSColors.ink.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ),
              if (_estimate.insuranceIncluded) ...[
                const SizedBox(height: 4),
                // Mode selector
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GsRadioGroup(
                    groupValue: _estimate.insuranceType,
                    onChanged: (v) => _setInsuranceType(v),
                    options: [
                      RadioOption(label: '%', value: 'percent'),
                      RadioOption(label: 'Amount', value: 'amount'),
                    ],
                  ),
                ),
                // Input fields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _estimate.insuranceType == 'percent'
                      ? _buildCurrencyField(
                          controller: _insPercentCtrl,
                          hint: '0',
                          currencySymbol: '',
                          suffix: '%',
                          onChanged: (v) {
                            final val = double.tryParse(v.replaceAll(
                                RegExp(r'[^0-9.]'), '')) ??
                                0;
                            _estimate.insurancePercent = val;
                          },
                        )
                      : _buildCurrencyField(
                          controller: _insAmountCtrl,
                          hint: '0',
                          currencySymbol: '\u20B9',
                          suffix: '',
                          onChanged: (v) {
                            final val = int.tryParse(v.replaceAll(
                                RegExp(r'[^0-9]'), '')) ??
                                0;
                            _estimate.insuranceAmount = val;
                          },
                        ),
                ),
              ],
            ],
          ),
        ),

        // System Size display
        if (cap != null) ...[
          _fieldCard(
            label: 'System Size',
            required: false,
            hint: '',
            input: _buildReadOnlyField(value: '${cap.toStringAsFixed(2)} kW'),
          ),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  // ── Shared field builders ────────────────────────────────────────

  Widget _textField({
    required TextEditingController controller,
    String? hint,
    String? prefixText,
    IconData? prefixIcon,
    String? suffixText,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    int? maxLines,
    String? errorText,
    bool readOnly = false,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: GSInputTheme.fieldDecoration(
        hint: hint,
        prefixText: prefixText,
        suffixText: suffixText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: GSColors.navy500) : null,
        suffixIcon: suffixIcon,
        errorText: errorText,
      ).copyWith(
        isDense: maxLines != null && maxLines > 1 ? false : true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines != null && maxLines > 1 ? 12 : 14,
        ),
      ),
      style: GSTextStyles.bodyMedium.copyWith(color: GSColors.navy900),
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdown<T>({
    required List<T> items,
    required T? value,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    String? hint,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        disabledColor: GSColors.ink.withValues(alpha: 0.3),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(itemLabel(e), style: GSTextStyles.bodyMedium),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: GSInputTheme.fieldDecoration(
          hint: hint ?? 'Select',
        ).copyWith(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: GSTextStyles.bodyMedium.copyWith(color: GSColors.navy900),
        icon: Icon(Icons.chevron_right,
            size: 20, color: GSColors.ink.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildDateField() {
    final formatted = DateFormat('dd MMM yyyy').format(_estimate.expiryDate);
    return TextFormField(
      decoration: GSInputTheme.fieldDecoration(
        hint: DateFormat('dd MMM yyyy').format(
          DateTime.now().add(Duration(days: _master!.expiryDays)),
        ),
        prefixIcon: const Icon(Icons.calendar_today,
            size: 20, color: GSColors.navy500),
      ),
      style: GSTextStyles.bodyMedium.copyWith(color: GSColors.navy900),
      readOnly: true,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _estimate.expiryDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() => _estimate.expiryDate = picked);
        }
      },
      controller: TextEditingController(text: formatted),
    );
  }

  Widget _buildCurrencyField({
    required TextEditingController controller,
    required String hint,
    required String currencySymbol,
    required String suffix,
    String? errorText,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: GSInputTheme.fieldDecoration(
        hint: hint,
        prefixText: currencySymbol.isNotEmpty ? '$currencySymbol ' : null,
        suffixText: suffix,
        errorText: errorText,
      ),
      style: GSTextStyles.bodyMedium.copyWith(color: GSColors.navy900),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
    );
  }

  Widget _buildReadOnlyField({required String value}) {
   return Container(
     width: double.infinity,
     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
     decoration: BoxDecoration(
       color: GSColors.pageBg,
       borderRadius: BorderRadius.circular(GSInputTheme.fieldBorderRadius),
       border: Border.all(color: GSColors.ink.withValues(alpha: 0.15)),
     ),
     child: Text(
       value,
       style: GSTextStyles.bodyMedium.copyWith(color: GSColors.navy900),
     ),
   );
  }

  // ── Field card wrapper ──

  Widget _fieldCard({
    required String label,
    required bool required,
    String? hint,
    required Widget input,
    String? helperText,
    String? errorText,
  }) {
    return GsInputCard(
      label: label,
      required: required,
      input: input,
      helperText: helperText,
      errorText: errorText,
    );
  }

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}
