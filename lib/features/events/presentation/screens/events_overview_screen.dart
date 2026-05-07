import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class EventsOverviewScreen extends StatelessWidget {
  const EventsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Events', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.calendar_badge_plus, size: 22, color: Color(0xFF1E293B)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UPCOMING EVENTS',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.2),
            ),
            const SizedBox(height: 20),
            
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final titles = [
                  'Annual Town Hall 2024',
                  'Community Blood Drive',
                  'Regional Leadership Summit',
                  'Youth Welfare Workshop'
                ];
                final locations = [
                  'Civic Plaza',
                  'District Hospital',
                  'Convention Center',
                  'Community Hall'
                ];
                final times = ['18:00 - 20:30', '10:00 - 14:00', '09:00 - 17:00', '11:00 - 15:00'];
                
                return _buildEventCard(
                  context,
                  title: titles[index],
                  time: times[index],
                  location: locations[index],
                  attendeesCount: 124 + (index * 15),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, {
    required String title,
    required String time,
    required String location,
    required int attendeesCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/event_details'),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            
            // Time and Location Row
            Row(
              children: [
                Icon(CupertinoIcons.clock, size: 16, color: const Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(time, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                const SizedBox(width: 16),
                Icon(CupertinoIcons.location_solid, size: 16, color: const Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(location, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
              ],
            ),
            const SizedBox(height: 20),
            
            // Attendees Section
            Row(
              children: [
                _buildAvatarStack(),
                const SizedBox(width: 12),
                Text(
                  '+$attendeesCount attending',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Going',
                    icon: CupertinoIcons.check_mark_circled,
                    backgroundColor: const Color(0xFF007B3E),
                    textColor: Colors.white,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    label: 'Maybe',
                    icon: CupertinoIcons.question_circle,
                    backgroundColor: Colors.white,
                    textColor: const Color(0xFF1E293B),
                    borderColor: const Color(0xFFE2E8F0),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    label: 'No',
                    icon: CupertinoIcons.xmark_circle,
                    backgroundColor: Colors.white,
                    textColor: const Color(0xFF1E293B),
                    borderColor: const Color(0xFFE2E8F0),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStack() {
    return SizedBox(
      width: 80,
      height: 32,
      child: Stack(
        children: [
          _buildAvatar(0, 'https://i.pravatar.cc/100?img=1'),
          _buildAvatar(1, 'https://i.pravatar.cc/100?img=2'),
          _buildAvatar(2, 'https://i.pravatar.cc/100?img=3'),
        ],
      ),
    );
  }

  Widget _buildAvatar(int index, String url) {
    return Positioned(
      left: index * 20.0,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: CircleAvatar(
          radius: 14,
          backgroundImage: NetworkImage(url),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        side: borderColor != null ? BorderSide(color: borderColor) : BorderSide.none,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
