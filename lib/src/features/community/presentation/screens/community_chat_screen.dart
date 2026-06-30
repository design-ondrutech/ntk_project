import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/community/data/models/community_model.dart';
import 'package:ntk_project/src/features/community/data/models/community_message_model.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_chat_bloc.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_chat_event.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_chat_state.dart';
import 'package:ntk_project/src/features/community/presentation/screens/starred_messages_screen.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:ntk_project/l10n/app_localizations.dart';

class CommunityChatScreen extends StatefulWidget {
  final CommunityModel community;
  final bool showAppBar;

  const CommunityChatScreen({
    Key? key,
    required this.community,
    this.showAppBar = true,
  }) : super(key: key);

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final token = context.read<AuthBloc>().state.loginData?.token ?? '';
    final bloc = context.read<CommunityChatBloc>();
    bloc.add(ConnectChatSocket(widget.community.id, token));
    bloc.add(FetchCommunityMessagesEvent(widget.community.id));

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<CommunityChatBloc>().state;
      if (!state.isLoading && state.messages.isNotEmpty) {
        // Find oldest message ID for pagination (assuming messages are sorted descending)
        final oldestId = state.messages.last.id;
        // Commenting out pagination for now to prevent infinite loops, can be added later
        // context.read<CommunityChatBloc>().add(FetchCommunityMessagesEvent(widget.community.id, beforeMessageId: oldestId));
      }
    }
  }

  @override
  void dispose() {
    context.read<CommunityChatBloc>().add(DisconnectChatSocket());
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<CommunityChatBloc>().add(
      SendCommunityMessageEvent(
        communityId: widget.community.id,
        message: text,
      ),
    );
    _messageController.clear();
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateHelper.parseUtcToLocal(isoDate);
      return DateFormat.jm().format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthBloc>().state.loginData?.id;
    final myName = context.watch<AuthBloc>().state.loginData?.name;

    final body = Container(
      color: const Color(0xFFEFEFEF),
      child: Column(
        children: [
          Expanded(
            child: BlocConsumer<CommunityChatBloc, CommunityChatState>(
              listener: (context, state) {
                if (state.error != null) {
                  NTKSnackbar.showError(
                    context,
                    message:
                        'செய்திகளைப் பெறுவதில் பிழை ஏற்பட்டது. தயவுசெய்து மீண்டும் முயற்சிக்கவும்.',
                  );
                }
              },
              builder: (context, state) {
                if (state.isLoading && state.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'சமூகத்திற்கு வரவேற்கிறோம்! முதல் செய்தியை அனுப்புங்கள்.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: NTKColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Messages appear from bottom up
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    final isMe = message.senderId == myId || message.senderName == 'Me' || message.senderName == myName;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          if (widget.community.isArchived)
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFFFFBEB),
              width: double.infinity,
              child: Row(
                children: [
                  const Icon(Icons.archive_rounded, color: Color(0xFFD97706)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)?.communityArchivedMessage ?? 'This community is archived. You can read previous messages, but cannot send new ones.',
                      style: const TextStyle(color: Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          else
            _buildMessageComposer(),
        ],
      ),
    );

    if (!widget.showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: NTKAppBar(
        title: widget.community.name,
        subtitle: 'Community Chat',
        actions: [
          IconButton(
            icon: const Icon(Icons.star, color: Colors.amber),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StarredMessagesScreen(communityId: widget.community.id),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFEFEFEF),
      body: body,
    );
  }

  Color _getSenderColor(String name) {
    final colors = [
      Colors.red[700]!,
      Colors.blue[700]!,
      Colors.green[700]!,
      Colors.orange[700]!,
      Colors.purple[700]!,
      Colors.teal[700]!,
      Colors.pink[700]!,
      Colors.indigo[700]!,
    ];
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }

  Widget _buildMessageBubble(CommunityMessageModel message, bool isMe) {
    if (message.isDeleted) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 0.8),
          ),
          child: const Text(
            '🚫 This message was deleted',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: () {
        _showMessageOptions(context, message, isMe);
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFDCFCE7) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 16),
            ),
            border: Border.all(
              color: isMe ? const Color(0xFFBBF7D0) : const Color(0xFFE5E7EB),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getSenderColor(message.senderName),
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                _buildMessageContent(message, isMe),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.isStarred)
                        const Padding(
                          padding: EdgeInsets.only(right: 4.0),
                          child: Icon(Icons.star, size: 14, color: Colors.amber),
                        ),
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          color: isMe
                              ? const Color(0xFF166534).withOpacity(0.7)
                              : const Color(0xFF6B7280),
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.readByCount > 0 ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.readByCount > 0
                              ? Colors.blue[600]
                              : const Color(0xFF166534).withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, CommunityMessageModel message, bool isMe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.isStarred)
                ListTile(
                  leading: const Icon(Icons.star_border),
                  title: const Text('Unstar Message'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<CommunityChatBloc>().add(UnstarMessageEvent(message.id));
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: const Text('Star Message'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<CommunityChatBloc>().add(StarMessageEvent(message.id));
                  },
                ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Message', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<CommunityChatBloc>().add(DeleteMessageEvent(message.id));
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageContent(CommunityMessageModel message, bool isMe) {
    final type = message.messageType.toUpperCase();
    switch (type) {
      case 'IMAGE':
        return _buildImageMessage(message, isMe);
      case 'VIDEO':
        return _buildVideoMessage(message, isMe);
      case 'AUDIO':
        return _buildAudioMessage(message, isMe);
      case 'FILE':
      case 'DOCUMENT':
        return _buildFileMessage(message, isMe);
      case 'CONTACT':
        return _buildContactMessage(message, isMe);
      case 'EVENT':
        return _buildEventMessage(message, isMe);
      case 'POLL':
        return _buildPollMessage(message, isMe);
      default:
        return _buildTextMessage(message, isMe);
    }
  }

  Widget _buildTextMessage(CommunityMessageModel message, bool isMe) {
    return Text(
      message.message,
      style: TextStyle(
        color: isMe ? const Color(0xFF14532D) : const Color(0xFF1F2937),
        fontSize: 15,
      ),
    );
  }

  Widget _buildImageMessage(CommunityMessageModel message, bool isMe) {
    final url = message.mediaUrl;
    if (url == null || url.isEmpty) {
      return _buildTextMessage(message, isMe);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _launchURL(url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: url.startsWith('http')
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: 200,
                    height: 150,
                    errorBuilder: (_, __, ___) => Container(
                      width: 200,
                      height: 150,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
          ),
        ),
        if (message.message.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            message.message,
            style: TextStyle(
              color: isMe ? const Color(0xFF14532D) : const Color(0xFF1F2937),
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVideoMessage(CommunityMessageModel message, bool isMe) {
    final url = message.mediaUrl;
    if (url == null || url.isEmpty) {
      return _buildTextMessage(message, isMe);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _launchURL(url),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.video_library,
                  color: Colors.white24,
                  size: 48,
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.8),
                radius: 20,
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        if (message.message.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            message.message,
            style: TextStyle(
              color: isMe ? const Color(0xFF14532D) : const Color(0xFF1F2937),
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAudioMessage(CommunityMessageModel message, bool isMe) {
    final url = message.mediaUrl;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFBBF7D0).withOpacity(0.3) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.audiotrack,
            color: isMe ? const Color(0xFF166534) : NTKColors.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fileName ?? 'Audio Attachment',
                  style: TextStyle(
                    color: isMe ? const Color(0xFF14532D) : const Color(0xFF1F2937),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  message.message.isNotEmpty ? message.message : 'Audio',
                  style: TextStyle(
                    color: isMe ? const Color(0xFF166534).withOpacity(0.8) : Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (url != null && url.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.play_circle_outline,
                color: isMe ? const Color(0xFF166534) : NTKColors.primary,
              ),
              onPressed: () => _launchURL(url),
            ),
        ],
      ),
    );
  }

  Widget _buildFileMessage(CommunityMessageModel message, bool isMe) {
    final url = message.mediaUrl;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFBBF7D0).withOpacity(0.3) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file,
            color: isMe ? const Color(0xFF166534) : NTKColors.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fileName ?? 'Document',
                  style: TextStyle(
                    color: isMe ? const Color(0xFF14532D) : const Color(0xFF1F2937),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  message.message.isNotEmpty
                      ? message.message
                      : 'File Attachment',
                  style: TextStyle(
                    color: isMe ? const Color(0xFF166534).withOpacity(0.8) : Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (url != null && url.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.download,
                color: isMe ? const Color(0xFF166534) : NTKColors.primary,
              ),
              onPressed: () => _launchURL(url),
            ),
        ],
      ),
    );
  }

  Widget _buildContactMessage(CommunityMessageModel message, bool isMe) {
    Map<String, dynamic>? contactData;
    if (message.metadata != null) {
      try {
        contactData = jsonDecode(message.metadata!) as Map<String, dynamic>;
      } catch (_) {}
    }

    if (contactData == null) {
      return _buildTextMessage(message, isMe);
    }

    final name = contactData['contactName'] ?? 'Unknown Contact';
    final phone = contactData['contactPhone'] ?? '';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFBBF7D0).withOpacity(0.3) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isMe ? const Color(0xFFBBF7D0) : Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isMe ? const Color(0xFFBBF7D0) : NTKColors.emerald50,
                child: Icon(
                  Icons.person,
                  color: isMe ? const Color(0xFF166534) : NTKColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isMe ? const Color(0xFF14532D) : const Color(0xFF1F2937),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        style: TextStyle(
                          color: isMe ? const Color(0xFF166534).withOpacity(0.8) : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => _launchURL('tel:$phone'),
              icon: Icon(
                Icons.phone,
                size: 16,
                color: isMe ? const Color(0xFF166534) : NTKColors.primary,
              ),
              label: Text(
                'Call Contact',
                style: TextStyle(
                  color: isMe ? const Color(0xFF166534) : NTKColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventMessage(CommunityMessageModel message, bool isMe) {
    Map<String, dynamic>? eventData;
    if (message.metadata != null) {
      try {
        eventData = jsonDecode(message.metadata!) as Map<String, dynamic>;
      } catch (_) {}
    }

    if (eventData == null) {
      return _buildTextMessage(message, isMe);
    }

    final title = eventData['eventTitle'] ?? 'Event Invitation';
    final eventId = eventData['eventId'];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFBBF7D0).withOpacity(0.3) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isMe ? const Color(0xFFBBF7D0) : Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event,
                color: isMe ? const Color(0xFF166534) : NTKColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EVENT INVITATION',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        color: isMe ? const Color(0xFF14532D) : const Color(0xFF1F2937),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (eventId != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/event_details',
                  arguments: eventId,
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View Event Details →',
                style: TextStyle(
                  color: isMe ? const Color(0xFF166534) : NTKColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPollMessage(CommunityMessageModel message, bool isMe) {
    Map<String, dynamic>? pollData;
    if (message.metadata != null) {
      try {
        pollData = jsonDecode(message.metadata!) as Map<String, dynamic>;
      } catch (_) {}
    }

    final question = pollData?['question'] ?? message.message;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFBBF7D0).withOpacity(0.3) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isMe ? const Color(0xFFBBF7D0) : Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: isMe ? const Color(0xFF166534) : NTKColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GROUP POLL',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                    Text(
                      question,
                      style: TextStyle(
                        color: isMe ? const Color(0xFF14532D) : const Color(0xFF1F2937),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Go to Polls Tab to Vote →',
              style: TextStyle(
                color: isMe ? const Color(0xFF166534) : NTKColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.grey),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                  ),
                  maxLines: 4,
                  minLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: NTKColors.primary,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
