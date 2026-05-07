import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class RequestsBroadcastsScreen extends StatefulWidget {
  const RequestsBroadcastsScreen({super.key});

  @override
  State<RequestsBroadcastsScreen> createState() => _RequestsBroadcastsScreenState();
}

class _RequestsBroadcastsScreenState extends State<RequestsBroadcastsScreen> {
  int activeTab = 0; // 0 for All Messages, 1 for Emergency Alerts
  String selectedFilter = 'All Members';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Broadcast Update', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Input Card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9), // Light grey container
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildPill('All Members', isSelected: selectedFilter == 'All Members', icon: CupertinoIcons.person_3_fill),
                      const SizedBox(width: 8),
                      _buildPill('Emergency Team', isSelected: selectedFilter == 'Emergency Team', icon: CupertinoIcons.shield_fill),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPill('South District', isSelected: selectedFilter == 'South District', icon: CupertinoIcons.location_fill),
                  const SizedBox(height: 20),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const TextField(
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Type your broadcast message here...',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007B3E),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF007B3E).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(CupertinoIcons.paperplane_fill, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabItem('All Messages', isSelected: activeTab == 0, onTap: () => setState(() => activeTab = 0)),
                    ),
                    Expanded(
                      child: _buildTabItem('Emergency Alerts', isSelected: activeTab == 1, onTap: () => setState(() => activeTab = 1)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Broadcast List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final titles = ['Infrastructure Funding', 'Blocked Water Main Re', 'Volunteer Drive Req'];
                final statuses = ['PENDING', 'URGENT', 'SCHEDULED'];
                final locations = ['Civic Center, Zone 4', 'Maple Ave & 12th St', 'Community Hall'];
                final times = ['Oct 24, 2023 • 09:15 AM', 'Oct 23, 2023 • 04:30 PM', 'Oct 22, 2023 • 11:00 AM'];
                final icons = [CupertinoIcons.doc_text_fill, CupertinoIcons.exclamationmark_triangle_fill, CupertinoIcons.hand_raised_fill];
                final colors = [const Color(0xFF22C55E), const Color(0xFFEF4444), const Color(0xFF3B82F6)];

                return _buildBroadcastCard(
                  title: titles[index],
                  status: statuses[index],
                  location: locations[index],
                  time: times[index],
                  icon: icons[index],
                  color: colors[index],
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String label, {required bool isSelected, required IconData icon}) {
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007B3E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF007B3E) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, {required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildBroadcastCard({
    required String title,
    required String status,
    required String location,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 20, color: color),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(CupertinoIcons.location_fill, size: 12, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(location, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(CupertinoIcons.calendar, size: 12, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
