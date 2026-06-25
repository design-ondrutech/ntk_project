import 'package:ntk_project/src/core/network/graphql_service.dart';
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
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final GraphQLService _graphQLService;

  CommunityRepositoryImpl(this._graphQLService);

  @override
  Future<List<CommunityModel>> getCommunities({bool? joinedOnly, String? privacyType}) async {
    const String query = r'''
      query GetCommunities($joinedOnly: Boolean, $privacyType: CommunityPrivacyType) {
        getCommunities(joinedOnly: $joinedOnly, privacyType: $privacyType) {
          id
          name
          description
          image
          memberCount
          isJoined
          rules
          privacyType
          isArchived
          locationId
          location {
            id
            name
            type
          }
          createdAt
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {
        'joinedOnly': joinedOnly,
        if (privacyType != null) 'privacyType': privacyType,
      },
    );

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
  Future<String> joinCommunityOrRequest({
    required int communityId,
    String? reason,
    String? inviteCode,
  }) async {
    const String mutation = r'''
      mutation JoinCommunityOrRequest($communityId: Int!, $reason: String, $inviteCode: String) {
        joinCommunityOrRequest(communityId: $communityId, reason: $reason, inviteCode: $inviteCode)
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'communityId': communityId,
        'reason': reason,
        'inviteCode': inviteCode,
      },
    );

    if (result.hasException) {
      throw Exception('Failed to join community: ${result.exception}');
    }

    return result.data?['joinCommunityOrRequest'] as String? ?? 'ERROR';
  }

  @override
  Future<bool> leaveCommunity({required int communityId}) async {
    const String mutation = r'''
      mutation LeaveCommunity($communityId: Int!) {
        leaveCommunity(communityId: $communityId)
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'communityId': communityId},
    );

    if (result.hasException) {
      throw Exception('Failed to leave community: ${result.exception}');
    }

    return result.data?['leaveCommunity'] as bool? ?? false;
  }

  @override
  Future<List<PostModel>> getCommunityFeed({int? locationId}) async {
    const String query = r'''
      query CommunityFeed($locationId: Int) {
        communityFeed(locationId: $locationId) {
          id
          content
          category
          image
          images
          likes
          commentCount
          createdAt
          authorName
          createdById
          isLiked
          location {
            name
          }
          comments {
            id
            content
            authorName
            authorRole
            createdAt
            parentId
            likesCount
            isLiked
            replies {
              id
              content
              authorName
              authorRole
              createdAt
              parentId
              likesCount
              isLiked
            }
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
  Future<List<PostModel>> getCommunityPosts({
    required int communityId,
    String? category,
  }) async {
    const String query = r'''
      query GetCommunityPosts($communityId: Int!, $category: String) {
        getCommunityPosts(communityId: $communityId, category: $category) {
          id
          content
          category
          image
          images
          documents
          attachments
          authorName
          authorRole
          likes
          commentCount
          isLiked
          community {
            id
            name
          }
          createdBy {
            id
            name
            role
          }
          location {
            id
            name
          }
          comments {
            id
            content
            authorName
            authorRole
            createdAt
            parentId
            likesCount
            isLiked
            replies {
              id
              content
              authorName
              authorRole
              createdAt
              parentId
              likesCount
              isLiked
            }
          }
          createdAt
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {'communityId': communityId, 'category': category},
    );

    if (result.hasException) {
      throw Exception('Failed to get community posts: ${result.exception}');
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
          createdByType
          isLiked
          location {
            name
          }
          createdBy {
            id
            name
            image
          }
          comments {
            id
            content
            authorName
            authorRole
            createdAt
            parentId
            likesCount
            isLiked
            replies {
              id
              content
              authorName
              authorRole
              createdAt
              parentId
              likesCount
              isLiked
            }
          }
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
    return (data['likesCount'] ?? data['likes_count'] ?? data['likes'])
            as int? ??
        0;
  }

  @override
  Future<int> unlikePost({required int id}) async {
    const String mutation = r'''
      mutation UnlikePost($unlikePostId: Int!) {
        unlikePost(id: $unlikePostId) {
          id
          likes
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'unlikePostId': id},
    );

    if (result.hasException) {
      throw Exception('Failed to unlike post: ${result.exception}');
    }

    final data = result.data?['unlikePost'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Unlike post failed');
    return (data['likesCount'] ?? data['likes_count'] ?? data['likes'])
            as int? ??
        0;
  }

  @override
  Future<Map<String, dynamic>> likeComment({required int commentId}) async {
    const String mutation = r'''
      mutation LikeComment($commentId: Int!) {
        likeComment(commentId: $commentId) {
          id
          likesCount
          isLiked
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'commentId': commentId},
    );

    if (result.hasException) {
      throw Exception('Failed to like comment: ${result.exception}');
    }

    final data = result.data?['likeComment'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Like comment failed');
    return {
      'likesCount': data['likesCount'] as int? ?? 0,
      'isLiked': data['isLiked'] as bool? ?? false,
    };
  }

  @override
  Future<CommentModel> addComment({
    required int postId,
    required String content,
    required String authorName,
    required String authorRole,
    int? parentId,
  }) async {
    const String mutation = r'''
      mutation AddComment($postId: Int!, $content: String!, $authorName: String!, $authorRole: String!, $parentId: Int) {
        addComment(postId: $postId, content: $content, authorName: $authorName, authorRole: $authorRole, parentId: $parentId) {
          id
          content
          authorName
          authorRole
          createdAt
          parentId
          likesCount
          isLiked
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
        'parentId': parentId,
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
  Future<PostModel> createFeedPost({
    required String title,
    required String content,
    required String category,
    required String authorName,
    required String authorRole,
    required int locationId,
    List<String>? images,
  }) async {
    const String mutation = r'''
      mutation CreatePost(
        $title: String!
        $content: String!
        $category: String
        $images: [String!]
        $authorName: String!
        $authorRole: String!
        $locationId: Int!
      ) {
        createPost(
          title: $title
          content: $content
          category: $category
          images: $images
          authorName: $authorName
          authorRole: $authorRole
          locationId: $locationId
        ) {
          id
          content
          category
          image
          images
          likes
          authorName
          createdById
          isLiked
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'title': title,
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
      throw Exception('Failed to create feed post: ${result.exception}');
    }

    final data = result.data?['createPost'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Create feed post failed');
    return PostModel.fromJson(data);
  }

  @override
  Future<PostModel> createCommunityPost({
    required int communityId,
    required String title,
    required String content,
    String? category,
    List<String>? images,
    List<String>? documents,
  }) async {
    const String mutation = r'''
      mutation CreateCommunityPost(
        $communityId: Int!
        $title: String!
        $content: String!
        $category: String
        $images: [String!]
        $documents: [String!]
      ) {
        createCommunityPost(
          communityId: $communityId
          title: $title
          content: $content
          category: $category
          images: $images
          documents: $documents
        ) {
          id
          content
          category
          images
          documents
          authorName
          authorRole
          createdAt
          isLiked
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'communityId': communityId,
        'title': title,
        'content': content,
        'category': category,
        'images': images,
        'documents': documents,
      },
    );

    if (result.hasException) {
      final errors = result.exception?.graphqlErrors;
      if (errors != null && errors.isNotEmpty) {
        throw Exception(errors.first.message);
      }
      throw Exception('Failed to create post: ${result.exception}');
    }

    final data = result.data?['createCommunityPost'] as Map<String, dynamic>?;
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
          isLiked
          location {
            name
          }
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
  Future<void> reportPost({required int postId, required String reason}) async {
    const String mutation = r'''
      mutation ReportPost($postId: Int!, $reason: String!) {
        reportPost(postId: $postId, reason: $reason) {
          id
          postId
          reason
          status
          createdAt
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'postId': postId, 'reason': reason},
    );

    if (result.hasException) {
      final errors = result.exception?.graphqlErrors;
      if (errors != null && errors.isNotEmpty) {
        throw Exception(errors.first.message);
      }
      throw Exception('Failed to report post: ${result.exception}');
    }
  }

  @override
  Future<List<PostModel>> getReportedPostsList({
    int? locationId,
    String? status,
  }) async {
    const String query = r'''
      query GetReportedPostsList($locationId: Int, $status: String) {
        getReportedPostsList(locationId: $locationId, status: $status) {
          id
          content
          images
          authorName
          authorRole
          createdAt
          location {
            id
            name
            type
          }
          status
          reportCount
          reportReasons
          reportedUsersCount
          isHighPriority
          isUnderReview
          hasWarning
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {
        if (locationId != null) 'locationId': locationId,
        if (status != null) 'status': status,
      },
    );

    if (result.hasException) {
      throw Exception('Failed to fetch reported posts: ${result.exception}');
    }

    final List data = result.data?['getReportedPostsList'] as List? ?? [];
    return data
        .map<PostModel>(
          (json) => PostModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<PostModel> moderatePost({
    required int postId,
    required String action,
    String? warningMessage,
  }) async {
    const String mutation = r'''
      mutation ModeratePost($postId: Int!, $action: String!, $warningMessage: String) {
        moderatePost(postId: $postId, action: $action, warningMessage: $warningMessage) {
          id
          content
          category
          image
          images
          likes
          commentCount
          createdAt
          authorName
          status
          reportCount
          reportReasons
          reportedUsersCount
          isHighPriority
          isUnderReview
          hasWarning
          isLiked
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'postId': postId,
        'action': action,
        'warningMessage': warningMessage,
      },
    );

    if (result.hasException) {
      final errors = result.exception?.graphqlErrors;
      if (errors != null && errors.isNotEmpty) {
        throw Exception(errors.first.message);
      }
      throw Exception('Failed to moderate post: ${result.exception}');
    }

    final data = result.data?['moderatePost'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Moderate post failed');
    return PostModel.fromJson(data);
  }

  @override
  Future<int> likeCommunityPost({required int postId}) async {
    const String mutation = r'''
      mutation LikeCommunityPost($postId: Int!) {
        likeCommunityPost(postId: $postId) {
          id
          likes
          isLiked
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'postId': postId},
    );

    if (result.hasException) {
      throw Exception('Failed to like community post: ${result.exception}');
    }

    final data = result.data?['likeCommunityPost'] as Map<String, dynamic>?;
    return (data?['likesCount'] ?? data?['likes_count'] ?? data?['likes'])
            as int? ??
        0;
  }

  @override
  Future<CommentModel> addCommunityComment({
    required int postId,
    required String content,
  }) async {
    const String mutation = r'''
      mutation AddCommunityComment($postId: Int!, $content: String!) {
        addCommunityComment(postId: $postId, content: $content) {
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
      variables: {'postId': postId, 'content': content},
    );

    if (result.hasException) {
      throw Exception('Failed to add community comment: ${result.exception}');
    }

    final data = result.data?['addCommunityComment'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Add community comment failed');
    return CommentModel.fromJson(data);
  }

  @override
  Future<void> reportCommunityPost({
    required int postId,
    required String reason,
  }) async {
    const String mutation = r'''
      mutation ReportCommunityPost($postId: Int!, $reason: String!) {
        reportCommunityPost(postId: $postId, reason: $reason) {
          id
          reason
          status
          createdAt
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'postId': postId, 'reason': reason},
    );

    if (result.hasException) {
      throw Exception('Failed to report community post: ${result.exception}');
    }
  }

  @override
  Future<void> resolveCommunityPostReport({
    required int reportId,
    required String action,
    String? warningMessage,
  }) async {
    const String mutation = r'''
      mutation ResolveCommunityPostReport(
        $reportId: Int!
        $action: String!
        $warningMessage: String
      ) {
        resolveCommunityPostReport(
          reportId: $reportId
          action: $action
          warningMessage: $warningMessage
        )
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'reportId': reportId,
        'action': action,
        'warningMessage': warningMessage,
      },
    );

    if (result.hasException) {
      throw Exception('Failed to resolve report: ${result.exception}');
    }
  }

  @override
  Future<CommunityModel> createCommunity({
    required String name,
    String? description,
    String? image,
    bool allowMemberMessages = true,
    int? locationId,
    String? privacyType,
  }) async {
    const String mutation = r'''
      mutation CreateCommunity(
        $name: String!
        $description: String
        $image: String
        $allowMemberMessages: Boolean
        $locationId: Int
        $privacyType: String
      ) {
        createCommunity(
          name: $name
          description: $description
          image: $image
          allowMemberMessages: $allowMemberMessages
          locationId: $locationId
          privacyType: $privacyType
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
        'locationId': locationId,
        'privacyType': privacyType,
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
    String? role,
    String? search,
  }) async {
    const String query = r'''
      query GetCommunityMembers($communityId: Int!, $role: String, $search: String) {
        getCommunityMembers(communityId: $communityId, role: $role, search: $search) {
          id
          userId
          role
          joinedAt
          user {
            id
            name
            phone
            image
          }
        }
      }
    ''';

    final result = await _graphQLService.performQuery(
      query,
      variables: {
        'communityId': communityId,
        if (role != null) 'role': role,
        if (search != null) 'search': search,
      },
    );

    if (result.hasException) {
      throw Exception('Failed to fetch community members: ${result.exception}');
    }

    final List data = result.data?['getCommunityMembers'] as List? ?? [];
    return data
        .map<CommunityMemberModel>(
          (json) => CommunityMemberModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
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
          createdAt
          expiresAt
          userVoteOptionId
          isLiked
          commentsCount
          options {
            id
            text
            votesCount
          }
          createdBy {
            name
            image
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
    if (result.hasException) {
      throw Exception('Failed to get polls: ${result.exception}');
    }
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
          createdBy {
            name
          }
          location {
            name
          }
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
          comments {
            id
            content
            authorName
            authorRole
            createdAt
            parentId
            likesCount
            isLiked
            replies {
              id
              content
              authorName
              authorRole
              createdAt
              parentId
              likesCount
              isLiked
            }
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

  @override
  Future<Map<String, dynamic>> likePoll({required int pollId}) async {
    const String mutation = r'''
      mutation LikePoll($pollId: Int) {
        likePoll(pollId: $pollId) {
          id
          likesCount
          isLiked
        }
      }
    ''';
    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'pollId': pollId},
    );
    if (result.hasException) {
      throw Exception('Failed to like poll: ${result.exception}');
    }
    final data = result.data?['likePoll'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Like poll failed');
    return {
      'likesCount': data['likesCount'] as int? ?? 0,
      'isLiked': data['isLiked'] as bool? ?? false,
    };
  }

  @override
  Future<Map<String, dynamic>> likePollComment({
    required int pollCommentId,
  }) async {
    const String mutation = r'''
      mutation LikePollComment($pollCommentId: Int!) {
        likePollComment(pollCommentId: $pollCommentId) {
          id
          likesCount
          isLiked
        }
      }
    ''';
    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'pollCommentId': pollCommentId},
    );
    if (result.hasException) {
      throw Exception('Failed to like poll comment: ${result.exception}');
    }
    final data = result.data?['likePollComment'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Like poll comment failed');
    return {
      'likesCount': data['likesCount'] as int? ?? 0,
      'isLiked': data['isLiked'] as bool? ?? false,
    };
  }

  @override
  Future<CommentModel> addPollComment({
    required int pollId,
    required String content,
    required String authorName,
    required String authorRole,
    int? parentId,
  }) async {
    const String mutation = r'''
      mutation AddPollComment(
        $pollId: Int!
        $content: String!
        $authorName: String!
        $authorRole: String!
        $parentId: Int
      ) {
        addPollComment(
          pollId: $pollId
          content: $content
          authorName: $authorName
          authorRole: $authorRole
          parentId: $parentId
        ) {
          id
          content
          authorName
          authorRole
          createdAt
          parentId
          likesCount
          isLiked
        }
      }
    ''';
    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'pollId': pollId,
        'content': content,
        'authorName': authorName,
        'authorRole': authorRole,
        'parentId': parentId,
      },
    );
    if (result.hasException) {
      throw Exception('Failed to add poll comment: ${result.exception}');
    }
    final data = result.data?['addPollComment'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to add poll comment: No data returned');
    }
    return CommentModel.fromJson(data);
  }

  // --- Admin Methods ---

  @override
  Future<List<PendingJoinRequestModel>> getPendingCommunityJoinRequests({required int communityId, String? status}) async {
    const String query = r'''
      query GetPendingCommunityJoinRequests($communityId: Int!, $status: String) {
        getPendingCommunityJoinRequests(communityId: $communityId, status: $status) {
          id
          reason
          createdAt
          user {
            id
            name
            phone
            location {
              name
              type
            }
          }
        }
      }
    ''';
    final result = await _graphQLService.performQuery(
      query,
      variables: {'communityId': communityId, 'status': status},
    );
    if (result.hasException)
      throw Exception('Failed to fetch pending requests: ${result.exception}');
    final List data =
        result.data?['getPendingCommunityJoinRequests'] as List? ?? [];
    return data
        .map(
          (json) =>
              PendingJoinRequestModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<bool> reviewCommunityJoinRequest({
    required int requestId,
    required String action,
    String? rejectionReason,
  }) async {
    const String mutation = r'''
      mutation ReviewCommunityJoinRequest($requestId: Int!, $action: JoinRequestAction!, $rejectionReason: String) {
        reviewCommunityJoinRequest(requestId: $requestId, action: $action, rejectionReason: $rejectionReason)
      }
    ''';
    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'requestId': requestId,
        'action': action,
        'rejectionReason': rejectionReason,
      },
    );
    if (result.hasException)
      throw Exception('Failed to review request: ${result.exception}');
    return result.data?['reviewCommunityJoinRequest'] as bool? ?? false;
  }

  @override
  Future<bool> updateCommunityMemberRole({
    required int communityId,
    required int targetUserId,
    required String newRole,
  }) async {
    const String mutation = r'''
      mutation UpdateCommunityMemberRole($communityId: Int!, $targetUserId: Int!, $newRole: CommunityGroupRole!) {
        updateCommunityMemberRole(communityId: $communityId, targetUserId: $targetUserId, newRole: $newRole)
      }
    ''';
    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'communityId': communityId,
        'targetUserId': targetUserId,
        'newRole': newRole,
      },
    );
    if (result.hasException)
      throw Exception('Failed to update role: ${result.exception}');
    return result.data?['updateCommunityMemberRole'] as bool? ?? false;
  }

  @override
  Future<ComplaintModel> createCommunityComplaint({
    required int communityId,
    required String title,
    required String description,
  }) async {
    const String mutation = r'''
      mutation CreateCommunityComplaint($communityId: Int!, $title: String!, $description: String!) {
        createCommunityComplaint(communityId: $communityId, title: $title, description: $description) {
          id
          title
          status
        }
      }
    ''';
    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'communityId': communityId,
        'title': title,
        'description': description,
      },
    );
    if (result.hasException)
      throw Exception('Failed to create complaint: ${result.exception}');
    return ComplaintModel.fromJson(
      result.data?['createCommunityComplaint'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<ComplaintModel>> getCommunityComplaints({
    required int communityId,
    String? status,
  }) async {
    const String query = r'''
      query GetCommunityComplaints($communityId: Int!, $status: ComplaintStatus) {
        getCommunityComplaints(communityId: $communityId, status: $status) {
          id
          title
          description
          status
          createdAt
          reporter {
            name
          }
        }
      }
    ''';
    final result = await _graphQLService.performQuery(
      query,
      variables: {'communityId': communityId, 'status': status},
    );
    if (result.hasException)
      throw Exception('Failed to get complaints: ${result.exception}');
    final List data = result.data?['getCommunityComplaints'] as List? ?? [];
    return data
        .map((json) => ComplaintModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<bool> banCommunityUser({
    required int communityId,
    required int userId,
    String? reason,
    int? durationDays,
  }) async {
    const String mutation = r'''
      mutation BanCommunityUser($communityId: Int!, $userId: Int!, $reason: String, $durationDays: Int) {
        banCommunityUser(communityId: $communityId, userId: $userId, reason: $reason, durationDays: $durationDays)
      }
    ''';
    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'communityId': communityId,
        'userId': userId,
        'reason': reason,
        'durationDays': durationDays,
      },
    );
    if (result.hasException)
      throw Exception('Failed to ban user: ${result.exception}');
    return result.data?['banCommunityUser'] as bool? ?? false;
  }

  @override
  Future<bool> unbanCommunityUser({
    required int communityId,
    required int userId,
  }) async {
    const String mutation = r'''
      mutation UnbanCommunityUser($communityId: Int!, $userId: Int!) {
        unbanCommunityUser(communityId: $communityId, userId: $userId)
      }
    ''';
    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'communityId': communityId, 'userId': userId},
    );
    if (result.hasException)
      throw Exception('Failed to unban user: ${result.exception}');
    return result.data?['unbanCommunityUser'] as bool? ?? false;
  }

  @override
  Future<AnnouncementModel> createCommunityAnnouncement({
    required int communityId,
    required String title,
    required String message,
    bool? isPinned,
    String? scheduledFor,
  }) async {
    const String mutation = r'''
      mutation CreateCommunityAnnouncement($communityId: Int!, $title: String!, $message: String!, $isPinned: Boolean, $scheduledFor: String) {
        createCommunityAnnouncement(communityId: $communityId, title: $title, message: $message, isPinned: $isPinned, scheduledFor: $scheduledFor) {
          id
          title
          message
          isPinned
          scheduledFor
        }
      }
    ''';
    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'communityId': communityId,
        'title': title,
        'message': message,
        'isPinned': isPinned,
        'scheduledFor': scheduledFor,
      },
    );
    if (result.hasException)
      throw Exception('Failed to create announcement: ${result.exception}');
    return AnnouncementModel.fromJson(
      result.data?['createCommunityAnnouncement'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<AnnouncementModel>> getCommunityAnnouncements({
    required int communityId,
  }) async {
    const String query = r'''
      query GetCommunityAnnouncements($communityId: Int!) {
        getCommunityAnnouncements(communityId: $communityId) {
          id
          title
          message
          isPinned
          createdAt
        }
      }
    ''';
    final result = await _graphQLService.performQuery(
      query,
      variables: {'communityId': communityId},
    );
    if (result.hasException)
      throw Exception('Failed to get announcements: ${result.exception}');
    final List data = result.data?['getCommunityAnnouncements'] as List? ?? [];
    return data
        .map((json) => AnnouncementModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  @override
  Future<List<CommunityModel>> getFeaturedCommunities() async {
    const String query = r'''
      query GetFeaturedCommunities {
        getFeaturedCommunities {
          id
          name
          description
          image
          memberCount
          isJoined
        }
      }
    ''';
    final result = await _graphQLService.performQuery(query);
    if (result.hasException) throw Exception('Failed to fetch featured communities');
    final List data = result.data?['getFeaturedCommunities'] as List? ?? [];
    return data.map((json) => CommunityModel.fromJson(json)).toList();
  }

  @override
  Future<List<CommunityModel>> getNearbyCommunities({int? locationId, int? radiusKm}) async {
    const String query = r'''
      query GetNearbyCommunities($locationId: Int, $radiusKm: Int) {
        getNearbyCommunities(locationId: $locationId, radiusKm: $radiusKm) {
          id
          name
          description
          image
          memberCount
          locationId
        }
      }
    ''';
    final result = await _graphQLService.performQuery(query, variables: {
      'locationId': locationId,
      'radiusKm': radiusKm,
    });
    if (result.hasException) throw Exception('Failed to fetch nearby communities');
    final List data = result.data?['getNearbyCommunities'] as List? ?? [];
    return data.map((json) => CommunityModel.fromJson(json)).toList();
  }

  @override
  Future<List<CommunityModel>> searchCommunities({String? query, int? locationId}) async {
    const String gqlQuery = r'''
      query SearchCommunities($query: String, $locationId: Int) {
        searchCommunities(query: $query, locationId: $locationId) {
          id
          name
          description
          image
          memberCount
        }
      }
    ''';
    final result = await _graphQLService.performQuery(gqlQuery, variables: {
      'query': query,
      'locationId': locationId,
    });
    if (result.hasException) throw Exception('Failed to search communities');
    final List data = result.data?['searchCommunities'] as List? ?? [];
    return data.map((json) => CommunityModel.fromJson(json)).toList();
  }

  @override
  Future<CommunityModel> getCommunityDetails({required int communityId}) async {
    const String query = r'''
      query GetCommunityDetails($communityId: Int!) {
        getCommunityDetails(communityId: $communityId) {
          id
          name
          description
          image
          privacyType
          memberCount
          isJoined
          rules
        }
      }
    ''';
    final result = await _graphQLService.performQuery(query, variables: {'communityId': communityId});
    if (result.hasException) throw Exception('Failed to fetch community details');
    return CommunityModel.fromJson(result.data?['getCommunityDetails']);
  }

  @override
  Future<String> getCommunityRules({required int communityId}) async {
    const String query = r'''
      query GetCommunityRules($communityId: Int!) {
        getCommunityRules(communityId: $communityId)
      }
    ''';
    final result = await _graphQLService.performQuery(query, variables: {'communityId': communityId});
    if (result.hasException) throw Exception('Failed to fetch community rules');
    return result.data?['getCommunityRules'] as String? ?? '';
  }

  @override
  Future<CommunitySettingsModel> getCommunitySettings({required int communityId}) async {
    const String query = r'''
      query GetCommunitySettings($communityId: Int!) {
        getCommunitySettings(communityId: $communityId) {
          communityId
          notificationsEnabled
          mediaAutoDownload
          linksAndDocsEnabled
          muted
          starredMessagesEnabled
          about
          location
        }
      }
    ''';
    final result = await _graphQLService.performQuery(query, variables: {'communityId': communityId});
    if (result.hasException) throw Exception('Failed to fetch community settings');
    return CommunitySettingsModel.fromJson(result.data?['getCommunitySettings']);
  }

  @override
  Future<List<Map<String, dynamic>>> getCommunityRolesAndPermissions({required int communityId}) async {
    const String query = r'''
      query GetCommunityRolesAndPermissions($communityId: Int!) {
        getCommunityRolesAndPermissions(communityId: $communityId) {
          roleName
          permissions
          description
        }
      }
    ''';
    final result = await _graphQLService.performQuery(query, variables: {'communityId': communityId});
    if (result.hasException) throw Exception('Failed to fetch roles');
    return List<Map<String, dynamic>>.from(result.data?['getCommunityRolesAndPermissions'] ?? []);
  }

  @override
  Future<CommunityMemberModel> getMemberDetails({required int id, int? communityId}) async {
    const String query = r'''
      query GetMemberDetails($id: Int!, $communityId: Int) {
        getMemberDetails(id: $id, communityId: $communityId) {
          id
          userId
          role
          joinedAt
          user {
            id
            name
            phone
            image
          }
        }
      }
    ''';
    final result = await _graphQLService.performQuery(query, variables: {'id': id, 'communityId': communityId});
    if (result.hasException) throw Exception('Failed to fetch member details');
    return CommunityMemberModel.fromJson(result.data?['getMemberDetails']);
  }

  @override
  Future<List<CommunityMemberModel>> getOnlineMembers({required int communityId}) async {
    const String query = r'''
      query GetOnlineMembers($communityId: Int!) {
        getCommunityOnlineMembers(communityId: $communityId) {
          id
          userId
          role
          user {
            id
            name
            image
          }
        }
      }
    ''';
    final result = await _graphQLService.performQuery(query, variables: {'communityId': communityId});
    if (result.hasException) throw Exception('Failed to fetch online members');
    final List data = result.data?['getCommunityOnlineMembers'] as List? ?? [];
    return data.map((json) => CommunityMemberModel.fromJson(json)).toList();
  }

  @override
  Future<bool> bulkApproveJoinRequests({required int communityId, required List<int> requestIds}) async {
    const String mutation = r'''
      mutation BulkApprove($communityId: Int!, $requestIds: [Int!]!) {
        bulkApproveJoinRequests(communityId: $communityId, requestIds: $requestIds)
      }
    ''';
    final result = await _graphQLService.performMutation(mutation, variables: {
      'communityId': communityId,
      'requestIds': requestIds,
    });
    if (result.hasException) throw Exception('Failed to bulk approve requests');
    return result.data?['bulkApproveJoinRequests'] as bool? ?? false;
  }

  @override
  Future<CommunityMessageModel> starCommunityMessage({required int messageId}) async {
    const String mutation = r'''
      mutation StarMessage($messageId: Int!) {
        starCommunityMessage(messageId: $messageId) {
          id
          message
          messageType
          mediaUrl
          senderId
          senderType
          createdAt
        }
      }
    ''';
    final result = await _graphQLService.performMutation(mutation, variables: {'messageId': messageId});
    if (result.hasException) throw Exception('Failed to star message');
    return CommunityMessageModel.fromJson(result.data?['starCommunityMessage']);
  }

  @override
  Future<CommunityMessageModel> unstarCommunityMessage({required int messageId}) async {
    const String mutation = r'''
      mutation UnstarMessage($messageId: Int!) {
        unstarCommunityMessage(messageId: $messageId) {
          id
          message
        }
      }
    ''';
    final result = await _graphQLService.performMutation(mutation, variables: {'messageId': messageId});
    if (result.hasException) throw Exception('Failed to unstar message');
    return CommunityMessageModel.fromJson(result.data?['unstarCommunityMessage']);
  }

  @override
  Future<List<CommunityMessageModel>> getCommunityStarredMessages({required int communityId}) async {
    const String query = r'''
      query GetStarredMessages($communityId: Int!) {
        getCommunityStarredMessages(communityId: $communityId) {
          id
          message
          messageType
          mediaUrl
          createdAt
        }
      }
    ''';
    final result = await _graphQLService.performQuery(query, variables: {'communityId': communityId});
    if (result.hasException) throw Exception('Failed to fetch starred messages');
    final List data = result.data?['getCommunityStarredMessages'] as List? ?? [];
    return data.map((json) => CommunityMessageModel.fromJson(json)).toList();
  }

  @override
  Future<AnnouncementModel> pinCommunityAnnouncement({required int announcementId}) async {
    const String mutation = r'''
      mutation PinAnnouncement($announcementId: Int!) {
        pinCommunityAnnouncement(announcementId: $announcementId) {
          id
          isPinned
        }
      }
    ''';
    final result = await _graphQLService.performMutation(mutation, variables: {'announcementId': announcementId});
    if (result.hasException) throw Exception('Failed to pin announcement');
    return AnnouncementModel.fromJson(result.data?['pinCommunityAnnouncement']);
  }

  @override
  Future<AnnouncementModel> unpinCommunityAnnouncement({required int announcementId}) async {
    const String mutation = r'''
      mutation UnpinAnnouncement($announcementId: Int!) {
        unpinCommunityAnnouncement(announcementId: $announcementId) {
          id
          isPinned
        }
      }
    ''';
    final result = await _graphQLService.performMutation(mutation, variables: {'announcementId': announcementId});
    if (result.hasException) throw Exception('Failed to unpin announcement');
    return AnnouncementModel.fromJson(result.data?['unpinCommunityAnnouncement']);
  }

  @override
  Future<AnnouncementModel> updateCommunityAnnouncement({
    required int announcementId,
    String? title,
    String? message,
    bool? isPinned,
    String? scheduledFor,
  }) async {
    const String mutation = r'''
      mutation UpdateAnnouncement($announcementId: Int!, $title: String, $message: String, $isPinned: Boolean, $scheduledFor: String) {
        updateCommunityAnnouncement(announcementId: $announcementId, title: $title, message: $message, isPinned: $isPinned, scheduledFor: $scheduledFor) {
          id
          title
          message
          isPinned
        }
      }
    ''';
    final result = await _graphQLService.performMutation(mutation, variables: {
      'announcementId': announcementId,
      'title': title,
      'message': message,
      'isPinned': isPinned,
      'scheduledFor': scheduledFor,
    });
    if (result.hasException) throw Exception('Failed to update announcement');
    return AnnouncementModel.fromJson(result.data?['updateCommunityAnnouncement']);
  }

  @override
  Future<bool> deleteCommunityAnnouncement({required int announcementId}) async {
    const String mutation = r'''
      mutation DeleteAnnouncement($announcementId: Int!) {
        deleteCommunityAnnouncement(announcementId: $announcementId)
      }
    ''';
    final result = await _graphQLService.performMutation(mutation, variables: {'announcementId': announcementId});
    if (result.hasException) throw Exception('Failed to delete announcement');
    return result.data?['deleteCommunityAnnouncement'] as bool? ?? false;
  }

  @override
  Future<List<CommunityLinkDocModel>> getCommunityLinksAndDocs({required int communityId}) async {
    const String query = r'''
      query GetLinksDocs($communityId: Int!) {
        getCommunityLinksAndDocs(communityId: $communityId) {
          id
          title
          url
          type
          uploadedAt
        }
      }
    ''';
    final result = await _graphQLService.performQuery(query, variables: {'communityId': communityId});
    if (result.hasException) throw Exception('Failed to fetch links and docs');
    final List data = result.data?['getCommunityLinksAndDocs'] as List? ?? [];
    return data.map((json) => CommunityLinkDocModel.fromJson(json)).toList();
  }

  @override
  Future<CommunityLinkDocModel> uploadCommunityLinkOrDoc({
    required int communityId,
    required String title,
    required String url,
    required String type,
  }) async {
    const String mutation = r'''
      mutation UploadLinkDoc($communityId: Int!, $title: String!, $url: String!, $type: String!) {
        uploadCommunityLinkOrDoc(communityId: $communityId, title: $title, url: $url, type: $type) {
          id
          title
          url
          type
          uploadedAt
        }
      }
    ''';
    final result = await _graphQLService.performMutation(mutation, variables: {
      'communityId': communityId,
      'title': title,
      'url': url,
      'type': type,
    });
    if (result.hasException) throw Exception('Failed to upload link/doc');
    return CommunityLinkDocModel.fromJson(result.data?['uploadCommunityLinkOrDoc']);
  }

  @override
  Future<bool> deleteCommunityLinkOrDoc({required int linkOrDocId}) async {
    const String mutation = r'''
      mutation DeleteLinkDoc($linkOrDocId: Int!) {
        deleteCommunityLinkOrDoc(linkOrDocId: $linkOrDocId)
      }
    ''';
    final result = await _graphQLService.performMutation(mutation, variables: {'linkOrDocId': linkOrDocId});
    if (result.hasException) throw Exception('Failed to delete link/doc');
    return result.data?['deleteCommunityLinkOrDoc'] as bool? ?? false;
  }

  @override
  Future<CommunitySettingsModel> updateCommunitySettings({
    required int communityId,
    required CommunitySettingsModel settings,
  }) async {
    const String mutation = r'''
      mutation UpdateSettings($communityId: Int!, $settings: CommunitySettingsInput!) {
        updateCommunitySettings(communityId: $communityId, settings: $settings) {
          communityId
          notificationsEnabled
          mediaAutoDownload
          linksAndDocsEnabled
          muted
          starredMessagesEnabled
          about
          location
        }
      }
    ''';
    final result = await _graphQLService.performMutation(mutation, variables: {
      'communityId': communityId,
      'settings': settings.toJson()..remove('communityId'),
    });
    if (result.hasException) throw Exception('Failed to update community settings');
    return CommunitySettingsModel.fromJson(result.data?['updateCommunitySettings']);
  }

  @override
  Future<String> generateCommunityInviteCode({required int communityId, int? expiryDays}) async {
    const String mutation = r'''
      mutation GenerateInviteCode($communityId: Int!, $expiryDays: Int) {
        generateCommunityInviteCode(communityId: $communityId, expiryDays: $expiryDays)
      }
    ''';
    final result = await _graphQLService.performMutation(mutation, variables: {
      'communityId': communityId,
      'expiryDays': expiryDays,
    });
    if (result.hasException) throw Exception('Failed to generate invite code');
    return result.data?['generateCommunityInviteCode'] as String? ?? '';
  }

  @override
  Future<String> getCommunityInviteCode({required int communityId}) async {
    const String query = r'''
      query GetInviteCode($communityId: Int!) {
        getCommunityInviteCode(communityId: $communityId)
      }
    ''';
    final result = await _graphQLService.performQuery(query, variables: {'communityId': communityId});
    if (result.hasException) throw Exception('Failed to fetch invite code');
    return result.data?['getCommunityInviteCode'] as String? ?? '';
  }

  @override
  Future<List<Map<String, dynamic>>> getCommunityEvents({required int communityId}) async {
    const String query = r'''
      query GetEvents($communityId: Int!) {
        getCommunityEvents(communityId: $communityId) {
          id
          title
          description
          date
          location {
            name
          }
          createdBy {
            name
          }
        }
      }
    ''';
    final result = await _graphQLService.performQuery(query, variables: {'communityId': communityId});
    if (result.hasException) throw Exception('Failed to fetch events');
    return List<Map<String, dynamic>>.from(result.data?['getCommunityEvents'] ?? []);
  }

  @override
  Future<CommunityAnalyticsModel> getCommunityAnalytics({required int communityId}) async {
    const String query = r'''
      query GetAnalytics($communityId: Int!) {
        getCommunityAnalytics(communityId: $communityId) {
          totalMembers
          activeMembersCount
          pendingJoinRequestsCount
          newMembersThisWeek
          eventsCreatedCount
          complaintResolutionRate
        }
      }
    ''';
    final result = await _graphQLService.performQuery(query, variables: {'communityId': communityId});
    if (result.hasException) throw Exception('Failed to fetch analytics');
    return CommunityAnalyticsModel.fromJson(result.data?['getCommunityAnalytics']);
  }

  @override
  Future<List<CommunityBanModel>> getCommunityBans({required int communityId}) async {
    const String query = r'''
      query GetBans($communityId: Int!) {
        getCommunityBans(communityId: $communityId) {
          id
          userId
          reason
          bannedUntil
          user {
            id
            name
            phone
          }
        }
      }
    ''';
    final result = await _graphQLService.performQuery(query, variables: {'communityId': communityId});
    if (result.hasException) throw Exception('Failed to fetch bans');
    final List data = result.data?['getCommunityBans'] as List? ?? [];
    return data.map((json) => CommunityBanModel.fromJson(json)).toList();
  }

  @override
  Future<bool> reportCommunityMember({required int communityId, required int reportedUserId, required String reason}) async {
    const String mutation = r'''
      mutation ReportMember($communityId: Int!, $reportedUserId: Int!, $reason: String!) {
        reportCommunityMember(communityId: $communityId, reportedUserId: $reportedUserId, reason: $reason)
      }
    ''';
    final result = await _graphQLService.performMutation(mutation, variables: {
      'communityId': communityId,
      'reportedUserId': reportedUserId,
      'reason': reason,
    });
    if (result.hasException) throw Exception('Failed to report member');
    return result.data?['reportCommunityMember'] as bool? ?? false;
  }
}
