import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/features/community/data/models/comment_model.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final GraphQLService _graphQLService;

  CommunityRepositoryImpl(this._graphQLService);

  @override
  Future<List<PostModel>> getCommunityFeed({int? locationId}) async {
    const String query = r'''
      query CommunityFeed($locationId: Int) {
        communityFeed(locationId: $locationId) {
          id
          content
          image
          authorName
          authorRole
          likes
          commentCount
          createdAt
          comments {
            id
            content
            authorName
            authorRole
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
        .map<PostModel>((json) => PostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> likePost({required int id}) async {
    const String mutation = r'''
      mutation LikePost($id: Int!) {
        likePost(id: $id) {
          id
          likes
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {'id': id},
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
    String? authorRole,
  }) async {
    const String mutation = r'''
      mutation AddComment(
        $postId: Int!
        $content: String!
        $authorName: String!
        $authorRole: String
      ) {
        addComment(
          postId: $postId
          content: $content
          authorName: $authorName
          authorRole: $authorRole
        ) {
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
      throw Exception('Failed to add comment: ${result.exception}');
    }

    final data = result.data?['addComment'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Add comment failed');
    return CommentModel.fromJson(data);
  }

  @override
  Future<PostModel> createPost({
    required String content,
    String? image,
    required String authorName,
    String? authorRole,
    required int locationId,
  }) async {
    const String mutation = r'''
      mutation CreatePost(
        $content: String!
        $image: String
        $authorName: String!
        $authorRole: String
        $locationId: Int!
      ) {
        createPost(
          content: $content
          image: $image
          authorName: $authorName
          authorRole: $authorRole
          locationId: $locationId
        ) {
          id
          content
          image
          authorName
          authorRole
          likes
          commentCount
          createdAt
        }
      }
    ''';

    final result = await _graphQLService.performMutation(
      mutation,
      variables: {
        'content': content,
        'image': image,
        'authorName': authorName,
        'authorRole': authorRole,
        'locationId': locationId,
      },
    );

    if (result.hasException) {
      throw Exception('Failed to create post: ${result.exception}');
    }

    final data = result.data?['createPost'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Create post failed');
    return PostModel.fromJson(data);
  }
}
