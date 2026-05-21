import 'package:ntk_project/src/features/community/data/models/comment_model.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';

abstract class CommunityRepository {
  Future<List<PostModel>> getCommunityFeed({int? locationId});

  Future<int> likePost({required int id});

  Future<CommentModel> addComment({
    required int postId,
    required String content,
    required String authorName,
    String? authorRole,
  });

  Future<PostModel> createPost({
    required String content,
    String? image,
    required String authorName,
    String? authorRole,
    required int locationId,
  });
}
