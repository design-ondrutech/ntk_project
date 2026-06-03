class EventModel {
  final String id;
  final String title;
  final String description;
  final String date;
  final String locationName;
  final int going;
  final int maybe;
  final int notGoing;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.locationName,
    required this.going,
    required this.maybe,
    required this.notGoing,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    final stats = json['stats'] as Map<String, dynamic>?;

    return EventModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      locationName: location?['name'] ?? 'Unknown Location',
      going: stats?['going'] ?? 0,
      maybe: stats?['maybe'] ?? 0,
      notGoing: stats?['notGoing'] ?? 0,
    );
  }
}

class EventMemberModel {
  final String id;
  final String name;
  final String phone;
  final String? role;

  EventMemberModel({
    required this.id,
    required this.name,
    required this.phone,
    this.role,
  });

  factory EventMemberModel.fromJson(Map<String, dynamic> json) {
    return EventMemberModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown',
      phone: json['phone'] ?? '',
      role: json['role'] as String?,
    );
  }
}

class EventResponseModel {
  final String status;
  final EventMemberModel member;

  EventResponseModel({required this.status, required this.member});

  factory EventResponseModel.fromJson(Map<String, dynamic> json) {
    return EventResponseModel(
      status: json['status'] ?? 'UNKNOWN',
      member: EventMemberModel.fromJson(
        json['member'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
