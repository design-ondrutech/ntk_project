import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';
import 'package:ntk_project/src/features/notifications/data/models/notification_model.dart';
import 'package:ntk_project/src/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:ntk_project/src/features/notifications/presentation/bloc/notification_event.dart';
import 'package:ntk_project/src/features/notifications/presentation/bloc/notification_state.dart';
import 'package:ntk_project/src/features/notifications/presentation/screens/notification_details_screen.dart';
import 'package:ntk_project/src/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:ntk_project/src/features/events/data/models/event_model.dart';
import 'package:ntk_project/src/features/events/data/models/emergency_model.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';
import 'package:ntk_project/src/features/community/data/models/poll_model.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_post_details_screen.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_posts_bloc.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';
import 'package:ntk_project/src/injection_container.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String activeFilter = 'All';
  final List<String> filters = [
    'All',
    'Unread',
    'Events',
    'Approvals',
    'Broadcasts',
    'Emergency',
    'Polls',
    'Community',
  ];

  @override
  void initState() {
    super.initState();
    final bloc = context.read<NotificationBloc>();
    bloc.add(ConnectNotificationSocket());
    final dashState = context.read<DashboardBloc>().state;
    final locationId = dashState.globalLocation?.id;
    bloc.add(FetchNotifications(locationId: locationId));
  }

  @override
  void dispose() {
    // Optionally disconnect or keep alive if needed globally
    // context.read<NotificationBloc>().add(DisconnectNotificationSocket());
    super.dispose();
  }

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '';
    try {
      final date = DateHelper.parseUtcToLocal(value);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 1) return DateFormat('dd MMM, yyyy').format(date);
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inHours > 0) return '${diff.inHours} hours ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes} mins ago';
      return 'Just now';
    } catch (_) {
      return value;
    }
  }

  IconData _iconForType(String? type) {
    switch (type?.toUpperCase()) {
      case 'EMERGENCY':
      case 'ALERT':
        return Icons.campaign;
      case 'EVENT':
        return Icons.calendar_month;
      case 'APPROVAL':
        return Icons.check_circle_outline;
      case 'BROADCAST':
        return Icons.podcasts;
      case 'POLL':
        return Icons.poll;
      case 'COMMUNITY':
        return Icons.people_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Color _colorForType(String? type) {
    switch (type?.toUpperCase()) {
      case 'EMERGENCY':
      case 'ALERT':
        return Colors.red;
      case 'EVENT':
        return Colors.blue;
      case 'APPROVAL':
        return Colors.green;
      case 'BROADCAST':
        return Colors.orange;
      case 'POLL':
        return Colors.purple;
      case 'COMMUNITY':
        return Colors.teal;
      default:
        return NTKColors.primary;
    }
  }

  List<NotificationModel> _filterNotifications(
    List<NotificationModel> notifications,
  ) {
    return notifications.where((item) {
      if (activeFilter == 'All') return true;
      if (activeFilter == 'Unread') return !item.isRead;
      if (activeFilter == 'Events') return item.type?.toUpperCase() == 'EVENT';
      if (activeFilter == 'Approvals')
        return item.type?.toUpperCase() == 'APPROVAL';
      if (activeFilter == 'Broadcasts')
        return item.type?.toUpperCase() == 'BROADCAST';
      if (activeFilter == 'Emergency')
        return item.type?.toUpperCase() == 'EMERGENCY' ||
            item.type?.toUpperCase() == 'ALERT';
      if (activeFilter == 'Polls') return item.type?.toUpperCase() == 'POLL';
      if (activeFilter == 'Community')
        return item.type?.toUpperCase() == 'COMMUNITY';
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NTKAppBar(
        title: 'Notifications',
        subtitle: 'Notification Center',
        showNotification: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterTabs(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Updates',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.read<NotificationBloc>().add(
                      MarkAllNotificationsAsRead(),
                    );
                  },
                  child: const Text('Mark all as read'),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<NotificationBloc, NotificationState>(
              listener: (context, state) {
                if (state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error!),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state.isLoading && state.notifications.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredList = _filterNotifications(state.notifications);

                if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final dashState = context.read<DashboardBloc>().state;
                    final locationId = dashState.globalLocation?.id;
                    context.read<NotificationBloc>().add(
                      FetchNotifications(locationId: locationId),
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24, top: 8),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return _buildDismissibleCard(item);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => activeFilter = filter);
                  final dashState = context.read<DashboardBloc>().state;
                  final locationId = dashState.globalLocation?.id;
                  String? apiType;
                  if (filter == 'Events')
                    apiType = 'EVENT';
                  else if (filter == 'Approvals')
                    apiType = 'APPROVAL';
                  else if (filter == 'Broadcasts')
                    apiType = 'BROADCAST';
                  else if (filter == 'Emergency')
                    apiType = 'EMERGENCY';
                  else if (filter == 'Polls')
                    apiType = 'POLL';
                  else if (filter == 'Community')
                    apiType = 'COMMUNITY';

                  context.read<NotificationBloc>().add(
                    FetchNotifications(locationId: locationId, type: apiType),
                  );
                }
              },
              selectedColor: NTKColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }

  void _navigateForNotification(BuildContext context, NotificationModel item) {
    final type = item.type?.toUpperCase() ?? '';
    final id = item.relatedEntityId;

    switch (type) {
      case 'EVENT':
        // Navigate to Event Details — only if we have a valid entity ID
        if (id != null) {
          final event = EventModel(
            id: id.toString(),
            title: item.title,
            description: item.message,
            date: '',
            locationName: '',
            going: 0,
            maybe: 0,
            notGoing: 0,
          );
          Navigator.pushNamed(context, '/event_details', arguments: event);
        } else {
          _fallbackToNotificationDetails(context, item);
        }
        break;

      case 'EMERGENCY':
      case 'ALERT':
        // Navigate to Emergency Details — only if we have a valid entity ID
        if (id != null) {
          Navigator.pushNamed(
            context,
            '/emergency_details',
            arguments: EmergencyModel(
              id: id.toString(),
              title: item.title,
              description: item.message,
              type: type,
              contactName: '',
              contactPhone: '',
              expiryDate: '',
              collectResponse: false,
              locationName: '',
              going: 0,
              maybe: 0,
              notGoing: 0,
            ),
          );
        } else {
          _fallbackToNotificationDetails(context, item);
        }
        break;

      case 'POLL':
        // Navigate to Poll Details — show a full-screen poll detail page
        if (id != null) {
          _showPollDetails(context, id, item);
        } else {
          _fallbackToNotificationDetails(context, item);
        }
        break;

      case 'POST':
      case 'COMMUNITY':
        // Navigate to Community Post Details
        if (id != null) {
          final post = PostModel(
            id: id,
            title: item.title,
            content: item.message,
            likes: 0,
            authorName: '',
            createdAt: item.createdAt,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: sl<CommunityPostsBloc>(),
                child: CommunityPostDetailsScreen(post: post),
              ),
            ),
          );
        } else {
          _fallbackToNotificationDetails(context, item);
        }
        break;

      default:
        _fallbackToNotificationDetails(context, item);
    }
  }

  void _fallbackToNotificationDetails(BuildContext context, NotificationModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailsScreen(notification: item),
      ),
    );
  }

  void _showPollDetails(BuildContext context, int pollId, NotificationModel item) {
    // Show a loading bottom sheet that fetches and displays poll details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PollDetailSheet(pollId: pollId, title: item.title),
    );
  }

  Widget _buildDismissibleCard(NotificationModel item) {
    return Dismissible(
      key: Key(item.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        context.read<NotificationBloc>().add(DeleteNotificationEvent(item.id));
      },
      child: GestureDetector(
        onTap: () {
          if (!item.isRead) {
            context.read<NotificationBloc>().add(
              MarkNotificationAsRead(item.id),
            );
          }
          _navigateForNotification(context, item);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: item.isRead
                ? Colors.white
                : NTKColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: [
              if (!item.isRead)
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _colorForType(item.type).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconForType(item.type),
                    color: _colorForType(item.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: item.isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                color: NTKColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!item.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: NTKColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: NTKColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(item.createdAt ?? item.time),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Poll Detail Sheet — shown when tapping a POLL notification
// ---------------------------------------------------------------------------
class _PollDetailSheet extends StatefulWidget {
  final int pollId;
  final String title;

  const _PollDetailSheet({required this.pollId, required this.title});

  @override
  State<_PollDetailSheet> createState() => _PollDetailSheetState();
}

class _PollDetailSheetState extends State<_PollDetailSheet> {
  PollModel? _poll;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPoll();
  }

  Future<void> _loadPoll() async {
    try {
      final poll = await sl<CommunityRepository>().getPollDetails(id: widget.pollId);
      if (mounted) setState(() { _poll = poll; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.poll, color: Colors.purple, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: NTKColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline, color: Colors.red[300], size: 48),
                                const SizedBox(height: 12),
                                const Text('Failed to load poll details',
                                    style: TextStyle(color: NTKColors.textSecondary)),
                              ],
                            ),
                          ),
                        )
                      : _buildPollContent(controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollContent(ScrollController controller) {
    final poll = _poll!;
    final totalVotes = poll.options.fold<int>(0, (sum, o) => sum + o.votesCount);

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          poll.question,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: NTKColors.textPrimary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        ...poll.options.map((option) {
          final percent = totalVotes > 0 ? option.votesCount / totalVotes : 0.0;
          final isVoted = poll.userVoteOptionId == option.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isVoted ? NTKColors.primary.withOpacity(0.08) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isVoted ? NTKColors.primary.withOpacity(0.4) : Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.text,
                        style: TextStyle(
                          fontWeight: isVoted ? FontWeight.bold : FontWeight.normal,
                          color: isVoted ? NTKColors.primary : NTKColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${(percent * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: isVoted ? NTKColors.primary : NTKColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: Colors.grey[200],
                    color: isVoted ? NTKColors.primary : Colors.purple,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Text(
          '$totalVotes vote${totalVotes != 1 ? 's' : ''} total',
          style: const TextStyle(color: NTKColors.textSecondary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
