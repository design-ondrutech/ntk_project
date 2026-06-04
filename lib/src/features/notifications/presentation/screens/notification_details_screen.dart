import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_event.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_state.dart';
import 'package:ntk_project/src/features/notifications/data/models/notification_model.dart';
import 'package:ntk_project/src/features/notifications/domain/repositories/notification_repository.dart';
import 'package:ntk_project/src/injection_container.dart';
import 'package:intl/intl.dart';

class NotificationDetailsScreen extends StatefulWidget {
  final NotificationModel notification;

  const NotificationDetailsScreen({super.key, required this.notification});

  @override
  State<NotificationDetailsScreen> createState() => _NotificationDetailsScreenState();
}

class _NotificationDetailsScreenState extends State<NotificationDetailsScreen> {
  String? _submittedActionKey;

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

  Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }

  List<dynamic> _asList(dynamic value) {
    return value is List ? value : const [];
  }

  /// Maps action key to RSVPStatus expected by the backend
  String _toRsvpStatus(String key) {
    switch (key.toUpperCase()) {
      case 'COMING':
        return 'COMING';
      case 'ON_THE_WAY':
        return 'ON_THE_WAY';
      case 'REACHED':
        return 'REACHED';
      case 'UNABLE':
        return 'UNABLE';
      case 'CONTACT_REQUESTED':
        return 'CONTACT_REQUESTED';
      default:
        return key.toUpperCase();
    }
  }

  Color _actionColor(String? style) {
    switch (style?.toUpperCase()) {
      case 'PRIMARY':
        return NTKColors.primary;
      case 'DANGER':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      case 'INFO':
        return Colors.blue;
      case 'SUCCESS':
        return NTKColors.primary;
      default:
        return NTKColors.primary;
    }
  }

  void _handleAction(String key, String? emergencyId) {
    final resolvedId = emergencyId ?? widget.notification.relatedEntityId?.toString();
    if (resolvedId == null || resolvedId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot process action: missing entity ID')),
      );
      return;
    }

    final status = _toRsvpStatus(key);
    setState(() => _submittedActionKey = key);

    context.read<EventBloc>().add(
      RespondToEmergency(emergencyRequestId: resolvedId, status: status),
    );
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
          child: Icon(_iconForType(widget.notification.type), size: 64, color: color),
        ),
        const SizedBox(height: 32),
        Text(
          widget.notification.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: NTKColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _formatDateTime(widget.notification.createdAt ?? widget.notification.time),
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 32),
        _InfoCard(
          title: 'Description',
          child: Text(
            widget.notification.message,
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

    // Try to get emergency ID — could be stored in the relatedEntityId
    final emergencyId = widget.notification.relatedEntityId?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type & status badges
        Row(
          children: [
            _Badge(details['notificationTypeBadge']?.toString() ?? 'Notification'),
            const SizedBox(width: 8),
            _Badge(details['statusBadge']?.toString() ?? 'Active'),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          details['purpose']?.toString() ?? widget.notification.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: NTKColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),

        // Location scope
        if (locationScope != null)
          _InfoCard(
            title: 'Location Scope',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locationScope['label']?.toString() ?? 'Location',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: NTKColors.textPrimary),
                ),
                const SizedBox(height: 4),
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

        // Emergency info
        if (emergency != null) ...[
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Emergency Details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emergency['title']?.toString() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  emergency['description']?.toString() ?? '',
                  style: const TextStyle(color: NTKColors.textSecondary),
                ),
                if ((emergency['contactName'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.person, size: 14, color: NTKColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Contact: ${emergency['contactName']}',
                        style: const TextStyle(color: NTKColors.textSecondary),
                      ),
                    ],
                  ),
                ],
                if ((emergency['contactPhone'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.phone, size: 14, color: NTKColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Phone: ${emergency['contactPhone']}',
                        style: const TextStyle(color: NTKColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],

        // Action buttons — fully interactive
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 20),
          BlocConsumer<EventBloc, EventState>(
            listener: (context, state) {
              if (state.message != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message!),
                    backgroundColor: NTKColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              if (state.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error!),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                setState(() => _submittedActionKey = null);
              }
            },
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: NTKColors.textSecondary,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: actions.map((action) {
                      final actionMap = _asMap(action);
                      final key = actionMap?['key']?.toString() ?? '';
                      final label = actionMap?['label']?.toString() ?? 'Action';
                      final style = actionMap?['style']?.toString();
                      final color = _actionColor(style);
                      final isSubmitted = _submittedActionKey == key;
                      final isLoading = state.isLoading && isSubmitted;

                      return GestureDetector(
                        onTap: state.isLoading ? null : () => _handleAction(key, emergencyId),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSubmitted ? color : color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: color.withOpacity(0.4)),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      isSubmitted ? Colors.white : color,
                                    ),
                                  ),
                                )
                              : Text(
                                  label,
                                  style: TextStyle(
                                    color: isSubmitted ? Colors.white : color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ],

        // Activity History
        if (history.isNotEmpty) ...[
          const SizedBox(height: 20),
          _InfoCard(
            title: 'Activity History',
            child: Column(
              children: history.map((item) {
                final row = _asMap(item);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.history_rounded, size: 16, color: NTKColors.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row?['title']?.toString() ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if ((row?['description'] ?? '').toString().isNotEmpty)
                              Text(
                                row?['description']?.toString() ?? '',
                                style: const TextStyle(
                                  color: NTKColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        _formatDateTime(row?['createdAt']?.toString()),
                        style: const TextStyle(
                          color: NTKColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
    final color = _colorForType(widget.notification.type);

    return Scaffold(
      backgroundColor: NTKColors.background,
      appBar: const NTKAppBar(
        title: 'Notification Details',
        subtitle: 'View more information',
        showNotification: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: sl<NotificationRepository>().getNotificationDetails(
          id: widget.notification.id,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
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
