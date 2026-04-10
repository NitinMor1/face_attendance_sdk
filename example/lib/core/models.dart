
enum IdentityCategory { individual, unauthorized, guest, enrolled }

class SDKIdentity {
  final String id;
  final String name;
  final String group;
  final IdentityCategory category;
  final List<double> embedding;
  final DateTime enrolledAt;

  SDKIdentity({
    required this.id,
    required this.name,
    this.group = 'General',
    this.category = IdentityCategory.enrolled,
    required this.embedding,
    DateTime? enrolledAt,
  }) : enrolledAt = enrolledAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'group': group,
        'category': category.index,
        'embedding': embedding,
        'enrolledAt': enrolledAt.toIso8601String(),
      };

  factory SDKIdentity.fromJson(Map<String, dynamic> json) => SDKIdentity(
        id: json['id'],
        name: json['name'],
        group: json['group'] ?? 'General',
        category: IdentityCategory.values[json['category'] ?? 0],
        embedding: List<double>.from(json['embedding']),
        enrolledAt: DateTime.parse(json['enrolledAt'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      );
}

enum EventType { identification, verification, enrollment }

class RecognitionEvent {
  final String identityId;
  final String identityName;
  final IdentityCategory category;
  final DateTime timestamp;
  final EventType type;
  final double confidence;

  RecognitionEvent({
    required this.identityId,
    required this.identityName,
    required this.category,
    required this.timestamp,
    required this.type,
    this.confidence = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'identityId': identityId,
        'identityName': identityName,
        'category': category.index,
        'timestamp': timestamp.toIso8601String(),
        'type': type.index,
        'confidence': confidence,
      };

  factory RecognitionEvent.fromJson(Map<String, dynamic> json) => RecognitionEvent(
        identityId: json['identityId'] ?? json['userId'] ?? 'unknown',
        identityName: json['identityName'] ?? json['userName'] ?? 'Unknown',
        category: IdentityCategory.values[json['category'] ?? 0],
        timestamp: DateTime.parse(json['timestamp']),
        type: EventType.values[json['type'] ?? 0],
        confidence: (json['confidence'] ?? 1.0).toDouble(),
      );
}
