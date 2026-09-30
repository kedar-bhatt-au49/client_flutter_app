import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Color-coded status chip matching the client pipeline stages.
class GSStatusChip extends StatelessWidget {
  final String status;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showBorder;

  const GSStatusChip({
    super.key,
    required this.status,
    this.isSelected = false,
    this.onTap,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final config = _ChipConfig.fromStatus(status);

    return ChoiceChip(
      label: Text(
        config.label,
        style: GSTextStyles.labelMedium.copyWith(
          color: isSelected ? GSColors.navy900 : config.color,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      backgroundColor: isSelected
          ? GSColors.gold500
          : config.color.withValues(alpha: 0.12),
      selectedColor: GSColors.gold500,
      shape: StadiumBorder(
        side: showBorder
            ? BorderSide(
                color: isSelected
                    ? GSColors.gold500
                    : config.color.withValues(alpha: 0.4),
                width: isSelected ? 2 : 1,
              )
            : BorderSide.none,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// Follow-up status chip.
class GSFollowUpStatusChip extends StatelessWidget {
  final String status;

  const GSFollowUpStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'done':
        color = GSColors.green600;
        label = 'Done';
        break;
      case 'missed':
        color = GSColors.followupMissed;
        label = 'Missed';
        break;
      default:
        color = GSColors.followupPending;
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(label,
          style: GSTextStyles.labelMedium.copyWith(color: color)),
    );
  }
}

/// Quote status chip.
class GSQuoteStatusChip extends StatelessWidget {
  final String status;

  const GSQuoteStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'accepted':
        color = GSColors.green600;
        label = 'Accepted';
        break;
      case 'sent':
        color = GSColors.blue500;
        label = 'Sent';
        break;
      case 'rejected':
        color = GSColors.followupMissed;
        label = 'Rejected';
        break;
      default:
        color = GSColors.followupPending;
        label = 'Draft';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(label,
          style: GSTextStyles.labelMedium.copyWith(color: color)),
    );
  }
}

/// Install stage chip.
class GSInstallStageChip extends StatelessWidget {
  final String stage;

  const GSInstallStageChip({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    final stageLabels = {
      'materials-dispatched': 'Materials',
      'fitting': 'Fitting',
      'pvcl-inspection': 'PVCL Inspection',
      'net-meter': 'Net Meter',
      'subsidy-credited': 'Subsidy Credited',
    };
    final label = stageLabels[stage] ?? stage;
    final idx = ['materials-dispatched', 'fitting', 'pvcl-inspection', 'net-meter', 'subsidy-credited'].indexOf(stage);
    final isComplete = idx >= 4;
    final color = isComplete ? GSColors.green600 : GSColors.blue500;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(label,
          style: GSTextStyles.labelMedium.copyWith(color: color)),
    );
  }
}

class _ChipConfig {
  final String label;
  final Color color;

  _ChipConfig(this.label, this.color);

  static _ChipConfig fromStatus(String status) {
    switch (status) {
      case 'new':
        return _ChipConfig('New Lead', GSColors.statusNew);
      case 'contacted':
        return _ChipConfig('Contacted', GSColors.statusContacted);
      case 'site-visit':
        return _ChipConfig('Site Visit', GSColors.statusQuoted);
      case 'quoted':
        return _ChipConfig('Quoted', GSColors.statusQuoted);
      case 'booked':
        return _ChipConfig('Booked', GSColors.statusBooked);
      case 'installed':
      case 'subsidized':
        return _ChipConfig(
            status == 'subsidized' ? 'Subsidized' : 'Installed',
            GSColors.statusInstalled);
      case 'lost':
        return _ChipConfig('Lost', GSColors.statusLost);
      default:
        return _ChipConfig(status, GSColors.statusNew);
    }
  }
}
