import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/features/community/data/models/comment_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_message_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_model.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';
import 'package:ntk_project/src/features/community/data/models/poll_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_member_model.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final GraphQLService _graphQLService;

  CommunityRepositoryImpl(this._graphQLService);

  @override
  Future<List<CommunityModel>> getCommunities() async {
    const String query = r'''
      query {
        getCommunities {
          id
          name
          description
          image
          allowMemberMessages
          isMuted
          mutedUntil
          pinnedMessageId
          unreadCount
          memberCount
          createdAt
        }
      }
    ''';

    final result = await _graphQLService.performQuery(query);

    if (result.hasException) {
      throw Exception('Failed to fetch communities: ${result.exception}');
    }

    final List data = result.data?['getCommunities'] as List? ?? [];
    return data
        .map<CommunityModel>(
          (json) => CommunityModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<List<PostModel>> getCommunityFeed({int? locationId}) async {
    const String query = r'''
      query CommunityFeed($locationId: Int) {
        communityFeed(locationId: $locationId) {
          id
          content
          image
          likes
          authorName
          commentCount
          comments {
            id
            content
            authorName
            createdAt
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {'locationId': locationId},
    );

    if (result.hasException) {
      throw Exception('Failed to fetch community feed: ${result.exception}');
    }

    final List data = result.data?['communityFeed'] as List? ?? [];
    return data
        .map<PostModel>(
          (json) => PostModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<List<PostModel>> getCommunityPosts({required int communityId}) async {
    const String query = r'''
      query GetPosts($communityId: Int!) {
        getCommunityPosts(communityId: $communityId) {
          id
          title
          content
          image
          likes
          authorName
          commentCount
          comments {
            id
            content
            authorName
            createdAt
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {'communityId': communityId},
    );

    if (result.hasException) {
      throw Exception('Failed to fetch community posts: ${result.exception}');
    }

    final List data = result.data?['getCommunityPosts'] as List? ?? [];
    return data
        .map<PostModel>(
          (json) => PostModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<PostModel> getPostDetails({required int id}) async {
    const String query = r'''
      query GetPostDetails($id: Int!) {
        getPostDetails(id: $id) {
          id
          content
          category
          images
          authorName
          authorRole
          likes
          commentCount
          createdAt
          createdById
          createdByType
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {'id': id},
    );

    if (result.hasException) {
      throw Exception('Failed to fetch post details: ${result.exception}');
    }

    final data = result.data?['getPostDetails'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Post details not found');
    return PostModel.fromJson(data);
  }

  @override
  Future<List<CommunityMessageModel>> getCommunityMessages({
    required int communityId,
    int? limit,
    int? beforeMessageId,
  }) async {
    const String query = r'''
      query GetCommunityMessages($communityId: Int!, $limit: Int, $beforeMessageId: Int) {
        getCommunityMessages(communityId: $communityId, limit: $limit, beforeMessageId: $beforeMessageId) {
          id
          communityId
          senderId
          senderType
          senderName
          message
          messageType
          mediaUrl
          mediaType
          fileName
          status
          replyToMessageId
          editedAt
          isDeleted
          deletedAt
          readByCount
          createdAt
          metadata
          replyTo {
            id
            senderName
            message
          }
          reactions {
            id
            emoji
            reactorName
            reactorId
            reactorType
            createdAt
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {
        'communityId': communityId,
        'limit': limit ?? 50,
        'beforeMessageId': beforeMessageId,
      },
    );

    if (result.hasException) {
      throw Exception(
        'Failed to fetch community messages: ${result.exception}',
      );
    }

    final List data = result.data?['getCommunityMessages'] as List? ?? [];
    return data
        .map<CommunityMessageModel>(
          (json) =>
              CommunityMessageModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<CommunityMessageModel> sendCommunityMessage({
    required int communityId,
    required String message,
    int? replyToMessageId,
    String? messageType,
    String? mediaUrl,
    String? mediaType,
    String? fileName,
    String? metadata,
  }) async {
    const String mutation = r'''
      mutation SendCommunityMessage(
        $communityId: Int!
        $message: String!
        $replyToMessageId: Int
        $messageType: String
        $mediaUrl: String
        $mediaType: String
        $fileName: String
        $metadata: String
      ) {
        sendCommunityMessage(
          communityId: $communityId
          message: $message
          replyToMessageId: $replyToMessageId
          messageType: $messageType
          mediaUrl: $mediaUrl
          mediaType: $mediaType
          fileName: $fileName
          metadata: $metadata
        ) {
          id
          communityId
          senderId
          senderType
          senderName
          message
          messageType
          mediaUrl
          mediaType
          fileName
          status
          replyToMessageId
          readByCount
          createdAt
          metadata
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'communityId': communityId,
        'message': message,
        'replyToMessageId': replyToMessageId,
        'messageType': messageType ?? 'TEXT',
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'fileName': fileName,
        'metadata': metadata,
      },
    );

    if (result.hasException) {
      throw Exception('Failed to send community message: ${result.exception}');
    }

    final data = result.data?['sendCommunityMessage'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Send community message failed');
    return CommunityMessageModel.fromJson(data);
  }

  @override
  Future<int> likePost({required int id}) async {
    const String mutation = r'''
      mutation LikePost($likePostId: Int!) {
        likePost(id: $likePostId) {
          id
          likes
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'likePostId': id},
    );

    if (result.hasException) {
      throw Exception('Failed to like post: ${result.exception}');
    }

    final data = result.data?['likePost'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Like post failed');
    return data['likes'] as int? ?? 0;
  }

  @override
  Future<CommentModel> addComment({
    required int postId,
    required String content,
    required String authorName,
    required String authorRole,
  }) async {
    const String mutation = r'''
      mutation AddComment($postId: Int!, $content: String!, $authorName: String!, $authorRole: String!) {
        addComment(postId: $postId, content: $content, authorName: $authorName, authorRole: $authorRole) {
          id
          content
          authorName
          authorRole
          createdAt
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'postId': postId,
        'content': content,
        'authorName': authorName,
        'authorRole': authorRole,
      },
    );

    if (result.hasException) {
      final errors = result.exception?.graphqlErrors;
      if (errors != null && errors.isNotEmpty) {
        throw Exception(errors.first.message);
      }
      throw Exception('Failed to add comment: ${result.exception}');
    }

    final data = result.data?['addComment'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Add comment failed');
    return CommentModel.fromJson(data);
  }

  @override
  Future<PostModel> createCommunityPost({
    required String title,
    required String content,
    required String category,
    required String authorName,
    required String authorRole,
    required int locationId,
    List<String>? images,
  }) async {
    const String mutation = r'''
      mutation CreatePost($content: String!, $category: String, $images: [String!], $authorName: String!, $authorRole: String!, $locationId: Int!) {
        createPost(content: $content, category: $category, images: $images, authorName: $authorName, authorRole: $authorRole, locationId: $locationId) {
          id
          content
          category
          images
          authorName
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'content': content,
        'category': category,
        'images': images,
        'authorName': authorName,
        'authorRole': authorRole,
        'locationId': locationId,
      },
    );

    if (result.hasException) {
      final errors = result.exception?.graphqlErrors;
      if (errors != null && errors.isNotEmpty) {
        throw Exception(errors.first.message);
      }
      throw Exception('Failed to create post: ${result.exception}');
    }

    final data = result.data?['createPost'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Create post failed');
    return PostModel.fromJson(data);
  }

  @override
  Future<PostModel> editPost({
    required int id,
    required String content,
    List<String>? images,
  }) async {
    const String mutation = r'''
      mutation EditPost($id: Int!, $content: String!, $images: [String!]) {
        editPost(id: $id, content: $content, images: $images) {
          id
          content
          images
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'id': id, 'content': content, 'images': images},
    );

    if (result.hasException) {
      throw Exception('Failed to edit post: ${result.exception}');
    }

    final data = result.data?['editPost'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Edit post failed');
    return PostModel.fromJson(data);
  }

  @override
  Future<bool> deletePost({required int id}) async {
    const String mutation = r'''
      mutation DeletePost($id: Int!) {
        deletePost(id: $id)
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'id': id},
    );

    if (result.hasException) {
      throw Exception('Failed to delete post: ${result.exception}');
    }

    return result.data?['deletePost'] as bool? ?? false;
  }

  @override
  Future<CommunityModel> createCommunity({
    required String name,
    String? description,
    String? image,
    bool allowMemberMessages = true,
  }) async {
    const String mutation = r'''
      mutation CreateCommunity(
        $name: String!
        $description: String
        $image: String
        $allowMemberMessages: Boolean
      ) {
        createCommunity(
          name: $name
          description: $description
          image: $image
          allowMemberMessages: $allowMemberMessages
        ) {
          id
          name
          description
          image
          allowMemberMessages
          memberCount
          createdAt
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'name': name,
        'description': description,
        'image': image,
        'allowMemberMessages': allowMemberMessages,
      },
    );

    if (result.hasException) {
      throw Exception('Failed to create community: ${result.exception}');
    }

    final data = result.data?['createCommunity'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Create community failed');
    return CommunityModel.fromJson(data);
  }

  @override
  Future<void> reactToCommunityMessage({
    required int messageId,
    required String emoji,
  }) async {
    const String mutation = r'''
      mutation ReactToCommunityMessage($messageId: Int!, $emoji: String!) {
        reactToCommunityMessage(messageId: $messageId, emoji: $emoji) {
          id
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'messageId': messageId, 'emoji': emoji},
    );

    if (result.hasException) {
      throw Exception('Failed to react to message: ${result.exception}');
    }
  }

  @override
  Future<void> markCommunityMessagesRead({
    required int communityId,
    required List<int> messageIds,
  }) async {
    const String mutation = r'''
      mutation MarkCommunityMessagesRead($communityId: Int!, $messageIds: [Int!]!) {
        markCommunityMessagesRead(communityId: $communityId, messageIds: $messageIds)
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'communityId': communityId, 'messageIds': messageIds},
    );

    if (result.hasException) {
      throw Exception('Failed to mark messages as read: ${result.exception}');
    }
  }

  @override
  Future<CommunityMessageModel> editCommunityMessage({
    required int id,
    required String message,
  }) async {
    const String mutation = r'''
      mutation EditCommunityMessage($id: Int!, $message: String!) {
        editCommunityMessage(id: $id, message: $message) {
          id
          message
          editedAt
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'id': id, 'message': message},
    );

    if (result.hasException) {
      throw Exception('Failed to edit message: ${result.exception}');
    }

    final data = result.data?['editCommunityMessage'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Edit message failed');
    return CommunityMessageModel.fromJson(data);
  }

  @override
  Future<void> deleteCommunityMessage({required int id}) async {
    const String mutation = r'''
      mutation DeleteCommunityMessage($id: Int!) {
        deleteCommunityMessage(id: $id)
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'id': id},
    );

    if (result.hasException) {
      throw Exception('Failed to delete message: ${result.exception}');
    }
  }

  @override
  Future<int> getCommunityUnreadCount({required int communityId}) async {
    const String query = r'''
      query GetUnreadCount($communityId: Int!) {
        getCommunityUnreadCount(communityId: $communityId)
      }
    ''';
    final result = await _graphQLService.performQuery(
      query,
      variables: {'communityId': communityId},
    );
    if (result.hasException) throw Exception('Failed to get unread count');
    return result.data?['getCommunityUnreadCount'] as int? ?? 0;
  }

  @override
  Future<List<CommunityMemberModel>> getCommunityMembers({
    required int communityId,
  }) async {
    const String query = r'''
      query GetCommunityMembers($communityId: Int!) {
        getCommunityMembers(communityId: $communityId) {
          id
          name
          phone
          image
          role
          isGroupAdmin
          isMuted
        }
      }
    ''';
    final result = await _graphQLService.performQuery(
      query,
      variables: {'communityId': communityId},
    );
    if (result.hasException) throw Exception('Failed to get members');
    final List data = result.data?['getCommunityMembers'] as List? ?? [];
    return data
        .map((e) => CommunityMemberModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<bool> joinCommunity({
    required int communityId,
    required int memberId,
  }) async {
    const String mutation = r'''
      mutation JoinCommunity($communityId: Int!, $memberId: Int!) {
        joinCommunity(communityId: $communityId, memberId: $memberId)
      }
    ''';
    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'communityId': communityId, 'memberId': memberId},
    );
    if (result.hasException) throw Exception('Failed to join community');
    return result.data?['joinCommunity'] as bool? ?? false;
  }

  @override
  Future<CommunityModel> updateCommunityChatSettings({
    required int communityId,
    bool? allowMemberMessages,
    bool? isMuted,
    String? mutedUntil,
    int? pinnedMessageId,
  }) async {
    const String mutation = r'''
      mutation UpdateSettings(
        $communityId: Int!
        $allowMemberMessages: Boolean
        $isMuted: Boolean
        $mutedUntil: String
        $pinnedMessageId: Int
      ) {
        updateCommunityChatSettings(
          communityId: $communityId
          allowMemberMessages: $allowMemberMessages
          isMuted: $isMuted
          mutedUntil: $mutedUntil
          pinnedMessageId: $pinnedMessageId
        ) {
          id
          name
          allowMemberMessages
          isMuted
          mutedUntil
          pinnedMessageId
          memberCount
          createdAt
        }
      }
    ''';
    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'communityId': communityId,
        'allowMemberMessages': allowMemberMessages,
        'isMuted': isMuted,
        'mutedUntil': mutedUntil,
        'pinnedMessageId': pinnedMessageId,
      },
    );
    if (result.hasException) throw Exception('Failed to update settings');
    final data =
        result.data?['updateCommunityChatSettings'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Update settings failed');
    return CommunityModel.fromJson(data);
  }

  @override
  Future<bool> muteCommunityMember({
    required int communityId,
    required int memberId,
    String? mutedUntil,
  }) async {
    const String mutation = r'''
      mutation MuteMember($communityId: Int!, $memberId: Int!, $mutedUntil: String) {
        muteCommunityMember(
          communityId: $communityId
          memberId: $memberId
          mutedUntil: $mutedUntil
        )
      }
    ''';
    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'communityId': communityId,
        'memberId': memberId,
        'mutedUntil': mutedUntil,
      },
    );
    if (result.hasException) throw Exception('Failed to mute member');
    return result.data?['muteCommunityMember'] as bool? ?? false;
  }

  @override
  Future<bool> removeCommunityMember({
    required int communityId,
    required int memberId,
  }) async {
    const String mutation = r'''
      mutation RemoveMember($communityId: Int!, $memberId: Int!) {
        removeCommunityMember(communityId: $communityId, memberId: $memberId)
      }
    ''';
    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'communityId': communityId, 'memberId': memberId},
    );
    if (result.hasException) throw Exception('Failed to remove member');
    return result.data?['removeCommunityMember'] as bool? ?? false;
  }

  @override
  Future<List<PollModel>> getPollList({
    int? communityId,
    int? locationId,
  }) async {
    const String query = r'''
      query GetPolls($communityId: Int, $locationId: Int) {
        getPollList(communityId: $communityId, locationId: $locationId) {
          id
          question
          locationId
          communityId
          expiresAt
          createdAt
          options {
            id
            text
            votesCount
          }
          votesCount
          userVoteOptionId
          createdBy {
            name
          }
          location {
            name
          }
        }
      }
    ''';
    final result = await _graphQLService.performQuery(
      query,
      variables: {'communityId': communityId, 'locationId': locationId},
    );
    if (result.hasException) throw Exception('Failed to get polls');
    final List data = result.data?['getPollList'] as List? ?? [];
    return data
        .map((e) => PollModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PollModel> createPoll({
    required String question,
    required List<String> options,
    required int durationDays,
    required int locationId,
    int? communityId,
  }) async {
    const String mutation = r'''
      mutation CreatePoll(
        $question: String!
        $options: [String!]!
        $durationDays: Int!
        $locationId: Int!
        $communityId: Int
      ) {
        createPoll(
          question: $question
          options: $options
          durationDays: $durationDays
          locationId: $locationId
          communityId: $communityId
        ) {
          id
          question
          options {
            id
            text
            votesCount
          }
          expiresAt
          createdAt
        }
      }
    ''';
    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'question': question,
        'options': options,
        'durationDays': durationDays,
        'locationId': locationId,
        'communityId': communityId,
      },
    );
    if (result.hasException) throw Exception('Failed to create poll');
    final data = result.data?['createPoll'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Create poll failed');
    return PollModel.fromJson(data);
  }

  @override
  Future<int> voteInPoll({required int pollId, required int optionId}) async {
    const String mutation = r'''
      mutation VoteInPoll($pollId: Int!, $optionId: Int!) {
        voteInPoll(pollId: $pollId, optionId: $optionId) {
          votesCount
        }
      }
    ''';
    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'pollId': pollId, 'optionId': optionId},
    );
    if (result.hasException) {
      final errors = result.exception?.graphqlErrors;
      if (errors != null && errors.isNotEmpty) {
        throw Exception(errors.first.message);
      }
      throw Exception('Failed to vote: ${result.exception}');
    }
    final data = result.data?['voteInPoll'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Vote failed');
    return data['votesCount'] as int? ?? 0;
  }

  @override
  Future<PollModel> getPollDetails({required int id}) async {
    const String query = r'''
      query GetPollDetails($id: Int!) {
        getPollDetails(id: $id) {
          id
          question
          locationId
          communityId
          expiresAt
          createdAt
          options {
            id
            text
            votesCount
          }
          votesCount
          userVoteOptionId
          createdBy {
            name
          }
          location {
            name
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {'id': id},
    );

    if (result.hasException) {
      throw Exception('Failed to get poll details: ${result.exception}');
    }

    final data = result.data?['getPollDetails'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Poll details not found');
    return PollModel.fromJson(data);
  }
}
