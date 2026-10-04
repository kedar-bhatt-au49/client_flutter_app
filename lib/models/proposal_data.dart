/// ---------------------------------------------------------------------------
/// Roof Top Solar Proposal + Quotation — Data Model
///
/// Holds every field referenced by the 7-page PDF layout spec.  All fields use
/// `{{double_braces}}` naming from the spec so the template is data-driven.
///
/// The [SolarProposalData.withDefaults] factory populates a real, internally
/// consistent quotation from the app's existing price table and constants — so
/// a preview works out of the box.
/// ---------------------------------------------------------------------------
library;

import 'dart:typed_data';

import '../core/constants.dart';
import 'client.dart';
import 'quote.dart';

/// A single line item in the quotation table.
class ProposalLineItem {
  final String description;
  final List<String> specs;
  final String qty;
  final String unit;
  final int rate; // per unit, before tax
  final int discount; // absolute discount
  final double cgstPercent;
  final double sgstPercent;

  const ProposalLineItem({
    required this.description,
    required this.specs,
    required this.qty,
    required this.unit,
    required this.rate,
    this.discount = 0,
    this.cgstPercent = 6,
    this.sgstPercent = 6,
  });

  int get taxableAmount => (rate * _qtyToInt) - discount;
  int get cgstAmount => ((taxableAmount * cgstPercent) / 100).round();
  int get sgstAmount => ((taxableAmount * sgstPercent) / 100).round();
  int get total => taxableAmount + cgstAmount + sgstAmount;

  int get _qtyToInt => int.tryParse(qty.split(' ').first) ?? 1;

  factory ProposalLineItem.fromJson(Map<String, dynamic> j) => ProposalLineItem(
        description: j['description'] as String,
        specs: List<String>.from(j['specs'] as List),
        qty: j['qty'] as String,
        unit: j['unit'] as String,
        rate: j['rate'] as int,
        discount: j['discount'] as int? ?? 0,
        cgstPercent: (j['cgst_percent'] as num?)?.toDouble() ?? 6,
        sgstPercent: (j['sgst_percent'] as num?)?.toDouble() ?? 6,
      );

  Map<String, dynamic> toJson() => {
        'description': description,
        'specs': specs,
        'qty': qty,
        'unit': unit,
        'rate': rate,
        'discount': discount,
        'cgst_amount': cgstAmount,
        'cgst_percent': cgstPercent,
        'sgst_amount': sgstAmount,
        'sgst_percent': sgstPercent,
        'total': total,
      };
}

/// Bank account details block.
class BankDetails {
  final String bankName;
  final String accountName;
  final String accountNo;
  final String ifsc;
  final String branch;

  const BankDetails({
    required this.bankName,
    required this.accountName,
    required this.accountNo,
    required this.ifsc,
    required this.branch,
  });

  factory BankDetails.fromJson(Map<String, dynamic> j) => BankDetails(
        bankName: j['bank_name'] as String,
        accountName: j['account_name'] as String,
        accountNo: j['account_no'] as String,
        ifsc: j['ifsc'] as String,
        branch: j['branch'] as String,
      );

  Map<String, dynamic> toJson() => {
        'bank_name': bankName,
        'account_name': accountName,
        'account_no': accountNo,
        'ifsc': ifsc,
        'branch': branch,
      };
}

/// One row of the Bill of Materials table.
class BomItem {
  final String item;
  final String qty;
  final String unit;
  final String brand;
  final String? category;

  const BomItem({
    required this.item,
    required this.qty,
    required this.unit,
    required this.brand,
    this.category,
  });

  factory BomItem.fromJson(Map<String, dynamic> j) => BomItem(
        item: j['item'] as String,
        qty: j['qty'] as String,
        unit: j['unit'] as String,
        brand: j['brand'] as String,
        category: j['category'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'item': item,
        'qty': qty,
        'unit': unit,
        'brand': brand,
        if (category != null) 'category': category,
      };
}

/// A warranty sub-section: bold heading + bullet list.
class WarrantySection {
  final String heading;
  final List<String> bullets;

  const WarrantySection({required this.heading, required this.bullets});

  factory WarrantySection.fromJson(Map<String, dynamic> j) => WarrantySection(
        heading: j['heading'] as String,
        bullets: List<String>.from(j['bullets'] as List),
      );

  Map<String, dynamic> toJson() => {
        'heading': heading,
        'bullets': bullets,
      };
}

/// A social / contact link shown in the footer.
class SocialLink {
  final String name;
  final String url;

  const SocialLink({required this.name, required this.url});

  factory SocialLink.fromJson(Map<String, dynamic> j) => SocialLink(
        name: j['name'] as String,
        url: j['url'] as String,
      );

  Map<String, dynamic> toJson() => {'name': name, 'url': url};
}

/// ---------------------------------------------------------------------------
/// Main proposal data class
/// ---------------------------------------------------------------------------
class SolarProposalData {
  // ── Company / brand ───────────────────────────────────────────────
  final String companyName;
  final String companyTagline;
  final String companyAddress;
  final String companyEmail;
  final String companyPhone;
  final String companyGstin;
  final String brandColorHex; // primary
  final String accentColorHex; // accent

  // ── Customer ──────────────────────────────────────────────────────
  final String customerName;
  final String customerLocation;
  final String customerMobile;
  final String state;

  // ── Lead / quotation meta ─────────────────────────────────────────
  final String leadName;
  final String quotationId;
  final String quotationDate;
  final String expiryDate;
  final String preparedBy;
  final String contactNumbers;
  final String plantCapacityKw;

  // ── Line items + totals ───────────────────────────────────────────
  final List<ProposalLineItem> lineItems;
  final int subTotal;
  final int taxGst;
  final int cgstTotal;
  final int sgstTotal;
  final int grandTotal;
  final String amountInWords;

  // ── Notes (footer box on quotation page) ──────────────────────────
  final List<String> notes;

  // ── Bank details ──────────────────────────────────────────────────
  final BankDetails bankDetails;

  // ── Bill of Materials ─────────────────────────────────────────────
  final List<BomItem> bomItems;

  // ── Solar Panel System Specs (for panel structure page) ──────────
  final int panelCount;
  final String panelWattpeak;
  final String panelBrand;

  // ── Editable specs (admin can override before generating) ────────────
  final String dcCableSpecs; // e.g. '4 sq.mm'
  final String acWireSpecs; // e.g. '2.5 sq.mm'
  final String earthingWireSpecs; // e.g. '2.5 sq.mm'
  final String inverterKwValue; // e.g. '3.6 kW'
  final int effectiveUpfront; // price after optional admin override
  final int subsidyAmount;  // PM Surya Ghar subsidy (₹78,000 residential)

  // ── Warranty sections (pages 5–6) ─────────────────────────────────
  final List<WarrantySection> warrantySections;

  // ── Payment / UPI ─────────────────────────────────────────────────
  final String upiId;
  final String upiQrUpiId; // data encoded into the QR

  // ── Language ─────────────────────────────────────────────────────
  /// When true, the PDF renders all static labels and headings in Hinglish
  /// (a natural mix of Hindi-Devanagari + English technical terms) alongside
  /// the English version.
  final bool useHinglish;

  // ── Social links (footer) ────────────────────────────────────────
  final List<SocialLink> socialLinks;

  // ── Images (loaded at generate-time; null ⇒ placeholder) ──────────
  final Uint8List? logoImage;
  final Uint8List? heroImage;
  final Uint8List? designImageTop;
  final Uint8List? designImageLeft;
  final Uint8List? designImageRight;
  final Uint8List? upiQrImage;
  final Uint8List? panelDetailImage;

  SolarProposalData({
    required this.companyName,
    required this.companyTagline,
    required this.companyAddress,
    required this.companyEmail,
    required this.companyPhone,
    required this.companyGstin,
    required this.brandColorHex,
    required this.accentColorHex,
    required this.customerName,
    required this.customerLocation,
    required this.customerMobile,
    required this.state,
    required this.leadName,
    required this.quotationId,
    required this.quotationDate,
    required this.expiryDate,
    required this.preparedBy,
    required this.contactNumbers,
    required this.plantCapacityKw,
    required this.lineItems,
    required this.subTotal,
    required this.taxGst,
    required this.cgstTotal,
    required this.sgstTotal,
    required this.grandTotal,
    required this.amountInWords,
    required this.notes,
    required this.bankDetails,
    required this.bomItems,
    required this.panelCount,
    required this.panelWattpeak,
    required this.panelBrand,
    required this.dcCableSpecs,
    required this.acWireSpecs,
    required this.earthingWireSpecs,
    required this.inverterKwValue,
    required this.effectiveUpfront,
    required this.subsidyAmount,
    required this.warrantySections,
    required this.upiId,
    required this.upiQrUpiId,
    this.useHinglish = false,
    required this.socialLinks,
    this.logoImage,
    this.heroImage,
    this.designImageTop,
    this.designImageLeft,
    this.designImageRight,
    this.upiQrImage,
    this.panelDetailImage,
  });

  // ── Factories ─────────────────────────────────────────────────────

  /// Builds a complete, internally-consistent default quotation from the app's
  /// price table (4.31 kW "Best Value" package) and constants.
  static SolarProposalData withDefaults({
    String? customerName,
    String? customerLocation,
    String? customerMobile,
    String? state,
    String? quotationId,
    String? quotationDate,
    String? preparedBy,
    String? plantCapacityKw,
    String? leadName,
    GSPackage? package,
    Uint8List? logoImage,
    /// --- admin-editable overrides ---
    String? dcCableSpecs,
    String? acWireSpecs,
    String? earthingWireSpecs,
    String? inverterKwOverride,
    int? customUpfrontPrice,
    bool? useHinglish,
  }) {
    final pkg = package ?? gsPackageById('p5')!; // 4.31 kW Best Value
    final upfront = customUpfrontPrice ?? pkg.upfront; // override if provided
    final subsidy = GSTax.subsidyMax; // 78000
    final structure = pkg.structureCost; // 12000
    final stamp = GSTax.stampCharge; // 300
    final meterCharge = 1500;
    final gedaCharge = 2000;
    const gstRate = 6.0; // % each of CGST & SGST => 12 % total

    final lineItems = [
      ProposalLineItem(
        description: '${pkg.kw.toStringAsFixed(2)} kW Solar PV System',
        specs: [
          '${pkg.panels} × ${pkg.panelWattpeak} Wp ${pkg.panelBrand} solar panels',
          '${pkg.panels} × MC4 connectors & MC4 extensions',
        ],
        qty: '1',
        unit: 'set',
        rate: upfront,
        cgstPercent: gstRate,
        sgstPercent: gstRate,
      ),
      ProposalLineItem(
        description: 'Structure & Mounting (Elevated)',
        specs: [
          pkg.structureDesc,
          'Hot-dip galvanized steel, 80×40×2 mm (leg & rafter), 40×40×2 mm (purlin)',
        ],
        qty: '1',
        unit: 'set',
        rate: structure,
        cgstPercent: gstRate,
        sgstPercent: gstRate,
      ),
      ProposalLineItem(
        description: 'Meter Charge & Agreement',
        specs: ['Single-phase net-meter application & agreement support'],
        qty: '1',
        unit: 'set',
        rate: meterCharge,
        cgstPercent: gstRate,
        sgstPercent: gstRate,
      ),
      ProposalLineItem(
        description: 'GEDA Registration Charge',
        specs: ['Government subsidy portal registration & processing'],
        qty: '1',
        unit: 'set',
        rate: gedaCharge,
        cgstPercent: gstRate,
        sgstPercent: gstRate,
      ),
      ProposalLineItem(
        description: 'Stamp Charge',
        specs: ['Govt. stamp paper for agreement'],
        qty: '1',
        unit: 'set',
        rate: stamp,
        cgstPercent: 0,
        sgstPercent: 0,
      ),
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

    final subTotal =
        lineItems.fold(0, (s, i) => s + (i.rate * i._qtyToInt) - i.discount);
    final cgstTotal = lineItems.fold(0, (s, i) => s + i.cgstAmount);
    final sgstTotal = lineItems.fold(0, (s, i) => s + i.sgstAmount);
    final taxGst = cgstTotal + sgstTotal;
    final grandTotal = subTotal + taxGst;

    final now = DateTime.now();
    final dq = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final expiry = '${(now.day + 15).toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    return SolarProposalData(
      companyName: 'Global Solar 2.0',
      companyTagline: siteConfigTagline,
      companyAddress: siteConfigAddress,
      companyEmail: siteConfigEmail,
      companyPhone: '${GSUsers.founderPhone} / ${GSUsers.coFounderPhone}',
      companyGstin: '24AABCG1234C1Z0',
      brandColorHex: '#3D2B6B',
      accentColorHex: '#F7941D',
      customerName: customerName ?? 'Valued Customer',
      customerLocation: customerLocation ?? 'Bhavnagar, Gujarat',
      customerMobile: customerMobile ?? '+91 ${GSUsers.founderPhone}',
      state: state ?? 'Gujarat',
      leadName: leadName ?? customerName ?? 'Valued Customer',
      quotationId: quotationId ?? 'GS-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-001',
      quotationDate: quotationDate ?? dq,
      expiryDate: expiry,
      preparedBy: preparedBy ?? 'Jayrajsinh S. Umat & Gopalsinh J. Parmar',
      contactNumbers: '${GSUsers.founderPhone} / ${GSUsers.coFounderPhone}',
      plantCapacityKw: plantCapacityKw ?? pkg.kw.toStringAsFixed(2),
      lineItems: lineItems,
      subTotal: subTotal,
      taxGst: taxGst,
      cgstTotal: cgstTotal,
      sgstTotal: sgstTotal,
      grandTotal: grandTotal,
      amountInWords: 'Indian Rupee ${_numberToWords(grandTotal)} Only',
      notes: _defaultNotes(pkg),
      bankDetails: const BankDetails(
        bankName: 'Bank of Baroda',
        accountName: 'Global Solar 2.0',
        accountNo: '25980500000094',
        ifsc: 'BARBOSSIBHA',
        branch: 'Bhavnagar',
      ),
      bomItems: _defaultBom(pkg,
          dcCableSpecs: dcCableSpecs ?? '4 sq.mm',
          acWireSpecs: acWireSpecs ?? '2.5 sq.mm',
          earthingWireSpecs: earthingWireSpecs ?? '2.5 sq.mm'),
      panelCount: pkg.panels,
      panelWattpeak: pkg.panelWattpeak,
      panelBrand: pkg.panelBrand,
      dcCableSpecs: dcCableSpecs ?? '4 sq.mm',
      acWireSpecs: acWireSpecs ?? '2.5 sq.mm',
      earthingWireSpecs: earthingWireSpecs ?? '2.5 sq.mm',
      inverterKwValue: inverterKwOverride ?? '3.6 kW',
      effectiveUpfront: upfront,
      subsidyAmount: subsidy,
      warrantySections: _defaultWarranty,
      upiId: 'global.solar.2.0@oksbi',
      upiQrUpiId: 'upi://pay?pa=global.solar.2.0@oksbi&pn=Global Solar 2.0&cu=INR',
      useHinglish: useHinglish ?? false,
      socialLinks: _defaultSocial,
      logoImage: logoImage,
    );
  }

  /// Convenience factory: convert an existing [ClientModel] + [QuoteModel]
  /// pair into a proposal, reusing real customer data.
  factory SolarProposalData.fromClientAndQuote({
    required ClientModel client,
    required QuoteModel quote,
    Uint8List? logoImage,
    String? dcCableSpecs,
    String? acWireSpecs,
    String? earthingWireSpecs,
    String? inverterKwOverride,
    int? customUpfrontPrice,
    bool? useHinglish,
  }) {
    final pkg = gsPackageById(quote.packageId) ?? gsPackages[2];
    return withDefaults(
      customerName: client.name,
      customerLocation: client.displayArea,
      customerMobile: '+91 ${client.phone}',
      state: client.area == GSArea.bhavnagar ? 'Gujarat' : 'Gujarat',
      leadName: client.name,
      plantCapacityKw: pkg.kw.toStringAsFixed(2),
      package: pkg,
      logoImage: logoImage,
      dcCableSpecs: dcCableSpecs,
      acWireSpecs: acWireSpecs,
      earthingWireSpecs: earthingWireSpecs,
      inverterKwOverride: inverterKwOverride,
      customUpfrontPrice: customUpfrontPrice,
      useHinglish: useHinglish,
    );
  }

  factory SolarProposalData.fromJson(Map<String, dynamic> j) =>
      SolarProposalData(
        companyName: j['company_name'] as String,
        companyTagline: j['company_tagline'] as String,
        companyAddress: j['company_address'] as String,
        companyEmail: j['company_email'] as String,
        companyPhone: j['company_phone'] as String,
        companyGstin: j['company_gstin'] as String,
        brandColorHex: j['brand_color'] as String? ?? '#3D2B6B',
        accentColorHex: j['accent_color'] as String? ?? '#F7941D',
        customerName: j['customer_name'] as String,
        customerLocation: j['customer_location'] as String,
        customerMobile: j['customer_mobile'] as String,
        state: j['state'] as String,
        leadName: j['lead_name'] as String,
        quotationId: j['quotation_id'] as String,
        quotationDate: j['quotation_date'] as String,
        expiryDate: j['expiry_date'] as String,
        preparedBy: j['prepared_by'] as String,
        contactNumbers: j['contact_numbers'] as String,
        plantCapacityKw: j['plant_capacity_kw'] as String,
        lineItems: (j['line_items'] as List)
            .map((e) => ProposalLineItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subTotal: j['sub_total'] as int,
        taxGst: j['tax_gst'] as int,
        cgstTotal: j['cgst_total'] as int? ?? 0,
        sgstTotal: j['sgst_total'] as int? ?? 0,
        grandTotal: j['grand_total'] as int,
        amountInWords: j['amount_in_words'] as String,
        notes: List<String>.from(j['notes'] as List),
        bankDetails:
            BankDetails.fromJson(j['bank_details'] as Map<String, dynamic>),
        bomItems: (j['bom_items'] as List)
            .map((e) => BomItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        panelCount: j['panel_count'] as int? ?? 0,
        panelWattpeak: j['panel_wattpeak'] as String? ?? '',
        panelBrand: j['panel_brand'] as String? ?? '',
        dcCableSpecs: j['dc_cable_specs'] as String? ?? '4 sq.mm',
        acWireSpecs: j['ac_wire_specs'] as String? ?? '2.5 sq.mm',
        earthingWireSpecs: j['earthing_wire_specs'] as String? ?? '2.5 sq.mm',
        inverterKwValue: j['inverter_kw_value'] as String? ?? '3.6 kW',
        effectiveUpfront: j['effective_upfront'] as int? ?? 0,
        subsidyAmount: j['subsidy_amount'] as int? ?? 0,
        warrantySections: (j['warranty_sections'] as List)
            .map((e) => WarrantySection.fromJson(e as Map<String, dynamic>))
            .toList(),
        upiId: j['upi_id'] as String,
        upiQrUpiId: j['upi_qr_upi_id'] as String? ?? '',
        useHinglish: j['use_hinglish'] as bool? ?? false,
        socialLinks: (j['social_links'] as List)
            .map((e) => SocialLink.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'company_name': companyName,
        'company_tagline': companyTagline,
        'company_address': companyAddress,
        'company_email': companyEmail,
        'company_phone': companyPhone,
        'company_gstin': companyGstin,
        'brand_color': brandColorHex,
        'accent_color': accentColorHex,
        'customer_name': customerName,
        'customer_location': customerLocation,
        'customer_mobile': customerMobile,
        'state': state,
        'lead_name': leadName,
        'quotation_id': quotationId,
        'quotation_date': quotationDate,
        'expiry_date': expiryDate,
        'prepared_by': preparedBy,
        'contact_numbers': contactNumbers,
        'plant_capacity_kw': plantCapacityKw,
        'line_items': lineItems.map((e) => e.toJson()).toList(),
        'sub_total': subTotal,
        'tax_gst': taxGst,
        'cgst_total': cgstTotal,
        'sgst_total': sgstTotal,
        'grand_total': grandTotal,
        'amount_in_words': amountInWords,
        'notes': notes,
        'bank_details': bankDetails.toJson(),
        'bom_items': bomItems.map((e) => e.toJson()).toList(),
        'panel_count': panelCount,
        'panel_wattpeak': panelWattpeak,
        'panel_brand': panelBrand,
        'dc_cable_specs': dcCableSpecs,
        'ac_wire_specs': acWireSpecs,
        'earthing_wire_specs': earthingWireSpecs,
        'inverter_kw_value': inverterKwValue,
        'effective_upfront': effectiveUpfront,
        'subsidy_amount': subsidyAmount,
        'warranty_sections': warrantySections.map((e) => e.toJson()).toList(),
        'upi_id': upiId,
        'upi_qr_upi_id': upiQrUpiId,
        'use_hinglish': useHinglish,
        'social_links': socialLinks.map((e) => e.toJson()).toList(),
      };
}

// ── siteConfig mirrors (kept local to avoid importing the website layer) ─
const siteConfigTagline = 'Serving Talaja, Bhavnagar and nearby villages';
const siteConfigAddress =
    'Shop No. 4A, Sukhsagar Complex, Bhagwati Circle, Kaliyabid, Bhavnagar, Gujarat 364002';
const siteConfigEmail = 'jayrajumat7797@gmail.com';

/// Default notes shown on the quotation footer box.
List<String> _defaultNotes(GSPackage pkg) => [
  '1. Final quotation is subject to a free site survey at the customer\'s location.',
  '2. Price is valid for 15 days from the date of issue.',
   '3. PM Surya Ghar residential subsidy of ₹78,000 is applicable only for residential rooftop solar (per connection, up to 10 kW).',
  '4. Commercial installations are not eligible for the subsidy.',
  '5. Required documents: Electricity Bill, Aadhaar Card, Cancelled Cheque.',
  '6. Prices last updated: ${GSTax.pricesLastUpdated}.',
];

/// Default BOM rows, populated with the selected package's specs.
List<BomItem> _defaultBom(GSPackage pkg, {
  String dcCableSpecs = '4 sq.mm',
  String acWireSpecs = '2.5 sq.mm',
  String earthingWireSpecs = '2.5 sq.mm',
}) => [
  BomItem(
    item: 'Solar Panels (PV Modules)',
    qty: '${pkg.panels}',
    unit: 'Nos.',
    brand: pkg.panelBrand,
    category: 'Solar Panels',
  ),
  BomItem(
    item: 'Solar String Inverter',
    qty: pkg.inverterQty,
    unit: 'Nos.',
    brand: pkg.inverterBrand,
    category: 'Inverters',
  ),
  BomItem(
    item: 'Solar Structure',
    qty: '${pkg.kw.toStringAsFixed(2)} kW',
    unit: 'set',
    brand: 'Hot-dip Galvanized Steel',
    category: 'Structure',
  ),
  BomItem(
    item: 'Protection Devices (ACDB / DCDB)',
    qty: '1',
    unit: 'set',
    brand: 'Havells',
    category: 'Protection Devices',
  ),
  BomItem(
    item: 'DC Cable',
    qty: '65',
    unit: 'mtr',
    brand: 'Polycab $dcCableSpecs',
    category: 'Cables',
  ),
  BomItem(
    item: 'AC Wire',
    qty: '80',
    unit: 'mtr',
    brand: 'Polycab $acWireSpecs',
    category: 'Cables',
  ),
  BomItem(
    item: 'Earthing Wire',
    qty: '150',
    unit: 'mtr',
    brand: 'Polycab $earthingWireSpecs',
    category: 'Earthing / LA',
  ),
  BomItem(
    item: 'LA (Aluminium) Cable',
    qty: '80',
    unit: 'mtr',
    brand: 'Polycab 16 sq.mm',
    category: 'Earthing / LA',
  ),
  BomItem(
    item: 'Conduit Pipe (PVC)',
    qty: '12',
    unit: 'mtr',
    brand: 'Polycab 20 mm',
    category: 'Cables',
  ),
  BomItem(
    item: 'Chemical Earthing',
    qty: '2',
    unit: 'Nos.',
    brand: 'Global Solar',
    category: 'Earthing / LA',
  ),
  BomItem(
    item: 'Cable Ties & Accessories',
    qty: '1',
    unit: 'set',
    brand: 'Shedal',
    category: 'Other Accessories',
  ),
];

/// Default warranty sections for pages 5–6.
List<WarrantySection> get _defaultWarranty => [
  WarrantySection(heading: '1. General Terms', bullets: [
    'All solar plant equipment is warranted against defects in material and workmanship.',
    'The warranty period commences from the date of successful commissioning.',
    'Any claim must be made in writing with supporting documentation and photos.',
  ]),
  WarrantySection(heading: '2. Government Subsidy (PM Surya Ghar)', bullets: [
    'Subsidy of ₹78,000 is applicable for residential connections up to 10 kW.',
    'The subsidy is credited directly by the government to the beneficiary\'s bank account.',
    'Global Solar 2.0 will assist in subsidy application but is not liable for any delay by the government agency.',
    'Commercial properties are not eligible for this subsidy.',
  ]),
  WarrantySection(heading: '3. Structure Terms', bullets: [
    'Hot-dip galvanized MS structure is warranted against corrosion for 5 years.',
    'Fabrication and erection work is warranted for 1 year against defects.',
  ]),
  WarrantySection(heading: '4. Solar Panel (PV Module) Performance Warranty', bullets: [
    'Product workmanship warranty: 12 years.',
    'Performance warranty: 80% output guaranteed for 25 years, 90% for 10 years.',
    'Linear power output warranty: 0.55% degradation per year.',
  ]),
  WarrantySection(heading: '5. Inverter Manufacturing Defect Warranty', bullets: [
    'String inverter: 5 + 5 years warranty (extendable up to 10 years).',
    'Workmanship defects covered for 2 years from commissioning.',
  ]),
  WarrantySection(heading: '6. Balance of System (BOS)', bullets: [
    'MC4 connectors, cables, and DC/AC box: 5 years.',
    'Chemical earthing: 5 years.',
    'Lightning arrester: 2 years.',
  ]),
  WarrantySection(heading: '7. Operation & Maintenance', bullets: [
    'Free comprehensive O&M for the first year after commissioning.',
    'AMC packages available from year 2 onwards at an additional cost.',
    '24x7 customer care: +91-${GSUsers.founderPhone}',
  ]),
  WarrantySection(heading: '8. Warranty Notes', bullets: [
    'Warranty is non-transferable but benefits the property owner.',
    'Force majeure events (lightning, floods) are not covered under standard warranty.',
    'Any unauthorised modification voids the warranty immediately.',
  ]),
  WarrantySection(heading: '9. Schedule for Site Completion', bullets: [
    'Material dispatch: within 3 working days of advance payment.',
    'Site survey & installation: within 7 working days of material arrival.',
    'Commissioning & net-meter application: within 15 working days of installation.',
  ]),
  WarrantySection(heading: '10. Quotation Validity', bullets: [
    'This quotation is valid for 15 days from the date of issue.',
    'Prices are subject to revision if the quotation validity period is exceeded.',
  ]),
  WarrantySection(heading: '11. Warranty Exclusions', bullets: [
    'Damage caused by natural calamities, negligence, or misuse.',
    'Performance degradation due to dust, bird droppings, or lack of cleaning.',
    'Any tampering with equipment or wiring by unauthorised persons.',
    'Normal wear and tear of consumable items (fuses, connectors).',
  ]),
  WarrantySection(heading: '12. Scope of Work For Customer', bullets: [
    'Provide safe and clear access to the rooftop on the scheduled date.',
    'Arrange 2-4 competent helpers for installation assistance (lifting panels).',
    'Share a recent electricity bill and property ownership documents.',
    'Coordinate with the local discom (MSED/PGVCL) for net-metering paperwork if required.',
  ]),
];

/// Default social / contact links for the footer.
List<SocialLink> get _defaultSocial => [
  SocialLink(name: 'Facebook', url: 'https://facebook.com/global.solar.2.0'),
  SocialLink(name: 'Instagram', url: 'https://instagram.com/global_solar_2.0'),
  SocialLink(name: 'LinkedIn', url: 'https://linkedin.com/company/global-solar-2-0'),
  SocialLink(name: 'Twitter', url: 'https://twitter.com/global_solar_2_0'),
  SocialLink(name: 'WhatsApp', url: 'https://wa.me/${GSUsers.whatsappNumber}'),
  SocialLink(name: 'Phone', url: 'tel:${GSUsers.founderPhone}'),
  SocialLink(name: 'Email', url: 'mailto:$siteConfigEmail'),
];

// ── Helpers ─────────────────────────────────────────────────────────

/// Converts an integer to Indian-English number words.
String _numberToWords(int n) {
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

/// Extension to add missing GSPackage helper getters used by defaults.
extension GSPackageProposalExt on GSPackage {
  String get panelBrand => 'Adani TOPCon';
  String get panelWattpeak => '610/615';
  String get inverterBrand => 'Polycab';
  String get inverterQty => '1';
  String get structureDesc => 'Elevated MS structure, 80×40×2 mm (leg & rafter), 40×40×2 mm (purlin)';
}






