import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/animated_like_button.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_posts_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_posts_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_posts_state.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';

class CommunityPostDetailsScreen extends StatefulWidget {
  final PostModel post;

  const CommunityPostDetailsScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<CommunityPostDetailsScreen> createState() => _CommunityPostDetailsScreenState();
}

class _CommunityPostDetailsScreenState extends State<CommunityPostDetailsScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _sendComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = context.read<AuthBloc>().state.loginData;
    if (user == null) return;

    if (widget.post.community != null) {
      context.read<CommunityPostsBloc>().add(
        AddCommunityCommentEvent(
          widget.post.id,
          text,
        ),
      );
    } else {
      context.read<CommunityPostsBloc>().add(
        AddCommentEvent(
          widget.post.id,
          text,
          user.name,
          user.role ?? 'MEMBER',
        ),
      );
    }

    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF005C3B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<CommunityPostsBloc, CommunityPostsState>(
        builder: (context, state) {
          // Find the latest version of the post in state if it was updated (e.g. liked or commented)
          final post = state.posts.firstWhere((p) => p.id == widget.post.id, orElse: () => widget.post);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Post Details
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: post.createdBy?['image'] != null
                                      ? NetworkImage(post.createdBy!['image'])
                                      : null,
                                  backgroundColor: Colors.grey[300],
                                  child: post.createdBy?['image'] == null
                                      ? const Icon(Icons.person, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      if (post.authorRole != null)
                                        Text(post.authorRole!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text(
                                  post.createdAt != null ? DateHelper.formatDateTime(post.createdAt!) : '',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (post.title.isNotEmpty) ...[
                              Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 8),
                            ],
                            Text(post.content, style: const TextStyle(fontSize: 16, height: 1.5)),
                            
                            // Images Attachment
                            if (post.images.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 200,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: post.images.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(post.images[index], fit: BoxFit.cover, width: 250),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],

                            // Documents Attachment
                            if (post.documents.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text('Attached Documents:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ...post.documents.map((docUrl) => ListTile(
                                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                title: const Text('Document attached'),
                                subtitle: const Text('Tap to view'),
                                tileColor: Colors.grey[100],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                onTap: () {
                                  // Add URL Launcher logic
                                },
                              )),
                            ],

                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            Row(
                              children: [
                                AnimatedLikeButton(
                                  postId: post.id,
                                  initialLikes: post.likes,
                                  initialIsLiked: post.isLiked,
                                  onLike: () {
                                    if (post.community != null) {
                                      context.read<CommunityPostsBloc>().add(LikeCommunityPostEvent(post.id));
                                    } else {
                                      context.read<CommunityPostsBloc>().add(LikePostEvent(post.id));
                                    }
                                  },
                                ),
                                const SizedBox(width: 16),
                                TextButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                                  label: Text('${post.commentCount}', style: const TextStyle(color: Colors.grey)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(height: 8, color: Colors.grey[200]),

                      // Comments List
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      if (post.comments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No comments yet. Be the first!', style: TextStyle(color: Colors.grey)),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: post.comments.length,
                          itemBuilder: (context, index) {
                            final comment = post.comments[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: comment.createdBy?['image'] != null
                                        ? NetworkImage(comment.createdBy!['image'])
                                        : null,
                                    backgroundColor: Colors.grey[300],
                                    child: comment.createdBy?['image'] == null
                                        ? const Icon(Icons.person, size: 20, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                comment.authorName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              Text(
                                                comment.createdAt != null ? DateHelper.formatDateTime(comment.createdAt!) : '',
                                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(comment.content, style: const TextStyle(fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 80), // Space for bottom input
                    ],
                  ),
                ),
              ),

              // Comment Input Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment... (use @ to mention)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            isDense: true,
                          ),
                          // Optional: Implement onChanged to trigger autocomplete overlay for @mentions
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: const Color(0xFF005C3B),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: _sendComment,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
