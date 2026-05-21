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
