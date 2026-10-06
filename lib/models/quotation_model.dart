/// ---------------------------------------------------------------------------
/// Global Enterprise — Quotation Data Model
///
/// Holds all fields for the "GLOBAL ENTERPRISE" solar quotation layout.
/// Used by [GlobalEnterpriseQuotation] widget to render a dynamic, parameterised
/// quotation that mirrors the printed template.
/// ---------------------------------------------------------------------------
class QuotationData {
  // ── Company info ─────────────────────────────────────────────────
  final String companyName;
  final String companyTagline;
  final String officeAddress;
  final String mobileNumbers;
  final String bankName;
  final String accountNumber;
  final String ifscCode;

  // ── Customer info ─────────────────────────────────────────────────
  final DateTime date;
  final String consumerName;
  final String contactNumber;
  final String address;

  // ── System specs ──────────────────────────────────────────────────
  final String solarPanelBrand;
  final String solarPanelWattpeak;
  final int solarPanelQuantity;
  final String inverterBrand;
  final String inverterKw;
  final String systemCapacity;
  final String dcCableBrand;
  final String dcCableSpecs;
  final String dcCableLengthFt;
  final String acWireBrand;
  final String acWireSpecs;
  final String acWireLengthFt;
  final String earthingWireBrand;
  final String earthingWireSpecs;
  final String earthingWireLengthFt;
  final String laCableSpecs;
  final String laCableLengthFt;
  final String dcSideMcb;
  final String acSideMcb;
  final String conduitPvc;
  final String structureHeight;
  final String pipeForLeg;
  final String pipeForRafter;
  final String pipeForPurlin;

  // ── Pricing ──────────────────────────────────────────────────────
  final int netPayableAmount;
  final int governmentSubsidy;
  final int netCostAfterSubsidy;

  // ── Page info ─────────────────────────────────────────────────────
  final String pageInfo;

  const QuotationData({
    // Company
    this.companyName = 'GLOBAL ENTERPRISE',
    this.companyTagline = 'Save Energy • Save Money • Save Earth',
    this.officeAddress =
        'OFFICE ADDRESS: GLOBAL SOLAR, F6, NATRAJ COMPLEX, OPP TOP3 CINEMA, BHAVNAGAR',
    this.mobileNumbers = 'Mo : (+91) 9924900599 / 9924900988',
    this.bankName = 'Bank of Baroda',
    this.accountNumber = '41400100011834',
    this.ifscCode = 'BARBOKALIAB',

    // Customer
    required this.date,
    required this.consumerName,
    required this.contactNumber,
    required this.address,

    // System specs
    this.solarPanelBrand = 'ADANI',
    this.solarPanelWattpeak = '610-615 Watt',
    this.solarPanelQuantity = 6,
    this.inverterBrand = 'POLYCAB',
    this.inverterKw = '3.6 kW',
    this.systemCapacity = '3.69 kW DC / 3.6 kW AC',
    this.dcCableBrand = 'POLYCAB',
    this.dcCableSpecs = '4 sq. mm',
    this.dcCableLengthFt = '65 ft',
    this.acWireBrand = 'POLYCAB',
    this.acWireSpecs = '2.5 sq. mm',
    this.acWireLengthFt = '80 ft',
    this.earthingWireBrand = 'POLYCAB',
    this.earthingWireSpecs = '2.5 sq. mm',
    this.earthingWireLengthFt = '150 ft',
    this.laCableSpecs = '16 sq. mm',
    this.laCableLengthFt = '80 ft',
    this.dcSideMcb = 'HAVELLS',
    this.acSideMcb = 'HAVELLS',
    this.conduitPvc = 'WHITE PVC POLYCAB',
    this.structureHeight = 'Up to 6.00 ft × 8.00 ft from bottom of terrace',
    this.pipeForLeg = '80 mm × 40 mm × 2 mm',
    this.pipeForRafter = '80 mm × 40 mm × 2 mm',
    this.pipeForPurlin = '40 mm × 40 mm × 2 mm',

    // Pricing — defaults from the price list for 6-panel / 3.69 kW package
    this.netPayableAmount = 178000,
    this.governmentSubsidy = 78000,
    this.netCostAfterSubsidy = 100000,

    // Page
    this.pageInfo = 'Page 1 of 2',
  });

  int get _netPayable => netPayableAmount;
  int get _subsidy => governmentSubsidy;
  int get _netCost => netCostAfterSubsidy;

  String get formattedNetPayable => '₹ ${_netPayable.formatWithComma()}/- Rs.';
  String get formattedSubsidy => '₹ ${_subsidy.formatWithComma()}/- Rs.';
  String get formattedNetCost => '₹ ${_netCost.formatWithComma()}/- Rs.';
  String get formattedCashPayable => '₹ ${_netPayable.formatWithComma()}/-';

  QuotationData copyWith({
    String? companyName,
    String? companyTagline,
    String? officeAddress,
    String? mobileNumbers,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    DateTime? date,
    String? consumerName,
    String? contactNumber,
    String? address,
    String? solarPanelBrand,
    String? solarPanelWattpeak,
    int? solarPanelQuantity,
    String? inverterBrand,
    String? inverterKw,
    String? systemCapacity,
    String? dcCableBrand,
    String? dcCableSpecs,
    String? dcCableLengthFt,
    String? acWireBrand,
    String? acWireSpecs,
    String? acWireLengthFt,
    String? earthingWireBrand,
    String? earthingWireSpecs,
    String? earthingWireLengthFt,
    String? laCableSpecs,
    String? laCableLengthFt,
    String? dcSideMcb,
    String? acSideMcb,
    String? conduitPvc,
    String? structureHeight,
    String? pipeForLeg,
    String? pipeForRafter,
    String? pipeForPurlin,
    int? netPayableAmount,
    int? governmentSubsidy,
    int? netCostAfterSubsidy,
    String? pageInfo,
  }) {
    return QuotationData(
      companyName: companyName ?? this.companyName,
      companyTagline: companyTagline ?? this.companyTagline,
      officeAddress: officeAddress ?? this.officeAddress,
      mobileNumbers: mobileNumbers ?? this.mobileNumbers,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      date: date ?? this.date,
      consumerName: consumerName ?? this.consumerName,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      solarPanelBrand: solarPanelBrand ?? this.solarPanelBrand,
      solarPanelWattpeak: solarPanelWattpeak ?? this.solarPanelWattpeak,
      solarPanelQuantity: solarPanelQuantity ?? this.solarPanelQuantity,
      inverterBrand: inverterBrand ?? this.inverterBrand,
      inverterKw: inverterKw ?? this.inverterKw,
      systemCapacity: systemCapacity ?? this.systemCapacity,
      dcCableBrand: dcCableBrand ?? this.dcCableBrand,
      dcCableSpecs: dcCableSpecs ?? this.dcCableSpecs,
      dcCableLengthFt: dcCableLengthFt ?? this.dcCableLengthFt,
      acWireBrand: acWireBrand ?? this.acWireBrand,
      acWireSpecs: acWireSpecs ?? this.acWireSpecs,
      acWireLengthFt: acWireLengthFt ?? this.acWireLengthFt,
      earthingWireBrand: earthingWireBrand ?? this.earthingWireBrand,
      earthingWireSpecs: earthingWireSpecs ?? this.earthingWireSpecs,
      earthingWireLengthFt: earthingWireLengthFt ?? this.earthingWireLengthFt,
      laCableSpecs: laCableSpecs ?? this.laCableSpecs,
      laCableLengthFt: laCableLengthFt ?? this.laCableLengthFt,
      dcSideMcb: dcSideMcb ?? this.dcSideMcb,
      acSideMcb: acSideMcb ?? this.acSideMcb,
      conduitPvc: conduitPvc ?? this.conduitPvc,
      structureHeight: structureHeight ?? this.structureHeight,
      pipeForLeg: pipeForLeg ?? this.pipeForLeg,
      pipeForRafter: pipeForRafter ?? this.pipeForRafter,
      pipeForPurlin: pipeForPurlin ?? this.pipeForPurlin,
      netPayableAmount: netPayableAmount ?? this.netPayableAmount,
      governmentSubsidy: governmentSubsidy ?? this.governmentSubsidy,
      netCostAfterSubsidy: netCostAfterSubsidy ?? this.netCostAfterSubsidy,
      pageInfo: pageInfo ?? this.pageInfo,
    );
  }
}

// ── Formatter extension ──────────────────────────────────────────────
extension QuotationNumberFmt on int {
  /// Indian-style comma grouping: 178000 → "1,78,000"
  String formatWithComma() {
    final s = toString();
    if (s.length <= 3) return s;
    final parts = <String>[];
    final remainder = s.length % 2;
    if (remainder != 0) {
      parts.add(s.substring(0, remainder));
    }
    for (var i = remainder; i < s.length; i += 2) {
      parts.add(s.substring(i, i + 2));
    }
    return parts.join(',');
  }
}
