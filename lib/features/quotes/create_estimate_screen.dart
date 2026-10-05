/// ---------------------------------------------------------------------------
/// Create Quotation — single-page form matching the Stitch
/// "Global Solar 2.0 - Create Quotation Mobile Screen" design.
///
///   • Lead Details            (customer identification & pipeline stage)
///   • Solar System Config     (package, panel image, pricing, GST mode)
///   • Additional Line Items   (custom charges)
///   • Fixed bottom action     (Create Quotation → PDF preview)
///
/// State is held in the [EstimateModel]. Master data is loaded from
/// `assets/data/estimate_master.json`.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/searchable_selector_sheet.dart';
import '../../models/estimate.dart';
import '../../providers/data_hub.dart';
import 'quotation_preview_screen.dart';

// ── Design tokens (Stitch) ──
const _navyDark = Color(0xFF071440);
const _navy = Color(0xFF0B1F5C);
const _gold = Color(0xFFF9B417);
const _goldLight = Color(0xFFFFCA40);
const _goldHover = Color(0xFFD9980B);
const _bgSky = Color(0xFFEAF4FF);
const _skyField = Color(0xFFE2EFFF);
const _labelMuted = Color(0xFF627193);
const _borderSky = Color(0xFFD0E3F8);

TextStyle _t(double size, FontWeight w, Color c,
        {double? ls, double? h}) =>
    TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: size,
        fontWeight: w,
        color: c,
        letterSpacing: ls,
        height: h);

TextStyle _th(double size, FontWeight w, Color c, {double? ls}) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: size,
    fontWeight: w,
    color: c,
    letterSpacing: ls);

class CreateEstimateScreen extends StatefulWidget {
  const CreateEstimateScreen({super.key});

  @override
  State<CreateEstimateScreen> createState() => _CreateEstimateScreenState();
}

class _CreateEstimateScreenState extends State<CreateEstimateScreen> {
  // ── Master data (loaded async from JSON) ──
  MasterData? _master;
  bool _ready = false;
  String? _loadError;

  final EstimateModel _estimate = EstimateModel();

  // ── Controllers ──
  final _companyCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _estimateNumberCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _wiringCtrl = TextEditingController();
  final _inverterKwCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _structureCostCtrl = TextEditingController();
  final _stampCtrl = TextEditingController();

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
    _descriptionCtrl.dispose();
    _estimateNumberCtrl.dispose();
    _capacityCtrl.dispose();
    _wiringCtrl.dispose();
    _inverterKwCtrl.dispose();
    _priceCtrl.dispose();
    _structureCostCtrl.dispose();
    _stampCtrl.dispose();
    super.dispose();
  }

  // ── Master data loading ────────────────────────────────────────────────

  Future<void> _loadMaster() async {
    _loadError = null;
    final hub = context.read<DataHub>();
    try {
      final master = await MasterData.load();

      _estimate.estimateNumber = EstimateModel.generateNumber(
          master.estimateNumberPrefix, hub.estimateCount);
      _estimateNumberCtrl.text = _estimate.estimateNumber;
      _estimate.currency = master.defaultCurrency;
      _estimate.leadStage = master.defaultLeadStage;
      _estimate.expiryDate =
          DateTime.now().add(Duration(days: master.expiryDays));
      _estimate.gstProfileLabel =
          master.gstProfiles.isNotEmpty ? master.gstProfiles.last.label : '';
      _estimate.bomLines = master.bosItems
          .map((b) => BomLine(
                name: b.name,
                qty: b.qty,
                unit: b.unit,
                brand: _autoBrand(b.name),
              ))
          .toList();

      if (!mounted) return;
      setState(() {
        _master = master;
        _ready = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ready = false;
        _loadError = e.toString();
      });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  bool get _leadDone =>
      _nameCtrl.text.trim().isNotEmpty && _mobileCtrl.text.trim().length >= 10;

  bool get _systemDone => _estimate.systemId != null;

  double get _progress => _systemDone ? 1.0 : (_leadDone ? 0.65 : 0.0);

  String _inr(num v) =>
      NumberFormat.decimalPattern('en_IN').format(v.round());

  GSQuoteSystem? get _selectedSystem => _estimate.systemId != null
      ? gsQuoteSystemById(_estimate.systemId!)
      : null;

  void _selectSystem(GSQuoteSystem s) {
    setState(() {
      _estimate.systemId = s.id;
      _estimate.capacityKw = s.kw;
      _capacityCtrl.text = s.kw.toStringAsFixed(2);
      _estimate.structureCostOverride = s.structureCost;
      _estimate.stampChargeOverride = s.stampCharge;
      _structureCostCtrl.text = s.structureCost.toString();
      _stampCtrl.text = s.stampCharge.toString();
      _estimate.totalPayableOverride = s.totalPayable;
      _priceCtrl.text = s.totalPayable.toString();
      if (_inverterKwCtrl.text.trim().isEmpty) {
        _inverterKwCtrl.text = (s.kw + 0.64).toStringAsFixed(1);
        _estimate.inverterKwManual = double.tryParse(_inverterKwCtrl.text);
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Select Solar System',
                  textAlign: TextAlign.center, style: _th(18, FontWeight.w700, _navy)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: gsQuoteSystems
                    .map((s) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _bgSky,
                            child: Text('${s.panels}',
                                style: _th(13, FontWeight.w700, _navy)),
                          ),
                          title: Text(s.label,
                              style: _t(14, FontWeight.w700, _navy)),
                          subtitle: Text(
                              'After subsidy Rs.${_inr(s.afterSubsidy)}',
                              style: _t(12, FontWeight.w500, _labelMuted)),
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

  void _addCustomLineItem() {
    final descCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final rateCtrl = TextEditingController();
    final gstCtrl = TextEditingController(text: '8.9');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Line Item', style: _th(18, FontWeight.w700, _navy)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g. Extra wiring / civil work'),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Qty'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: rateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rate (Rs.)'),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: gstCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'GST % (total)', hintText: 'e.g. 8.9'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _gold, foregroundColor: _navyDark),
            onPressed: () {
              final desc = descCtrl.text.trim();
              if (desc.isEmpty) return;
              final qty = int.tryParse(qtyCtrl.text) ?? 1;
              final rate = int.tryParse(
                      rateCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                  0;
              final gst = double.tryParse(gstCtrl.text) ?? 8.9;
              setState(() {
                _estimate.lineItems.add(EstimateLineItem(
                  description: desc,
                  qty: qty,
                  rate: rate,
                  cgstPercent: gst / 2,
                  sgstPercent: gst / 2,
                ));
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ── Save ───────────────────────────────────────────────────────────────

  bool _validate() {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Client name is required');
      return false;
    }
    if (_mobileCtrl.text.trim().length < 10) {
      _snack('Valid 10-digit mobile number is required');
      return false;
    }
    if (_estimate.clientType == 'business' &&
        _companyCtrl.text.trim().isEmpty) {
      _snack('Company name is required');
      return false;
    }
    if (_estimate.systemId == null) {
      _snack('Please select a solar system');
      return false;
    }
    return true;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _saveEstimate() async {
    if (!_validate()) return;
    final hub = context.read<DataHub>();

    _estimate
      ..companyName = _companyCtrl.text.trim().isEmpty
          ? null
          : _companyCtrl.text.trim()
      ..leadName = _nameCtrl.text.trim()
      ..mobileNumber = _mobileCtrl.text.trim()
      ..description = _descriptionCtrl.text.trim().isNotEmpty
          ? _descriptionCtrl.text.trim()
          : null
      ..estimateNumber = _estimateNumberCtrl.text.trim()
      ..capacityKw = double.tryParse(_capacityCtrl.text);

    late EstimateRecord record;
    try {
      record = await hub.addEstimate(_estimate);
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to save estimate: $e');
      return;
    }
    if (!mounted) return;

    Navigator.of(context).popUntil((r) => r.isFirst);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            QuotationPreviewScreen(record: record, master: _master!),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_ready) return _loadingScaffold();

    return Scaffold(
      backgroundColor: _bgSky,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _leadCard(),
                  _systemCard(),
                  _bomCard(),
                  _lineItemsCard(),
                  _trustNote(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _loadingScaffold() {
    return Scaffold(
      backgroundColor: _bgSky,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('CREATE QUOTATION', style: _th(18, FontWeight.w700, Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: _loadError != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: GSColors.statusNew),
                  const SizedBox(height: 16),
                  Text('Failed to load quotation data.',
                      style: _t(15, FontWeight.w600, _navy)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadMaster,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _navy, foregroundColor: Colors.white),
                  ),
                ],
              )
            : const CircularProgressIndicator(color: _gold),
      ),
    );
  }

  // ── Header ──

  Widget _header() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF071440), Color(0xFF0B1E58), Color(0xFF0B1F5C)],
        ),
        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 8)],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 24,
            top: -40,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                      color: _gold.withValues(alpha: 0.15), blurRadius: 60),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 10, 20, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    _circleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Create Quotation',
                                  style: _th(20, FontWeight.w700, Colors.white,
                                      ls: -0.3)),
                              const SizedBox(width: 6),
                              _pulseDot(),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('PM Surya Ghar 2.0',
                              style: _t(12, FontWeight.w500,
                                  const Color(0xFFBFD8F5))),
                        ],
                      ),
                    ),
                    _circleButton(
                      icon: Icons.bookmark_border_rounded,
                      gold: true,
                      onTap: _saveEstimate,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _progressBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pulseDot() => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _gold,
          boxShadow: [
            BoxShadow(color: _gold.withValues(alpha: 0.8), blurRadius: 8),
          ],
        ),
      );

  Widget _circleButton(
      {required IconData icon, required VoidCallback onTap, bool gold = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: gold
            ? const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [_gold, _goldLight],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight),
              )
            : BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
        child: Icon(icon,
            size: gold ? 20 : 22, color: gold ? _navyDark : Colors.white),
      ),
    );
  }

  Widget _progressBar() {
    final step1Done = _leadDone;
    final step2Done = _systemDone;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              _stepBadge('1', active: step1Done),
              const SizedBox(width: 6),
              Text('Step 1: Lead Details',
                  style: step1Done
                      ? _t(11, FontWeight.w700, _goldLight, ls: 0.4)
                      : _t(11, FontWeight.w600,
                          Colors.white.withValues(alpha: 0.7), ls: 0.4)),
            ]),
            Row(children: [
              _stepBadge('2', active: step2Done),
              const SizedBox(width: 6),
              Text('Step 2: Solar System',
                  style: step2Done
                      ? _t(11, FontWeight.w700, _goldLight, ls: 0.4)
                      : _t(11, FontWeight.w600,
                          Colors.white.withValues(alpha: 0.7), ls: 0.4)),
            ]),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: _progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_gold, _goldLight, _gold]),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                        color: _gold.withValues(alpha: 0.7), blurRadius: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepBadge(String n, {required bool active}) => Container(
        width: 16,
        height: 16,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? _gold : Colors.white.withValues(alpha: 0.2),
        ),
        child: Text(n,
            style: _th(10, FontWeight.w800,
                active ? _navyDark : Colors.white.withValues(alpha: 0.9))),
      );

  // ── Card 1: Lead Details ──

  Widget _leadCard() {
    final stage = _master!.stageById(_estimate.leadStage);
    final isIndividual = _estimate.clientType == 'individual';
    return _card(
      children: [
        _sectionHeader(
          icon: Icons.person_outline,
          title: 'Lead Details',
          subtitle: 'Customer identification & pipeline stage',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF3),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0xFFA6F4C5)),
            ),
            child: Row(children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFF12B76A))),
              const SizedBox(width: 5),
              Text('VERIFIED LEAD',
                  style: _t(9, FontWeight.w700, const Color(0xFF067647),
                      ls: 0.6)),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        _lbl('Customer Category'),
        _segmented(
          children: [
            _segmentButton(
              label: 'Individual (Home)',
              icon: Icons.person,
              selected: isIndividual,
              onTap: () => setState(() => _estimate.clientType = 'individual'),
            ),
            _segmentButton(
              label: 'Business / C&I',
              icon: Icons.business,
              selected: !isIndividual,
              onTap: () => setState(() => _estimate.clientType = 'business'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (!isIndividual) ...[
          _lbl('Company Name', required: true),
          _field(
            controller: _companyCtrl,
            icon: Icons.business_center_outlined,
            hint: 'e.g. Priya & Co.',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
        ],
        _lbl('Client Full Name', required: true),
        _field(
          controller: _nameCtrl,
          icon: Icons.person_outline,
          hint: "Enter client's legal name",
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _lbl('Mobile Contact', required: true),
        _field(
          controller: _mobileCtrl,
          icon: Icons.phone_outlined,
          prefixText: '+91',
          hint: '10-digit number',
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _lbl('Lead Pipeline Stage'),
        GestureDetector(
          onTap: _openLeadStageSelector,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _bgSky,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderSky),
            ),
            child: Row(children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hexToColor(stage.dotColorHex),
                      boxShadow: [
                        BoxShadow(
                            color: _hexToColor(stage.dotColorHex)
                                .withValues(alpha: 0.6),
                            blurRadius: 6),
                      ])),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(stage.label,
                      style: _t(14, FontWeight.w600, _navy))),
              const Icon(Icons.expand_more, size: 18, color: _labelMuted),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        _lbl('Requirement & Site Notes'),
        _field(
          controller: _descriptionCtrl,
          icon: Icons.edit_outlined,
          hint: 'e.g. 3-phase connection, elevated walkway framing desired.',
          maxLines: 3,
        ),
      ],
    );
  }

  // ── Card 2: Solar System Configuration ──

  Widget _systemCard() {
    final s = _selectedSystem;
    final panels = s?.panels ?? 0;
    final cols = panels == 0 ? 0 : ((panels + 1) ~/ 2);
    return _card(
      children: [
        _sectionHeader(
          icon: Icons.wb_sunny_outlined,
          title: 'Solar System Configuration',
          subtitle: 'Tier-1 Hardware & Turnkey Pricing',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: _gold.withValues(alpha: 0.3)),
            ),
            child: Text('Adani TOPCon',
                style: _t(10, FontWeight.w700, const Color(0xFF8A5A00))),
          ),
        ),
        const SizedBox(height: 14),
        _lbl('Selected Package'),
        GestureDetector(
          onTap: _openSystemSelector,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_bgSky, Colors.white],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _navy.withValues(alpha: 0.2), width: 2),
            ),
            child: Row(children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: _navy, borderRadius: BorderRadius.circular(12)),
                child: Text(
                    s == null ? '—' : '${s.kw.toStringAsFixed(2)}k',
                    style: _th(13, FontWeight.w800, _gold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s?.label ?? 'Select a package',
                        style: _th(15, FontWeight.w800, _navy)),
                    const SizedBox(height: 2),
                    Text(
                      s == null
                          ? 'Tap to choose capacity'
                          : 'Adani TOPCon ${s.panelWatt}Wp Bifacial  •  Rs.${_inr(s.subsidy)} Subsidy',
                      style: _t(11, FontWeight.w500, _labelMuted),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: _bgSky, borderRadius: BorderRadius.circular(99)),
                child: const Icon(Icons.expand_more, size: 18, color: _navy),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        if (s != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.asset(
                  s.panelImageAsset,
                  height: 128,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 128,
                    color: _navyDark,
                    alignment: Alignment.center,
                    child: Text('${s.panels}-panel array',
                        style: _t(12, FontWeight.w600, Colors.white70)),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          _navyDark.withValues(alpha: 0.9),
                          _navyDark.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _imgBadge(
                      '3D Roof Simulation • $panels Panels (2×$cols Array)'),
                ),
                if (_estimate.structureCostOverride != null)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _navyDark.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: _gold.withValues(alpha: 0.4)),
                      ),
                      child: Text('Elevated GI Frame (8.5ft)',
                          style: _t(11, FontWeight.w700, _goldLight)),
                    ),
                  ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Text('Orientation: South (Azimuth 180° • Tilt 22°)',
                      style: _t(10, FontWeight.w500,
                          Colors.white.withValues(alpha: 0.9))),
                ),
              ],
            ),
          ),
        if (s == null)
          Container(
            height: 110,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _bgSky,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderSky),
            ),
            child: Text('Select a package to preview the array design',
                style: _t(12, FontWeight.w500, _labelMuted)),
          ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lbl('DC Capacity'),
                _field(
                  controller: _capacityCtrl,
                  readOnly: true,
                  suffixText: 'kW',
                  hint: '—',
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lbl('Inverter Rating'),
                _field(
                  controller: _inverterKwCtrl,
                  suffixText: 'kW',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) =>
                      _estimate.inverterKwManual = double.tryParse(v.trim()),
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 12),
        _lbl('AC / DC Wiring Size'),
        _field(
          controller: _wiringCtrl,
          suffixText: 'sq.mm',
          hint: '4.0 UV Tinned Copper',
          onChanged: (v) => _estimate.wiringSqMm =
              v.trim().isNotEmpty ? '${v.trim()} sq.mm' : null,
        ),
        const SizedBox(height: 14),
        _totalPayableBanner(s),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lbl('Structure Cost'),
                _field(
                  controller: _structureCostCtrl,
                  prefixText: 'Rs.',
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _estimate.structureCostOverride =
                      int.tryParse(v.trim()),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lbl('Stamp & Franking'),
                _field(
                  controller: _stampCtrl,
                  prefixText: 'Rs.',
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _estimate.stampChargeOverride =
                      int.tryParse(v.trim()),
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 14),
        _lbl('Tax Calculation Mode'),
        _segmented(children: [
          _segmentButton(
            label: 'With GST (8.9% Composite)',
            icon: Icons.check,
            selected: _estimate.gstIncluded,
            onTap: () => setState(() => _estimate.gstIncluded = true),
          ),
          _segmentButton(
            label: 'Without GST (Ex-tax)',
            selected: !_estimate.gstIncluded,
            onTap: () => setState(() => _estimate.gstIncluded = false),
          ),
        ]),
      ],
    );
  }

  Widget _imgBadge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _navyDark.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  const BoxDecoration(shape: BoxShape.circle, color: _gold)),
          const SizedBox(width: 6),
          Text(text, style: _th(11, FontWeight.w700, Colors.white)),
        ]),
      );

  Widget _totalPayableBanner(GSQuoteSystem? s) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_bgSky, Color(0xFFE2EFFF), _bgSky],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _navy.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('TOTAL PAYABLE (CLIENT SHARE)',
                    style: _t(11, FontWeight.w700, _navy, ls: 0.5)),
              ),
              if (s != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFFD1FADF),
                      borderRadius: BorderRadius.circular(99)),
                  child: Text('After Subsidy Rs.${_inr(s.afterSubsidy)}',
                      style: _t(10, FontWeight.w700, const Color(0xFF067647))),
                ),
            ],
          ),
          const SizedBox(height: 6),
          _field(
            controller: _priceCtrl,
            prefixText: 'Rs.',
            bold: true,
            big: true,
            keyboardType: TextInputType.number,
            hint: s != null ? '${s.totalPayable}' : 'Auto from package',
            onChanged: (v) => _estimate.totalPayableOverride =
                int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  s != null
                      ? 'Gross Turnkey: Rs.${_inr(s.totalPayable)}'
                      : 'Incl. GST 8.9%',
                  style: _t(11, FontWeight.w500, _labelMuted)),
              Text('Net Net Cost',
                  style: _t(11, FontWeight.w700, _navy)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Card 3: Additional Line Items ──

  // ── Card 3: Bill of Materials ──

  Widget _bomCard() {
    final lines = _estimate.bomLines;
    return _card(children: [
      _sectionHeader(
        icon: Icons.inventory_2_outlined,
        title: 'Bill of Materials',
        subtitle: 'Choose materials & quantities used in the quotation',
        trailing: GestureDetector(
          onTap: _addBomMaterial,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_gold, _goldLight]),
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(color: _gold.withValues(alpha: 0.4), blurRadius: 8),
              ],
            ),
            child: Row(children: [
              const Icon(Icons.add, size: 16, color: _navyDark),
              const SizedBox(width: 4),
              Text('Add Material', style: _th(12, FontWeight.w800, _navyDark)),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _bgSky.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderSky),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info, size: 16, color: _gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Set the quantity for each material. Unit is detected automatically; brand is pre-filled and can be set when adding a new material.',
              style: _t(11, FontWeight.w500, _labelMuted, h: 1.4),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      if (lines.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text('No materials yet — tap "Add Material".',
              style: _t(12, FontWeight.w500, _labelMuted)),
        )
      else
        ...lines.asMap().entries.map((e) => _bomRow(e.value, e.key)),
    ]);
  }

  Widget _bomRow(BomLine l, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bgSky.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderSky.withValues(alpha: 0.9)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.name, style: _th(13, FontWeight.w700, _navy)),
              const SizedBox(height: 2),
              Text(
                '${l.unit}  •  ${l.brand.trim().isEmpty ? 'As per standard' : l.brand}',
                style: _t(11, FontWeight.w500, _labelMuted),
              ),
            ],
          ),
        ),
        _qtyBtn(Icons.remove_rounded, () {
          if (l.qty > 1) setState(() => l.qty--);
        }),
        SizedBox(
          width: 34,
          child: Text('${l.qty}',
              textAlign: TextAlign.center,
              style: _t(14, FontWeight.w700, _navy)),
        ),
        _qtyBtn(Icons.add_rounded, () => setState(() => l.qty++)),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => setState(() => _estimate.bomLines.removeAt(index)),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3F2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFECDCA)),
            ),
            child: const Icon(Icons.delete_outline,
                size: 16, color: Color(0xFFF04438)),
          ),
        ),
      ]),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _borderSky),
          ),
          child: Icon(icon, size: 16, color: _navy),
        ),
      );

  void _addBomMaterial() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final brandCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Material', style: _th(18, FontWeight.w700, _navy)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Material name',
                  hintText: 'e.g. DC Cable 6 sq.mm'),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: brandCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Brand', hintText: 'e.g. POLYCAB'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Unit is added automatically.',
                  style: _t(11, FontWeight.w500, _labelMuted)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _gold, foregroundColor: _navyDark),
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
              setState(() {
                _estimate.bomLines.add(BomLine(
                  name: name,
                  qty: qty < 1 ? 1 : qty,
                  unit: _unitFor(name),
                  brand: brandCtrl.text.trim(),
                ));
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  static String _unitFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('cable') ||
        n.contains('wire') ||
        n.contains('conductor') ||
        n.contains('mtr')) {
      return 'mtr';
    }
    if (n.contains('registration') ||
        n.contains('application') ||
        n.contains('net meter')) {
      return 'set';
    }
    if (n.contains('structure') ||
        n.contains('pipe') ||
        n.contains('frame') ||
        n.contains('channel')) {
      return 'Set';
    }
    return 'Nos';
  }

  static String _autoBrand(String name) {
    final n = name.toLowerCase();
    if (n.contains('cable') || n.contains('wire') || n.contains('mc4')) {
      return 'POLYCAB';
    }
    if (n.contains('earthing')) return 'Copper Bonded';
    if (n.contains('net meter')) return 'PGVCL';
    if (n.contains('geda')) return 'GEDA';
    return '';
  }

  Widget _lineItemsCard() {
    return _card(
      children: [
        _sectionHeader(
          icon: Icons.receipt_long_outlined,
          title: 'Additional Line Items',
          subtitle: 'Extra civil, electrical or bespoke charges',
          trailing: GestureDetector(
            onTap: _addCustomLineItem,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient:
                    const LinearGradient(colors: [_gold, _goldLight]),
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                      color: _gold.withValues(alpha: 0.4), blurRadius: 8),
                ],
              ),
              child: Row(children: [
                const Icon(Icons.add, size: 16, color: _navyDark),
                const SizedBox(width: 4),
                Text('Add Item',
                    style: _th(12, FontWeight.w800, _navyDark)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _bgSky.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderSky),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info, size: 16, color: _gold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Structure, Stamp & Subsidy are added automatically. Add any extra charge or customer-specific site accessories here.',
                style: _t(11, FontWeight.w500, _labelMuted, h: 1.4),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        if (_estimate.lineItems.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text('No extra items yet — tap "Add Item" above.',
                style: _t(12, FontWeight.w500, _labelMuted)),
          )
        else
          ..._estimate.lineItems
              .asMap()
              .entries
              .map((e) => _lineRow(e.value, e.key)),
      ],
    );
  }

  Widget _lineRow(EstimateLineItem item, int index) {
    final gst = item.cgstPercent + item.sgstPercent;
    final g = gst == gst.roundToDouble()
        ? gst.toInt().toString()
        : gst.toStringAsFixed(2);
    final amount = (item.qty * item.rate * (1 + gst / 100)).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bgSky.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderSky.withValues(alpha: 0.9)),
      ),
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _borderSky),
          ),
          child: Text('${index + 1}',
              style: _t(11, FontWeight.w700, _labelMuted)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.description,
                  style: _th(13, FontWeight.w700, _navy)),
              const SizedBox(height: 2),
              Text('${item.qty} × Rs.${item.rate} • GST $g%',
                  style: _t(11, FontWeight.w500, _labelMuted)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('Rs.${_inr(amount)}',
            style: _t(13, FontWeight.w800, _navy)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => _estimate.lineItems.removeAt(index)),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3F2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFECDCA)),
            ),
            child: const Icon(Icons.delete_outline,
                size: 16, color: Color(0xFFF04438)),
          ),
        ),
      ]),
    );
  }

  Widget _trustNote() => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_outlined,
                size: 14, color: GSColors.green600),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'PGVCL Net-metering & 30-Year Performance Warranty Guaranteed',
                textAlign: TextAlign.center,
                style: _t(11, FontWeight.w600, _labelMuted),
              ),
            ),
          ],
        ),
      );

  // ── Bottom action bar ──

  Widget _bottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        border:
            Border(top: BorderSide(color: _borderSky.withValues(alpha: 0.9))),
        boxShadow: [
          BoxShadow(
              color: _navy.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, -8)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _saveEstimate,
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_gold, _goldLight, _goldHover]),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: _goldLight.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                          color: _gold.withValues(alpha: 0.45),
                          blurRadius: 24,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 22, color: _navyDark),
                      const SizedBox(width: 8),
                      Text('Create Quotation',
                          style: _th(15, FontWeight.w800, _navyDark,
                              ls: -0.2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Prices last updated ${GSTax.pricesLastUpdated}  •  Gujarat Discom Tariff Verified',
                style: _t(11, FontWeight.w500, _labelMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared building blocks ──

  Widget _card({required List<Widget> children}) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
                color: _navy.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4),
            BoxShadow(
                color: _navy.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) =>
      Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _bgSky,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _skyField),
            ),
            child: Icon(icon, size: 19, color: _navy),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _th(16, FontWeight.w700, _navy)),
                const SizedBox(height: 2),
                Text(subtitle, style: _t(11, FontWeight.w500, _labelMuted)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      );

  Widget _lbl(String s, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text.rich(
          TextSpan(
            text: s.toUpperCase(),
            style: _t(11, FontWeight.w700, _labelMuted, ls: 0.6),
            children: [
              if (required)
                TextSpan(
                    text: ' *',
                    style: _t(11, FontWeight.w700, const Color(0xFFF43F5E))),
            ],
          ),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    IconData? icon,
    String? hint,
    String? prefixText,
    String? suffixText,
    bool readOnly = false,
    bool bold = false,
    bool big = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      textAlignVertical:
          maxLines > 1 ? TextAlignVertical.top : TextAlignVertical.center,
      style: big
          ? _th(18, FontWeight.w800, _navy)
          : _t(14, bold ? FontWeight.w700 : FontWeight.w500, _navy),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _t(14, FontWeight.w500, _labelMuted.withValues(alpha: 0.7)),
        prefixIcon: icon == null
            ? null
            : (maxLines > 1
                ? Padding(
                    padding: const EdgeInsets.only(top: 13, left: 14),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Icon(icon,
                          size: 20, color: _navy.withValues(alpha: 0.6)),
                    ),
                  )
                : Icon(icon, size: 20, color: _navy.withValues(alpha: 0.6))),
        prefixIconConstraints: const BoxConstraints(minWidth: 46),
        prefixText: prefixText,
        prefixStyle: _t(13, FontWeight.w700, _navy, ls: 0.5),
        suffixText: suffixText,
        suffixStyle: _t(12, FontWeight.w700, _labelMuted),
        filled: true,
        fillColor: readOnly ? _bgSky.withValues(alpha: 0.7) : _bgSky,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _navy, width: 1.2)),
      ),
    );
  }

  Widget _segmented({required List<Widget> children}) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _bgSky,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderSky.withValues(alpha: 0.8)),
        ),
        child: Row(children: children),
      );

  Widget _segmentButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(colors: [_gold, _goldLight])
                  : null,
              color: selected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: _gold.withValues(alpha: 0.3), blurRadius: 6)
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      size: 14,
                      color: selected ? _navyDark : _labelMuted),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: _t(12,
                          selected ? FontWeight.w800 : FontWeight.w600,
                          selected ? _navyDark : _labelMuted)),
                ),
              ],
            ),
          ),
        ),
      );

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    final v = int.tryParse(h, radix: 16) ?? 0x999999;
    return Color(0xFF000000 | v);
  }
}
