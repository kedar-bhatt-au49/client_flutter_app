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

    // ── Convert estimate line items → proposal line items ──
    final lineItems = e.lineItems.map(_toProposalLineItem).toList();

    // ── Extract panel / inverter specs from line-item descriptions ──
    final panelCount = _extractPanelCount(e, master);
    final (panelBrand, panelWattpeak) = _extractPanelInfo(e);
    final (inverterBrand, inverterKw) = _extractInverterInfo(e);

    // ── Build BOM items from MasterData ──
    final bomItems = _bomFromMaster(e, master);

    // ── Totals come from the PriceBreakdown when available, otherwise
    // recomputed from line items. ──
    final int subTotal = b?.subtotal ??
        lineItems.fold(0, (s, i) => s + i.rate * int.parse(i.qty));
    final int cgstTotal = b?.cgstTotal ?? 0;
    final int sgstTotal = b?.sgstTotal ?? 0;
    final int grandTotal = b?.grandTotal ?? (subTotal + cgstTotal + sgstTotal);

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
      effectiveUpfront: grandTotal,
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
      cgstPercent: item.cgstPercent.toInt(),
      sgstPercent: item.sgstPercent.toInt(),
    );
  }

  // ── Panel / inverter extraction ───────────────────────────────────

  static int _extractPanelCount(EstimateModel e, MasterData master) {
    final (_, wattage) = _extractPanelInfo(e);
    final w = int.tryParse(RegExp(r'(\d+)').firstMatch(wattage)?.group(1) ?? '');
    if (w == null || w == 0) {
      return ((e.capacityKw ?? 0) * 1000 / master.defaultPanelWattage).ceil();
    }
    final cap = e.capacityKw ?? 0;
    return (cap * 1000 / w).ceil();
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
              'Commercial properties are not eligible for this subsidy.',
            ]),
        const WarrantySection(heading: '3. Structure Terms', bullets: [
          'Hot-dip galvanized MS structure is warranted against corrosion for 5 years.',
          'Fabrication and erection work is warranted for 1 year against defects.',
        ]),
        const WarrantySection(
            heading: '4. Solar Panel Warranty',
            bullets: [
              'Product workmanship warranty: 12 years.',
              'Performance warranty: 80% output guaranteed for 25 years.',
              'Linear power output warranty: 0.55% degradation per year.',
            ]),
        const WarrantySection(
            heading: '5. Inverter Warranty',
            bullets: [
              'String inverter: 5 + 5 years warranty (extendable up to 10 years).',
              'Workmanship defects covered for 2 years from commissioning.',
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
