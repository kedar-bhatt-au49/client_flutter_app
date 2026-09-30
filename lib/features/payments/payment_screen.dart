import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/gs_button.dart';
import '../../core/widgets/gs_card.dart';
import '../../models/payment.dart';
import '../../providers/data_hub.dart';

/// Payment tracker — manages registration & balance payments + documents.
class PaymentScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const PaymentScreen({super.key, required this.clientId, required this.clientName});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final hub = context.watch<DataHub>();
    final payment = hub.getPaymentForClient(widget.clientId) ??
        PaymentModel(id: hub.generateId(), clientId: widget.clientId);

    return Scaffold(
      backgroundColor: GSColors.whiteBg,
      appBar: AppBar(title: Text('${widget.clientName} — Payments')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Payment tracker ─────────────────────────────────
            GsCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Tracker',
                      style: GSTextStyles.headlineSmall.copyWith(color: GSColors.navy900)),
                  const SizedBox(height: 16),

                  // Registration payment
                  _PaymentRow(
                    label: 'Registration (₹${GSTax.registrationAmount.formatWithComma()})',
                    isPaid: payment.registrationPaid,
                    paidDate: payment.registrationDate,
                    onToggle: (paid) {
                      final updated = payment.copyWith(
                        registrationPaid: paid,
                        registrationDate: paid ? DateTime.now() : null,
                      );
                      hub.savePayment(updated);
                      setState(() {});
                    },
                    paidColor: GSColors.green600,
                  ),
                  const SizedBox(height: 12),

                  // Balance payment
                  _PaymentRow(
                    label: 'Balance Payment',
                    subtitle: 'Remaining before material dispatch',
                    isPaid: payment.balancePaid,
                    paidDate: payment.balanceDate,
                    onToggle: (paid) {
                      final updated = payment.copyWith(
                        balancePaid: paid,
                        balanceDate: paid ? DateTime.now() : null,
                      );
                      hub.savePayment(updated);
                      setState(() {});
                    },
                    paidColor: GSColors.blue500,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Documents ─────────────────────────────────────────
            GsCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Required Documents',
                      style: GSTextStyles.headlineSmall.copyWith(color: GSColors.navy900)),
                  const SizedBox(height: 16),
                  _DocumentTile(
                    label: GSDocument.electricityBill,
                    doc: payment.electricityBill,
                    onUpload: () => _uploadDoc(hub, payment, 'electricityBill'),
                  ),
                  _DocumentTile(
                    label: GSDocument.aadhaar,
                    doc: payment.aadhaar,
                    onUpload: () => _uploadDoc(hub, payment, 'aadhaar'),
                  ),
                  _DocumentTile(
                    label: GSDocument.cancelledCheque,
                    doc: payment.cancelledCheque,
                    onUpload: () => _uploadDoc(hub, payment, 'cancelledCheque'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Save ───────────────────────────────────────────────
            GsButton(
              text: 'Save Changes',
              onPressed: () {
                hub.savePayment(payment);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Payment saved')));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _uploadDoc(DataHub hub, PaymentModel payment, String field) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GSColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: GSColors.ink.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.upload_file, size: 48, color: GSColors.navy700),
            const SizedBox(height: 12),
            Text('Upload Document Photo',
                style: GSTextStyles.headlineSmall.copyWith(color: GSColors.navy900)),
            const SizedBox(height: 8),
            Text('Take a photo or select from gallery',
                style: GSTextStyles.bodyMedium.copyWith(color: GSColors.ink.withValues(alpha: 0.6)),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      // Simulate photo capture / selection
                      final newDoc = payment.copyWith(
                        electricityBill: field == 'electricityBill'
                            ? payment.electricityBill.copyWith(
                                uploaded: true,
                                url: 'mock://electricity_bill',
                                uploadedAt: DateTime.now())
                            : payment.electricityBill,
                        aadhaar: field == 'aadhaar'
                            ? payment.aadhaar.copyWith(
                                uploaded: true,
                                url: 'mock://aadhaar',
                                uploadedAt: DateTime.now())
                            : payment.aadhaar,
                        cancelledCheque: field == 'cancelledCheque'
                            ? payment.cancelledCheque.copyWith(
                                uploaded: true,
                                url: 'mock://cheque',
                                uploadedAt: DateTime.now())
                            : payment.cancelledCheque,
                      );
                      hub.savePayment(newDoc);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$field uploaded')),
                      );
                    },
                    icon: const Icon(Icons.camera_alt, color: GSColors.navy700),
                    label: const Text('Take Photo', style: TextStyle(color: GSColors.navy700)),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select from gallery')),
                      );
                    },
                    icon: const Icon(Icons.photo_library, color: GSColors.navy700),
                    label: const Text('Gallery', style: TextStyle(color: GSColors.navy700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool isPaid;
  final DateTime? paidDate;
  final Color paidColor;
  final ValueChanged<bool> onToggle;

  const _PaymentRow({
    required this.label,
    this.subtitle,
    required this.isPaid,
    this.paidDate,
    required this.paidColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GSTextStyles.bodyMediumSemiBold.copyWith(color: GSColors.navy900)),
              if (subtitle != null)
                Text(subtitle!,
                    style: GSTextStyles.bodySmall.copyWith(color: GSColors.ink.withValues(alpha: 0.6))),
              if (isPaid && paidDate != null)
                Text('Paid on ${paidDate!.day}/${paidDate!.month}/${paidDate!.year}',
                    style: GSTextStyles.bodySmall.copyWith(color: paidColor)),
            ],
          )),
        Switch(
          value: isPaid,
          onChanged: onToggle,
          activeThumbColor: paidColor,
        ),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final String label;
  final DocumentStatus doc;
  final VoidCallback onUpload;

  const _DocumentTile({required this.label, required this.doc, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 24, color: GSColors.navy700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: GSTextStyles.bodyMedium.copyWith(color: GSColors.navy900)),
          ),
          if (doc.uploaded)
            const Icon(Icons.check_circle, size: 20, color: GSColors.green600),
          if (!doc.uploaded)
            TextButton(
              onPressed: onUpload,
              child: const Text('Upload', style: TextStyle(color: GSColors.blue500)),
            ),
        ],
      ),
    );
  }
}
