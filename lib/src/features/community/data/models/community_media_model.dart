import 'package:equatable/equatable.dart';

class CommunityMediaModel extends Equatable {
  final int messageId;
  final String mediaUrl;
  final String mediaType;
  final String? fileName;
  final String createdAt;

  const CommunityMediaModel({
    required this.messageId,
    required this.mediaUrl,
    required this.mediaType,
    this.fileName,
    required this.createdAt,
  });

  factory CommunityMediaModel.fromJson(Map<String, dynamic> json) {
    return CommunityMediaModel(
      messageId: json['messageId'] as int,
      mediaUrl: json['mediaUrl'] as String,
      mediaType: json['mediaType'] as String,
      fileName: json['fileName'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'fileName': fileName,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [messageId, mediaUrl, mediaType, fileName, createdAt];
}
