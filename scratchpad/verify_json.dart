import 'dart:convert';
import 'dart:io';

void main() {
  final raw = File('assets/data/estimate_master.json').readAsStringSync();
  final j = jsonDecode(raw) as Map<String, dynamic>;

  // Replicate BosItem.fromJson with the FIXED robust parser
  final bosItems = (j['bos_items'] as List);
  int totalQty = 0;
  for (final e in bosItems) {
    final m = Map<String, dynamic>.from(e);
    final qty = (m['qty'] as num?)?.toInt() ??
        int.tryParse((m['qty'] as String?)?.trim() ?? '') ??
        0;
    final rate = (m['rate'] as num?)?.toInt() ?? 0;
    print('name=${m['name']} qty=$qty rate=$rate total=${qty * rate}');
    totalQty += qty;
  }
  print('ALL BOS ITEMS PARSED OK. totalQty=$totalQty');

  // Also verify all other critical fields parse without error
  print('panels: ${(j['panels'] as List).length}');
  print('inverters: ${(j['inverters'] as List).length}');
  print('structure_pipes: ${(j['structure_pipes'] as List).length}');
  print('currencies: ${(j['currencies'] as List).length}');
  print('gst_profiles: ${(j['gst_profiles'] as List).length}');
  print('lead_stages: ${(j['lead_stages'] as List).length}');
  print('ALL MASTER DATA PARSED OK');
}
