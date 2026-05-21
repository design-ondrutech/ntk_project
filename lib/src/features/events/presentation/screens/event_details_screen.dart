import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/events/data/models/event_model.dart';

class EventDetailsScreen extends StatelessWidget {
  const EventDetailsScreen({super.key});

  String _formatDateTime(String dt) {
    try {
      final date = DateTime.parse(dt);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
    final event = ModalRoute.of(context)?.settings.arguments as EventModel?;
    final theme = Theme.of(context);

    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No event data found')),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          IconButton(icon: const Icon(CupertinoIcons.share), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Hero Image Placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
              ),
              child: Center(
                child: Icon(
                  CupertinoIcons.calendar,
                  size: 80,
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'UPCOMING EVENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.title,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 32),
                  
                  _buildDetailTile(context, CupertinoIcons.calendar, 'Date & Time', _formatDateTime(event.date)),
                  _buildDetailTile(context, CupertinoIcons.location, 'Location', 'Kalaignar Arangam, Teynampet, Chennai'),
                  _buildDetailTile(context, CupertinoIcons.person_3, 'Attendees', 'Limited seats available'),
                  
                  const SizedBox(height: 40),
                  Text('About Event', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(
                    event.description ?? 'No detailed description available for this event.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: NTKColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('REGISTER FOR EVENT'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: NTKColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
