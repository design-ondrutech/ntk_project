import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class MembersListScreen extends StatelessWidget {
  const MembersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        leading: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B)),
        title: const Text('Members', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.bell, size: 22, color: Color(0xFF1E293B)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search members by name or street...',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      icon: Icon(CupertinoIcons.search, size: 18, color: Color(0xFF64748B)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Filters
                Row(
                  children: [
                    _buildFilterButton('All', isSelected: true, icon: CupertinoIcons.slider_horizontal_3),
                    const SizedBox(width: 12),
                    _buildFilterDropdown('Street'),
                    const SizedBox(width: 12),
                    _buildFilterDropdown('Blood Group'),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(child: _buildSummaryCard('TOTAL MEMBERS', '1,248')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSummaryCard('ACTIVE TODAY', '342')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Members List
                  _buildMemberCard(context,
                    name: 'Marcus Sterling',
                    address: 'Maplewood Drive',
                    role: 'Admin',
                    bloodGroup: 'B+',
                    status: 'Verified',
                    isOnline: true,
                  ),
                  const SizedBox(height: 16),
                  _buildMemberCard(context,
                    name: 'Sarah Chen',
                    address: 'Cedar Avenue',
                    role: 'Member',
                    bloodGroup: 'O-',
                    status: 'Volunteer',
                    isOnline: false,
                  ),
                  const SizedBox(height: 16),
                   _buildMemberCard(context,
                    name: 'David Miller',
                    address: 'Oak Street',
                    role: 'Admin',
                    bloodGroup: 'A+',
                    status: 'Verified',
                    isOnline: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, {bool isSelected = false, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF007B3E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? const Color(0xFF007B3E) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF64748B)),
          if (icon != null) const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          const Icon(CupertinoIcons.chevron_down, size: 12, color: Color(0xFF3B82F6)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, {
    required String name,
    required String address,
    required String role,
    required String bloodGroup,
    required String status,
    required bool isOnline,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/profile'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFF1F5F9),
                  child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF007B3E))),
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(role, style: const TextStyle(fontSize: 10, color: Color(0xFF1E40AF), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(address, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(bloodGroup, style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(status, style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                IconButton(icon: const Icon(CupertinoIcons.phone, size: 20, color: Color(0xFF007B3E)), onPressed: () {}),
                IconButton(icon: const Icon(CupertinoIcons.chat_bubble_text, size: 20, color: Color(0xFF007B3E)), onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
