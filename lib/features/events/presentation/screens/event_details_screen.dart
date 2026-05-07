import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';

class EventDetailsScreen extends StatelessWidget {
  const EventDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            // Event Hero Image
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: const Icon(CupertinoIcons.photo, size: 64, color: Colors.grey),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildTag('Annual'),
                      const SizedBox(width: 8),
                      _buildTag('Meeting'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Annual General Meeting 2026',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildDetailTile(CupertinoIcons.calendar, 'Date & Time', 'Oct 15, 2026 • 10:00 AM - 04:00 PM'),
                  _buildDetailTile(CupertinoIcons.location, 'Location', 'Kalaignar Arangam, Teynampet, Chennai, Tamil Nadu.'),
                  _buildDetailTile(CupertinoIcons.person_3, 'Attendees', '450 Members registered'),
                  
                  const SizedBox(height: 32),
                  const Text('About Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text(
                    'The Annual General Meeting of the NTK Project will discuss the progress of community management, financial reports, and future goals for 2027. All members are requested to attend.',
                    style: TextStyle(fontSize: 15, color: Color(0xFF444444), height: 1.5),
                  ),
                  
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('REGISTER FOR EVENT'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF007B3E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF007B3E)),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF007B3E)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
