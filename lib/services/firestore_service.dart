import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../models/app_settings.dart';
import '../models/client.dart';
import '../models/estimate.dart';
import '../models/follow_up.dart';
import '../models/installation.dart';
import '../models/payment.dart';
import '../models/quote.dart';

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

  // ── Follow-ups ────────────────────────────────────────────────

  Stream<List<FollowUpModel>> watchFollowUps() => _db
      .collection('followUps')
      .snapshots()
      .map((s) => s.docs
          .map((d) =>
              _try(() => FollowUpModel.fromJson(_map(d.data())), d.id, 'followUp'))
          .whereType<FollowUpModel>()
          .toList());

  Future<void> saveFollowUp(FollowUpModel f) =>
      _db.collection('followUps').doc(f.id).set(f.toJson());

  Future<void> deleteFollowUp(String id) =>
      _db.collection('followUps').doc(id).delete();

  // ── Quotes (legacy quote builder) ─────────────────────────────

  Stream<List<QuoteModel>> watchQuotes() => _db
      .collection('quotes')
      .snapshots()
      .map((s) => s.docs
          .map((d) =>
              _try(() => QuoteModel.fromJson(_map(d.data())), d.id, 'quote'))
          .whereType<QuoteModel>()
          .toList());

  Future<void> saveQuote(QuoteModel q) =>
      _db.collection('quotes').doc(q.id).set(q.toJson());

  Future<void> deleteQuote(String id) =>
      _db.collection('quotes').doc(id).delete();

  // ── Payments ──────────────────────────────────────────────────

  Stream<List<PaymentModel>> watchPayments() => _db
      .collection('payments')
      .snapshots()
      .map((s) => s.docs
          .map((d) =>
              _try(() => PaymentModel.fromJson(_map(d.data())), d.id, 'payment'))
          .whereType<PaymentModel>()
          .toList());

  Future<void> savePayment(PaymentModel p) =>
      _db.collection('payments').doc(p.id).set(p.toJson());

  // ── Installations ─────────────────────────────────────────────

  Stream<List<InstallationModel>> watchInstallations() => _db
      .collection('installations')
      .snapshots()
      .map((s) => s.docs
          .map((d) => _try(
              () => InstallationModel.fromJson(_map(d.data())),
              d.id,
              'installation'))
          .whereType<InstallationModel>()
          .toList());

  Future<void> saveInstallation(InstallationModel i) =>
      _db.collection('installations').doc(i.id).set(i.toJson());

  // ── Settings (single document) ────────────────────────────────

  Stream<AppSettingsModel> watchSettings() => _db
      .collection('settings')
      .doc('app')
      .snapshots()
      .map((d) =>
          d.exists ? AppSettingsModel.fromJson(_map(d.data())) : AppSettingsModel());

  Future<void> saveSettings(AppSettingsModel s) =>
      _db.collection('settings').doc('app').set(s.toJson());

  static T? _try<T>(T Function() build, String id, String kind) {
    try {
      return build();
    } catch (e) {
      debugPrint('Skipping bad $kind doc $id: $e');
      return null;
    }
  }

  static Map<String, dynamic> _map(Map<String, dynamic>? d) =>
      Map<String, dynamic>.from(d ?? {});
}