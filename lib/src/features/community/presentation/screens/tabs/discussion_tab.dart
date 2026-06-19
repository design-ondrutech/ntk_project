import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/animated_like_button.dart';
import 'package:ntk_project/src/features/community/data/models/community_model.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_posts_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_posts_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_posts_state.dart';
import 'package:ntk_project/src/features/community/presentation/screens/create_community_post_screen.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_post_details_screen.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';

class DiscussionTab extends StatefulWidget {
  final CommunityModel community;

  const DiscussionTab({Key? key, required this.community}) : super(key: key);

  @override
  State<DiscussionTab> createState() => _DiscussionTabState();
}

class _DiscussionTabState extends State<DiscussionTab> {
  @override
  void initState() {
    super.initState();
    context.read<CommunityPostsBloc>().add(FetchCommunityPostsList(widget.community.id));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<CommunityPostsBloc>().add(FetchCommunityPostsList(widget.community.id));
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildCreatePostContainer(context),
          ),
          BlocBuilder<CommunityPostsBloc, CommunityPostsState>(
            builder: (context, state) {
              if (state.isLoading && state.posts.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state.error != null && state.posts.isEmpty) {
                return SliverFillRemaining(
                  child: Center(child: Text(state.error!)),
                );
              }
              if (state.posts.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text("No posts yet. Start the discussion!")),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = state.posts[index];
                    return _PostCard(
                      post: post,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommunityPostDetailsScreen(post: post),
                          ),
                        );
                      },
                    );
                  },
                  childCount: state.posts.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCreatePostContainer(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF7E8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_rounded, color: Color(0xFF0A3D28), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateCommunityPostScreen(communityId: widget.community.id),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8F7),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: const Color(0xFFE7ECE9)),
                    ),
                    child: const Text(
                      "What do you need help with?",
                      style: TextStyle(color: Color(0xFF667085), fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE7ECE9)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateCommunityPostScreen(communityId: widget.community.id),
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF0F8A4B)),
                icon: const Icon(Icons.image_outlined, size: 20),
                label: const Text('Image', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              Container(width: 1, height: 24, color: const Color(0xFFE7ECE9)),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateCommunityPostScreen(communityId: widget.community.id),
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF0F8A4B)),
                icon: const Icon(Icons.attach_file_rounded, size: 20),
                label: const Text('Document', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final dynamic post;
  final VoidCallback onTap;

  const _PostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8F7),
                      borderRadius: BorderRadius.circular(12),
                      image: post.createdBy?['image'] != null
                          ? DecorationImage(
                              image: NetworkImage(post.createdBy!['image']),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: post.createdBy?['image'] == null
                        ? const Icon(Icons.person_rounded, color: Color(0xFF667085), size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF111827),
                          ),
                        ),
                        if (post.authorRole != null)
                          Text(
                            post.authorRole!,
                            style: const TextStyle(color: Color(0xFF0F8A4B), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    post.createdAt != null
                        ? DateHelper.formatDateTime(post.createdAt!)
                        : '',
                    style: const TextStyle(color: Color(0xFF667085), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (post.title.isNotEmpty) ...[
                Text(
                  post.title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.5),
              ),
              if (post.images.isNotEmpty) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post.images.first,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE7ECE9)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedLikeButton(
                    postId: post.id,
                    initialLikes: post.likes,
                    initialIsLiked: post.isLiked,
                    onLike: () {
                      context.read<CommunityPostsBloc>().add(LikeCommunityPostEvent(post.id));
                    },
                  ),
                  TextButton.icon(
                    onPressed: onTap,
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF667085)),
                    icon: const Icon(Icons.mode_comment_outlined, size: 20),
                    label: Text('${post.commentCount}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.share_outlined, color: Color(0xFF667085), size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
