import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';

class CommunityFeedScreen extends StatelessWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B)),
        title: const Text('Community', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF007B3E))),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(CupertinoIcons.bell_fill, color: Color(0xFF007B3E)),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                  ),
                ),
              ],
            ),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Post Input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const CircleAvatar(backgroundColor: Color(0xFFF0F0F0), child: Icon(CupertinoIcons.person_fill, color: Colors.grey)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text('Share something with community...', style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(CupertinoIcons.photo_fill, color: Color(0xFF007B3E)), onPressed: () {}),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Posts
          _buildPostCard(
            context,
            author: 'Senthamizhan S.',
            time: '3 hours ago',
            content: 'Great turn out at today\'s local meeting. Together we are stronger! 🐯 #NTK #TamilPride',
            hasImage: true,
            likes: 124,
            comments: 18,
          ),
          _buildPostCard(
            context,
            author: 'Meena R.',
            time: '5 hours ago',
            content: 'Please remember to register for the upcoming blood donation camp this weekend.',
            hasImage: false,
            likes: 45,
            comments: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, {
    required String author,
    required String time,
    required String content,
    required bool hasImage,
    required int likes,
    required int comments,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(backgroundColor: const Color(0xFF007B3E).withOpacity(0.1), child: Text(author[0], style: const TextStyle(color: Color(0xFF007B3E)))),
            title: Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(time, style: const TextStyle(fontSize: 12)),
            trailing: IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(content, style: const TextStyle(fontSize: 15, height: 1.4)),
          ),
          if (hasImage)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              color: Colors.grey.shade100,
              child: const Icon(CupertinoIcons.photo, size: 48, color: Colors.grey),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildPostAction(CupertinoIcons.heart, likes.toString()),
                const SizedBox(width: 24),
                _buildPostAction(CupertinoIcons.chat_bubble, comments.toString()),
                const Spacer(),
                IconButton(icon: const Icon(CupertinoIcons.share, size: 20), onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostAction(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF666666)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Color(0xFF666666), fontWeight: FontWeight.w600)),
      ],
    );
  }
}
