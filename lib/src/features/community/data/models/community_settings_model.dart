import 'package:equatable/equatable.dart';

class CommunitySettingsModel extends Equatable {
  final int communityId;
  final bool notificationsEnabled;
  final bool mediaAutoDownload;
  final bool linksAndDocsEnabled;
  final bool muted;
  final bool starredMessagesEnabled;
  final String? about;
  final String? location;

  const CommunitySettingsModel({
    required this.communityId,
    this.notificationsEnabled = true,
    this.mediaAutoDownload = false,
    this.linksAndDocsEnabled = true,
    this.muted = false,
    this.starredMessagesEnabled = true,
    this.about,
    this.location,
  });

  factory CommunitySettingsModel.fromJson(Map<String, dynamic> json) {
    return CommunitySettingsModel(
      communityId: json['communityId'] as int,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      mediaAutoDownload: json['mediaAutoDownload'] as bool? ?? false,
      linksAndDocsEnabled: json['linksAndDocsEnabled'] as bool? ?? true,
      muted: json['muted'] as bool? ?? false,
      starredMessagesEnabled: json['starredMessagesEnabled'] as bool? ?? true,
      about: json['about'] as String?,
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'communityId': communityId,
      'notificationsEnabled': notificationsEnabled,
      'mediaAutoDownload': mediaAutoDownload,
      'linksAndDocsEnabled': linksAndDocsEnabled,
      'muted': muted,
      'starredMessagesEnabled': starredMessagesEnabled,
      'about': about,
      'location': location,
    };
  }

  CommunitySettingsModel copyWith({
    bool? notificationsEnabled,
    bool? mediaAutoDownload,
    bool? linksAndDocsEnabled,
    bool? muted,
    bool? starredMessagesEnabled,
    String? about,
    String? location,
  }) {
    return CommunitySettingsModel(
      communityId: communityId,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      mediaAutoDownload: mediaAutoDownload ?? this.mediaAutoDownload,
      linksAndDocsEnabled: linksAndDocsEnabled ?? this.linksAndDocsEnabled,
      muted: muted ?? this.muted,
      starredMessagesEnabled: starredMessagesEnabled ?? this.starredMessagesEnabled,
      about: about ?? this.about,
      location: location ?? this.location,
    );
  }

  @override
  List<Object?> get props => [
        communityId,
        notificationsEnabled,
        mediaAutoDownload,
        linksAndDocsEnabled,
        muted,
        starredMessagesEnabled,
        about,
        location,
      ];
}
