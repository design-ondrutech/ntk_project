import 'package:equatable/equatable.dart';

class CommunityMessageReactionModel extends Equatable {
  final int id;
  final String emoji;
  final String reactorName;
  final int? reactorId;
  final String? reactorType;
  final String? createdAt;

  const CommunityMessageReactionModel({
    required this.id,
    required this.emoji,
    required this.reactorName,
    this.reactorId,
    this.reactorType,
    this.createdAt,
  });

  factory CommunityMessageReactionModel.fromJson(Map<String, dynamic> json) {
    return CommunityMessageReactionModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      emoji: json['emoji'] as String? ?? '',
      reactorName: json['reactorName'] as String? ?? 'Unknown',
      reactorId: json['reactorId'] is int
          ? json['reactorId'] as int
          : int.tryParse(json['reactorId']?.toString() ?? ''),
      reactorType: json['reactorType'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    emoji,
    reactorName,
    reactorId,
    reactorType,
    createdAt,
  ];
}

class CommunityMessageModel extends Equatable {
  final int id;
  final int communityId;
  final int? senderId;
  final String? senderType;
  final String senderName;
  final String message;
  final String messageType;
  final String? mediaUrl;
  final String? mediaType;
  final String? fileName;
  final String? status;
  final int? replyToMessageId;
  final String? editedAt;
  final bool isDeleted;
  final String? deletedAt;
  final int readByCount;
  final String? createdAt;
  final CommunityMessageModel? replyTo;
  final List<CommunityMessageReactionModel> reactions;
  final String? metadata;

  const CommunityMessageModel({
    required this.id,
    required this.communityId,
    this.senderId,
    this.senderType,
    required this.senderName,
    required this.message,
    required this.messageType,
    this.mediaUrl,
    this.mediaType,
    this.fileName,
    this.status,
    this.replyToMessageId,
    this.editedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.readByCount = 0,
    this.createdAt,
    this.replyTo,
    this.reactions = const [],
    this.metadata,
  });

  factory CommunityMessageModel.fromJson(Map<String, dynamic> json) {
    final reactionsJson = json['reactions'] as List? ?? [];
    final replyJson = json['replyTo'] as Map<String, dynamic>?;

    return CommunityMessageModel(
      id: json['id'] != null ? (json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0) : 0,
      communityId: json['communityId'] != null ? (json['communityId'] is int ? json['communityId'] as int : int.tryParse(json['communityId'].toString()) ?? 0) : 0,
      senderId: json['senderId'] != null ? (json['senderId'] is int ? json['senderId'] as int : int.tryParse(json['senderId'].toString())) : null,
      senderType: json['senderType'] as String?,
      senderName: json['senderName'] as String? ?? 'Unknown',
      message: json['message'] as String? ?? '',
      messageType: json['messageType'] as String? ?? 'TEXT',
      mediaUrl: json['mediaUrl'] as String?,
      mediaType: json['mediaType'] as String?,
      fileName: json['fileName'] as String?,
      status: json['status'] as String?,
      replyToMessageId: json['replyToMessageId'] as int?,
      editedAt: json['editedAt'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] as String?,
      readByCount: json['readByCount'] as int? ?? 0,
      createdAt: json['createdAt'] as String?,
      replyTo: replyJson == null
          ? null
          : CommunityMessageModel.fromJson({
              ...replyJson,
              'communityId': json['communityId'],
            }),
      reactions: reactionsJson
          .map(
            (json) => CommunityMessageReactionModel.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList(),
      metadata: json['metadata'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    communityId,
    senderId,
    senderType,
    senderName,
    message,
    messageType,
    mediaUrl,
    mediaType,
    fileName,
    status,
    replyToMessageId,
    editedAt,
    isDeleted,
    deletedAt,
    readByCount,
    createdAt,
    replyTo,
    reactions,
    metadata,
  ];
}
