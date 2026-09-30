import 'package:intl/intl.dart';

/// Quote model — mirrors the Firestore `quotes` document.
class QuoteModel {
  final String id;
  final String clientId;
  final String packageId; // e.g. "p3", "p4"
  final double kw;
  final int panels;
  final int upfront; // pre-subsidy, shown to client
  final int afterSubsidy; // after ₹78,000 subsidy
  final int structureCost;
  final int total; // = upfront (shown to client before subsidy)
  final String status; // sent | accepted | rejected | draft
  final DateTime sentAt;
  final DateTime? acceptedAt;
  final bool isResidential;

  QuoteModel({
    required this.id,
    required this.clientId,
    required this.packageId,
    required this.kw,
    required this.panels,
    required this.upfront,
    required this.afterSubsidy,
    required this.structureCost,
    required this.total,
    required this.status,
    required this.sentAt,
    this.acceptedAt,
    this.isResidential = true,
  });

  factory QuoteModel.fromJson(Map<String, dynamic> json) => QuoteModel(
        id: json['id'] as String,
        clientId: json['clientId'] as String,
        packageId: json['packageId'] as String,
        kw: (json['kw'] as num).toDouble(),
        panels: json['panels'] as int,
        upfront: json['upfront'] as int,
        afterSubsidy: json['afterSubsidy'] as int,
        structureCost: json['structureCost'] as int,
        total: json['total'] as int,
        status: json['status'] as String? ?? 'draft',
        sentAt: json['sentAt'] != null
            ? DateTime.parse(json['sentAt'] as String)
            : DateTime.now(),
        acceptedAt: json['acceptedAt'] != null
            ? DateTime.parse(json['acceptedAt'] as String)
            : null,
        isResidential: json['isResidential'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'packageId': packageId,
        'kw': kw,
        'panels': panels,
        'upfront': upfront,
        'afterSubsidy': afterSubsidy,
        'structureCost': structureCost,
        'total': total,
        'status': status,
        'sentAt': sentAt.toIso8601String(),
        'acceptedAt': acceptedAt?.toIso8601String(),
        'isResidential': isResidential,
      };

  int get effectiveSubsidy => isResidential ? 78000 : 0;
  int get grandTotal => total + 300; // + stamp charge

  String get sentAtFormatted =>
      DateFormat('dd MMM yyyy, hh:mm a').format(sentAt);

  QuoteModel copyWith({String? status, DateTime? acceptedAt}) => QuoteModel(
        id: id,
        clientId: clientId,
        packageId: packageId,
        kw: kw,
        panels: panels,
        upfront: upfront,
        afterSubsidy: afterSubsidy,
        structureCost: structureCost,
        total: total,
        status: status ?? this.status,
        sentAt: sentAt,
        acceptedAt: acceptedAt ?? this.acceptedAt,
        isResidential: isResidential,
      );
}
