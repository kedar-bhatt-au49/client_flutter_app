import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/gs_button.dart';
import '../../core/widgets/gs_card.dart';
import '../../core/widgets/solar_grid_divider.dart';
import '../../core/widgets/status_chip.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_hub.dart';
import '../../models/client.dart';
import 'add_edit_client_screen.dart';

/// Client detail — info, follow-ups, quotes, payments, install timeline.
class ClientDetailScreen extends StatelessWidget {
  final ClientModel client;

  const ClientDetailScreen({super.key, required this.client});

  Future<void> _openWhatsApp(BuildContext context, String phone, String name) async {
    final message = Uri.encodeComponent(
        'Hello $name, this is Global Solar 2.0 following up on your inquiry.');
    final url = Uri.parse('https://wa.me/91$phone?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openPhone(BuildContext context, String phone) async {
    final url = Uri.parse('tel:+91$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hub = context.watch<DataHub>();
    final auth = context.watch<AuthProvider>();
    final isOwner = auth.isOwner;
    final client = hub.getClient(this.client.id) ?? this.client;

    final followUps = hub.getFollowUpsForClient(client.id);
    final quote = hub.getQuoteForClient(client.id);
    final payment = hub.getPaymentForClient(client.id);
    final installation = hub.getInstallationForClient(client.id);

    return Scaffold(
      backgroundColor: GSColors.whiteBg,
      appBar: AppBar(
        title: Text(client.name),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: GSColors.followupMissed),
              onPressed: () => _confirmDelete(context, hub, client.id),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => hub.init(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header card ───────────────────────────────────────
              GsCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(client.name,
                            style: GSTextStyles.headlineMedium
                                .copyWith(color: GSColors.navy900)),
                        GSStatusChip(status: client.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.phone, 'Phone', client.phone),
                    if (client.altPhone != null && client.altPhone!.isNotEmpty)
                      _buildInfoRow(Icons.phone, 'Alt Phone', client.altPhone!),
                    _buildInfoRow(Icons.location_on, 'Area', client.displayArea),
                    _buildInfoRow(Icons.home, 'Property', client.propertyType),
                    _buildInfoRow(Icons.receipt_long, 'Monthly Bill',
                        '₹${client.monthlyBill.toInt()}'),
                    _buildInfoRow(Icons.sunny, 'Preferred Package',
                        client.preferredPackage == 'not-sure'
                            ? 'Not sure yet'
                            : '${client.preferredPackage} kW'),
                    _buildInfoRow(Icons.group, 'Lead Source', client.source),
                    if (client.notes != null && client.notes!.isNotEmpty)
                      _buildInfoRow(Icons.note, 'Notes', client.notes!),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Quick actions ─────────────────────────────────────
              _buildQuickActions(context, client, auth),
              const SizedBox(height: 16),

              // ── Pipeline & stats ──────────────────────────────────
              _buildPipelineSummary(context, client, quote, payment, installation),
              const SizedBox(height: 16),

              // ── Follow-ups ────────────────────────────────────────
              _buildFollowUpsSection(context, followUps, client),
              const SizedBox(height: 16),

              // ── Quote preview ─────────────────────────────────────
              if (quote != null) _buildQuoteSection(context, quote),
              if (quote != null) const SizedBox(height: 16),

              // ── Payment preview ────────────────────────────────────
              if (payment != null) _buildPaymentSection(context, payment),
              if (payment != null) const SizedBox(height: 16),

              // ── Installation timeline ───────────────────────────────
              if (installation != null) _buildInstallationSection(context, installation),
              if (installation != null) const SizedBox(height: 16),

              // ── Edit button ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: GsButton(
                  text: 'Edit Client',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddEditClientScreen(client: client),
                      ),
                    );
                  },
                  icon: Icons.edit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: GSColors.navy700),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GSTextStyles.bodyLarge,
                  children: [
                    TextSpan(
                        text: '$label: ',
                        style: TextStyle(color: GSColors.ink.withValues(alpha: 0.6))),
                    TextSpan(text: value, style: TextStyle(color: GSColors.ink)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildQuickActions(BuildContext context, ClientModel client, auth) {
    return Row(
      children: [
        Expanded(
          child: GsButton(
            text: 'Call',
            onPressed: () => _openPhone(context, client.phone),
            icon: Icons.phone,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GsOutlinedButton(
            text: 'WhatsApp',
            onPressed: () => _openWhatsApp(context, client.phone, client.name),
            icon: Icons.chat_bubble_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildPipelineSummary(
    BuildContext context,
    ClientModel client,
    dynamic quote,
    dynamic payment,
    dynamic installation,
  ) {
    return GsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pipeline Progress',
              style: GSTextStyles.headlineSmall
                  .copyWith(color: GSColors.navy900)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _MiniStat('Quote', quote != null ? 'Done' : 'Pending',
                  quote != null ? GSColors.green600 : GSColors.followupPending),
              _MiniStat('Payment',
                  payment != null && payment.registrationPaid ? 'Partial' : 'Pending',
                  payment != null && payment.registrationPaid
                      ? GSColors.green600
                      : GSColors.followupPending),
              _MiniStat('Install',
                  installation != null ? 'Started' : 'Not started',
                  installation != null
                      ? GSColors.blue500
                      : GSColors.statusLost),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpsSection(BuildContext context, dynamic followUps, ClientModel client) {
    return GsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Follow-ups',
                  style: GSTextStyles.headlineSmall
                      .copyWith(color: GSColors.navy900)),
              TextButton.icon(
                onPressed: () {
                  // TODO: open add follow-up screen
                },
                icon: const Icon(Icons.add, size: 18, color: GSColors.gold500),
                label: const Text('Add', style: TextStyle(color: GSColors.gold500)),
              ),
            ],
          ),
          if (followUps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No follow-ups yet',
                  style: TextStyle(color: GSColors.ink, fontSize: 13)),
            ),
          if (followUps.isNotEmpty)
            ...followUps.take(5).map((f) => _FollowUpRow(followUp: f)),
        ],
      ),
    );
  }

  Widget _buildQuoteSection(BuildContext context, dynamic quote) {
    final pkg = gsPackageById(quote.packageId);
    return GsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quote', style: GSTextStyles.headlineSmall.copyWith(color: GSColors.navy900)),
              GSQuoteStatusChip(status: quote.status),
            ],
          ),
          const SizedBox(height: 10),
          if (pkg != null) Text('${pkg.kw} kW • ${pkg.panels} panels',
              style: GSTextStyles.bodySmall.copyWith(color: GSColors.ink.withValues(alpha: 0.7))),
          _buildQuoteRow('Upfront (pre-subsidy)', quote.upfront),
          if (quote.isResidential)
            _buildQuoteRow('Subsidy applied', -GSTax.subsidyMax, color: GSColors.green600)
          else
            _buildQuoteRow('Subsidy', 0, color: GSColors.statusLost,
                note: 'Non-residential — subsidy not applicable'),
          _buildQuoteRow('Structure cost', quote.structureCost),
          _buildQuoteRow('Stamp charge', GSTax.stampCharge),
          const SolarGridDivider(height: 1, margin: EdgeInsets.only(top: 8)),
          _buildQuoteRow('Total', quote.grandTotal, isTotal: true),
          const SizedBox(height: 8),
          if (quote.status == 'draft' || quote.status == 'sent')
            SizedBox(
              width: double.infinity,
              child: GsButton(
                text: 'Send on WhatsApp',
                onPressed: () {
                  final msg = Uri.encodeComponent(
                    'Hello ${quote.clientId},\n'
                    'Here is your solar quote for Global Solar 2.0:\n'
                    '${pkg?.kw} kW system • ${pkg?.panels} panels\n'
                    'Total: ₹${quote.grandTotal.formatWithComma()}\n'
                    'After subsidy: ₹${quote.afterSubsidy.formatWithComma()}\n\n'
                    'Final quote after free site survey. Valid for 1 week.',
                  );
                  launchUrl(Uri.parse('https://wa.me/${client.phone}?text=$msg'),
                      mode: LaunchMode.externalApplication);
                },
                icon: Icons.chat_bubble_outline,
              ),
            )
          else
            Text('Quote ${quote.status}. Sent ${DateFormat('dd MMM').format(quote.sentAt)}',
                style: GSTextStyles.bodySmall.copyWith(color: GSColors.ink.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(BuildContext context, dynamic payment) {
    return GsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment', style: GSTextStyles.headlineSmall.copyWith(color: GSColors.navy900)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Registration (₹${payment.registrationAmount.formatWithComma()})',
                  style: GSTextStyles.bodyMedium),
              Chip(
                backgroundColor: payment.registrationPaid
                    ? GSColors.green600.withValues(alpha: 0.15)
                    : GSColors.followupMissed.withValues(alpha: 0.15),
                label: Text(
                  payment.registrationPaid ? 'Paid' : 'Pending',
                  style: TextStyle(
                      color: payment.registrationPaid ? GSColors.green600 : GSColors.followupMissed),
                ),
              ),
            ],
          ),
          if (payment.registrationPaid && payment.registrationDate != null)
            Text('Paid on ${DateFormat('dd MMM yyyy').format(payment.registrationDate!)}',
                style: GSTextStyles.bodySmall.copyWith(color: GSColors.ink.withValues(alpha: 0.6))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Balance payment', style: GSTextStyles.bodyMedium),
              Chip(
                backgroundColor: payment.balancePaid
                    ? GSColors.green600.withValues(alpha: 0.15)
                    : GSColors.blue500.withValues(alpha: 0.15),
                label: Text(
                  payment.balancePaid ? 'Paid' : 'Pending',
                  style: TextStyle(
                      color: payment.balancePaid ? GSColors.green600 : GSColors.blue500),
                ),
              ),
            ],
          ),
          if (payment.balancePaid && payment.balanceDate != null)
            Text('Paid on ${DateFormat('dd MMM yyyy').format(payment.balanceDate!)}',
                style: GSTextStyles.bodySmall.copyWith(color: GSColors.ink.withValues(alpha: 0.6))),
          const SizedBox(height: 12),
          Text('Documents', style: GSTextStyles.bodyMediumSemiBold.copyWith(color: GSColors.navy900)),
          const SizedBox(height: 8),
          _DocRow('Electricity Bill', payment.electricityBill),
          _DocRow('Aadhaar Card', payment.aadhaar),
          _DocRow('Cancelled Cheque', payment.cancelledCheque),
        ],
      ),
    );
  }

  Widget _buildInstallationSection(BuildContext context, dynamic installation) {
    final stages = GSInstallStage.all;
    final currentIdx = installation.currentStageIndex;

    return GsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Installation',
                  style: GSTextStyles.headlineSmall.copyWith(color: GSColors.navy900)),
              GSInstallStageChip(stage: installation.stage),
            ],
          ),
          const SizedBox(height: 16),
          // Timeline
          Column(
            children: List.generate(stages.length, (i) {
              final isComplete = i <= currentIdx;
              final isCurrent = i == currentIdx;
              final isLast = i == stages.length - 1;
              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isComplete ? GSColors.gold500 : GSColors.ink.withValues(alpha: 0.2),
                          border: Border.all(
                              color: isComplete ? GSColors.navy900 : GSColors.ink.withValues(alpha: 0.1),
                              width: isCurrent ? 3 : 2),
                        ),
                        child: isComplete
                            ? const Icon(Icons.check, size: 14, color: GSColors.navy900)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(GSInstallStage.labelOf(stages[i]),
                                style: GSTextStyles.bodyMediumSemiBold.copyWith(
                                    color: isComplete ? GSColors.navy900 : GSColors.ink.withValues(alpha: 0.5))),
                            if (installation.installDate != null && i == 1)
                              Text('Started: ${DateFormat('dd MMM yyyy').format(installation.installDate!)}',
                                  style: GSTextStyles.bodySmall.copyWith(color: GSColors.ink.withValues(alpha: 0.6))),
                          ],
                        )),
                    ],
                  ),
                  if (!isLast)
                    Container(
                      margin: const EdgeInsets.only(left: 12),
                      width: 2,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: isComplete ? GSGradients.energy : null,
                        color: isComplete
                            ? null
                            : GSColors.ink.withValues(alpha: 0.1),
                      ),
                    ),
                ],
              );
            }),
          ),
          // Warranty
          if (installation.warrantyExpiry.om > 0)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Warranty: OM ${installation.warrantyExpiry.om} | Panel ${installation.warrantyExpiry.panel} | '
                'Performance ${installation.warrantyExpiry.performance} | Inverter ${installation.warrantyExpiry.inverter}',
                style: GSTextStyles.bodySmall.copyWith(color: GSColors.ink.withValues(alpha: 0.6)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuoteRow(String label, int amount,
      {Color? color, bool isTotal = false, String? note}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: (isTotal
                      ? GSTextStyles.bodyMediumSemiBold
                      : GSTextStyles.bodyMedium)
                  .copyWith(color: GSColors.ink)),
          Row(
            children: [
              if (note != null)
                Text(note,
                    style: GSTextStyles.bodySmall.copyWith(color: GSColors.ink.withValues(alpha: 0.5))),
              Text(
                '${amount.isNegative ? '' : '₹'}${amount.isNegative ? '₹${(amount).abs().formatWithComma()}' : amount.formatWithComma()}',
                style: (isTotal
                        ? GSTextStyles.bodyLargeSemiBold
                        : GSTextStyles.bodyMedium)
                    .copyWith(
                        color: color ?? (amount.isNegative ? GSColors.green600 : GSColors.navy900)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DataHub hub, String clientId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: GSColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Client?'),
        content: const Text('This will remove the client and all linked data. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              hub.deleteClient(clientId);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Client deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: GSColors.followupMissed)),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(label, style: GSTextStyles.bodySmall.copyWith(color: GSColors.ink.withValues(alpha: 0.7))),
          const SizedBox(width: 6),
          Text(value, style: GSTextStyles.labelMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _FollowUpRow extends StatelessWidget {
  final dynamic followUp;

  const _FollowUpRow({required this.followUp});

  @override
  Widget build(BuildContext context) {
    final isOverdue = followUp.isOverdue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOverdue ? GSColors.followupMissed : GSColors.gold500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${followUp.timeFormatted} — ${followUp.dateFormatted}',
              style: GSTextStyles.bodyMedium.copyWith(
                color: isOverdue ? GSColors.followupMissed : GSColors.ink,
                fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          if (followUp.note != null && followUp.note!.isNotEmpty)
            Text('${followUp.note}',
                style: GSTextStyles.bodySmall.copyWith(color: GSColors.ink.withValues(alpha: 0.6)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  final String label;
  final dynamic doc;

  const _DocRow(this.label, this.doc);

  @override
  Widget build(BuildContext context) {
    final uploaded = doc.uploaded;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GSTextStyles.bodyMedium),
          if (uploaded)
            Icon(Icons.check_circle, size: 18, color: GSColors.green600),
          if (!uploaded)
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Upload $label photo (coming soon)')),
                );
              },
              icon: const Icon(Icons.upload, size: 16, color: GSColors.navy700),
              label: const Text('Upload', style: TextStyle(color: GSColors.navy700)),
            ),
        ],
      ),
    );
  }
}
