import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/community/data/models/community_message_model.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';
import 'package:intl/intl.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';

class StarredMessagesScreen extends StatefulWidget {
  final int communityId;

  const StarredMessagesScreen({Key? key, required this.communityId}) : super(key: key);

  @override
  State<StarredMessagesScreen> createState() => _StarredMessagesScreenState();
}

class _StarredMessagesScreenState extends State<StarredMessagesScreen> {
  List<CommunityMessageModel> _messages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStarredMessages();
  }

  Future<void> _fetchStarredMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = context.read<CommunityRepository>();
      final messages = await repo.getCommunityStarredMessages(communityId: widget.communityId);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _unstarMessage(int messageId) async {
    try {
      final repo = context.read<CommunityRepository>();
      await repo.unstarCommunityMessage(messageId: messageId);
      setState(() {
        _messages.removeWhere((m) => m.id == messageId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unstar message: $e')),
        );
      }
    }
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateHelper.parseUtcToLocal(isoDate);
      return DateFormat('MMM d, yyyy - jm').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: const NTKAppBar(
        title: 'Starred Messages',
        subtitle: 'Important saved messages',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A3D28)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchStarredMessages,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No starred messages yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(0xFFEAF6EF),
                                      child: const Icon(Icons.person, color: Color(0xFF0F8A4B), size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message.senderName,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            _formatTime(message.createdAt),
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.star, color: Colors.amber),
                                      onPressed: () => _unstarMessage(message.id),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  message.message,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
