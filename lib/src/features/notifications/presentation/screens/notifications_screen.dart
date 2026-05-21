import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String activeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: NTKColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stay Updated',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Your latest community activities and alerts',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            // Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterPill('All', isSelected: activeFilter == 'All'),
                  const SizedBox(width: 12),
                  _buildFilterPill('Events', isSelected: activeFilter == 'Events'),
                  const SizedBox(width: 12),
                  _buildFilterPill('Requests', isSelected: activeFilter == 'Requests'),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Events Section
            _buildSectionHeader('EVENTS'),
            const SizedBox(height: 16),
            _buildNotificationCard(
              title: 'Town Hall Meeting',
              time: '2h ago',
              message: "Don't forget the monthly meeting at 6:00 PM. We'll be discussing the new park initiative.",
              icon: CupertinoIcons.calendar,
              iconColor: theme.colorScheme.primary,
              hasActions: true,
            ),
            const SizedBox(height: 16),
            _buildNotificationCard(
              title: 'Community Block Party',
              time: 'Yesterday',
              message: "Photos from yesterday's successful event are now available in the gallery.",
              icon: CupertinoIcons.sparkles,
              iconColor: const Color(0xFF3B82F6),
            ),

            const SizedBox(height: 40),
            // Requests Section
            _buildSectionHeader('REQUESTS'),
            const SizedBox(height: 16),
            _buildNotificationCard(
              title: 'Emergency Blood Request',
              time: '3h ago',
              message: "Urgent O+ blood needed at City Hospital for an emergency procedure.",
              icon: CupertinoIcons.drop_fill,
              iconColor: theme.colorScheme.error,
              hasActions: true,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () => setState(() => activeFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? NTKColors.primary : NTKColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? NTKColors.primary : NTKColors.border,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: NTKColors.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : NTKColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: NTKColors.textTertiary,
        fontSize: 12,
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String time,
    required String message,
    required IconData icon,
    required Color iconColor,
    bool hasActions = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NTKColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: NTKColors.slate900.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
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
                            title,
                            style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                          ),
                        ),
                        Text(
                          time,
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, color: NTKColors.textTertiary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasActions) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text('View Details', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    side: const BorderSide(color: NTKColors.border),
                  ),
                  child: const Text('Dismiss', style: TextStyle(fontSize: 13, color: NTKColors.textSecondary)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
