import 'package:flutter/material.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/notifications/data/models/notification_model.dart';
import 'package:ntk_project/src/features/notifications/domain/repositories/notification_repository.dart';
import 'package:ntk_project/src/injection_container.dart';
import 'package:intl/intl.dart';

class NotificationDetailsScreen extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailsScreen({super.key, required this.notification});

  String _formatDateTime(String? value) {
    if (value == null || value.isEmpty) return '';
    try {
      final date = DateTime.parse(value).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
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

  String _actionButtonText(String? type) {
    switch (type?.toUpperCase()) {
      case 'EVENT':
        return 'View Event';
      case 'APPROVAL':
        return 'View Member';
      case 'BROADCAST':
        return 'View Broadcast';
      case 'POLL':
        return 'View Poll';
      case 'COMMUNITY':
        return 'View Community';
      default:
        return 'View Details';
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }

  List<dynamic> _asList(dynamic value) {
    return value is List ? value : const [];
  }

  Widget _buildBasicDetails(BuildContext context, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_iconForType(notification.type), size: 64, color: color),
        ),
        const SizedBox(height: 32),
        Text(
          notification.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: NTKColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _formatDateTime(notification.createdAt ?? notification.time),
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 32),
        _InfoCard(
          title: 'Description',
          child: Text(
            notification.message,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: NTKColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApiDetails(BuildContext context, Map<String, dynamic> details) {
    final locationScope = _asMap(details['locationScope']);
    final emergency = _asMap(details['emergency']);
    final actions = _asList(details['availableActions']);
    final history = _asList(details['activityHistory']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Badge(
              details['notificationTypeBadge']?.toString() ?? 'Notification',
            ),
            const SizedBox(width: 8),
            _Badge(details['statusBadge']?.toString() ?? 'Active'),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          details['purpose']?.toString() ?? notification.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: NTKColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        if (locationScope != null)
          _InfoCard(
            title: 'Location Scope',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locationScope['label']?.toString() ?? 'Location'),
                Text(
                  [
                        locationScope['district'],
                        locationScope['constituency'],
                        locationScope['area'],
                        locationScope['street'],
                      ]
                      .where((e) => e != null && e.toString().isNotEmpty)
                      .join(' / '),
                  style: const TextStyle(color: NTKColors.textSecondary),
                ),
              ],
            ),
          ),
        if (emergency != null) ...[
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Emergency',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emergency['title']?.toString() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(emergency['description']?.toString() ?? ''),
                const SizedBox(height: 12),
                Text('Contact: ${emergency['contactName'] ?? '-'}'),
                Text('Phone: ${emergency['contactPhone'] ?? '-'}'),
              ],
            ),
          ),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions
                .map(
                  (action) =>
                      _Badge(_asMap(action)?['label']?.toString() ?? 'Action'),
                )
                .toList(),
          ),
        ],
        if (history.isNotEmpty) ...[
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Activity History',
            child: Column(
              children: history.map((item) {
                final row = _asMap(item);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(row?['title']?.toString() ?? ''),
                  subtitle: Text(row?['description']?.toString() ?? ''),
                  trailing: Text(
                    _formatDateTime(row?['createdAt']?.toString()),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(notification.type);

    return Scaffold(
      backgroundColor: NTKColors.background,
      appBar: const NTKAppBar(
        title: 'Notification Details',
        subtitle: 'View more information',
        showNotification: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: sl<NotificationRepository>().getNotificationDetails(
          id: notification.id,
        ),
        builder: (context, snapshot) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: snapshot.hasData
                ? _buildApiDetails(context, snapshot.data!)
                : _buildBasicDetails(context, color),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: NTKColors.emerald50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: NTKColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
