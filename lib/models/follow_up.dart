import 'package:intl/intl.dart';

/// Follow-up model — mirrors the Firestore `followups` document.
class FollowUpModel {
  final String id;
  final String clientId;
  final DateTime date;
  final String time; // "HH:mm"
  final String status; // pending | done | missed
  final String? note;
  final DateTime createdAt;
  final DateTime? doneAt;

  FollowUpModel({
    required this.id,
    required this.clientId,
    required this.date,
    required this.time,
    required this.status,
    this.note,
    required this.createdAt,
    this.doneAt,
  });

  factory FollowUpModel.fromJson(Map<String, dynamic> json) => FollowUpModel(
        id: json['id'] as String,
        clientId: json['clientId'] as String,
        date: DateTime.parse(json['date'] as String),
        time: json['time'] as String? ?? '10:00',
        status: json['status'] as String? ?? 'pending',
        note: json['note'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        doneAt: json['doneAt'] != null
            ? DateTime.parse(json['doneAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'date': date.toIso8601String(),
        'time': time,
        'status': status,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'doneAt': doneAt?.toIso8601String(),
      };

  bool get isPending => status == 'pending';
  bool get isDone => status == 'done';
  bool get isMissed => status == 'missed';
  bool get isOverdue {
    final due = DateTime(date.year, date.month, date.day);
    return isPending && DateTime.now().isAfter(due);
  }

  String get dateFormatted => DateFormat('EEE, dd MMM').format(date);
  String get timeFormatted => _formatTime(time);

  static String _formatTime(String t) {
    final parts = t.split(':');
    if (parts.length != 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '${displayH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  FollowUpModel copyWith({
    String? status,
    String? note,
    DateTime? date,
    String? time,
    DateTime? doneAt,
  }) =>
      FollowUpModel(
        id: id,
        clientId: clientId,
        date: date ?? this.date,
        time: time ?? this.time,
        status: status ?? this.status,
        note: note ?? this.note,
        createdAt: createdAt,
        doneAt: doneAt ?? this.doneAt,
      );
}
