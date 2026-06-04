import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/events/data/models/event_model.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_event.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_state.dart';
import 'package:ntk_project/src/features/events/domain/repositories/event_repository.dart';
import 'package:ntk_project/src/injection_container.dart';

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({super.key});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  EventModel? _event;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_event == null) {
      _event = ModalRoute.of(context)?.settings.arguments as EventModel?;
      if (_event != null) {
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
    try {
      final date = DateTime.parse(dt);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final ampm = date.hour < 12 ? 'AM' : 'PM';
      final minute = date.minute.toString().padLeft(2, '0');
      return '${months[date.month - 1]} ${date.day}, ${date.year} • $hour:$minute $ampm';
    } catch (_) {
      return dt;
    }
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

    return BlocBuilder<EventBloc, EventState>(
      builder: (context, state) {
        // Find latest stats from state.events if available, to keep UI updated
        final updatedEvent = state.events.firstWhere(
          (e) => e.id == _event!.id,
          orElse: () => _event!,
        );

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
                        content: const Text('Are you sure you want to recall this event? This will remove all RSVPs and notifications.'),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            child: const Text('Recall'),
                            onPressed: () {
                              context.read<EventBloc>().add(RecallEvent(id: _event!.id));
                              Navigator.pop(context); // close dialog
                              Navigator.pop(context); // go back
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              IconButton(
                icon: const Icon(CupertinoIcons.share, color: Colors.white),
                onPressed: () {},
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
                      // Header title & details card
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.time,
                                  size: 16,
                                  color: Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDateTime(updatedEvent.date),
                                  style: const TextStyle(
                                    color: Color(0xFF4B5563),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.location_solid,
                                  size: 16,
                                  color: Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    updatedEvent.locationName,
                                    style: const TextStyle(
                                      color: Color(0xFF4B5563),
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1, color: Color(0xFFF3F4F6)),
                            const SizedBox(height: 16),

                            // 3 RSVP summary pills
                            Row(
                              children: [
                                Expanded(
                                  child: _buildRsvppill(
                                    count: updatedEvent.going,
                                    label: 'Attend',
                                    color: const Color(0xFF004D2A),
                                    bgColor: const Color(0xFFE8F5E9),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildRsvppill(
                                    count: updatedEvent.maybe,
                                    label: 'Maybe',
                                    color: Colors.orange,
                                    bgColor: const Color(0xFFFFF3E0),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildRsvppill(
                                    count: updatedEvent.notGoing,
                                    label: 'Not Attend',
                                    color: const Color(0xFFEF4444),
                                    bgColor: const Color(0xFFFFEBEE),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Description
                      const Text(
                        'Event Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        updatedEvent.description.isNotEmpty
                            ? updatedEvent.description
                            : 'No additional details are provided for this event. Please reach out to your local constituency administrator for more information.',
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // RSVP distribution / Doughnut chart
                      const Text(
                        'Response Distribution',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (totalResponses > 0)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLegendItem(
                                      'Attend',
                                      updatedEvent.going,
                                      totalResponses,
                                      const Color(0xFF004D2A),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildLegendItem(
                                      'Maybe',
                                      updatedEvent.maybe,
                                      totalResponses,
                                      Colors.orange,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildLegendItem(
                                      'Not Attend',
                                      updatedEvent.notGoing,
                                      totalResponses,
                                      const Color(0xFFEF4444),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Center(
                            child: Text(
                              'No responses recorded yet.',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 48),

                      // Navigation Button
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
                            if (isAdmin) {
                              Navigator.pushNamed(
                                context,
                                '/event_responses',
                                arguments: updatedEvent,
                              );
                            } else {
                              Navigator.pushNamed(
                                context,
                                '/member_event_response',
                                arguments: updatedEvent,
                              );
                            }
                          },
                          child: Text(
                            isAdmin ? 'VIEW RESPONSES' : 'PARTICIPATION RSVP',
                            style: const TextStyle(
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
