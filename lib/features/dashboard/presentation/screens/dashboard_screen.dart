import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('NTK Dashboard'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.bell, size: 24),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(CupertinoIcons.person, size: 20, color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Admin',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const Text(
              'Monitor your community activity today',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
            ),
            const SizedBox(height: 32),
            
            // Metrics Grid (2x2)
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Members',
                    value: '1,284',
                    trend: '+12%',
                    isPositiveTrend: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Streets',
                    value: '42',
                    icon: CupertinoIcons.map,
                    iconColor: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Active Events',
                    value: '8',
                    icon: CupertinoIcons.calendar,
                    iconColor: Color(0xFF007B3E),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Emergency Requests',
                    value: '3',
                    icon: CupertinoIcons.exclamationmark_circle_fill,
                    iconColor: Color(0xFFEF4444),
                    backgroundColor: Color(0xFFFEE2E2),
                    textColor: Color(0xFF991B1B),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            const Text(
              'QUICK ACTIONS',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.5),
            ),
            const SizedBox(height: 16),
            
            // Quick Action Buttons
            _buildQuickActionButton(
              label: 'Add Member',
              icon: CupertinoIcons.person_add_solid,
              backgroundColor: const Color(0xFF007B3E),
              textColor: Colors.white,
              onTap: () => Navigator.pushNamed(context, '/add_member'),
            ),
            const SizedBox(height: 12),
            _buildQuickActionButton(
              label: 'Broadcast',
              icon: CupertinoIcons.speaker_2_fill,
              backgroundColor: Colors.white,
              textColor: Color(0xFF1E293B),
              onTap: () => Navigator.pushNamed(context, '/requests'),
            ),
            const SizedBox(height: 12),
            _buildQuickActionButton(
              label: 'Emergency Alert',
              icon: CupertinoIcons.bolt_fill,
              backgroundColor: Colors.white,
              textColor: Color(0xFFEF4444),
              onTap: () {},
              iconColor: Color(0xFFEF4444),
            ),

            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECENT ACTIVITY',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.2),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All', style: TextStyle(color: Color(0xFF007B3E), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Recent Activity List (Keep existing or update if needed)
            _buildActivityItem('New Member: Sarah Chen joined', '10m ago', CupertinoIcons.person_add, Colors.blue),
            const SizedBox(height: 12),
            _buildActivityItem('Emergency Request: Blood needed', '25m ago', CupertinoIcons.exclamationmark_circle, Colors.red),
            const SizedBox(height: 12),
            _buildActivityItem('Event Update: AGM rescheduled', '1h ago', CupertinoIcons.calendar_today, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    String? trend,
    bool isPositiveTrend = false,
    IconData? icon,
    Color? iconColor,
    Color backgroundColor = Colors.white,
    Color textColor = const Color(0xFF0F172A),
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: backgroundColor == Colors.white ? const Color(0xFFE2E8F0) : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.7), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  if (trend != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPositiveTrend ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        trend,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPositiveTrend ? const Color(0xFF166534) : const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (icon != null)
                Icon(icon, color: iconColor, size: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: backgroundColor == Colors.white ? Border.all(color: const Color(0xFFE2E8F0)) : null,
          boxShadow: backgroundColor != Colors.white ? [
            BoxShadow(
              color: backgroundColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? textColor, size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            const Spacer(),
            Icon(CupertinoIcons.chevron_right, color: textColor.withOpacity(0.3), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B)),
                ),
                Text(
                  time,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }
}
