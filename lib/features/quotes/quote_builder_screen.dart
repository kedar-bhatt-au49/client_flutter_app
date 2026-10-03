import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../models/client.dart';
import '../../models/proposal_data.dart';
import '../../models/quote.dart';
import '../../providers/data_hub.dart';
import '../../services/proposal_pdf.dart';

/// Quote builder — select a package, see prices, save & share (exact design).
class QuoteBuilderScreen extends StatefulWidget {
  final ClientModel? client;
  final QuoteModel? existing;

  const QuoteBuilderScreen({super.key, this.client, this.existing});

  @override
  State<QuoteBuilderScreen> createState() => _QuoteBuilderScreenState();
}

class _QuoteBuilderScreenState extends State<QuoteBuilderScreen> {
  static const _gold = Color(0xFFF9B417);
  static const _goldLight = Color(0xFFFFCA40);
  static const _goldDark = Color(0xFFD9980B);
  static const _navy = Color(0xFF071440);
  static const _navyDeep = Color(0xFF0B1F5C);
  static const _sky = Color(0xFFEAF4FF);
  static const _skyBorder = Color(0xFFDBEAFE);
  static const _slate = Color(0xFF627193);
  static const _dark = Color(0xFF0F1B3D);
  static const _green = Color(0xFF1E8E3E);

  String _selectedPackageId = 'p3';
  bool _residential = true;
  String _status = 'draft';
  bool _loading = false;
  final _notesController = TextEditingController(
    text: 'Free site survey • Installation in 7 days • 1-year service support included.',
  );
  // Admin-editable overrides
  final _dcCableSpecsController = TextEditingController(text: '4 sq.mm');
  final _acWireSpecsController = TextEditingController(text: '2.5 sq.mm');
  final _earthingWireSpecsController = TextEditingController(text: '2.5 sq.mm');
  final _inverterKwController = TextEditingController(text: '3.6 kW');
  final _customPriceController = TextEditingController();

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

  @override
  void dispose() {
    _notesController.dispose();
    _dcCableSpecsController.dispose();
    _acWireSpecsController.dispose();
    _earthingWireSpecsController.dispose();
    _inverterKwController.dispose();
    _customPriceController.dispose();
    super.dispose();
  }

  GSPackage get _pkg => gsPackageById(_selectedPackageId) ?? gsPackages.first;
  bool get _isEdit => widget.existing != null;

  int get _effectiveUpfront =>
      _customPriceController.text.trim().isNotEmpty
          ? int.tryParse(_customPriceController.text.trim()) ?? _pkg.upfront
          : _pkg.upfront;

  int get _effectiveSubsidy => _residential ? GSTax.subsidyMax : 0;
  int get _afterSubsidy => _effectiveUpfront - _effectiveSubsidy;
  int get _grandTotal => _effectiveUpfront + GSTax.stampCharge;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _sky,
      body: Column(
        children: [
          // ── 1. Header ─────────────────────────────────────────
          _buildHeader(context),
          // ── 2. Scrollable content ─────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildContextBanner(),
                  const SizedBox(height: 14),
                  _buildPackageSelector(),
                  const SizedBox(height: 14),
                  _buildPropertyType(),
                  const SizedBox(height: 14),
                  _buildBreakdown(),
                  const SizedBox(height: 14),
                  _buildAdvancedSpecs(),
                  const SizedBox(height: 14),
                  _buildNotes(),
                  const SizedBox(height: 10),
                  _buildTrustBadges(),
                ],
              ),
            ),
          ),
          // ── 8. Fixed bottom bar ───────────────────────────────
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_navy, Color(0xFF091A4E), _navyDeep],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              // Back
              InkWell(
                onTap: () => Navigator.pop(context),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.chevron_left_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
              // Title
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Create Quote',
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.4)),
                        const SizedBox(width: 6),
                        _PulseDot(),
                      ],
                    ),
                    const Text('PM Surya Ghar 2.0',
                        style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xE6D6E6FF))),
                  ],
                ),
              ),
              // Share (gold circle)
              InkWell(
                onTap: _shareToWhatsApp,
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
                      BoxShadow(color: _gold.withValues(alpha: 0.35), blurRadius: 18),
                    ],
                  ),
                  child: const Icon(Icons.share_rounded, color: _navy, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Context banner ─────────────────────────────────────────────
  Widget _buildContextBanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white),
              ),
              child: Row(
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
                  const Text('New Lead — ₹ Budget',
                      style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _slate)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x99BFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 13, color: Color(0xFF1D4ED8)),
                  SizedBox(width: 4),
                  Text('Adani TOPCon 575Wp',
                      style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D4ED8))),
                ],
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4, left: 2),
          child: Text('Set the quote and share instantly.',
              style: TextStyle(fontSize: 12, color: _slate)),
        ),
      ],
    );
  }

  // ── Package selector ───────────────────────────────────────────
  Widget _buildPackageSelector() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(
            icon: Icons.solar_power_rounded,
            title: 'Select System Package',
            right: const Text('6 sizes',
                style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _slate)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: gsPackages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _packageCard(gsPackages[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _packageCard(GSPackage pkg) {
    final selected = _selectedPackageId == pkg.id;
    final tag = pkg.tag;

    return InkWell(
      onTap: () => setState(() => _selectedPackageId = pkg.id),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 152,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _gold : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: _gold.withValues(alpha: 0.22), blurRadius: 16)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: tag != null && tag.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: pkg.id == 'p5'
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(tag,
                              style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: pkg.id == 'p5'
                                      ? const Color(0xFF1D4ED8)
                                      : const Color(0xFF78350F))),
                        )
                      : const SizedBox(height: 18),
                ),
                if (selected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _gold,
                    ),
                    child: const Icon(Icons.check_rounded, size: 14, color: _navy),
                  ),
              ],
            ),
            Text('${pkg.kw} kW',
                style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _navy)),
            Text('${pkg.panels} panels',
                style: const TextStyle(
                    fontFamily: 'PlusJakartaSans', fontSize: 11, color: _slate)),
            const SizedBox(height: 6),
            Container(
              height: 1,
              color: selected
                  ? const Color(0xFFFEF3C7)
                  : const Color(0xFFF1F5F9),
            ),
            const SizedBox(height: 6),
            Text('₹${pkg.upfront.formatWithComma()}',
                style: TextStyle(
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: _slate.withValues(alpha: 0.8),
                    color: _slate.withValues(alpha: 0.8))),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('₹${pkg.afterSubsidy.formatWithComma()}',
                    style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _green)),
                const SizedBox(width: 3),
                const Text('after',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600, color: _green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Property type toggle ───────────────────────────────────────
  Widget _buildPropertyType() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _iconTile(Icons.storefront_rounded),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Property Type',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _dark)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFD1FAE5)),
                ),
                child: const Text('PM Surya Ghar subsidy',
                    style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _green)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _typeToggle(
                  label: 'Residential',
                  icon: Icons.home_rounded,
                  active: _residential,
                  onTap: () => setState(() => _residential = true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _typeToggle(
                  label: 'Commercial',
                  icon: Icons.store_rounded,
                  active: !_residential,
                  onTap: () => setState(() => _residential = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xE6ECFDF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xCCD1FAE5)),
            ),
            child: Row(
              children: [
                Icon(
                  _residential
                      ? Icons.eco_rounded
                      : Icons.warning_amber_rounded,
                  size: 16,
                  color: _residential ? _green : const Color(0xFFEA580C),
                ),
                const SizedBox(width: 8),
                Text(
                  _residential
                      ? 'Subsidy ₹78,000 applies (PM Surya Ghar)'
                      : 'Subsidy not applicable for commercial',
                  style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _residential ? _green : const Color(0xFFEA580C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeToggle({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: active ? _navyDeep : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: active ? _navyDeep : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18, color: active ? _gold : _slate),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? Colors.white : _slate)),
          ],
        ),
      ),
    );
  }

  // ── Quote breakdown ────────────────────────────────────────────
  Widget _buildBreakdown() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _iconTile(Icons.currency_rupee_rounded),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Quote Breakdown',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _dark)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('valid 1 week',
                    style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10,
                        color: _slate)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _breakdownRow('Upfront (pre-subsidy)', '₹${_effectiveUpfront.formatWithComma()}', _dark),
          _breakdownRow(
            'PM Surya Ghar Subsidy',
            _residential
                ? '−₹${_effectiveSubsidy.formatWithComma()}'
                : '—',
            _residential ? _green : _slate,
          ),
          _breakdownRow('Structure Cost', '₹${_pkg.structureCost.formatWithComma()}', _dark),
          _breakdownRow('Stamp Charge', '₹${GSTax.stampCharge}', _dark),
          const SizedBox(height: 12),
          Container(
            height: 1,
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: Color(0xFFE2E8F0),
                      style: BorderStyle.solid)),
            ),
          ),
          const SizedBox(height: 12),
          // Highlight box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _sky,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _skyBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('After Subsidy',
                          style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 11,
                              color: _slate)),
                      Text('₹${_afterSubsidy.formatWithComma()}',
                          style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _green)),
                    ],
                  ),
                ),
                Container(width: 1, height: 34, color: const Color(0xCCBFDBFE)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total (incl. stamp)',
                          style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 11,
                              color: _slate)),
                      Text('₹${_grandTotal.formatWithComma()}',
                          style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _navyDeep)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_residential)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x99BBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 15, color: _green),
                  SizedBox(width: 6),
                  Text('Save ₹78,000 with PM Surya Ghar subsidy',
                      style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _green)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500, color: _slate)),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: valueColor)),
        ],
      ),
    );
  }

  // ── Advanced Specs ─────────────────────────────────────────────
  Widget _buildAdvancedSpecs() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _iconTile(Icons.tune_rounded),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Advanced Specs',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _dark)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('Optional',
                    style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10,
                        color: _slate)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Override wiring gauge, inverter kW, or price before sharing.',
            style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11.5,
                color: _slate),
          ),
          const SizedBox(height: 12),
          _specField('DC Cable (sq.mm)', _dcCableSpecsController),
          _specField('AC Wire (sq.mm)', _acWireSpecsController),
          _specField('Earthing Wire (sq.mm)', _earthingWireSpecsController),
          _specField('Inverter Capacity', _inverterKwController),
          const SizedBox(height: 12),
          TextFormField(
            controller: _customPriceController,
            style: const TextStyle(fontSize: 12, color: _dark, height: 1.5),
            decoration: InputDecoration(
              labelText: 'Custom Price (Optional)',
              hintText: 'Leave blank to use package price (₹${_pkg.upfront})',
              prefixIcon: Icon(Icons.currency_rupee, size: 20, color: _navyDeep),
              prefixText: '₹ ',
              labelStyle: TextStyle(color: _navyDeep),
              hintStyle: TextStyle(color: _slate),
              filled: true,
              fillColor: _sky,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _skyBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _navyDeep, width: 1.2),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          if (_isEdit)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: 'Quote Status',
                  labelStyle: TextStyle(color: _navyDeep),
                  filled: true,
                  fillColor: _sky,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _skyBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _navyDeep, width: 1.2),
                  ),
                ),
                items: GSQuoteStatus.all
                    .map((s) => DropdownMenuItem(
                        value: s, child: Text(GSQuoteStatus.labelOf(s))))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? 'draft'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _specField(String label, TextEditingController controller) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 12, color: _dark, height: 1.5),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: _navyDeep),
            hintStyle: TextStyle(color: _slate),
            filled: true,
            fillColor: _sky,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _skyBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _navyDeep, width: 1.2),
            ),
          ),
        ),
      );

  // ── Special notes ──────────────────────────────────────────────
  Widget _buildNotes() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _iconTile(Icons.edit_note_rounded),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Special Notes',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _dark)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('Optional',
                    style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10,
                        color: _slate)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(
                fontSize: 12, color: _dark, height: 1.5),
            decoration: InputDecoration(
              hintText:
                  'Free site survey • Installation in 7 days • 1-year service...',
              hintStyle: const TextStyle(fontSize: 12, color: _slate),
              filled: true,
              fillColor: _sky,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _skyBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _navyDeep, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Trust badges ───────────────────────────────────────────────
  Widget _buildTrustBadges() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _trustBadge(
          prefix: '★',
          prefixColor: const Color(0xFFF59E0B),
          label: 'Tier-1 Adani Warranty',
        ),
        _trustBadge(
          prefix: '✓',
          prefixColor: _green,
          label: 'PGVCL Net-Meter Fast-Track',
        ),
      ],
    );
  }

  Widget _trustBadge({
    required String prefix,
    required Color prefixColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(prefix,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: prefixColor)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _slate)),
        ],
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: const Border(top: BorderSide(color: Color(0xCCE2E8F0))),
        boxShadow: const [
          BoxShadow(color: Color(0x0D071440), blurRadius: 20, offset: Offset(0, -8)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _loading ? null : _saveQuote,
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
                          BoxShadow(color: _gold.withValues(alpha: 0.35), blurRadius: 18),
                        ],
                      ),
                      child: Center(
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _navy))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      size: 20, color: _navy),
                                  const SizedBox(width: 8),
                                  Text(_isEdit ? 'Update Quote' : 'Save & Share Quote',
                                      style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: _navy)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                if (!_isEdit)
                  const SizedBox(width: 12),
                if (!_isEdit)
                  Expanded(
                    child: InkWell(
                      onTap: _loading ? null : _sharePdf,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _navyDeep.withValues(alpha: 0.2)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x0A071440), blurRadius: 8),
                          ],
                        ),
                        child: Center(
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: _navy))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.picture_as_pdf,
                                        size: 20, color: _navyDeep),
                                    const SizedBox(width: 8),
                                    Text('Share PDF',
                                        style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: _navyDeep)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Prices last updated ${GSTax.pricesLastUpdated} • Final quote after free site survey',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: _slate),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0B1F5C),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: _navyDeep),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required Widget right,
  }) {
    return Row(
      children: [
        _iconTile(icon),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _dark)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: _sky,
            borderRadius: BorderRadius.circular(999),
          ),
          child: right,
        ),
      ],
    );
  }

  // ── Save / share ───────────────────────────────────────────────
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
      upfront: _effectiveUpfront,
      afterSubsidy: _afterSubsidy,
      structureCost: _pkg.structureCost,
      total: _effectiveUpfront,
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
      'Total (pre-subsidy): ₹${_effectiveUpfront.formatWithComma()}\n'
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
        upfront: _effectiveUpfront,
        afterSubsidy: _afterSubsidy,
        structureCost: _pkg.structureCost,
        total: _effectiveUpfront,
        status: 'draft',
        sentAt: DateTime.now(),
        isResidential: _residential,
      );

      final SolarProposalData proposalData;
      if (widget.client != null) {
        proposalData = SolarProposalData.fromClientAndQuote(
          client: widget.client!,
          quote: quote,
          dcCableSpecs: _dcCableSpecsController.text.trim().isNotEmpty
              ? _dcCableSpecsController.text.trim()
              : null,
          acWireSpecs: _acWireSpecsController.text.trim().isNotEmpty
              ? _acWireSpecsController.text.trim()
              : null,
          earthingWireSpecs: _earthingWireSpecsController.text.trim().isNotEmpty
              ? _earthingWireSpecsController.text.trim()
              : null,
          inverterKwOverride: _inverterKwController.text.trim().isNotEmpty
              ? _inverterKwController.text.trim()
              : null,
          customUpfrontPrice: _customPriceController.text.trim().isNotEmpty
              ? int.tryParse(_customPriceController.text.trim().replaceAll(RegExp(r'[\s,₹]'), ''))
              : null,
        );
      } else {
        proposalData = SolarProposalData.withDefaults(
          quotationId: quote.id,
          plantCapacityKw: _pkg.kw.toStringAsFixed(2),
          package: _pkg,
          dcCableSpecs: _dcCableSpecsController.text.trim().isNotEmpty
              ? _dcCableSpecsController.text.trim()
              : null,
          acWireSpecs: _acWireSpecsController.text.trim().isNotEmpty
              ? _acWireSpecsController.text.trim()
              : null,
          earthingWireSpecs: _earthingWireSpecsController.text.trim().isNotEmpty
              ? _earthingWireSpecsController.text.trim()
              : null,
          inverterKwOverride: _inverterKwController.text.trim().isNotEmpty
              ? _inverterKwController.text.trim()
              : null,
          customUpfrontPrice: _customPriceController.text.trim().isNotEmpty
              ? int.tryParse(_customPriceController.text.trim().replaceAll(RegExp(r'[\s,₹]'), ''))
              : null,
        );
      }

      final bytes = await ProposalPdf.generate(proposalData);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/gs_proposal_${quote.id}.pdf');
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'Global Solar 2.0 — Roof Top Solar Proposal',
          text: '${_pkg.kw} kW System (${_pkg.panels} panels)\n'
              'After subsidy: ₹${_afterSubsidy.formatWithComma()}\n'
              'Total: ₹${_grandTotal.formatWithComma()}\n'
              '7-page detailed proposal PDF attached.',
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('7-Page Proposal PDF shared')),
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

/// Pulsing gold dot in header.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
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