import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_state.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  void _fetchFeed() {
    final locationId = context.read<AuthBloc>().state.loginData?.locationId;
    context.read<CommunityBloc>().add(FetchCommunityFeed(locationId: locationId));
  }

  String _formatTimeAgo(String? dt) {
    if (dt == null || dt.isEmpty) return '';
    try {
      DateTime date;
      final epoch = int.tryParse(dt);
      if (epoch != null) {
        date = epoch > 9999999999
            ? DateTime.fromMillisecondsSinceEpoch(epoch)
            : DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
      } else {
        date = DateTime.parse(dt);
      }
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'இப்போது';
    } catch (_) {
      return dt;
    }
  }

  void _showCreatePostSheet() {
    final theme = Theme.of(context);
    final auth = context.read<AuthBloc>().state.loginData;
    final locationId = auth?.locationId;
    if (locationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location கிடைக்கவில்லை')),
      );
      return;
    }

    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('புதிய போஸ்ட்', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'உங்கள் எண்ணத்தை பகிருங்கள்...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    context.read<CommunityBloc>().add(
                      CreatePost(
                        content: text,
                        authorName: auth?.name ?? 'User',
                        authorRole: auth?.role,
                        locationId: locationId,
                      ),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('போஸ்ட் செய்'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showCommentsSheet(PostModel post) {
    final auth = context.read<AuthBloc>().state.loginData;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return BlocBuilder<CommunityBloc, CommunityState>(
          builder: (_, state) {
            final current = state.posts.firstWhere(
              (p) => p.id == post.id,
              orElse: () => post,
            );

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'கமெண்ட்கள்',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (current.comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'இன்னும் கமெண்ட் இல்லை. முதல் கமெண்ட் சேர்க்கவும்!',
                        style: TextStyle(color: NTKColors.textTertiary),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: current.comments.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final c = current.comments[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              c.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (c.authorRole != null)
                                  Text(
                                    c.authorRole!.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: NTKColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                Text(c.content),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: const InputDecoration(
                            hintText: 'கமெண்ட் எழுதுங்கள்...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.paperplane_fill,
                          color: NTKColors.primary,
                        ),
                        onPressed: () {
                          final text = commentController.text.trim();
                          if (text.isEmpty) return;
                          context.read<CommunityBloc>().add(
                            AddComment(
                              postId: post.id,
                              content: text,
                              authorName: auth?.name ?? 'User',
                              authorRole: auth?.role,
                            ),
                          );
                          commentController.clear();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: NTKColors.background,
      appBar: NTKAppBar(
        title: 'Community',
        subtitle:
            context.read<AuthBloc>().state.loginData?.locationName ??
            'Tamil Nadu',
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(CupertinoIcons.bell, color: Colors.white),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<CommunityBloc, CommunityState>(
        listener: (context, state) {
          if (state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async => _fetchFeed(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildPostInput(theme),
                const SizedBox(height: 24),
                Text(
                  'RECENT UPDATES',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: NTKColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 16),
                if (state.isLoading && state.posts.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state.posts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            CupertinoIcons.chat_bubble_2,
                            size: 48,
                            color: theme.dividerColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'இன்னும் போஸ்ட் இல்லை',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...state.posts.map((post) => _buildPostCard(context, post)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostSheet,
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(CupertinoIcons.pencil, color: Colors.white),
      ),
    );
  }

  Widget _buildPostInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NTKColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: NTKColors.slate900.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: NTKColors.emerald50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: NTKColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _showCreatePostSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: NTKColors.slate100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'What\'s on your mind?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: NTKColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, PostModel post) {
    final theme = Theme.of(context);
    final role = (post.authorRole ?? 'MEMBER').toUpperCase();
    final time = _formatTimeAgo(post.createdAt);
    final hasImage = post.image != null && post.image!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: NTKColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: NTKColors.slate900.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: NTKColors.emerald50,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  post.authorName.isNotEmpty ? post.authorName[0] : '?',
                  style: const TextStyle(
                    color: NTKColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    post.authorName,
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (role.contains('CHIEF') || role.contains('ADMIN'))
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.verified, color: Colors.blue, size: 14),
                  ),
              ],
            ),
            subtitle: Row(
              children: [
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: NTKColors.primary,
                  ),
                ),
                if (time.isNotEmpty) ...[
                  Text(' • ', style: TextStyle(color: NTKColors.textTertiary)),
                  Text(
                    time,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(CupertinoIcons.ellipsis, size: 18),
              onPressed: () {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              post.content,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Image.network(
                post.image!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: NTKColors.slate100,
                  child: const Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: NTKColors.slate200,
                  ),
                ),
              ),
            )
          else if (post.image != null)
            Container(
              height: 200,
              width: double.infinity,
              color: NTKColors.slate100,
              child: const Icon(
                Icons.image_outlined,
                size: 48,
                color: NTKColors.slate200,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _buildPostAction(
                  context,
                  Icons.favorite_border,
                  post.likes.toString(),
                  onTap: () =>
                      context.read<CommunityBloc>().add(LikePost(post.id)),
                ),
                _buildPostAction(
                  context,
                  Icons.chat_bubble_outline,
                  post.commentCount.toString(),
                  onTap: () => _showCommentsSheet(post),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    CupertinoIcons.share,
                    size: 20,
                    color: NTKColors.textSecondary,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostAction(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: NTKColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: NTKColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
