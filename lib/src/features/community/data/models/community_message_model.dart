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
  final bool isStarred;

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
    this.isStarred = false,
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
      isStarred: json['isStarred'] as bool? ?? false,
    );
  }

  CommunityMessageModel copyWith({
    int? id,
    int? communityId,
    int? senderId,
    String? senderType,
    String? senderName,
    String? message,
    String? messageType,
    String? mediaUrl,
    String? mediaType,
    String? fileName,
    String? status,
    int? replyToMessageId,
    String? editedAt,
    bool? isDeleted,
    String? deletedAt,
    int? readByCount,
    String? createdAt,
    CommunityMessageModel? replyTo,
    List<CommunityMessageReactionModel>? reactions,
    String? metadata,
    bool? isStarred,
  }) {
    return CommunityMessageModel(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      readByCount: readByCount ?? this.readByCount,
      createdAt: createdAt ?? this.createdAt,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
      metadata: metadata ?? this.metadata,
      isStarred: isStarred ?? this.isStarred,
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
    isStarred,
  ];
}
