import 'package:equatable/equatable.dart';

class ComplaintModel extends Equatable {
  final int id;
  final String title;
  final String? description;
  final String? status;
  final String createdAt;
  final Map<String, dynamic>? reporter;

  const ComplaintModel({
    required this.id,
    required this.title,
    this.description,
    this.status,
    required this.createdAt,
    this.reporter,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      reporter: json['reporter'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [id, title, description, status, createdAt, reporter];
}
