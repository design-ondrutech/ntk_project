import 'package:ntk_project/src/features/community/data/models/comment_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_message_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_model.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';
import 'package:ntk_project/src/features/community/data/models/poll_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_member_model.dart';

abstract class CommunityRepository {
  Future<List<CommunityModel>> getCommunities();

  Future<List<PostModel>> getCommunityFeed({int? locationId});

  Future<List<PostModel>> getCommunityPosts({required int communityId});
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

  Future<CommentModel> addComment({
    required int postId,
    required String content,
    required String authorName,
    required String authorRole,
  });

  Future<PostModel> createCommunityPost({
    required String title,
    required String content,
    required String category,
    required String authorName,
    required String authorRole,
    required int locationId,
    List<String>? images,
  });

  Future<PostModel> editPost({
    required int id,
    required String content,
    List<String>? images,
  });

  Future<bool> deletePost({required int id});

  Future<CommunityModel> createCommunity({
    required String name,
    String? description,
    String? image,
    bool allowMemberMessages,
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

  Future<int> getCommunityUnreadCount({required int communityId});

  Future<List<CommunityMemberModel>> getCommunityMembers({
    required int communityId,
  });

  Future<bool> joinCommunity({required int communityId, required int memberId});

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

  Future<PollModel> getPollDetails({required int id});
}
