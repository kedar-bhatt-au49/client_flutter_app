import 'package:intl/intl.dart';

/// Status of a single document upload.
class DocumentStatus {
  final bool uploaded;
  final String? url;
  final DateTime? uploadedAt;

  DocumentStatus({this.uploaded = false, this.url, this.uploadedAt});

  factory DocumentStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DocumentStatus();
    return DocumentStatus(
      uploaded: json['uploaded'] as bool? ?? false,
      url: json['url'] as String?,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'uploaded': uploaded,
        'url': url,
        'uploadedAt': uploadedAt?.toIso8601String(),
      };

  DocumentStatus copyWith({bool? uploaded, String? url, DateTime? uploadedAt}) =>
      DocumentStatus(
        uploaded: uploaded ?? this.uploaded,
        url: url ?? this.url,
        uploadedAt: uploadedAt ?? this.uploadedAt,
      );
}

/// Payment model — mirrors the Firestore `payments` document.
class PaymentModel {
  final String id;
  final String clientId;
  final int registrationAmount;
  final bool registrationPaid;
  final DateTime? registrationDate;
  final bool balancePaid;
  final DateTime? balanceDate;
  final DocumentStatus electricityBill;
  final DocumentStatus aadhaar;
  final DocumentStatus cancelledCheque;

  PaymentModel({
    required this.id,
    required this.clientId,
    this.registrationAmount = 10000,
    this.registrationPaid = false,
    this.registrationDate,
    this.balancePaid = false,
    this.balanceDate,
    DocumentStatus? electricityBill,
    DocumentStatus? aadhaar,
    DocumentStatus? cancelledCheque,
  })  : electricityBill = electricityBill ?? DocumentStatus(),
        aadhaar = aadhaar ?? DocumentStatus(),
        cancelledCheque = cancelledCheque ?? DocumentStatus();

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: json['id'] as String,
        clientId: json['clientId'] as String,
        registrationAmount:
            (json['registrationAmount'] as num?)?.toInt() ?? 10000,
        registrationPaid: json['registrationPaid'] as bool? ?? false,
        registrationDate: json['registrationDate'] != null
            ? DateTime.parse(json['registrationDate'] as String)
            : null,
        balancePaid: json['balancePaid'] as bool? ?? false,
        balanceDate: json['balanceDate'] != null
            ? DateTime.parse(json['balanceDate'] as String)
            : null,
        electricityBill: DocumentStatus.fromJson(
            json['electricityBill'] as Map<String, dynamic>?),
        aadhaar: DocumentStatus.fromJson(
            json['aadhaar'] as Map<String, dynamic>?),
        cancelledCheque: DocumentStatus.fromJson(
            json['cancelledCheque'] as Map<String, dynamic>?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'registrationAmount': registrationAmount,
        'registrationPaid': registrationPaid,
        'registrationDate': registrationDate?.toIso8601String(),
        'balancePaid': balancePaid,
        'balanceDate': balanceDate?.toIso8601String(),
        'electricityBill': electricityBill.toJson(),
        'aadhaar': aadhaar.toJson(),
        'cancelledCheque': cancelledCheque.toJson(),
      };

  String get registrationDateFormatted => registrationDate != null
      ? DateFormat('dd MMM yyyy').format(registrationDate!)
      : '';

  String get balanceDateFormatted => balanceDate != null
      ? DateFormat('dd MMM yyyy').format(balanceDate!)
      : '';

  int get amountDue => balancePaid
      ? 0
      : (registrationPaid ? 0 : registrationAmount);

  bool get allDocsUploaded =>
      electricityBill.uploaded && aadhaar.uploaded && cancelledCheque.uploaded;

  PaymentModel copyWith({
    bool? registrationPaid,
    DateTime? registrationDate,
    bool? balancePaid,
    DateTime? balanceDate,
    DocumentStatus? electricityBill,
    DocumentStatus? aadhaar,
    DocumentStatus? cancelledCheque,
  }) =>
      PaymentModel(
        id: id,
        clientId: clientId,
        registrationAmount: registrationAmount,
        registrationPaid: registrationPaid ?? this.registrationPaid,
        registrationDate: registrationDate ?? this.registrationDate,
        balancePaid: balancePaid ?? this.balancePaid,
        balanceDate: balanceDate ?? this.balanceDate,
        electricityBill: electricityBill ?? this.electricityBill,
        aadhaar: aadhaar ?? this.aadhaar,
        cancelledCheque: cancelledCheque ?? this.cancelledCheque,
      );
}
