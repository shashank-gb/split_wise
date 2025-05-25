import 'package:cloud_firestore/cloud_firestore.dart';

enum GroupType { trip, home, couple, other }

class Group {
  final String id;
  final String name;
  final GroupType type;
  final String createdBy;
  final List<String> members;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.type,
    required this.createdBy,
    required this.members,
    required this.createdAt,
  });

  factory Group.fromMap(Map<String, dynamic> data, String id) {
    return Group(
      id: id,
      name: data['name'] ?? '',
      type: _stringToGroupType(data['type'] ?? 'other'),
      createdBy: data['createdBy'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': _groupTypeToString(type),
      'createdBy': createdBy,
      'members': members,
      'createdAt': createdAt,
    };
  }

  static String _groupTypeToString(GroupType type) {
    return type.toString().split('.').last;
  }

  static GroupType _stringToGroupType(String type) {
    return GroupType.values.firstWhere(
          (e) => e.toString().split('.').last == type,
      orElse: () => GroupType.other,
    );
  }
}