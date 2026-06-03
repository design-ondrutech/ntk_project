import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ntk_project/src/features/events/data/models/event_model.dart';

class ResponseSuccessScreen extends StatelessWidget {
  const ResponseSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final event = args?['event'] as EventModel?;
    final status = args?['status'] as String?;

    if (event == null || status == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Success')),
        body: const Center(child: Text('Invalid arguments')),
      );
    }

    String statusText = 'Attend';
    Color statusColor = const Color(0xFF0A7E3E);
    Color statusBgColor = const Color(0xFFE8F5E9);
    IconData statusIcon = CupertinoIcons.checkmark_circle_fill;

    if (status == 'MAYBE') {
      statusText = 'Maybe';
      statusColor = Colors.orange;
      statusBgColor = const Color(0xFFFFF3E0);
      statusIcon = CupertinoIcons.question_circle_fill;
    } else if (status == 'NOT_GOING') {
      statusText = 'Not Attend';
      statusColor = const Color(0xFFEF4444);
      statusBgColor = const Color(0xFFFFEBEE);
      statusIcon = CupertinoIcons.xmark_circle_fill;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Success Illustration / Icon
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.checkmark_seal_fill,
                    color: Color(0xFF0A7E3E),
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'RSVP Confirmed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your participation response has been registered successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 32),

              // Status summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    Text(
                      event.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Back to event details button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A7E3E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // Navigate back to event details. Pop screens until we reach it or push replacement.
                    // To be safe, we pop this success screen and the response screen to go back to event details.
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'VIEW EVENT DETAILS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
}
