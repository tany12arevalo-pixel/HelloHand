import '../models/participant.dart';

class Room {
  final String id;
  final String name;
  final int maxParticipants;
  final List<Participant> participants;
  final DateTime createdAt;
  final bool isActive;

  Room({
    required this.id,
    required this.name,
    required this.maxParticipants,
    required this.participants,
    required this.createdAt,
    required this.isActive,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['room_id'] ?? json['id'],
      name: json['name'],
      maxParticipants: json['max_participants'],
      participants: (json['participants'] as List?)
          ?.map((p) => Participant.fromJson(p))
          .toList() ?? [],
      createdAt: DateTime.parse(json['created_at']),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': id,
      'name': name,
      'max_participants': maxParticipants,
      'participants': participants.map((p) => p.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}