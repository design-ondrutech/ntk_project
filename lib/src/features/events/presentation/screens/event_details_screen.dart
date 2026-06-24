import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/events/data/models/event_model.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_event.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_state.dart';
import 'package:ntk_project/src/features/events/domain/repositories/event_repository.dart';
import 'package:ntk_project/src/injection_container.dart';
import 'package:share_plus/share_plus.dart';

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({super.key});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

enum EventExpiryStatus { active, upcoming, expired }

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  EventModel? _event;
  bool _isSubmitting = false;

  // Optimistic local RSVP state — persists independently of BLoC state.
  // Set immediately on tap; initialised from server on first load; reverted on error.
  String? _localRsvpStatus;
  String? _previousRsvpStatus; // Used to revert on API error
  // Track whether we have attempted to initialize from server (not just once —
  // reset when event changes so navigating back triggers a fresh lookup).
  bool _rsvpInitializedFromServer = false;

  DateTime _parseEventDate(String dt) {
    return DateHelper.parseUtcToLocal(dt);
  }

  EventExpiryStatus _getEventStatus(String dateStr) {
    final eventTime = _parseEventDate(dateStr);
    final now = DateTime.now();
    if (now.isAfter(eventTime)) {
      return EventExpiryStatus.expired;
    }
    if (eventTime.year == now.year &&
        eventTime.month == now.month &&
        eventTime.day == now.day) {
      return EventExpiryStatus.active;
    }
    return EventExpiryStatus.upcoming;
  }

  Widget _buildStatusBadge(EventExpiryStatus status) {
    switch (status) {
      case EventExpiryStatus.active:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F4EA),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: Color(0xFF0F5A29)),
              SizedBox(width: 4),
              Text(
                'Active Event',
                style: TextStyle(
                  color: Color(0xFF0F5A29),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case EventExpiryStatus.upcoming:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: Color(0xFFD97706)),
              SizedBox(width: 4),
              Text(
                'Upcoming Event',
                style: TextStyle(
                  color: Color(0xFFD97706),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case EventExpiryStatus.expired:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: Color(0xFFDC2626)),
              SizedBox(width: 4),
              Text(
                'Expired Event',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    }
  }

  void _submitRsvp(String eventId, int? memberId, String status) {
    if (memberId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    // Allow changing response but not re-submitting the same status.
    if (_localRsvpStatus == status) return;

    setState(() {
      _isSubmitting = true;
      _previousRsvpStatus = _localRsvpStatus; // Save for potential revert
      _localRsvpStatus = status; // Optimistic update — shows immediately
    });

    context.read<EventBloc>().add(
      RespondToEvent(eventId: eventId, memberId: memberId, status: status),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_event == null) {
      _event = ModalRoute.of(context)?.settings.arguments as EventModel?;
      if (_event != null) {
        // Reset initialization so RSVP state is re-read from bloc for this event
        _rsvpInitializedFromServer = false;
        _localRsvpStatus = null;
        context.read<EventBloc>().add(FetchEventResponses(eventId: _event!.id));
        _loadEventDetails();
      }
    }
  }

  Future<void> _loadEventDetails() async {
    final eventId = _event?.id;
    if (eventId == null || eventId.isEmpty) return;
    try {
      final details = await sl<EventRepository>().getEventDetails(id: eventId);
      if (!mounted) return;
      setState(() => _event = details);
    } catch (_) {
      // Keep the route argument data visible if the details endpoint is unavailable.
    }
  }

  String _formatDateTime(String dt) {
    return DateHelper.formatDateTime(dt);
  }

  @override
  Widget build(BuildContext context) {
    if (_event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: const Center(child: Text('No event data found')),
      );
    }

    final authState = context.watch<AuthBloc>().state;
    final userRole = authState.loginData?.role ?? 'MEMBER';
    final isAdmin = userRole != 'MEMBER';
    final memberId = authState.loginData?.id;

    // Eagerly initialize RSVP status from bloc state if the listener hasn't
    // fired yet (e.g., responses already loaded when widget first builds).
    if (!_rsvpInitializedFromServer) {
      final existingResponses =
          context.read<EventBloc>().state.eventResponses;
      if (existingResponses.isNotEmpty) {
        final serverResponse = existingResponses.firstWhere(
          (r) => r.member.id == memberId?.toString(),
          orElse: () =>
              EventResponseModel(
                status: '',
                member: EventMemberModel(id: '', name: '', phone: ''),
              ),
        );
        if (serverResponse.status.isNotEmpty) {
          // Use WidgetsBinding to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_rsvpInitializedFromServer) {
              setState(() {
                _localRsvpStatus = serverResponse.status;
                _rsvpInitializedFromServer = true;
              });
            }
          });
        } else {
          _rsvpInitializedFromServer = true;
        }
      }
    }


    return BlocListener<EventBloc, EventState>(
      listener: (context, state) {
        // ── Initialise from server on first load ──────────────────────────
        if (!_rsvpInitializedFromServer && state.eventResponses.isNotEmpty) {
          final serverResponse = state.eventResponses.firstWhere(
            (r) => r.member.id == memberId?.toString(),
            orElse: () => EventResponseModel(
              status: '',
              member: EventMemberModel(id: '', name: '', phone: ''),
            ),
          );
          if (serverResponse.status.isNotEmpty) {
            setState(() {
              _localRsvpStatus = serverResponse.status;
              _rsvpInitializedFromServer = true;
            });
          } else {
            // Responses loaded but this member hasn't responded yet.
            _rsvpInitializedFromServer = true;
          }
        }

        // ── Handle submit result ──────────────────────────────────────────
        if (_isSubmitting) {
          if (state.error != null) {
            setState(() {
              _isSubmitting = false;
              _localRsvpStatus =
                  _previousRsvpStatus; // Revert optimistic update
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state.message != null &&
              state.message!.contains('Successfully')) {
            setState(() {
              _isSubmitting = false;
              // _localRsvpStatus already set optimistically — keep it.
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('RSVP submitted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      },
      listenWhen: (previous, current) =>
          previous.eventResponses != current.eventResponses ||
          previous.isResponsesLoading != current.isResponsesLoading ||
          previous.error != current.error ||
          previous.message != current.message,
      child: BlocBuilder<EventBloc, EventState>(
        builder: (context, state) {
          // Find latest stats from state.events if available, to keep UI updated.
          // Prefer _event for createdById since getEventDetails fetches createdBy
          // but getEventList may not always include it.
          final updatedEvent = state.events.firstWhere(
            (e) => e.id == _event!.id,
            orElse: () => _event!,
          );

          // Determine creator: use createdById from updatedEvent if populated,
          // otherwise fall back to _event (which was fetched from getEventDetails).
          final effectiveCreatedById =
              updatedEvent.createdById ?? _event?.createdById;
          final isCreator =
              memberId != null && effectiveCreatedById == memberId;

          final totalResponses =
              updatedEvent.going + updatedEvent.maybe + updatedEvent.notGoing;

          return Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            appBar: AppBar(
              backgroundColor: const Color(0xFF004D2A),
              foregroundColor: Colors.white,
              title: const Text(
                'Event Details',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              actions: [
                if (isAdmin)
                  IconButton(
                    icon: const Icon(CupertinoIcons.trash, color: Colors.white),
                    onPressed: () {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Recall Event'),
                          content: const Text(
                            'Are you sure you want to recall this event? This will remove all RSVPs and notifications.',
                          ),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              child: const Text('Recall'),
                              onPressed: () {
                                context.read<EventBloc>().add(
                                  RecallEvent(id: _event!.id),
                                );
                                Navigator.pop(context); // close dialog
                                Navigator.pop(context); // go back
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Banner image/card placeholder
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF004D2A), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.calendar,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'COMMUNITY ENGAGEMENT',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header title card — floats up over the banner
                        Container(
                          width: double.infinity,
                          transform: Matrix4.translationValues(0.0, -40.0, 0.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                updatedEvent.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _buildStatusBadge(
                                      _getEventStatus(updatedEvent.date)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(CupertinoIcons.person_2_fill,
                                            size: 12,
                                            color: Color(0xFF6B7280)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${updatedEvent.going + updatedEvent.maybe + updatedEvent.notGoing} responded',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF6B7280),
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),


                        // ── Event Info Card ─────────────────────────────────────
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card header strip
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF004D2A),
                                      Color(0xFF006837)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          CupertinoIcons.doc_text_fill,
                                          color: Colors.white,
                                          size: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Event Description',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Description body
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      updatedEvent.description.isNotEmpty
                                          ? updatedEvent.description
                                          : 'No additional details are provided for this event. Please reach out to your local constituency administrator for more information.',
                                      style: TextStyle(
                                        color: updatedEvent.description.isNotEmpty
                                            ? const Color(0xFF374151)
                                            : const Color(0xFF9CA3AF),
                                        fontSize: 14,
                                        height: 1.7,
                                        fontStyle: updatedEvent.description.isNotEmpty
                                            ? FontStyle.normal
                                            : FontStyle.italic,
                                      ),
                                    ),

                                    const SizedBox(height: 16),
                                    const Divider(
                                        height: 1, color: Color(0xFFF3F4F6)),
                                    const SizedBox(height: 14),

                                    // Date & Time row
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F5E9),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                              CupertinoIcons.calendar,
                                              size: 14,
                                              color: Color(0xFF004D2A)),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('Date & Time',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF9CA3AF),
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatDateTime(
                                                    updatedEvent.date),
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1F2937)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Location row
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0FDF4),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                              CupertinoIcons.location_solid,
                                              size: 14,
                                              color: Color(0xFF059669)),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('Location',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF9CA3AF),
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              const SizedBox(height: 2),
                                              Text(
                                                updatedEvent.locationName
                                                        .isNotEmpty
                                                    ? updatedEvent.locationName
                                                    : 'Location not specified',
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1F2937)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── RSVP section: NON-CREATORS ─────────────────────────
                        if (!isCreator) ...[
                          const Text(
                            'Your Participation RSVP',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Select your attendance status directly below.',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Builder(
                            builder: (context) {
                              String? currentRsvpStatus = state.myEventResponses[updatedEvent.id] ?? _localRsvpStatus;
                              if (currentRsvpStatus == null &&
                                  state.eventResponses.isNotEmpty) {
                                final serverResponse = state.eventResponses
                                    .firstWhere(
                                  (r) => r.member.id == memberId?.toString(),
                                  orElse: () => EventResponseModel(
                                    status: '',
                                    member: EventMemberModel(
                                        id: '', name: '', phone: ''),
                                  ),
                                );
                                if (serverResponse.status.isNotEmpty) {
                                  currentRsvpStatus = serverResponse.status;
                                }
                              }
                              final eventStatus =
                                  _getEventStatus(updatedEvent.date);
                              final isExpired =
                                  eventStatus == EventExpiryStatus.expired;
                              return _buildMemberRsvpOptions(
                                context: context,
                                eventId: updatedEvent.id,
                                memberId: memberId,
                                currentStatus: currentRsvpStatus,
                                // Only disable RSVP when actively submitting — not when
                                // fetching initial responses (isResponsesLoading).
                                isLoading: _isSubmitting,
                                isExpired: isExpired,
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                        ],

                        // ── Organizer section: CREATORS ONLY ─────────────────────
                        if (isCreator) ...[
                          // Organizer badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF004D2A), Color(0xFF006837)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                      Icons.admin_panel_settings_rounded,
                                      color: Colors.white,
                                      size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Event Organizer View',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'You created this event. Manage participant responses below.',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Live stat tiles
                          Row(
                            children: [
                              Expanded(
                                child: _buildOrganizerStat(
                                  label: 'Attending',
                                  count: updatedEvent.going,
                                  color: const Color(0xFF004D2A),
                                  bgColor: const Color(0xFFE8F5E9),
                                  icon: CupertinoIcons.checkmark_circle_fill,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildOrganizerStat(
                                  label: 'Maybe',
                                  count: updatedEvent.maybe,
                                  color: Colors.orange,
                                  bgColor: const Color(0xFFFFF3E0),
                                  icon: CupertinoIcons.question_circle_fill,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildOrganizerStat(
                                  label: 'Declined',
                                  count: updatedEvent.notGoing,
                                  color: const Color(0xFFEF4444),
                                  bgColor: const Color(0xFFFFEBEE),
                                  icon: CupertinoIcons.xmark_circle_fill,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Response Distribution
                          const Text(
                            'Response Distribution',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (totalResponses > 0)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 90,
                                    height: 90,
                                    child: CustomPaint(
                                      painter: DoughnutPainter(
                                        going: updatedEvent.going,
                                        maybe: updatedEvent.maybe,
                                        notGoing: updatedEvent.notGoing,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildLegendItem(
                                            'Attend',
                                            updatedEvent.going,
                                            totalResponses,
                                            const Color(0xFF004D2A)),
                                        const SizedBox(height: 8),
                                        _buildLegendItem(
                                            'Maybe',
                                            updatedEvent.maybe,
                                            totalResponses,
                                            Colors.orange),
                                        const SizedBox(height: 8),
                                        _buildLegendItem(
                                            'Not Attend',
                                            updatedEvent.notGoing,
                                            totalResponses,
                                            const Color(0xFFEF4444)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 28),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Column(
                                children: [
                                  Icon(CupertinoIcons.chart_pie,
                                      size: 36, color: Colors.grey[300]),
                                  const SizedBox(height: 8),
                                  const Text('No responses yet.',
                                      style: TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 14)),
                                ],
                              ),
                            ),
                        ],


                        const SizedBox(height: 48),

                        // Navigation Button
                        if (isCreator)
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF004D2A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/event_responses',
                                  arguments: updatedEvent,
                                );
                              },
                              child: const Text(
                                'VIEW RESPONSES',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemberRsvpOptions({
    required BuildContext context,
    required String eventId,
    required int? memberId,
    required String? currentStatus,
    required bool isLoading,
    required bool isExpired,
  }) {
    return Column(
      children: [
        _buildRsvpOptionCard(
          status: 'GOING',
          title: 'Attend',
          description: 'Yes, I will be attending this event.',
          icon: CupertinoIcons.checkmark_circle_fill,
          selectedColor: isExpired ? Colors.grey : const Color(0xFF004D2A),
          selectedBgColor: isExpired
              ? Colors.grey[200]!
              : const Color(0xFFE8F5E9),
          isSelected: currentStatus == 'GOING',
          isLoading: isExpired ? true : (isLoading && currentStatus != 'GOING'),
          isExpired: isExpired,
          onTap: (currentStatus != null) ? null : () => _submitRsvp(eventId, memberId, 'GOING'),
        ),
        const SizedBox(height: 12),
        _buildRsvpOptionCard(
          status: 'MAYBE',
          title: 'Maybe',
          description: 'I am not sure yet, might attend.',
          icon: CupertinoIcons.question_circle_fill,
          selectedColor: isExpired ? Colors.grey : Colors.orange,
          selectedBgColor: isExpired
              ? Colors.grey[200]!
              : const Color(0xFFFFF3E0),
          isSelected: currentStatus == 'MAYBE',
          isLoading: isExpired ? true : (isLoading && currentStatus != 'MAYBE'),
          isExpired: isExpired,
          onTap: (currentStatus != null) ? null : () => _submitRsvp(eventId, memberId, 'MAYBE'),
        ),
        const SizedBox(height: 12),
        _buildRsvpOptionCard(
          status: 'NOT_GOING',
          title: 'Not Attend',
          description: 'No, I will not be able to attend.',
          icon: CupertinoIcons.xmark_circle_fill,
          selectedColor: isExpired ? Colors.grey : const Color(0xFFEF4444),
          selectedBgColor: isExpired
              ? Colors.grey[200]!
              : const Color(0xFFFFEBEE),
          isSelected: currentStatus == 'NOT_GOING',
          isLoading: isExpired
              ? true
              : (isLoading && currentStatus != 'NOT_GOING'),
          isExpired: isExpired,
          onTap: (currentStatus != null) ? null : () => _submitRsvp(eventId, memberId, 'NOT_GOING'),
        ),
        if (isExpired) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This event has ended. RSVP options are disabled.',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRsvpOptionCard({
    required String status,
    required String title,
    required String description,
    required IconData icon,
    required Color selectedColor, // Border / icon / text color when selected
    required Color selectedBgColor, // Background color when selected
    required bool isSelected,
    required bool isLoading,
    required bool isExpired,
    required VoidCallback? onTap,
  }) {
    final cardBgColor = isSelected ? selectedBgColor : Colors.white;
    final cardBorderColor = isSelected
        ? selectedColor
        : const Color(0xFFE5E7EB);
    final iconColor = isSelected ? selectedColor : const Color(0xFF9CA3AF);
    final titleColor = isSelected ? selectedColor : const Color(0xFF1F2937);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorderColor,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: selectedColor.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.015),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: selectedColor.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    key: ValueKey(isSelected),
                    color: iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: isExpired
                              ? Colors.grey[500]
                              : const Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right indicator: spinner while THIS card is submitting, radio otherwise
                if (isLoading && isSelected && !isExpired)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(selectedColor),
                    ),
                  )
                else
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? selectedColor
                            : const Color(0xFFD1D5DB),
                        width: 2,
                      ),
                      color: isSelected ? selectedColor : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRsvppill({
    required int count,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Organizer stat tile: shown in the admin-only section of event details.
  Widget _buildOrganizerStat({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildLegendItem(String label, int count, int total, Color color) {
    final percentage = (count / total * 100).toStringAsFixed(0);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$count ($percentage%)',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}

class DoughnutPainter extends CustomPainter {
  final int going;
  final int maybe;
  final int notGoing;

  DoughnutPainter({
    required this.going,
    required this.maybe,
    required this.notGoing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = going + maybe + notGoing;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 14.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2;

    void drawSegment(int count, Color color) {
      if (count == 0) return;
      final sweepAngle = (count / total) * 2 * pi;
      paint.color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }

    drawSegment(going, const Color(0xFF004D2A));
    drawSegment(maybe, Colors.orange);
    drawSegment(notGoing, const Color(0xFFEF4444));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
