import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

import '../core/constants.dart';
import '../models/estimate.dart';

/// Builds the standalone 7-page quotation **HTML** (self-contained: inline CSS,
/// embedded fonts, base64 images) from an [EstimateRecord] + [MasterData].
///
/// The same HTML string is used for the in-app WebView preview and for the
/// HTML→PDF export via `Printing.convertHtml`.
class QuotationHtml {
  QuotationHtml._();

  static const _assetEn = 'assets/templates/quotation.html';
  static const _assetGu = 'assets/templates/quotation_gu.html';
  static final Map<String, String> _cache = {};

  static final DateFormat _dmy = DateFormat('dd/MM/yyyy');
  static final DateFormat _dMonY = DateFormat('dd MMM yyyy');

  /// Returns the fully-populated 7-page HTML document.
  /// [language] is `'en'` (default) or `'gu'` (Gujarati).
  static Future<String> build({
    required EstimateRecord record,
    required MasterData master,
    String language = 'en',
  }) async {
    final lang = language == 'gu' ? 'gu' : 'en';
    if (_cache[lang] == null) {
      _cache[lang] =
          await rootBundle.loadString(lang == 'gu' ? _assetGu : _assetEn);
    }
    final tokens = _tokens(record, master, lang);

    // ── Panel-count design image (real asset, base64) ──
    final system = record.data.systemId != null
        ? gsQuoteSystemById(record.data.systemId!)
        : null;
    final asset =
        system?.panelImageAsset ?? 'assets/images/solar_plant_8_panels.png';
    try {
      final bytes = (await rootBundle.load(asset)).buffer.asUint8List();
      final mime = asset.endsWith('.png') ? 'image/png' : 'image/jpeg';
      tokens['PANEL_IMAGE'] = 'data:$mime;base64,${base64Encode(bytes)}';
    } catch (_) {
      tokens['PANEL_IMAGE'] = '';
    }

    // ── Bill of Materials (from the selected lines / master list) ──
    tokens['BOM_ROWS'] = _bomRows(record.data.bomLines, record.data);

    var html = _cache[lang]!;
    for (final e in tokens.entries) {
      html = html.replaceAll('{{${e.key}}}', e.value);
    }
    return html;
  }

  /// Name of the logged-in creator (strips the "Mr." style title).
  static String _creatorName(EstimateModel e) {
    var n = (e.createdByName ?? '').trim();
    if (n.isEmpty) return 'Jayrajsinh S. Umat';
    for (final p in const ['Mr. ', 'Mrs. ', 'Ms. ', 'Dr. ']) {
      if (n.startsWith(p)) {
        n = n.substring(p.length).trim();
        break;
      }
    }
    return n;
  }

  static String _creatorTitle(EstimateModel e, String lang) {
    final gu = lang == 'gu';
    if (e.createdByRole == 'coowner') {
      return gu ? 'સહ-સ્થાપક અને ઓપરેશન્સ' : 'Co-Founder & Operations';
    }
    return gu
        ? 'સ્થાપક અને મુખ્ય ટેકનિકલ ઓફિસર'
        : 'Founder & Chief Technical Officer';
  }

  /// Cover block showing the lead's requirement / site notes (empty if none).
  static String _siteNotesBlock(String? notes) {
    final n = (notes ?? '').trim();
    if (n.isEmpty) return '';
    return '<div class="mt-2 pt-2 border-t border-slate-100">'
        '<span class="text-[9px] uppercase font-bold tracking-wider '
        'text-slate-400 block mb-0.5">Site Requirement &amp; Notes</span>'
        '<p class="text-[10.5px] text-slate-600 leading-snug">${_esc(n)}</p>'
        '</div>';
  }

  static String _bomRows(List<BomLine> lines, EstimateModel e) {
    final src = lines.isNotEmpty
        ? lines
        : gsBomItems
            .map((b) => BomLine(
                name: b.name, qty: b.qty, unit: b.unit, brand: b.brand))
            .toList();
    if (src.isEmpty) return '';
    final ac = e.acWiringSqMm?.trim();
    final dc = e.dcWiringSqMm?.trim();
    final sb = StringBuffer();
    for (var i = 0; i < src.length; i++) {
      final l = src[i];
      // Show the AC / DC wiring size on the matching cable rows.
      var name = l.name;
      final ln = l.name.toLowerCase();
      if (ln.contains('ac cable') && ac != null && ac.isNotEmpty) {
        name = '$name ($ac)';
      } else if (ln.contains('dc cable') && dc != null && dc.isNotEmpty) {
        name = '$name ($dc)';
      }
      final shade = i.isEven ? 'bg-white' : 'bg-slate-50/50';
      sb.writeln('<tr class="$shade">'
          '<td class="py-1.5 px-3 text-center text-slate-500 font-mono">${i + 1}</td>'
          '<td class="py-1.5 px-3 font-medium text-slate-800">${_esc(name)}</td>'
          '<td class="py-1.5 px-3 text-center font-bold">${l.qty}</td>'
          '<td class="py-1.5 px-3 text-center text-slate-600">${_esc(l.unit)}</td>'
          '<td class="py-1.5 px-4 font-semibold text-[#0B1F5C]">'
          '${_esc(l.brand.trim().isEmpty ? 'As per standard' : l.brand)}'
          '</td></tr>');
    }
    return sb.toString();
  }

  // ── Token mapping ──────────────────────────────────────────────────────

  static Map<String, String> _tokens(
      EstimateRecord record, MasterData master, String lang) {
    final e = record.data;
    final system =
        e.systemId != null ? gsQuoteSystemById(e.systemId!) : null;

    final kw = e.capacityKw ?? system?.kw ?? 0;
    final panels = system?.panels ?? 0;
    final wattLabel = system?.wattLabel ?? '540/545/550';
    final brandEn = system?.brandEn ?? 'Adani Bi-Facial';
    final brandGu = system?.brandGu ?? 'અદાણી બાય એફિશિયલ';
    final subsidy = system?.subsidy ?? 0;
    final invKw = e.inverterKwManual ??
        (kw > 0 ? (kw + 0.64) : 0);

    // ── Price model (mirrors EstimatePdf._fromSystem) ──
    final baseTotal =
        e.totalPayableOverride ?? system?.totalPayable ?? 0;
    final structure =
        e.structureCostOverride ?? system?.structureCost ?? 0;
    final stamp = e.stampChargeOverride ?? system?.stampCharge ?? 0;
    final includeGst = e.gstIncluded;
    final gstMul = 1 + GSGst.totalPercent / 100;

    final systemStructure = system?.structureCost ?? 0;
    final systemStamp = system?.stampCharge ?? 0;
    final pvTaxable =
        ((baseTotal - systemStructure - systemStamp) / gstMul).round();
    final cgstPct = includeGst ? GSGst.cgstPercent : 0.0;
    final sgstPct = includeGst ? GSGst.sgstPercent : 0.0;
    final cgst = ((pvTaxable * cgstPct) / 100).round();
    final sgst = ((pvTaxable * sgstPct) / 100).round();

    // Custom line items
    final rows = <String>[];
    var idx = 0;
    String nextNo() => (++idx).toString().padLeft(2, '0');

    rows.add(_row(
      no: nextNo(),
      title: '${kw.toStringAsFixed(2)} kW Solar PV System (Grid-Tied)',
      desc: '$panels × $wattLabel Wp $brandEn Tier-1 Modules '
          '(Glass-to-Glass), 1 × ${invKw.toStringAsFixed(1)} kW Smart MPPT '
          'Inverter, $panels Pairs MC4 Connectors, AC/DC DB boxes, '
          '${e.acWiringSqMm ?? '2.5 sq.mm'} AC & '
          '${e.dcWiringSqMm ?? '4.0 sq.mm'} DC UV cables.',
      qty: '1 Set',
      rate: pvTaxable,
      cgstPct: cgstPct,
      sgstPct: sgstPct,
      total: pvTaxable + cgst + sgst,
    ));
    rows.add(_row(
      no: nextNo(),
      title: 'Structure &amp; Mounting (Elevated GI Walkway)',
      desc: 'Heavy duty hot-dip galvanized C-channel frame with 8.5ft '
          'clearance, dual earthing civil work, wind resistance up to '
          '160 km/h.',
      qty: '1 Job',
      rate: structure,
      cgstPct: 0,
      sgstPct: 0,
      total: structure,
    ));
    rows.add(_row(
      no: nextNo(),
      title: 'Stamp Paper, Agreement &amp; Portal Documentation',
      desc: 'Legal agreement franking, PGVCL liaison, CEIG compliance '
          'processing.',
      qty: '1 Job',
      rate: stamp,
      cgstPct: 0,
      sgstPct: 0,
      total: stamp,
    ));

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
      final g = it.cgstPercent + it.sgstPercent;
      rows.add(_row(
        no: nextNo(),
        title: _esc(it.description),
        desc: '$qty × Rs.${_inr(it.rate)} • GST ${_gstLabel(g)}%',
        qty: '$qty Set',
        rate: base,
        cgstPct: includeGst ? it.cgstPercent : 0,
        sgstPct: includeGst ? it.sgstPercent : 0,
        total: base + c + s,
      ));
    }

    final baseExclGst = pvTaxable + structure + stamp + customNet;
    final cgstTotal = cgst + customCgst;
    final sgstTotal = sgst + customSgst;
    final gross = baseExclGst + cgstTotal + sgstTotal;
    final afterSubsidy = gross - subsidy;

    if (subsidy > 0) {
      rows.add(_subsidyRow(nextNo(), subsidy));
    }

    // ── Cover / meta ──
    final date = _dmy.format(record.createdAt);
    final quoteDate = _dMonY.format(record.createdAt);
    final validity = _dMonY.format(e.expiryDate);
    final loc = (e.address ?? '').trim().isNotEmpty
        ? e.address!.trim()
        : 'Bhavnagar, Gujarat';
    final name = e.leadName.trim();
    final cols = panels == 0 ? 2 : ((panels + 1) ~/ 2);
    final creatorName = _creatorName(e);
    final creatorTitle = _creatorTitle(e, lang);

    return {
      'CLIENT_NAME': _esc(name),
      'CLIENT_NAME_UPPER': _esc(name.toUpperCase()),
      'CLIENT_NAME_FULL': _esc(name),
      'CLIENT_LOCATION': _esc(loc),
      'CLIENT_ADDRESS': _esc(loc),
      'CLIENT_MOBILE': '+91 ${_esc(e.mobileNumber)}',
      'CONSUMER_NO': _esc(e.referenceNo?.trim().isNotEmpty == true
          ? e.referenceNo!.trim()
          : '—'),
      'ESTIMATE_NO': _esc(e.estimateNumber.trim().isNotEmpty
          ? e.estimateNumber.trim()
          : record.id),
      'DATE': date,
      'QUOTE_DATE': quoteDate,
      'VALIDITY_DATE': validity,
      'CREATED_BY': creatorName,
      'CREATED_BY_TITLE': creatorTitle,
      'PREPARED_BY': creatorName,
      'FOUNDER_NAME': 'Jayrajsinh S. Umat',
      'CAPACITY': '${kw.toStringAsFixed(2)} kW',
      'CAPACITY_CONFIG': lang == 'gu'
          ? '${kw.toStringAsFixed(2)} kWp ટર્નકી કન્ફિગ'
          : '${kw.toStringAsFixed(2)} kWp Turnkey Config',
      'SUBSIDY_GUARANTEE': lang == 'gu'
          ? '₹${_inr(subsidy)} ખાતરીપૂર્વક'
          : '₹${_inr(subsidy)} Guaranteed',
      'PANEL_COUNT': '$panels',
      'ARRAY_RC': '2x$cols',
      'PANEL_BRAND': brandEn,
      'PANEL_BRAND_GU': brandGu,
      'PANEL_WATT': wattLabel,
      'MODULE_WARRANTY': '${system?.moduleWarrantyYears ?? 30}',
      'SITE_NOTES_BLOCK': _siteNotesBlock(e.description),
      'TABLE_ROWS': rows.join('\n'),
      'GROSS': '₹${_inr2(gross)}',
      'SUBSIDY_AMT': '− ₹${_inr2(subsidy)}',
      'NET_COST': '₹${_inr2(afterSubsidy)}',
      'AMOUNT_WORDS': lang == 'gu'
          ? 'ભારતીય રૂપિયા ${_wordsGu(afterSubsidy)} પૂરા'
          : 'Indian Rupee ${_words(afterSubsidy)} Only',
    };
  }

  // ── Table row HTML ─────────────────────────────────────────────────────

  static String _row({
    required String no,
    required String title,
    required String desc,
    required String qty,
    required int rate,
    required double cgstPct,
    required double sgstPct,
    required int total,
  }) {
    return '''
<tr class="bg-white hover:bg-slate-50">
<td class="py-2 px-2.5 text-center font-bold text-slate-400">$no</td>
<td class="py-2 px-3">
<span class="font-bold text-[#071440] block">$title</span>
<span class="text-[9.5px] text-slate-500 block leading-tight">$desc</span>
</td>
<td class="py-2 px-2 text-center font-medium">$qty</td>
<td class="py-2 px-2.5 text-right font-mono text-slate-700">${_inr(rate)}</td>
<td class="py-2 px-2 text-right font-mono text-slate-500">₹0</td>
<td class="py-2 px-2 text-right font-mono text-slate-500">${_gstLabel(cgstPct)}%</td>
<td class="py-2 px-2 text-right font-mono text-slate-500">${_gstLabel(sgstPct)}%</td>
<td class="py-2 px-3 text-right font-mono font-bold text-[#071440]">${_inr(total)}</td>
</tr>''';
  }

  static String _subsidyRow(String no, int subsidy) {
    return '''
<tr class="bg-[#E6F4EA]/50 font-semibold text-[#1E8E3E]">
<td class="py-2 px-2.5 text-center font-bold text-[#1E8E3E]">$no</td>
<td class="py-2 px-3">
<span class="font-bold block text-[#1E8E3E]">PM Surya Ghar: Muft Bijli Yojana Central Subsidy</span>
<span class="text-[9.5px] text-emerald-700 block">Direct Benefit Transfer (DBT) approved for 3 kW+ capacity. Credited directly to customer bank account post bi-directional meter activation.</span>
</td>
<td class="py-2 px-2 text-center">1 App</td>
<td class="py-2 px-2.5 text-right font-mono">−${_inr(subsidy)}</td>
<td class="py-2 px-2 text-right font-mono">—</td>
<td class="py-2 px-2 text-right font-mono">0%</td>
<td class="py-2 px-2 text-right font-mono">0%</td>
<td class="py-2 px-3 text-right font-mono font-bold text-[#1E8E3E]">−₹${_inr(subsidy)}</td>
</tr>''';
  }

  // ── Formatting helpers ─────────────────────────────────────────────────

  static String _gstLabel(double v) => v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toStringAsFixed(2);

  static String _inr(num v) =>
      NumberFormat.decimalPattern('en_IN').format(v.round());

  static String _inr2(num v) =>
      NumberFormat('#,##,##0.00', 'en_IN').format(v);

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  // ── Indian number → words ──────────────────────────────────────────────

  static const _ones = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight',
    'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
    'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
  ];
  static const _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy',
    'Eighty', 'Ninety'
  ];

  static String _twoDigits(int n) {
    if (n < 20) return _ones[n];
    return '${_tens[n ~/ 10]}${n % 10 == 0 ? '' : ' ${_ones[n % 10]}'}';
  }

  static String _words(int n) {
    if (n == 0) return 'Zero';
    var num = n;
    final parts = <String>[];
    final crore = num ~/ 10000000;
    num %= 10000000;
    final lakh = num ~/ 100000;
    num %= 100000;
    final thousand = num ~/ 1000;
    num %= 1000;
    final hundred = num ~/ 100;
    num %= 100;
    if (crore > 0) parts.add('${_twoDigits(crore)} Crore');
    if (lakh > 0) parts.add('${_twoDigits(lakh)} Lakh');
    if (thousand > 0) parts.add('${_twoDigits(thousand)} Thousand');
    if (hundred > 0) parts.add('${_ones[hundred]} Hundred');
    if (num > 0) parts.add(_twoDigits(num));
    return parts.join(' ');
  }

  // ── Gujarati number → words ────────────────────────────────────────────

  static const _guOnes = [
    '', 'એક', 'બે', 'ત્રણ', 'ચાર', 'પાંચ', 'છ', 'સાત', 'આઠ', 'નવ',
    'દસ', 'અગિયાર', 'બાર', 'તેર', 'ચૌદ', 'પંદર', 'સોળ', 'સત્તર', 'અઢાર',
    'ઓગણીસ'
  ];
  static const _guTens = [
    '', '', 'વીસ', 'ત્રીસ', 'ચાલીસ', 'પચાસ', 'સાઠ', 'સિત્તેર', 'એંસી',
    'નેવું'
  ];

  static String _guTwo(int n) {
    if (n < 20) return _guOnes[n];
    return '${_guTens[n ~/ 10]}${n % 10 == 0 ? '' : ' ${_guOnes[n % 10]}'}';
  }

  static String _wordsGu(int n) {
    if (n == 0) return 'શૂન્ય';
    var num = n;
    final parts = <String>[];
    final crore = num ~/ 10000000;
    num %= 10000000;
    final lakh = num ~/ 100000;
    num %= 100000;
    final thousand = num ~/ 1000;
    num %= 1000;
    final hundred = num ~/ 100;
    num %= 100;
    if (crore > 0) parts.add('${_guTwo(crore)} કરોડ');
    if (lakh > 0) parts.add('${_guTwo(lakh)} લાખ');
    if (thousand > 0) parts.add('${_guTwo(thousand)} હજાર');
    if (hundred > 0) parts.add('${_guOnes[hundred]} સો');
    if (num > 0) parts.add(_guTwo(num));
    return parts.join(' ');
  }
}
