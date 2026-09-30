/// User model — mirrors the Firestore `users` document.
class UserModel {
  final String uid;
  final String name;
  final String nameGu;
  final String role; // "owner" | "coowner"
  final String phone;
  final String email;
  final String? photoUrl;

  const UserModel({
    required this.uid,
    required this.name,
    required this.nameGu,
    required this.role,
    required this.phone,
    required this.email,
    this.photoUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['uid'] as String,
        name: json['name'] as String,
        nameGu: json['nameGu'] as String,
        role: json['role'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String,
        photoUrl: json['photoUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'nameGu': nameGu,
        'role': role,
        'phone': phone,
        'email': email,
        'photoUrl': photoUrl,
      };

  bool get isOwner => role == 'owner';
  bool get isCoOwner => role == 'coowner';
  bool get canDelete => isOwner;

  String get displayName => name;
  String get displayRole =>
      role == 'owner' ? 'Founder' : role == 'coowner' ? 'Co-Founder' : role;

  UserModel copyWith({String? photoUrl}) => UserModel(
        uid: uid,
        name: name,
        nameGu: nameGu,
        role: role,
        phone: phone,
        email: email,
        photoUrl: photoUrl ?? this.photoUrl,
      );
}
