import 'package:intl/intl.dart';

/// Warranty expiry years — computed from install date.
class WarrantyExpiry {
  static const omYears = 5;
  static const panelYears = 12;
  static const performanceYears = 30;
  static const inverterYears = 8;

  final int om;
  final int panel;
  final int performance;
  final int inverter;

  WarrantyExpiry({
    required this.om,
    required this.panel,
    required this.performance,
    required this.inverter,
  });

  factory WarrantyExpiry.fromInstallDate(DateTime installDate) {
    final y = installDate.year;
    return WarrantyExpiry(om: y + 5, panel: y + 12, performance: y + 30, inverter: y + 8);
  }

  factory WarrantyExpiry.fromJson(Map<String, dynamic> json) => WarrantyExpiry(
        om: json['om'] as int,
        panel: json['panel'] as int,
        performance: json['performance'] as int,
        inverter: json['inverter'] as int,
      );

  Map<String, dynamic> toJson() => {
        'om': om,
        'panel': panel,
        'performance': performance,
        'inverter': inverter,
      };

  String get omFormatted => om.toString();
  String get panelFormatted => panel.toString();
  String get performanceFormatted => performance.toString();
  String get inverterFormatted => inverter.toString();

  /// Duration in years from the install date to the expiry year.
  int yearsTo(DateTime? installDate) =>
      installDate == null ? om - DateTime.now().year : om - installDate.year;
}

/// Photo attached to an installation stage.
class InstallationPhoto {
  final String id;
  final String url;
  final String stage;
  final DateTime uploadedAt;

  InstallationPhoto({
    required this.id,
    required this.url,
    required this.stage,
    required this.uploadedAt,
  });

  factory InstallationPhoto.fromJson(Map<String, dynamic> json) => InstallationPhoto(
        id: json['id'] as String,
        url: json['url'] as String,
        stage: json['stage'] as String,
        uploadedAt: json['uploadedAt'] != null
            ? DateTime.parse(json['uploadedAt'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'stage': stage,
        'uploadedAt': uploadedAt.toIso8601String(),
      };
}

/// Installation model — mirrors the Firestore `installations` document.
class InstallationModel {
  final String id;
  final String clientId;
  final String stage;
  final List<InstallationPhoto> photos;
  final WarrantyExpiry warrantyExpiry;
  final String? notes;
  final DateTime? installDate;

  InstallationModel({
    required this.id,
    required this.clientId,
    this.stage = 'materials-dispatched',
    List<InstallationPhoto>? photos,
    WarrantyExpiry? warrantyExpiry,
    this.notes,
    this.installDate,
  })  : photos = photos ?? [],
        warrantyExpiry = warrantyExpiry ??
            WarrantyExpiry(om: 0, panel: 0, performance: 0, inverter: 0);

  factory InstallationModel.fromJson(Map<String, dynamic> json) => InstallationModel(
        id: json['id'] as String,
        clientId: json['clientId'] as String,
        stage: json['stage'] as String? ?? 'materials-dispatched',
        photos: (json['photos'] as List<dynamic>? ?? [])
            .map((e) => InstallationPhoto.fromJson(e as Map<String, dynamic>))
            .toList(),
        warrantyExpiry: json['warrantyExpiry'] != null
            ? WarrantyExpiry.fromJson(
                json['warrantyExpiry'] as Map<String, dynamic>)
            : WarrantyExpiry(om: 0, panel: 0, performance: 0, inverter: 0),
        notes: json['notes'] as String?,
        installDate: json['installDate'] != null
            ? DateTime.parse(json['installDate'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'stage': stage,
        'photos': photos.map((p) => p.toJson()).toList(),
        'warrantyExpiry': warrantyExpiry.toJson(),
        'notes': notes,
        'installDate': installDate?.toIso8601String(),
      };

  bool get isComplete => stage == 'subsidy-credited';
  bool get hasStarted => stage != 'materials-dispatched' || photos.isNotEmpty;

  int get currentStageIndex =>
      ['materials-dispatched', 'fitting', 'pvcl-inspection', 'net-meter', 'subsidy-credited']
          .indexOf(stage);

  String get installDateFormatted => installDate != null
      ? DateFormat('dd MMM yyyy').format(installDate!)
      : '';

  InstallationModel copyWith({
    String? stage,
    List<InstallationPhoto>? photos,
    WarrantyExpiry? warrantyExpiry,
    String? notes,
    DateTime? installDate,
  }) =>
      InstallationModel(
        id: id,
        clientId: clientId,
        stage: stage ?? this.stage,
        photos: photos ?? this.photos,
        warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
        notes: notes ?? this.notes,
        installDate: installDate ?? this.installDate,
      );
}
