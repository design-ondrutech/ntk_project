import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/moderation_queue/moderation_queue_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/moderation_queue/moderation_queue_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/moderation_queue/moderation_queue_state.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';

class ModerationQueueScreen extends StatefulWidget {
  const ModerationQueueScreen({super.key});

  @override
  State<ModerationQueueScreen> createState() => _ModerationQueueScreenState();
}

class _ModerationQueueScreenState extends State<ModerationQueueScreen> {
  @override
  void initState() {
    super.initState();
    _fetchReportedPosts();
  }

  void _fetchReportedPosts() {
    final authState = context.read<AuthBloc>().state;
    final dashboardState = context.read<DashboardBloc>().state;
    final locationId = dashboardState.globalLocation?.id ?? authState.loginData?.locationId;
    context.read<ModerationQueueBloc>().add(LoadReportedPosts(locationId: locationId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ModerationQueueBloc, ModerationQueueState>(
      listener: (context, state) {
        if (state.message != null) {
          NTKSnackbar.showSuccess(context, message: state.message!);
          context.read<ModerationQueueBloc>().add(ClearModerationMessage());
          
          // Refresh dashboard moderation stats
          final authState = context.read<AuthBloc>().state;
          final dashboardState = context.read<DashboardBloc>().state;
          final locationId = dashboardState.globalLocation?.id ?? authState.loginData?.locationId;
          context.read<DashboardBloc>().add(LoadModerationStats(locationId));
        }
        if (state.error != null) {
          NTKSnackbar.showError(context, message: state.error!);
          context.read<ModerationQueueBloc>().add(ClearModerationError());
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: const NTKAppBar(
          title: 'Reported Posts',
          subtitle: 'Moderation Queue',
        ),
        body: BlocBuilder<ModerationQueueBloc, ModerationQueueState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.reportedPosts.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                _fetchReportedPosts();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.reportedPosts.length,
                itemBuilder: (context, index) {
                  return _ModerationPostCard(post: state.reportedPosts[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Color(0xFF004D2A),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'There are no reported posts to review.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModerationPostCard extends StatelessWidget {
  final PostModel post;

  const _ModerationPostCard({required this.post});

  Widget _buildHeaderBadge({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isModerating = context.watch<ModerationQueueBloc>().state.isModerating;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
            ),
            child: Row(
              children: [
                if (post.location?['name'] != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        post.location!['name'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                const Spacer(),
                // Badges
                Wrap(
                  spacing: 6,
                  children: [
                    if (post.isHighPriority)
                      _buildHeaderBadge(
                        label: 'High Priority',
                        bgColor: Colors.red.withOpacity(0.1),
                        textColor: Colors.red,
                      ),
                    if (post.isUnderReview)
                      _buildHeaderBadge(
                        label: 'Under Review',
                        bgColor: Colors.orange.withOpacity(0.1),
                        textColor: Colors.orange,
                      ),
                    if (post.hasWarning)
                      _buildHeaderBadge(
                        label: 'Warning Sent',
                        bgColor: Colors.amber.withOpacity(0.1),
                        textColor: Colors.amber[800]!,
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF004D2A).withOpacity(0.1),
                      child: Text(
                        post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Color(0xFF004D2A), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                post.authorName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              if (post.authorRole != null && post.authorRole!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF004D2A).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    post.authorRole!,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF004D2A),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            post.createdAt ?? '',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Post Content
                if (post.category != null && post.category != 'General Post')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      post.category!,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                  ),
                
                Text(
                  post.content,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                ),
                
                if (post.images.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: post.images.length,
                      itemBuilder: (context, idx) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: post.images[idx].startsWith('http')
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    post.images[idx],
                                    height: 120,
                                    width: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey[200],
                                      height: 120,
                                      width: 120,
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        );
                      },
                    ),
                  ),
                ] else if (post.image != null && post.image!.startsWith('http')) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      post.image!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        height: 160,
                        width: double.infinity,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                
                // Report Details: Count Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.report_problem_outlined, size: 14, color: Colors.red),
                      const SizedBox(width: 6),
                      Text(
                        'Reported by ${post.reportCount} members',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Report Reasons: Joined Array
                if (post.reportReasons.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      children: [
                        const TextSpan(
                          text: 'Reasons: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: post.reportReasons.join(', '),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Admin Actions
                if (isModerating)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF004D2A)),
                      ),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _showKeepPostDialog(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF004D2A),
                            side: const BorderSide(color: Color(0xFF004D2A)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Keep Post'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _showWarningDialog(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Send Warning'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showDeleteDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete Post'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showKeepPostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Keep Post'),
          content: const Text('Are you sure you want to ignore the reports and keep this post? This will clear the pending review status.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<ModerationQueueBloc>().add(
                  ModeratePost(postId: post.id, action: 'KEEP'),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004D2A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showWarningDialog(BuildContext context) {
    final TextEditingController msgController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Send Warning'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Send a warning to the author of this post. The post will remain visible but marked with a warning.'),
              const SizedBox(height: 12),
              TextField(
                controller: msgController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter warning message to the user...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<ModerationQueueBloc>().add(
                  ModeratePost(
                    postId: post.id,
                    action: 'WARN',
                    warningMessage: msgController.text.trim().isNotEmpty ? msgController.text.trim() : null,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Send Warning'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<ModerationQueueBloc>().add(
                  ModeratePost(postId: post.id, action: 'DELETE'),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
