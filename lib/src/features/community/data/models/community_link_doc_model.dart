import 'package:equatable/equatable.dart';

class CommunityLinkDocModel extends Equatable {
  final int id;
  final String title;
  final String url;
  final String type;
  final String uploadedAt;

  const CommunityLinkDocModel({
    required this.id,
    required this.title,
    required this.url,
    required this.type,
    required this.uploadedAt,
  });

  factory CommunityLinkDocModel.fromJson(Map<String, dynamic> json) {
    return CommunityLinkDocModel(
      id: json['id'] as int,
      title: json['title'] as String,
      url: json['url'] as String,
      type: json['type'] as String,
      uploadedAt: json['uploadedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'type': type,
      'uploadedAt': uploadedAt,
    };
  }

  @override
  List<Object?> get props => [id, title, url, type, uploadedAt];
}
