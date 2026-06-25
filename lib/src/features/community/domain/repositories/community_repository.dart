import 'package:ntk_project/src/features/community/data/models/comment_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_message_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_model.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';
import 'package:ntk_project/src/features/community/data/models/poll_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_member_model.dart';
import 'package:ntk_project/src/features/community/data/models/pending_join_request_model.dart';
import 'package:ntk_project/src/features/community/data/models/complaint_model.dart';
import 'package:ntk_project/src/features/community/data/models/announcement_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_settings_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_link_doc_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_analytics_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_ban_model.dart';

abstract class CommunityRepository {
  // 1. Community Discovery & Listing
  Future<List<CommunityModel>> getCommunities({bool? joinedOnly, String? privacyType});
  Future<List<CommunityModel>> getFeaturedCommunities();
  Future<List<CommunityModel>> getNearbyCommunities({int? locationId, int? radiusKm});
  Future<List<CommunityModel>> searchCommunities({String? query, int? locationId});

  // 2. Community Details & Info
  Future<CommunityModel> getCommunityDetails({required int communityId});
  Future<String> getCommunityRules({required int communityId});
  Future<CommunitySettingsModel> getCommunitySettings({required int communityId});
  Future<List<Map<String, dynamic>>> getCommunityRolesAndPermissions({required int communityId});

  Future<List<PostModel>> getCommunityFeed({int? locationId});

  Future<List<PostModel>> getCommunityPosts({
    required int communityId,
    String? category,
  });
  Future<PostModel> getPostDetails({required int id});

  Future<List<CommunityMessageModel>> getCommunityMessages({
    required int communityId,
    int? limit,
    int? beforeMessageId,
  });

  Future<CommunityMessageModel> sendCommunityMessage({
    required int communityId,
    required String message,
    int? replyToMessageId,
    String? messageType,
    String? mediaUrl,
    String? mediaType,
    String? fileName,
    String? metadata,
  });

  Future<int> likePost({required int id});
  Future<int> unlikePost({required int id});
  Future<Map<String, dynamic>> likeComment({required int commentId});

  Future<CommentModel> addComment({
    required int postId,
    required String content,
    required String authorName,
    required String authorRole,
    int? parentId,
  });

  Future<PostModel> createFeedPost({
    required String title,
    required String content,
    required String category,
    required String authorName,
    required String authorRole,
    required int locationId,
    List<String>? images,
  });

  Future<PostModel> createCommunityPost({
    required int communityId,
    required String title,
    required String content,
    String? category,
    List<String>? images,
    List<String>? documents,
  });

  Future<PostModel> editPost({
    required int id,
    required String content,
    List<String>? images,
  });

  Future<bool> deletePost({required int id});

  Future<void> reportPost({required int postId, required String reason});

  Future<List<PostModel>> getReportedPostsList({
    int? locationId,
    String? status,
  });

  Future<PostModel> moderatePost({
    required int postId,
    required String action,
    String? warningMessage,
  });

  Future<int> likeCommunityPost({required int postId});

  Future<CommentModel> addCommunityComment({
    required int postId,
    required String content,
  });

  Future<void> reportCommunityPost({
    required int postId,
    required String reason,
  });

  Future<void> resolveCommunityPostReport({
    required int reportId,
    required String action,
    String? warningMessage,
  });

  Future<CommunityModel> createCommunity({
    required String name,
    String? description,
    String? image,
    bool allowMemberMessages,
    int? locationId,
    String? privacyType,
  });

  Future<void> reactToCommunityMessage({
    required int messageId,
    required String emoji,
  });

  Future<void> markCommunityMessagesRead({
    required int communityId,
    required List<int> messageIds,
  });

  Future<CommunityMessageModel> editCommunityMessage({
    required int id,
    required String message,
  });

  Future<void> deleteCommunityMessage({required int id});

  Future<CommunityMessageModel> starCommunityMessage({required int messageId});
  Future<CommunityMessageModel> unstarCommunityMessage({required int messageId});
  Future<List<CommunityMessageModel>> getCommunityStarredMessages({required int communityId});

  Future<int> getCommunityUnreadCount({required int communityId});

  Future<List<CommunityMemberModel>> getCommunityMembers({
    required int communityId,
    String? role,
    String? search,
  });

  Future<CommunityMemberModel> getMemberDetails({required int id, int? communityId});
  Future<List<CommunityMemberModel>> getOnlineMembers({required int communityId});

  // 4. Community Join & Management
  Future<String> joinCommunityOrRequest({
    required int communityId,
    String? reason,
    String? inviteCode,
  });
  Future<bool> leaveCommunity({required int communityId});

  // Admin Methods
  Future<List<PendingJoinRequestModel>> getPendingCommunityJoinRequests({required int communityId, String? status});
  Future<bool> bulkApproveJoinRequests({required int communityId, required List<int> requestIds});
  Future<bool> reviewCommunityJoinRequest({required int requestId, required String action, String? rejectionReason});
  Future<bool> updateCommunityMemberRole({required int communityId, required int targetUserId, required String newRole});
  
  // Complaints & Bans
  Future<ComplaintModel> createCommunityComplaint({required int communityId, required String title, required String description});
  Future<List<ComplaintModel>> getCommunityComplaints({required int communityId, String? status});
  Future<bool> banCommunityUser({required int communityId, required int userId, String? reason, int? durationDays});
  Future<bool> unbanCommunityUser({required int communityId, required int userId});

  // Announcements
  Future<AnnouncementModel> createCommunityAnnouncement({
    required int communityId,
    required String title,
    required String message,
    bool? isPinned,
    String? scheduledFor,
  });
  Future<List<AnnouncementModel>> getCommunityAnnouncements({required int communityId});
  Future<AnnouncementModel> pinCommunityAnnouncement({required int announcementId});
  Future<AnnouncementModel> unpinCommunityAnnouncement({required int announcementId});
  Future<AnnouncementModel> updateCommunityAnnouncement({
    required int announcementId,
    String? title,
    String? message,
    bool? isPinned,
    String? scheduledFor,
  });
  Future<bool> deleteCommunityAnnouncement({required int announcementId});

  // Links & Docs
  Future<List<CommunityLinkDocModel>> getCommunityLinksAndDocs({required int communityId});
  Future<CommunityLinkDocModel> uploadCommunityLinkOrDoc({
    required int communityId,
    required String title,
    required String url,
    required String type,
  });
  Future<bool> deleteCommunityLinkOrDoc({required int linkOrDocId});

  // Community Settings & Invites
  Future<CommunitySettingsModel> updateCommunitySettings({
    required int communityId,
    required CommunitySettingsModel settings,
  });
  Future<String> generateCommunityInviteCode({required int communityId, int? expiryDays});
  Future<String> getCommunityInviteCode({required int communityId});

  // Events
  Future<List<Map<String, dynamic>>> getCommunityEvents({required int communityId});

  // Analytics & Bans
  Future<CommunityAnalyticsModel> getCommunityAnalytics({required int communityId});
  Future<List<CommunityBanModel>> getCommunityBans({required int communityId});
  Future<bool> reportCommunityMember({required int communityId, required int reportedUserId, required String reason});

  Future<CommunityModel> updateCommunityChatSettings({
    required int communityId,
    bool? allowMemberMessages,
    bool? isMuted,
    String? mutedUntil,
    int? pinnedMessageId,
  });

  Future<bool> muteCommunityMember({
    required int communityId,
    required int memberId,
    String? mutedUntil,
  });

  Future<bool> removeCommunityMember({
    required int communityId,
    required int memberId,
  });

  Future<List<PollModel>> getPollList({int? communityId, int? locationId});

  Future<PollModel> createPoll({
    required String question,
    required List<String> options,
    required int durationDays,
    required int locationId,
    int? communityId,
  });

  Future<int> voteInPoll({required int pollId, required int optionId});
  Future<Map<String, dynamic>> likePoll({required int pollId});
  Future<Map<String, dynamic>> likePollComment({required int pollCommentId});
  Future<CommentModel> addPollComment({
    required int pollId,
    required String content,
    required String authorName,
    required String authorRole,
    int? parentId,
  });
  Future<PollModel> getPollDetails({required int id});
}
