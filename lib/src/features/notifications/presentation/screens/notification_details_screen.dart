import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';
import 'package:ntk_project/src/features/notifications/data/models/notification_model.dart';
import 'package:ntk_project/src/features/notifications/domain/repositories/notification_repository.dart';
import 'package:ntk_project/src/injection_container.dart';
import 'package:intl/intl.dart';
import 'package:ntk_project/src/features/events/data/models/event_model.dart';
import 'package:ntk_project/src/features/events/data/models/emergency_model.dart';
import 'package:ntk_project/src/features/requests_broadcasts/data/models/broadcast_model.dart';
import 'package:ntk_project/src/features/community/data/models/post_model.dart';
import 'package:ntk_project/src/features/community/presentation/screens/community_post_details_screen.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_posts_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';

class NotificationDetailsScreen extends StatefulWidget {
  final NotificationModel notification;

  const NotificationDetailsScreen({super.key, required this.notification});

  @override
  State<NotificationDetailsScreen> createState() => _NotificationDetailsScreenState();
}

class _NotificationDetailsScreenState extends State<NotificationDetailsScreen> {

  String _formatDateTime(String? value) {
    if (value == null || value.isEmpty) return '';
    try {
      final date = DateHelper.parseUtcToLocal(value);
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
    final history = _asList(details['activityHistory']);

    // Resolve sender: prefer createdBy field, fallback to first activityHistory actorName
    final createdBy = _asMap(details['createdBy']);
    final senderName = createdBy?['name']?.toString() ??
        (_asList(details['activityHistory'])
            .map((e) => _asMap(e)?['actorName']?.toString())
            .firstWhere((n) => n != null && n.isNotEmpty, orElse: () => null));
    final senderRole = createdBy?['role']?.toString();

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
        const SizedBox(height: 12),

        // Sent By row
        if (senderName != null && senderName.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: NTKColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: NTKColors.primary,
                  child: Text(
                    senderName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sent by',
                      style: TextStyle(
                        fontSize: 11,
                        color: NTKColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      senderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: NTKColors.textPrimary,
                      ),
                    ),
                    if (senderRole != null && senderRole.isNotEmpty)
                      Text(
                        senderRole,
                        style: const TextStyle(
                          fontSize: 12,
                          color: NTKColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

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
        _buildForwardButton(context, details),
        _buildGoToDetailsButton(context, details),
      ],
    );
  }

  Widget _buildForwardButton(BuildContext context, Map<String, dynamic> details) {
    final role = context.read<AuthBloc>().state.loginData?.role;
    final canForward = role == 'DISTRICT_INCHARGE';
    if (!canForward) return const SizedBox.shrink();

    final type = widget.notification.type?.toUpperCase() ?? '';
    final notificationField = _asMap(details['notification']);
    final entityId = notificationField != null
        ? int.tryParse(notificationField['entityId']?.toString() ?? '')
        : widget.notification.relatedEntityId;
    final entityType = (notificationField != null
        ? notificationField['entityType']?.toString()
        : null) ?? type;

    if (entityId == null || entityType.isEmpty) return const SizedBox.shrink();

    final locationScope = _asMap(details['locationScope']);
    final sourceLocationName = locationScope?['constituency']?.toString();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton(
          onPressed: () => _showForwardModal(context, entityId, entityType, sourceLocationName),
          style: OutlinedButton.styleFrom(
            foregroundColor: NTKColors.primary,
            side: const BorderSide(color: NTKColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.forward_to_inbox, size: 20),
              SizedBox(width: 10),
              Text(
                'Forward',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showForwardModal(BuildContext context, int entityId, String type, String? sourceLocationName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ForwardModal(entityId: entityId, type: type, sourceLocationName: sourceLocationName),
    );
  }

  Widget _buildGoToDetailsButton(BuildContext context, Map<String, dynamic> details) {
    final type = widget.notification.type?.toUpperCase() ?? '';
    final notificationField = _asMap(details['notification']);
    final entityId = notificationField != null
        ? int.tryParse(notificationField['entityId']?.toString() ?? '')
        : widget.notification.relatedEntityId;
    final entityType = (notificationField != null
        ? notificationField['entityType']?.toString()
        : widget.notification.type)?.toUpperCase() ?? '';

    // Check if we have the corresponding entity data/ID
    final hasEmergency = details['emergency'] != null;
    final hasEvent = details['event'] != null;
    final hasBroadcast = details['broadcast'] != null;
    final hasPoll = entityType == 'POLL' && entityId != null;
    final hasPost = (entityType == 'POST' || entityType == 'COMMUNITY') && entityId != null;

    if (!hasEmergency && !hasEvent && !hasBroadcast && !hasPoll && !hasPost) {
      return const SizedBox.shrink();
    }

    String label = 'View Details';
    IconData icon = Icons.info_outline;
    VoidCallback? onTap;

    if (hasEmergency) {
      label = 'View Emergency Details';
      icon = Icons.campaign;
      onTap = () {
        final emergency = EmergencyModel.fromJson(_asMap(details['emergency'])!);
        Navigator.pushNamed(
          context,
          '/emergency_details',
          arguments: emergency,
        );
      };
    } else if (hasEvent) {
      label = 'View Event Details';
      icon = Icons.calendar_month;
      onTap = () {
        final event = EventModel.fromJson(_asMap(details['event'])!);
        Navigator.pushNamed(
          context,
          '/event_details',
          arguments: event,
        );
      };
    } else if (hasBroadcast) {
      label = 'View Broadcast Details';
      icon = Icons.podcasts;
      onTap = () {
        final broadcast = BroadcastModel.fromJson(_asMap(details['broadcast'])!);
        Navigator.pushNamed(
          context,
          '/broadcast_details',
          arguments: broadcast,
        );
      };
    } else if (hasPoll) {
      label = 'View Poll Details';
      icon = Icons.poll;
      onTap = () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => PollDetailSheet(
            pollId: entityId!,
            title: widget.notification.title,
          ),
        );
      };
    } else if (hasPost) {
      label = 'View Post Details';
      icon = Icons.people_outline;
      onTap = () {
        final post = PostModel(
          id: entityId!,
          title: widget.notification.title,
          content: widget.notification.message,
          likes: 0,
          authorName: '',
          createdAt: widget.notification.createdAt,
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
      };
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: NTKColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
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

class _ForwardModal extends StatefulWidget {
  final int entityId;
  final String type;
  final String? sourceLocationName;

  const _ForwardModal({required this.entityId, required this.type, this.sourceLocationName});

  @override
  State<_ForwardModal> createState() => _ForwardModalState();
}

class _ForwardModalState extends State<_ForwardModal> {
  bool _loading = true;
  bool _submitting = false;
  List<LocationModel> _locations = [];
  final Set<int> _selectedIds = {};
  int? _sourceLocId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    try {
      final repo = sl<NotificationRepository>();
      final locs = await repo.getForwardLocations(entityId: widget.entityId, type: widget.type);
      
      if (mounted) {
        setState(() {
          _locations = locs;
          // Pre-select the source location if it exists in the list
          if (widget.sourceLocationName != null) {
            final sourceLoc = _locations.where((l) => l.name == widget.sourceLocationName).firstOrNull;
            if (sourceLoc != null) {
              _sourceLocId = sourceLoc.id;
              _selectedIds.add(sourceLoc.id);
            }
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        NTKSnackbar.showError(context, message: 'Failed to load locations');
      }
    }
  }

  Future<void> _forward() async {
    if (_selectedIds.isEmpty) {
      setState(() => _errorMessage = 'Please select at least one location');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final repo = sl<NotificationRepository>();
      await repo.forwardNotification(
        entityId: widget.entityId,
        type: widget.type,
        targetLocationIds: _selectedIds.toList(),
      );
      if (mounted) {
        NTKSnackbar.showSuccess(context, message: 'Forwarded successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.startsWith('Exception: ')) msg = msg.substring(11);
        setState(() {
          _submitting = false;
          _errorMessage = msg;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Forward To',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: NTKColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_locations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No locations available to forward.',
                  style: TextStyle(color: NTKColors.textSecondary),
                ),
              ),
            )
          else ...[
            const Text(
              'Select locations to forward this notification:',
              style: TextStyle(color: NTKColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _locations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final loc = _locations[index];
                  final isSelected = _selectedIds.contains(loc.id);
                  final isSource = loc.id == _sourceLocId;
                  
                  return InkWell(
                    onTap: isSource ? null : () {
                      setState(() {
                        if (isSelected) {
                          _selectedIds.remove(loc.id);
                        } else {
                          _selectedIds.add(loc.id);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? NTKColors.primary.withOpacity(isSource ? 0.04 : 0.08) : Colors.white,
                        border: Border.all(
                          color: isSelected ? NTKColors.primary.withOpacity(isSource ? 0.5 : 1.0) : Colors.grey.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? (isSource ? Icons.check_circle : Icons.check_circle) : Icons.radio_button_unchecked,
                            color: isSelected ? NTKColors.primary.withOpacity(isSource ? 0.5 : 1.0) : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            loc.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? NTKColors.primary.withOpacity(isSource ? 0.5 : 1.0) : NTKColors.textPrimary,
                            ),
                          ),
                          if (isSource) ...[
                            const Spacer(),
                            const Text(
                              'Origin',
                              style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: NTKColors.error, fontSize: 14, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _submitting || _selectedIds.isEmpty ? null : _forward,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NTKColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send, size: 18),
                          const SizedBox(width: 8),
                          Text('Forward (${_selectedIds.length})'),
                        ],
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
