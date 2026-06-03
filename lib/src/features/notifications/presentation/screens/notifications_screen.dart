import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/notifications/data/models/notification_model.dart';
import 'package:ntk_project/src/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:ntk_project/src/features/notifications/presentation/bloc/notification_event.dart';
import 'package:ntk_project/src/features/notifications/presentation/bloc/notification_state.dart';
import 'package:ntk_project/src/features/notifications/presentation/screens/notification_details_screen.dart';
import 'package:ntk_project/src/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_state.dart';
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
      final date = DateTime.parse(value).toLocal();
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  NotificationDetailsScreen(notification: item),
            ),
          );
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
