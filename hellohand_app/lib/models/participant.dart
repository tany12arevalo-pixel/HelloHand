class Participant {
  final String id;
  final String name;
  final bool hasCamera;
  final bool hasMicrophone;
  final bool isDeaf;
  final bool isMute;
  final DateTime joinedAt;

  Participant({
    required this.id,
    required this.name,
    required this.hasCamera,
    required this.hasMicrophone,
    required this.isDeaf,
    required this.isMute,
    required this.joinedAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'],
      name: json['name'],
      hasCamera: json['has_camera'] ?? false,
      hasMicrophone: json['has_microphone'] ?? false,
      isDeaf: json['is_deaf'] ?? false,
      isMute: json['is_mute'] ?? false,
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'has_camera': hasCamera,
      'has_microphone': hasMicrophone,
      'is_deaf': isDeaf,
      'is_mute': isMute,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}