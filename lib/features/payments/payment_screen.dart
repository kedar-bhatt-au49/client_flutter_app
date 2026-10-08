import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/payment.dart';
import '../../providers/data_hub.dart';
import '../../services/storage_service.dart';

/// Payments & Documents — exact design: navy header, summary banner,
/// milestones, documents, fixed bottom bar.
class PaymentScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const PaymentScreen(
      {super.key, required this.clientId, required this.clientName});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const _gold = Color(0xFFF9B417);
  static const _goldLight = Color(0xFFFFCA40);
  static const _goldDark = Color(0xFFD9980B);
  static const _navy900 = Color(0xFF071440);
  static const _navy800 = Color(0xFF0B1F5C);
  static const _sky = Color(0xFFEAF4FF);
  static const _skyBorder = Color(0xFFDBEAFE);
  static const _dark = Color(0xFF0F1B3D);
  static const _slate = Color(0xFF627193);
  static const _green = Color(0xFF059669);
  static const _greenLight = Color(0xFF10B981);
  static const _blue = Color(0xFF1E5BD8);

  @override
  Widget build(BuildContext context) {
    final hub = context.watch<DataHub>();
    final payment = hub.getPaymentForClient(widget.clientId) ??
        PaymentModel(id: hub.generateId(), clientId: widget.clientId);
    final quote = hub.getQuoteForClient(widget.clientId);

    // Amounts (data-driven; fall back to registration default)
    final total = quote?.upfront ?? payment.registrationAmount + 76000;
    final registrationAmt = payment.registrationAmount;
    final balanceAmt = total - registrationAmt;
    final paid = (payment.registrationPaid ? registrationAmt : 0) +
        (payment.balancePaid ? balanceAmt : 0);
    final balance = total - paid;
    final progress = total == 0 ? 0.0 : paid / total;
    final cleared = payment.balancePaid && payment.registrationPaid;

    return Scaffold(
      backgroundColor: _sky,
      body: Column(
        children: [
          // ── 1. Header ─────────────────────────────────────────
          _buildHeader(context),
          // ── Scrollable body ───────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryBanner(total, paid, balance, progress, cleared,
                      payment.registrationPaid, payment.balancePaid,
                      registrationAmt, balanceAmt),
                  const SizedBox(height: 16),
                  _buildMilestones(
                      context, hub, payment, registrationAmt, balanceAmt),
                  const SizedBox(height: 16),
                  _buildDocuments(context, hub, payment),
                  const SizedBox(height: 16),
                  _buildDbtNote(),
                ],
              ),
            ),
          ),
          // ── 5. Fixed bottom bar ───────────────────────────────
          _buildBottomBar(context, hub, payment),
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
          colors: [_navy900, _navy800, _navy900],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
                        Flexible(
                          child: Text(
                            'Payments & Documents',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const _PulseDot(),
                      ],
                    ),
                    Text(widget.clientName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xCCD0E6FF))),
                  ],
                ),
              ),
              // Add payment (gold rupee)
              InkWell(
                onTap: () => _showAddPaymentSheet(context),
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
                      BoxShadow(color: _gold.withValues(alpha: 0.4), blurRadius: 10),
                    ],
                  ),
                  child: const Icon(Icons.currency_rupee_rounded,
                      color: _navy900, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Summary banner ─────────────────────────────────────────────
  Widget _buildSummaryBanner(int total, int paid, int balance, double progress,
      bool cleared, bool registrationPaid, bool balancePaid, int registrationAmt,
      int balanceAmt) {
    final pct = (progress * 100).toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy800, _navy900, _navy900],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: const [
          BoxShadow(color: Color(0x4D071440), blurRadius: 25, offset: Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          // watermark ornament
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: Icon(Icons.solar_power_rounded,
                size: 60, color: _goldLight.withValues(alpha: 0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top row
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        border:
                            Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Icon(Icons.currency_rupee_rounded,
                          size: 16, color: _goldLight),
                    ),
                    const SizedBox(width: 8),
                    const Text('TOTAL SYSTEM DUE',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Color(0xCCD0E6FF))),
                    const Spacer(),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: _gold.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _goldLight,
                              boxShadow: [
                                BoxShadow(
                                    color: _goldLight.withValues(alpha: 0.7),
                                    blurRadius: 4),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(cleared ? 'Cleared' : 'Partially Paid',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: _goldLight)),
                        ],
                      ),
                    ),
                  ],
                ),
                // Big amount
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('₹${total.formatWithComma()}',
                        style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5)),
                    const SizedBox(width: 6),
                    const Text('on-grid turnkey',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0x99D0E6FF),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _greenLight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('₹${paid.formatWithComma()} paid',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _goldLight)),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Color(0x66FFFFFF))),
                    const SizedBox(width: 8),
                    Text('₹${balance.formatWithComma()} balance remaining',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xCCD0E6FF))),
                  ],
                ),
                // Progress bar
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment Progress',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xCCD0E6FF),
                            fontWeight: FontWeight.w500)),
                    Text('$pct%',
                        style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: _goldLight)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_gold, _goldLight, _gold],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                // Bottom stats
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Registration',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xB3D0E6FF))),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 15,
                                    color: registrationPaid
                                        ? _greenLight
                                        : const Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Text('₹${registrationAmt.formatWithComma()}',
                                    style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: (registrationPaid
                                            ? _greenLight
                                            : Colors.white)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                      registrationPaid
                                          ? 'Paid'
                                          : 'Pending',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: registrationPaid
                                              ? _greenLight
                                              : const Color(0xFF94A3B8))),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 34,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Balance due',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xB3D0E6FF))),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                    balancePaid
                                        ? Icons.check_circle_rounded
                                        : Icons.schedule_rounded,
                                    size: 15,
                                    color: balancePaid
                                        ? _greenLight
                                        : _goldLight),
                                const SizedBox(width: 4),
                                Text('₹${balance.formatWithComma()}',
                                    style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: (balancePaid
                                            ? _greenLight
                                            : _goldLight)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                      balancePaid ? 'Paid' : 'Pending',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: balancePaid
                                              ? _greenLight
                                              : _goldLight)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Milestones card ────────────────────────────────────────────
  Widget _buildMilestones(BuildContext context, DataHub hub,
      PaymentModel payment, int registrationAmt, int balanceAmt) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _iconTile(Icons.account_balance_wallet_rounded),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Milestones',
                        style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _dark)),
                    Text('Verified EPC escrow tracking',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: _slate)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _sky,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _skyBorder.withValues(alpha: 0.6)),
                ),
                child: const Text('2 steps',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: _slate)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Registration milestone
          _milestoneRow(
            paid: payment.registrationPaid,
            icon: Icons.check_circle_rounded,
            iconBg: _greenLight.withValues(alpha: 0.15),
            iconColor: _green,
            title: 'Registration (₹${registrationAmt.formatWithComma()})',
            subtitle: payment.registrationPaid
                ? 'Paid on ${payment.registrationDateFormatted}'
                : 'Refundable advance',
            subtitleColor: payment.registrationPaid ? _green : _slate,
            tileColor: payment.registrationPaid
                ? const Color(0x4DECFDF5)
                : Colors.white,
            tileBorder: payment.registrationPaid
                ? const Color(0xB3A7F3D0)
                : const Color(0xFFE2E8F0),
            trailing: payment.registrationPaid
                ? _paidPill()
                : _markPaidPill(
                    () => _togglePaid(hub, payment, registrationAmt, 'registration')),
          ),
          const SizedBox(height: 10),
          // Balance milestone
          _milestoneRow(
            paid: payment.balancePaid,
            icon: Icons.schedule_rounded,
            iconBg: _gold.withValues(alpha: 0.15),
            iconColor: _goldDark,
            title: 'Balance Payment (₹${balanceAmt.formatWithComma()})',
            subtitle: payment.balancePaid
                ? 'Paid on ${payment.balanceDateFormatted}'
                : 'Remaining before material dispatch',
            subtitleColor: payment.balancePaid ? _green : _slate,
            tileColor: payment.balancePaid
                ? const Color(0x4DECFDF5)
                : Colors.white,
            tileBorder: payment.balancePaid
                ? const Color(0xB3A7F3D0)
                : const Color(0xFFE2E8F0),
            trailing: payment.balancePaid
                ? _paidPill()
                : _markPaidPill(
                    () => _togglePaid(hub, payment, balanceAmt, 'balance')),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: _gold),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '100% payment clears warehouse dispatch & installation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11, color: _slate.withValues(alpha: 0.9))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _milestoneRow({
    required bool paid,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color subtitleColor,
    required Color tileColor,
    required Color tileBorder,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tileBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBg,
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _dark)),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  Widget _paidPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Paid',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          SizedBox(width: 3),
          Icon(Icons.check_rounded, size: 14, color: Colors.white),
        ],
      ),
    );
  }

  Widget _markPaidPill(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_gold, _goldLight],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(color: _gold.withValues(alpha: 0.3), blurRadius: 8),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mark Paid',
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _navy900)),
            SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, size: 14, color: _navy900),
          ],
        ),
      ),
    );
  }

  // ── Documents card ─────────────────────────────────────────────
  Widget _buildDocuments(BuildContext context, DataHub hub, PaymentModel payment) {
    final uploadedCount = [
      payment.electricityBill.uploaded,
      payment.aadhaar.uploaded,
      payment.cancelledCheque.uploaded,
    ].where((u) => u).length;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _iconTile(Icons.folder_open_rounded),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Required Documents',
                        style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _dark)),
                    Text('Required for PM Surya Ghar subsidy portal',
                        style: TextStyle(fontSize: 11, color: _slate)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _greenLight,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text('$uploadedCount of 3 Verified',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _green)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _docRow(
            icon: Icons.receipt_long_rounded,
            title: 'Electricity Bill (PGVCL)',
            doc: payment.electricityBill,
            onUpload: () => _uploadDoc(context, hub, payment, 'electricityBill'),
          ),
          const SizedBox(height: 10),
          _docRow(
            icon: Icons.badge_rounded,
            title: 'Aadhaar Card (Linked)',
            doc: payment.aadhaar,
            onUpload: () => _uploadDoc(context, hub, payment, 'aadhaar'),
          ),
          const SizedBox(height: 10),
          _docRow(
            icon: Icons.account_balance_rounded,
            title: 'Cancelled Cheque / Passbook',
            doc: payment.cancelledCheque,
            onUpload: () => _uploadDoc(context, hub, payment, 'cancelledCheque'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Need to replace a document?',
                    style: TextStyle(fontSize: 11, color: _slate)),
                InkWell(
                  onTap: () => _uploadDoc(context, hub, payment, 'replace'),
                  child: const Row(
                    children: [
                      Icon(Icons.cloud_upload_rounded,
                          size: 14, color: _goldDark),
                      SizedBox(width: 4),
                      Text('Re-upload File',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _goldDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _docRow({
    required IconData icon,
    required String title,
    required DocumentStatus doc,
    required VoidCallback onUpload,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xB3F4F9FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: _navy800),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _dark)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      doc.uploaded
                          ? Icons.verified_rounded
                          : Icons.info_outline_rounded,
                      size: 12,
                      color: doc.uploaded ? _green : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        doc.uploaded
                            ? 'Uploaded ${_formatDate(doc.uploadedAt)}'
                            : 'Not uploaded yet',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: doc.uploaded ? _green : const Color(0xFF94A3B8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (doc.uploaded)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 18, color: _green),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('View $title (mock preview)')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Text('View',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _blue)),
                  ),
                ),
              ],
            )
          else
            InkWell(
              onTap: onUpload,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [_gold, _goldLight],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(color: _gold.withValues(alpha: 0.3), blurRadius: 8),
                  ],
                ),
                child: const Text('Upload',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _navy900)),
              ),
            ),
        ],
      ),
    );
  }

  // ── DBT note ───────────────────────────────────────────────────
  Widget _buildDbtNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 11, color: _slate, height: 1.5),
          children: [
            const TextSpan(
                text: 'Subsidy Direct Benefit Transfer (DBT): ',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: _dark)),
            TextSpan(
                text:
                    '₹78,000 direct central subsidy will be credited to ${widget.clientName}'
                    "'s Aadhaar-linked SBI Account upon bi-directional meter synchronisation."),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────
  Widget _buildBottomBar(
      BuildContext context, DataHub hub, PaymentModel payment) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: _skyBorder)),
        boxShadow: const [
          BoxShadow(color: Color(0x26F9B417), blurRadius: 25, offset: Offset(0, -8)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                hub.savePayment(payment);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Changes saved to client ledger')),
                );
              },
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
                    BoxShadow(color: _gold.withValues(alpha: 0.35), blurRadius: 16),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 20, color: _navy900),
                    SizedBox(width: 8),
                    Text('Save Changes',
                        style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _navy900)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Synced to client ledger • Auto-generated payment reminder',
              style: TextStyle(fontSize: 11, color: _slate),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x0D0F1B3D), blurRadius: 20, offset: Offset(0, 4)),
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
      child: Icon(icon, size: 19, color: _blue),
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    return '${d.day} ${_monthAbbr(d.month)} ${d.year}';
  }

  String _monthAbbr(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }

  void _togglePaid(DataHub hub, PaymentModel payment, int amount, String type) {
    if (type == 'registration') {
      final updated = payment.copyWith(
        registrationPaid: true,
        registrationDate: DateTime.now(),
      );
      hub.savePayment(updated);
    } else {
      final updated = payment.copyWith(
        balancePaid: true,
        balanceDate: DateTime.now(),
      );
      hub.savePayment(updated);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment marked as paid')),
    );
  }

  void _showAddPaymentSheet(BuildContext context) {
    final hub = context.read<DataHub>();
    final payment = hub.getPaymentForClient(widget.clientId) ??
        PaymentModel(id: hub.generateId(), clientId: widget.clientId);
    final quote = hub.getQuoteForClient(widget.clientId);
    final total = quote?.upfront ?? payment.registrationAmount + 76000;
    final balanceAmt = total - payment.registrationAmount;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _dark.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Record a Payment',
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _dark)),
            const SizedBox(height: 16),
            _addPaymentTile(
              icon: Icons.check_circle_rounded,
              iconColor: _green,
              title: 'Registration (₹${payment.registrationAmount.formatWithComma()})',
              paid: payment.registrationPaid,
              onTap: payment.registrationPaid
                  ? null
                  : () {
                      _togglePaid(hub, payment, payment.registrationAmount, 'registration');
                      Navigator.pop(sheetContext);
                    },
            ),
            const SizedBox(height: 10),
            _addPaymentTile(
              icon: Icons.schedule_rounded,
              iconColor: _goldDark,
              title: 'Balance Payment (₹${balanceAmt.formatWithComma()})',
              paid: payment.balancePaid,
              onTap: payment.balancePaid
                  ? null
                  : () {
                      _togglePaid(hub, payment, balanceAmt, 'balance');
                      Navigator.pop(sheetContext);
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _addPaymentTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool paid,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF4FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDBEAFE)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _dark)),
            ),
            paid
                ? const Text('Paid ✓',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: _green))
                : Icon(Icons.chevron_right_rounded,
                    size: 20, color: _navy800.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadDoc(BuildContext context, DataHub hub,
      PaymentModel payment, String field) async {
    final source = await _pickImageSource(context);
    if (source == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ImagePicker()
          .pickImage(source: source, imageQuality: 70, maxWidth: 1600);
      if (file == null) return;
      messenger.showSnackBar(const SnackBar(content: Text('Uploading…')));
      final bytes = await file.readAsBytes();
      final url = await StorageService.instance.uploadBytes(
          bytes, file.name, folder: 'payments/${payment.clientId}');
      final updated = _markDoc(payment, field, url: url);
      await hub.savePayment(updated);
      messenger.showSnackBar(const SnackBar(content: Text('Document uploaded')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<ImageSource?> _pickImageSource(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: _navy800),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library_rounded, color: _navy800),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  PaymentModel _markDoc(PaymentModel payment, String field, {String? url}) {
    final uploaded = DocumentStatus(
        uploaded: true, url: url, uploadedAt: DateTime.now());
    if (field == 'electricityBill') {
      return payment.copyWith(electricityBill: uploaded);
    } else if (field == 'aadhaar') {
      return payment.copyWith(aadhaar: uploaded);
    } else if (field == 'cancelledCheque') {
      return payment.copyWith(cancelledCheque: uploaded);
    }
    // 'replace' — replace first missing, else first doc
    if (!payment.electricityBill.uploaded) {
      return payment.copyWith(electricityBill: uploaded);
    } else if (!payment.aadhaar.uploaded) {
      return payment.copyWith(aadhaar: uploaded);
    }
    return payment.copyWith(cancelledCheque: uploaded);
  }
}

/// Pulsing gold dot in header.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
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
          color: Color(0xFFFFCA40),
          boxShadow: [BoxShadow(color: Color(0xFFFFCA40), blurRadius: 8)],
        ),
      ),
    );
  }
}