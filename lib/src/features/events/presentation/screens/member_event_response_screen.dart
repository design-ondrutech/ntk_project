import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';
import 'package:ntk_project/src/features/events/data/models/event_model.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_event.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemberEventResponseScreen extends StatefulWidget {
  const MemberEventResponseScreen({super.key});

  @override
  State<MemberEventResponseScreen> createState() =>
      _MemberEventResponseScreenState();
}

class _MemberEventResponseScreenState extends State<MemberEventResponseScreen> {
  String? _selectedStatus; // 'GOING', 'MAYBE', 'NOT_GOING'
  String? _previousStatus; // stored previous RSVP (to pre-select on re-open)
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load previous response from storage as soon as we have a route context
    final event = ModalRoute.of(context)?.settings.arguments as EventModel?;
    if (event != null && _previousStatus == null) {
      _loadPreviousResponse(event.id);
    }
  }

  Future<void> _loadPreviousResponse(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('rsvp_event_$eventId');
    if (saved != null && mounted) {
      setState(() {
        _previousStatus = saved;
        _selectedStatus = saved; // pre-select the previous choice
      });
    }
  }

  Future<void> _savePreviousResponse(String eventId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rsvp_event_$eventId', status);
  }

  String _formatDateTime(String dt) {
    return DateHelper.formatDateTime(dt);
  }

  void _submitResponse(EventModel event) {
    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a participation option')),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    final memberId = authState.loginData?.id;
    if (memberId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    context.read<EventBloc>().add(
      RespondToEvent(
        eventId: event.id,
        memberId: memberId,
        status: _selectedStatus!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = ModalRoute.of(context)?.settings.arguments as EventModel?;
    if (event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event RSVP')),
        body: const Center(child: Text('No event specified')),
      );
    }

    return BlocListener<EventBloc, EventState>(
      listener: (context, state) {
        if (_isSubmitting) {
          if (state.error != null) {
            setState(() {
              _isSubmitting = false;
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
              _previousStatus = _selectedStatus;
            });
            // Persist the new RSVP choice
            _savePreviousResponse(event.id, _selectedStatus!);
            // Navigate to Success screen
            Navigator.pushReplacementNamed(
              context,
              '/response_success',
              arguments: {'event': event, 'status': _selectedStatus},
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: const Color(0xFF004D2A),
          foregroundColor: Colors.white,
          title: const Text(
            'Participation RSVP',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event info card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF004D2A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Upcoming Event',
                        style: TextStyle(
                          color: Color(0xFF004D2A),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      event.title,
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
                          _formatDateTime(event.date),
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
                            event.locationName,
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
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Will you participate in this event?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Please select one of the options below.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              const SizedBox(height: 20),

              // Option cards
              _buildOptionCard(
                status: 'GOING',
                title: 'Attend',
                description: 'Yes, I will be attending this event.',
                icon: CupertinoIcons.checkmark_circle_fill,
                selectedColor: const Color(0xFF004D2A),
                bgColor: const Color(0xFFE8F5E9),
              ),
              const SizedBox(height: 16),
              _buildOptionCard(
                status: 'MAYBE',
                title: 'Maybe',
                description: 'I am not sure yet, might attend.',
                icon: CupertinoIcons.question_circle_fill,
                selectedColor: Colors.orange,
                bgColor: const Color(0xFFFFF3E0),
              ),
              const SizedBox(height: 16),
              _buildOptionCard(
                status: 'NOT_GOING',
                title: 'Not Attend',
                description: 'No, I will not be able to attend.',
                icon: CupertinoIcons.xmark_circle_fill,
                selectedColor: const Color(0xFFEF4444),
                bgColor: const Color(0xFFFFEBEE),
              ),

              const SizedBox(height: 48),

              // Submit button
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
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitResponse(event),
                  child: _isSubmitting
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Text(
                          _previousStatus != null ? 'UPDATE RESPONSE' : 'CONFIRM RESPONSE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String status,
    required String title,
    required String description,
    required IconData icon,
    required Color selectedColor,
    required Color bgColor,
  }) {
    final isSelected = _selectedStatus == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? bgColor.withOpacity(0.5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? selectedColor : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : const Color(0xFF9CA3AF),
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected
                          ? selectedColor
                          : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? selectedColor : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                color: isSelected ? selectedColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
