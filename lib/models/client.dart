import 'package:intl/intl.dart';

/// Client / Lead model — mirrors the Firestore `clients` document.
class ClientModel {
  final String id;
  final String name;
  final String phone;
  final String? altPhone;
  final String area; // Talaja | Bhavnagar | Village
  final String? village;
  final String? city;
  final String propertyType; // Residential | Commercial
  final double monthlyBill;
  final String preferredPackage; // "3.08" | "3.69" | ... | "not-sure"
  final String source; // Website | WhatsApp | Walk-in | Referral
  final String status; // new | contacted | site-visit | quoted | booked | installed | subsidized | lost
  final String ownerUid;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClientModel({
    required this.id,
    required this.name,
    required this.phone,
    this.altPhone,
    required this.area,
    this.village,
    this.city,
    required this.propertyType,
    required this.monthlyBill,
    required this.preferredPackage,
    required this.source,
    required this.status,
    required this.ownerUid,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) => ClientModel(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        altPhone: json['altPhone'] as String?,
        area: json['area'] as String,
        village: json['village'] as String?,
        city: json['city'] as String?,
        propertyType: json['propertyType'] as String? ?? 'Residential',
        monthlyBill: (json['monthlyBill'] as num).toDouble(),
        preferredPackage: json['preferredPackage'] as String? ?? 'not-sure',
        source: json['source'] as String? ?? 'Website',
        status: json['status'] as String? ?? 'new',
        ownerUid: json['ownerUid'] as String,
        notes: json['notes'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'altPhone': altPhone,
        'area': area,
        'village': village,
        'city': city,
        'propertyType': propertyType,
        'monthlyBill': monthlyBill,
        'preferredPackage': preferredPackage,
        'source': source,
        'status': status,
        'ownerUid': ownerUid,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  String get displayArea {
    if (village != null && village!.isNotEmpty) return village!;
    if (city != null && city!.isNotEmpty) return city!;
    return area;
  }
  String get createdAtFormatted => DateFormat('dd MMM yyyy').format(createdAt);
  bool get isNew => status == 'new';

  ClientModel copyWith({
    String? name,
    String? phone,
    String? altPhone,
    String? area,
    String? village,
    String? city,
    String? propertyType,
    double? monthlyBill,
    String? preferredPackage,
    String? source,
    String? status,
    String? ownerUid,
    String? notes,
    DateTime? updatedAt,
  }) =>
      ClientModel(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        altPhone: altPhone ?? this.altPhone,
        area: area ?? this.area,
        village: village ?? this.village,
        city: city ?? this.city,
        propertyType: propertyType ?? this.propertyType,
        monthlyBill: monthlyBill ?? this.monthlyBill,
        preferredPackage: preferredPackage ?? this.preferredPackage,
        source: source ?? this.source,
        status: status ?? this.status,
        ownerUid: ownerUid ?? this.ownerUid,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}
