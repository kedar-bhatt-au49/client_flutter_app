/// App settings model — mirrors the Firestore `settings` document.
class AppSettingsModel {
  final String id;
  final String workingHours;
  final String defaultPackage;
  final double subsidyMax;
  final String pricesLastUpdated;

  AppSettingsModel({
    this.id = 'single',
    this.workingHours = '9:00 AM – 8:00 PM, all days',
    this.defaultPackage = '3.69',
    this.subsidyMax = 78000,
    this.pricesLastUpdated = '2026-09-29',
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) => AppSettingsModel(
        id: json['id'] as String? ?? 'single',
        workingHours: json['workingHours'] as String? ??
            '9:00 AM – 8:00 PM, all days',
        defaultPackage: json['defaultPackage'] as String? ?? '3.69',
        subsidyMax: (json['subsidyMax'] as num?)?.toDouble() ?? 78000,
        pricesLastUpdated:
            json['pricesLastUpdated'] as String? ?? '2026-09-29',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workingHours': workingHours,
        'defaultPackage': defaultPackage,
        'subsidyMax': subsidyMax,
        'pricesLastUpdated': pricesLastUpdated,
      };
}
