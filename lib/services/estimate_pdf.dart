import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../models/estimate.dart';
import '../models/proposal_data.dart';
import '../services/proposal_pdf.dart';

/// Generates a **7-page estimate PDF** by mapping the estimate data to
/// [SolarProposalData] and delegating to [ProposalPdf.generate].
///
/// The resulting PDF mirrors the professional proposal layout:
///   Page 1 — Cover
///   Page 2 — Solar Plant Design Showcase
///   Page 3 — Quotation / Estimate Table
///   Page 4 — Terms & Conditions + Bill of Materials
///   Page 5 — Warranty Terms (Part 1)
///   Page 6 — Warranty Terms (Part 2)
///   Page 7 — Payment / UPI QR + Contact strip
///
/// Only packages already in the dependency tree are used (pdf, intl).
/// The Hinglish label toggle is forwarded to the proposal renderer.
class EstimatePdf {
  EstimatePdf._();

  static final DateFormat _dateFmt = DateFormat('dd/MM/yyyy');

  /// Generates the full 7-page estimate PDF and returns the raw bytes.
  static Future<Uint8List> generate({
    required EstimateRecord record,
    required MasterData master,
    bool useHinglish = false,
    Uint8List? logoImage,
  }) async {
    final data = _toSolarProposalData(
      record: record,
      master: master,
      useHinglish: useHinglish,
      logoImage: logoImage,
    );
    return ProposalPdf.generate(data);
  }

  /// Maps an [EstimateRecord] + [MasterData] into a [SolarProposalData] so the
  /// existing 7-page [ProposalPdf] can render it.
  static SolarProposalData _toSolarProposalData({
    required EstimateRecord record,
    required MasterData master,
    bool useHinglish = false,
    Uint8List? logoImage,
  }) {
    final e = record.data;
    final b = e.priceBreakdown;

    // ── Standard quotation system selected? ──
    // Build the exact table-based quotation (GST-inclusive totals) instead
    // of the raw price-calculator line items.
    final system = e.systemId != null ? gsQuoteSystemById(e.systemId!) : null;
    if (system != null) {
      return _fromSystem(
        e: e,
        system: system,
        record: record,
        useHinglish: useHinglish,
        logoImage: logoImage,
      );
    }

    // ── Convert estimate line items → proposal line items ──
    final lineItems = e.lineItems.map(_toProposalLineItem).toList();

    // ── Extract panel / inverter specs from line-item descriptions ──
    final panelCount = _extractPanelCount(e, master);
    final (panelBrand, panelWattpeak) = _extractPanelInfo(e);
    final (inverterBrand, inverterKw) = _extractInverterInfo(e);

    // ── Build BOM items from MasterData ──
    final bomItems = _bomFromMaster(e, master);

    // ── Totals come from the PriceBreakdown when available, otherwise
    // recomputed from line items. Base (pre-subsidy) values are captured
    // here — before the subsidy adjustment line item is appended below —
    // so the fold does not count the -Subsidy row. ──
    final int baseSubTotal = b?.subtotal ??
        lineItems.fold(0, (s, i) => s + i.rate * int.parse(i.qty));
    final int cgstTotal = b?.cgstTotal ?? 0;
    final int sgstTotal = b?.sgstTotal ?? 0;
    final int baseGrandTotal =
        b?.grandTotal ?? (baseSubTotal + cgstTotal + sgstTotal);

    // ── PM Surya Ghar residential subsidy (₹78,000) ──
    final isResidential = e.clientType == 'individual';
    final subsidy = isResidential ? GSTax.subsidyMax : 0;

    // Subtract subsidy so grandTotal = final amount the customer pays.
    // The PDF renderer (_totalsBlock) adds subsidy back to display the
    // pre-subsidy "Total" (highlighted), shows the deduction row
    // unstyled, and highlights the "Final Total".
    final int subTotal = baseSubTotal - subsidy;
    final int grandTotal = baseGrandTotal - subsidy;

    // Add the subsidy adjustment line item so it appears in the quotation
    // table and the per-line totals reconcile with the totals box.
    if (subsidy > 0) {
      lineItems.add(ProposalLineItem(
        description: 'PM Surya Ghar Subsidy (Adjustment)',
        specs: ['Government subsidy credit', 'Residential only'],
        qty: '1',
        unit: 'set',
        rate: -subsidy,
        cgstPercent: 0,
        sgstPercent: 0,
      ));
    }

    return SolarProposalData(
      companyName: 'Global Solar 2.0',
      companyTagline: siteConfigTagline,
      companyAddress: siteConfigAddress,
      companyEmail: siteConfigEmail,
      companyPhone: '${GSUsers.founderPhone} / ${GSUsers.coFounderPhone}',
      companyGstin: '24AABCG1234C1Z0',
      brandColorHex: '#071440',
      accentColorHex: '#F9B417',
      customerName: e.leadName,
      customerLocation: e.address ?? 'Bhavnagar, Gujarat',
      customerMobile: '+91 ${e.mobileNumber}',
      state: 'Gujarat',
      leadName: e.leadName,
      quotationId: e.estimateNumber,
      quotationDate: _dateFmt.format(record.createdAt),
      expiryDate: _dateFmt.format(e.expiryDate),
      preparedBy: 'Jayrajsinh S. Umat & Gopalsinh J. Parmar',
      contactNumbers: '${GSUsers.founderPhone} / ${GSUsers.coFounderPhone}',
      plantCapacityKw: '${e.capacityKw?.toStringAsFixed(2) ?? '0.00'}',
      lineItems: lineItems,
      subTotal: subTotal,
      taxGst: cgstTotal + sgstTotal,
      cgstTotal: cgstTotal,
      sgstTotal: sgstTotal,
      grandTotal: grandTotal,
      amountInWords: 'Indian Rupee ${_numberToWords(grandTotal)} Only',
      notes: _estimateNotes(e, useHinglish),
      bankDetails: const BankDetails(
        bankName: 'Bank of Baroda',
        accountName: 'Global Solar 2.0',
        accountNo: '25980500000094',
        ifsc: 'BARBOSSIBHA',
        branch: 'Bhavnagar',
      ),
      bomItems: bomItems,
      panelCount: panelCount,
      panelWattpeak: panelWattpeak,
      panelBrand: panelBrand,
      dcCableSpecs: '4 sq.mm',
      acWireSpecs: '2.5 sq.mm',
      earthingWireSpecs: '2.5 sq.mm',
      inverterKwValue: inverterKw,
      effectiveUpfront: baseGrandTotal,
      subsidyAmount: subsidy,
      warrantySections: _defaultWarrantySections,
      upiId: 'global.solar.2.0@oksbi',
      upiQrUpiId:
          'upi://pay?pa=global.solar.2.0@oksbi&pn=Global Solar 2.0&cu=INR',
      useHinglish: useHinglish,
      socialLinks: _defaultSocialLinks,
      logoImage: logoImage,
    );
  }

  // ── Standard quotation system → proposal ───────────────────────────

  static SolarProposalData _fromSystem({
    required EstimateModel e,
    required GSQuoteSystem system,
    required EstimateRecord record,
    bool useHinglish = false,
    Uint8List? logoImage,
  }) {
    // Total payable (from the system table). GST-inclusive by default.
    final totalPayable = e.totalPayableOverride ?? system.totalPayable;
    final subsidy = system.subsidy;
    final includeGst = e.gstIncluded;
    final gstMul = 1 + GSGst.totalPercent / 100; // 1.089

    // GST-exclusive PV-system amount so that
    // pvTaxable + structure + stamp + GST == totalPayable (when GST included).
    final pvTaxable =
        ((totalPayable - system.structureCost - system.stampCharge) / gstMul)
            .round();
    final cgstPct = includeGst ? GSGst.cgstPercent : 0.0;
    final sgstPct = includeGst ? GSGst.sgstPercent : 0.0;
    final cgst = ((pvTaxable * cgstPct) / 100).round();
    final sgst = ((pvTaxable * sgstPct) / 100).round();

    // Custom line items added by the user (each with its own GST %).
    final custom = <ProposalLineItem>[];
    var customNet = 0;
    var customCgst = 0;
    var customSgst = 0;
    for (final it in e.lineItems) {
      final qty = it.qty == 0 ? 1 : it.qty;
      final base = it.rate * qty;
      final c = includeGst ? (base * it.cgstPercent / 100).round() : 0;
      final s = includeGst ? (base * it.sgstPercent / 100).round() : 0;
      customNet += base;
      customCgst += c;
      customSgst += s;
      custom.add(ProposalLineItem(
        description: it.description,
        specs: const [],
        qty: '$qty',
        unit: 'set',
        rate: it.rate,
        cgstPercent: includeGst ? it.cgstPercent : 0,
        sgstPercent: includeGst ? it.sgstPercent : 0,
      ));
    }

    final baseExclGst =
        pvTaxable + system.structureCost + system.stampCharge + customNet;
    final cgstTotal = cgst + customCgst;
    final sgstTotal = sgst + customSgst;
    final gross = baseExclGst + cgstTotal + sgstTotal;
    final afterSubsidy = gross - subsidy;

    final lineItems = <ProposalLineItem>[
      ProposalLineItem(
        description: '${system.kw.toStringAsFixed(2)} kW Solar PV System',
        specs: [
          '${system.panels} × ${system.panelWatt} Wp Adani TOPCon solar panels',
          '${system.panels} × MC4 connectors & MC4 extensions',
        ],
        qty: '1',
        unit: 'set',
        rate: pvTaxable,
        cgstPercent: cgstPct,
        sgstPercent: sgstPct,
      ),
      ProposalLineItem(
        description: 'Structure & Mounting (Elevated)',
        specs: ['Hot-dip galvanized MS structure'],
        qty: '1',
        unit: 'set',
        rate: system.structureCost,
        cgstPercent: 0,
        sgstPercent: 0,
      ),
      ProposalLineItem(
        description: 'Stamp Charge',
        specs: ['Govt. stamp paper for agreement'],
        qty: '1',
        unit: 'set',
        rate: system.stampCharge,
        cgstPercent: 0,
        sgstPercent: 0,
      ),
      ...custom,
      ProposalLineItem(
        description: 'PM Surya Ghar Subsidy (Adjustment)',
        specs: ['Government subsidy credit', 'Residential only'],
        qty: '1',
        unit: 'set',
        rate: -subsidy,
        cgstPercent: 0,
        sgstPercent: 0,
      ),
    ];

    return SolarProposalData(
      companyName: 'Global Solar 2.0',
      companyTagline: siteConfigTagline,
      companyAddress: siteConfigAddress,
      companyEmail: siteConfigEmail,
      companyPhone: '${GSUsers.founderPhone} / ${GSUsers.coFounderPhone}',
      companyGstin: '24AABCG1234C1Z0',
      brandColorHex: '#071440',
      accentColorHex: '#F9B417',
      customerName: e.leadName,
      customerLocation: e.address ?? 'Bhavnagar, Gujarat',
      customerMobile: '+91 ${e.mobileNumber}',
      state: 'Gujarat',
      leadName: e.leadName,
      quotationId: e.estimateNumber,
      quotationDate: _dateFmt.format(record.createdAt),
      expiryDate: _dateFmt.format(e.expiryDate),
      preparedBy: 'Jayrajsinh S. Umat & Gopalsinh J. Parmar',
      contactNumbers: '${GSUsers.founderPhone} / ${GSUsers.coFounderPhone}',
      plantCapacityKw: system.kw.toStringAsFixed(2),
      lineItems: lineItems,
      subTotal: baseExclGst,
      taxGst: cgstTotal + sgstTotal,
      cgstTotal: cgstTotal,
      sgstTotal: sgstTotal,
      grandTotal: afterSubsidy,
      amountInWords: 'Indian Rupee ${_numberToWords(afterSubsidy)} Only',
      notes: _estimateNotes(e, useHinglish),
      bankDetails: const BankDetails(
        bankName: 'Bank of Baroda',
        accountName: 'Global Solar 2.0',
        accountNo: '25980500000094',
        ifsc: 'BARBOSSIBHA',
        branch: 'Bhavnagar',
      ),
      bomItems: [
        BomItem(
          item: 'Solar Panels',
          qty: '${system.panels}',
          unit: 'Nos.',
          brand: 'ADANI TOPCON (610/615)',
          category: 'Solar Panels',
        ),
        BomItem(
          item: 'Inverter',
          qty: '1',
          unit: 'Nos.',
          brand: 'POLYCAB',
          category: 'Inverters',
        ),
        BomItem(
          item: 'Structure',
          qty: '1',
          unit: 'Set',
          brand: '80 x 40 x 2 MM (LEG & RAFTER) / 40 x 40 x 2 MM (PERLIN)',
          category: 'Structure',
        ),
        BomItem(
          item: 'AC Cables',
          qty: '1',
          unit: 'Lot',
          brand: 'POLYCAB',
          category: 'Cables & Wiring',
        ),
        BomItem(
          item: 'DC Cables',
          qty: '1',
          unit: 'Lot',
          brand: 'POLYCAB',
          category: 'Cables & Wiring',
        ),
        BomItem(
          item: 'Earthing Cables',
          qty: '1',
          unit: 'Lot',
          brand: 'POLYCAB',
          category: 'Cables & Wiring',
        ),
        BomItem(
          item: 'LA Cable',
          qty: '1',
          unit: 'Lot',
          brand: 'KANBERY / KOREMAN',
          category: 'Cables & Wiring',
        ),
        BomItem(
          item: 'MCB',
          qty: '1',
          unit: 'Nos.',
          brand: 'HAVELLS',
          category: 'BOS & Protection',
        ),
        BomItem(
          item: 'SPD',
          qty: '1',
          unit: 'Nos.',
          brand: 'ELMEX / PHOENIX',
          category: 'BOS & Protection',
        ),
      ],
      panelCount: system.panels,
      panelWattpeak: system.panelWatt.toString(),
      panelBrand: 'Adani TOPCon',
      dcCableSpecs: e.wiringSqMm ?? '4 sq.mm',
      acWireSpecs: e.wiringSqMm ?? '2.5 sq.mm',
      earthingWireSpecs: e.wiringSqMm ?? '2.5 sq.mm',
      inverterKwValue: e.inverterKwManual != null
          ? '${e.inverterKwManual} kW'
          : '3.6 kW',
      effectiveUpfront: totalPayable,
      subsidyAmount: subsidy,
      warrantySections: _defaultWarrantySections,
      upiId: 'global.solar.2.0@oksbi',
      upiQrUpiId:
          'upi://pay?pa=global.solar.2.0@oksbi&pn=Global Solar 2.0&cu=INR',
      useHinglish: useHinglish,
      socialLinks: _defaultSocialLinks,
      logoImage: logoImage,
    );
  }

  // ── Line-item conversion ───────────────────────────────────────────

  static ProposalLineItem _toProposalLineItem(EstimateLineItem item) {
    return ProposalLineItem(
      description: item.description,
      specs: item.specs.isNotEmpty ? [item.specs] : [],
      qty: item.qty.toString(),
      unit: 'set',
      rate: item.rate,
      discount: item.discount,
      cgstPercent: item.cgstPercent.toDouble(),
      sgstPercent: item.sgstPercent.toDouble(),
    );
  }

  // ── Panel / inverter extraction ───────────────────────────────────

  static int _extractPanelCount(EstimateModel e, MasterData master) {
    // Prefer the explicit quantity on the "Solar Panels" line item — this is
    // the exact module count chosen for the selected system, so the correct
    // panel-count design image is used (5..10 panels).
    final panelItem = e.lineItems.firstWhere(
      (i) => i.description == 'Solar Panels',
      orElse: () =>
          EstimateLineItem(description: '', specs: '', qty: 0, rate: 0),
    );
    if (panelItem.qty > 0) return panelItem.qty;

    // Fallback: derive from capacity / per-panel wattage. Use round() (not
    // ceil()) so floating-point noise like 5.0000001 does not become 6.
    final (_, wattage) = _extractPanelInfo(e);
    final w = int.tryParse(RegExp(r'(\d+)').firstMatch(wattage)?.group(1) ?? '');
    final cap = e.capacityKw ?? 0;
    if (w == null || w == 0) {
      return (cap * 1000 / master.defaultPanelWattage).round();
    }
    return (cap * 1000 / w).round();
  }

  static (String, String) _extractPanelInfo(EstimateModel e) {
    final item = e.lineItems
        .firstWhere((i) => i.description == 'Solar Panels', orElse: () =>
            EstimateLineItem(description: '', specs: '', qty: 0, rate: 0));
    final specs = item.specs;
    if (specs.isEmpty) return ('Adani TOPCon', '610 Wp');
    // specs example: "Adani 610Wp (25 Years, 25 Years, 25 Years)"
    final m = RegExp(r'(\d+)\s*Wp').firstMatch(specs);
    final wattage = m != null ? '${m.group(1)} Wp' : '610 Wp';
    final brand = specs.substring(0, m?.start ?? 0).trim();
    return (brand.isNotEmpty ? brand : 'Adani TOPCon', wattage);
  }

  static (String, String) _extractInverterInfo(EstimateModel e) {
    final item = e.lineItems
        .firstWhere((i) => i.description == 'Inverter', orElse: () =>
            EstimateLineItem(description: '', specs: '', qty: 0, rate: 0));
    final specs = item.specs;
    if (specs.isEmpty) return ('Polycab', '3.6 kW');
    // specs example: "SMA @ 3.6kW"
    final m = RegExp(r'@\s*([\d.]+)\s*kW').firstMatch(specs);
    final kw = m != null ? m.group(1) != null ? '${m.group(1)} kW' : '3.6 kW' : '3.6 kW';
    final brand = specs.split('@').first.trim();
    return (brand.isNotEmpty ? brand : 'Polycab', kw);
  }

  // ── BOM items from MasterData ─────────────────────────────────────

  static List<BomItem> _bomFromMaster(
      EstimateModel e, MasterData master) {
    final bom = <BomItem>[];

    // Panel
    final (pBrand, _) = _extractPanelInfo(e);
    bom.add(BomItem(
      item: 'Solar Panels (PV Modules)',
      qty: '${_extractPanelCount(e, master)}',
      unit: 'Nos.',
      brand: pBrand,
      category: 'Solar Panels',
    ));

    // Inverter
    final (invBrand, invKw) = _extractInverterInfo(e);
    bom.add(BomItem(
      item: 'Solar String Inverter',
      qty: '1',
      unit: 'Nos.',
      brand: invBrand,
      category: 'Inverters',
    ));

    // BOS items from MasterData
    for (final bos in master.bosItems) {
      bom.add(BomItem(
        item: bos.name,
        qty: '${bos.qty}',
        unit: bos.unit,
        brand: 'Global Solar',
        category: 'BOS',
      ));
    }

    // Structure pipes (qty from estimate's structureQuantities)
    for (final pipe in master.structurePipes) {
      final meters = e.structureQuantities[pipe.label] ?? 0;
      if (meters > 0) {
        bom.add(BomItem(
          item: pipe.label,
          qty: '$meters',
          unit: 'mtr',
          brand: 'MS Steel',
          category: 'Structure',
        ));
      }
    }

    return bom;
  }

  // ── Notes ──────────────────────────────────────────────────────────

  static List<String> _estimateNotes(EstimateModel e, bool hi) {
    if (e.description != null && e.description!.isNotEmpty) {
      return [e.description!];
    }
    return hi
        ? [
            '1. यह अनुमान स्थान पर मुफ्त साइट सर्वे के बाद अंतिम बनेगा।',
            '2. यह अनुमान जारी होने की तारीख से 7 दिनों तक वैध है।',
            '3. PM सुर्य घर आवासीय सब्सिडी ₹78,000 केवल घरेलू 10 kW तक।',
            '4. व्यावसायिक संतालन सब्सिडी के पात्र नहीं हैं।',
          ]
        : [
            '1. Final estimate is subject to a free site survey at the customer\'s location.',
            '2. This estimate is valid for 7 days from the date of issue.',
            '3. PM Surya Ghar residential subsidy of ₹78,000 is applicable only for residential rooftop solar (up to 10 kW).',
            '4. Commercial installations are not eligible for the subsidy.',
          ];
  }

  // ── Warranty sections (reused from proposal defaults) ─────────────

  static List<WarrantySection> get _defaultWarrantySections => [
        const WarrantySection(heading: '1. General Terms', bullets: [
          'All solar plant equipment is warranted against defects in material and workmanship.',
          'The warranty period commences from the date of successful commissioning.',
          'Any claim must be made in writing with supporting documentation and photos.',
        ]),
        const WarrantySection(
            heading: '2. Government Subsidy (PM Surya Ghar)',
            bullets: [
              'Subsidy of ₹78,000 is applicable for residential connections up to 10 kW.',
              'The subsidy is credited directly by the government to the beneficiary\'s bank account.',
              'Global Solar 2.0 assists in the subsidy application but is not liable for any government delay.',
              'Commercial properties are not eligible for this subsidy.',
            ]),
        const WarrantySection(heading: '3. Structure Terms', bullets: [
          'Hot-dip galvanized MS structure is warranted against corrosion for 5 years.',
          'Fabrication and erection work is warranted for 1 year against defects.',
        ]),
        const WarrantySection(
            heading: '4. Solar Panel (PV Module) Performance Warranty',
            bullets: [
              'Product workmanship warranty: 12 years.',
              'Performance warranty: 80% output guaranteed for 25 years, 90% for 10 years.',
              'Linear power output warranty: 0.55% degradation per year.',
            ]),
        const WarrantySection(
            heading: '5. Inverter Manufacturing Defect Warranty',
            bullets: [
              'String inverter: 5 + 5 years warranty (extendable up to 10 years).',
              'Workmanship defects covered for 2 years from commissioning.',
            ]),
        const WarrantySection(heading: '6. Balance of System (BOS)', bullets: [
          'MC4 connectors, cables, and DC/AC box: 5 years.',
          'Chemical earthing: 5 years.',
          'Lightning arrester: 2 years.',
        ]),
        const WarrantySection(heading: '7. Operation & Maintenance', bullets: [
          'Free comprehensive O&M for the first year after commissioning.',
          'AMC packages available from year 2 onwards at an additional cost.',
          '24x7 customer care available.',
        ]),
        const WarrantySection(heading: '8. Warranty Notes', bullets: [
          'Warranty is non-transferable but benefits the property owner.',
          'Force majeure events (lightning, floods) are not covered under standard warranty.',
          'Any unauthorised modification voids the warranty immediately.',
        ]),
        const WarrantySection(
            heading: '9. Schedule for Site Completion',
            bullets: [
              'Material dispatch: within 3 working days of advance payment.',
              'Site survey & installation: within 7 working days of material arrival.',
              'Commissioning & net-meter application: within 15 working days of installation.',
            ]),
        const WarrantySection(heading: '10. Quotation Validity', bullets: [
          'This quotation is valid for 15 days from the date of issue.',
          'Prices are subject to revision if the quotation validity period is exceeded.',
        ]),
        const WarrantySection(heading: '11. Warranty Exclusions', bullets: [
          'Damage caused by natural calamities, negligence, or misuse.',
          'Performance degradation due to dust, bird droppings, or lack of cleaning.',
          'Any tampering with equipment or wiring by unauthorised persons.',
          'Normal wear and tear of consumable items (fuses, connectors).',
        ]),
        const WarrantySection(
            heading: '12. Scope of Work For Customer', bullets: [
          'Provide safe and clear access to the rooftop on the scheduled date.',
          'Arrange 2-4 competent helpers for installation assistance (lifting panels).',
          'Share a recent electricity bill and property ownership documents.',
          'Coordinate with the local discom (PGVCL) for net-metering paperwork if required.',
        ]),
      ];

  // ── Social links ───────────────────────────────────────────────────

  static List<SocialLink> get _defaultSocialLinks => [
        SocialLink(
            name: 'WhatsApp',
            url:
                'https://wa.me/${GSUsers.whatsappNumber}'),
        SocialLink(name: 'Phone', url: 'tel:${GSUsers.founderPhone}'),
        SocialLink(name: 'Email', url: 'mailto:$siteConfigEmail'),
      ];

  // ── Number-to-words ────────────────────────────────────────────────

  static String _numberToWords(int n) {
    if (n == 0) return 'Zero';
    const ones = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven',
        'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen',
        'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    const tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty',
        'Seventy', 'Eighty', 'Ninety'];

    String buildUnder1000(int num) {
      final parts = <String>[];
      if (num >= 100) {
        parts.add('${ones[num ~/ 100]} Hundred');
        num -= (num ~/ 100) * 100;
      }
      if (num >= 20) {
        parts.add(tens[num ~/ 10]);
        num -= (num ~/ 10) * 10;
      }
      if (num > 0) parts.add(ones[num]);
      return parts.join(' ').trim();
    }

    final crore = n ~/ 10000000;
    var remainder = n % 10000000;
    final lakh = remainder ~/ 100000;
    remainder = remainder % 100000;
    final thousand = remainder ~/ 1000;
    remainder = remainder % 1000;
    final hundreds = remainder;

    final parts = <String>[];
    if (crore > 0) parts.add('${buildUnder1000(crore)} Crore');
    if (lakh > 0) parts.add('${buildUnder1000(lakh)} Lakh');
    if (thousand > 0) parts.add('${buildUnder1000(thousand)} Thousand');
    if (hundreds > 0) {
      final h = buildUnder1000(hundreds);
      if (h.isNotEmpty) parts.add(h);
    }
    return parts.join(' ').trim();
  }
}
