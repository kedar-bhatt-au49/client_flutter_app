import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../models/client.dart';
import '../models/estimate.dart';

/// Firestore-backed persistence for **clients** and **quotations**.
///
/// Follow-ups / payments / installations / settings still use local Hive
/// storage for now (phase 2 will move them here too).
class FirestoreService {
  FirestoreService._internal();
  static final FirestoreService instance = FirestoreService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Clients ───────────────────────────────────────────────────

  Stream<List<ClientModel>> watchClients() => _db
      .collection('clients')
      .snapshots()
      .map((s) => s.docs
          .map((d) {
            try {
              return ClientModel.fromJson(_map(d.data()));
            } catch (e) {
              debugPrint('Skipping bad client doc ${d.id}: $e');
              return null;
            }
          })
          .whereType<ClientModel>()
          .toList());

  Future<void> saveClient(ClientModel c) =>
      _db.collection('clients').doc(c.id).set(c.toJson());

  Future<void> deleteClient(String id) =>
      _db.collection('clients').doc(id).delete();

  // ── Estimates / quotations ────────────────────────────────────

  Stream<List<EstimateRecord>> watchEstimates(MasterData master) => _db
      .collection('estimates')
      .snapshots()
      .map((s) => s.docs
          .map((d) {
            try {
              return EstimateRecord.fromJson(_map(d.data()), master);
            } catch (e) {
              debugPrint('Skipping bad estimate doc ${d.id}: $e');
              return null;
            }
          })
          .whereType<EstimateRecord>()
          .toList());

  /// Creates (no [id]) or updates (with [id]) an estimate document.
  Future<EstimateRecord> saveEstimate(
    EstimateModel e, {
    String? id,
    DateTime? createdAt,
  }) async {
    final docId = id ?? _db.collection('estimates').doc().id;
    final now = DateTime.now();
    final record = EstimateRecord(
      id: docId,
      data: e,
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
    await _db.collection('estimates').doc(docId).set(record.toJson());
    return record;
  }

  Future<void> deleteEstimate(String id) =>
      _db.collection('estimates').doc(id).delete();

  /// Atomically reserves the next quotation number (safe across devices).
  /// e.g. prefix "EST" → "EST-007". Throws if offline / rules deny.
  Future<String> nextEstimateNumber(String prefix) async {
    final ref = _db.collection('counters').doc('estimates');
    final seq = await _db.runTransaction<int>((tx) async {
      final snap = await tx.get(ref);
      final current = (snap.data()?['seq'] as int?) ?? 0;
      final next = current + 1;
      tx.set(ref, {'seq': next}, SetOptions(merge: true));
      return next;
    });
    return '${prefix}-${seq.toString().padLeft(3, '0')}';
  }

  static Map<String, dynamic> _map(Map<String, dynamic>? d) =>
      Map<String, dynamic>.from(d ?? {});
}
