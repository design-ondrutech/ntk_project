import 'package:equatable/equatable.dart';

class CommunityModel extends Equatable {
  final int id;
  final String name;
  final String? description;
  final String? image;
  final bool allowMemberMessages;
  final bool isMuted;
  final String? mutedUntil;
  final int? pinnedMessageId;
  final Map<String, dynamic>? pinnedMessage;
  final int unreadCount;
  final int memberCount;
  final int? locationId;
  final Map<String, dynamic>? location;
  final String createdAt;

  const CommunityModel({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.allowMemberMessages = true,
    this.isMuted = false,
    this.mutedUntil,
    this.pinnedMessageId,
    this.pinnedMessage,
    this.unreadCount = 0,
    required this.memberCount,
    this.locationId,
    this.location,
    required this.createdAt,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      image: json['image'] as String?,
      allowMemberMessages: json['allowMemberMessages'] as bool? ?? true,
      isMuted: json['isMuted'] as bool? ?? false,
      mutedUntil: json['mutedUntil'] as String?,
      pinnedMessageId: json['pinnedMessageId'] as int?,
      pinnedMessage: json['pinnedMessage'] as Map<String, dynamic>?,
      unreadCount: json['unreadCount'] as int? ?? 0,
      memberCount: json['memberCount'] as int? ?? 0,
      locationId: json['locationId'] as int?,
      location: json['location'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] as String,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    image,
    allowMemberMessages,
    isMuted,
    mutedUntil,
    pinnedMessageId,
    pinnedMessage,
    unreadCount,
    memberCount,
    locationId,
    location,
    createdAt,
  ];
}
