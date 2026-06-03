import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/events/data/models/event_model.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_state.dart';
import 'package:url_launcher/url_launcher.dart';

class EventResponsesScreen extends StatefulWidget {
  const EventResponsesScreen({super.key});

  @override
  State<EventResponsesScreen> createState() => _EventResponsesScreenState();
}

class _EventResponsesScreenState extends State<EventResponsesScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Future<void> _launchAction(String? phone, String scheme) async {
    final cleanPhone = phone?.replaceAll(RegExp(r'\s+'), '');
    if (cleanPhone == null || cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    if (scheme == 'whatsapp') {
      var finalPhone = cleanPhone;
      if (!finalPhone.startsWith('+') && finalPhone.length == 10) {
        finalPhone = '91$finalPhone';
      }
      final url = 'https://wa.me/$finalPhone';
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open WhatsApp')),
        );
      }
    } else {
      final uri = Uri(scheme: scheme, path: cleanPhone);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              scheme == 'tel'
                  ? 'Unable to open phone dialer'
                  : 'Unable to open messaging app',
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = ModalRoute.of(context)?.settings.arguments as EventModel?;
    if (event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Responses')),
        body: const Center(child: Text('No event specified')),
      );
    }

    return BlocBuilder<EventBloc, EventState>(
      builder: (context, state) {
        final goingList = state.eventResponses
            .where((r) => r.status == 'GOING')
            .map((r) => r.member)
            .where(
              (m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

        final maybeList = state.eventResponses
            .where((r) => r.status == 'MAYBE')
            .map((r) => r.member)
            .where(
              (m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

        final notGoingList = state.eventResponses
            .where((r) => r.status == 'NOT_GOING')
            .map((r) => r.member)
            .where(
              (m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0A7E3E),
              foregroundColor: Colors.white,
              title: Text(
                event.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
              bottom: TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'Attend (${goingList.length})'),
                  Tab(text: 'Maybe (${maybeList.length})'),
                  Tab(text: 'Not Attend (${notGoingList.length})'),
                ],
              ),
            ),
            body: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.search,
                                color: Color(0xFF6B7280),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    hintText: 'Search member...',
                                    border: InputBorder.none,
                                    isDense: true,
                                    filled: false,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _searchQuery = val;
                                    });
                                  },
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  child: const Icon(
                                    CupertinoIcons.clear_circled_solid,
                                    color: Color(0xFF9CA3AF),
                                    size: 18,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            CupertinoIcons.slider_horizontal_3,
                            color: Color(0xFF6B7280),
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab content
                Expanded(
                  child: state.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                              Color(0xFF0A7E3E),
                            ),
                          ),
                        )
                      : TabBarView(
                          children: [
                            _buildMemberList(goingList),
                            _buildMemberList(maybeList),
                            _buildMemberList(notGoingList),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemberList(List<EventMemberModel> members) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.person_3, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching members'
                  : 'No responses yet',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final member = members[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3F4F6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF0A7E3E).withOpacity(0.1),
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Color(0xFF0A7E3E),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.phone,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.phone_fill,
                        color: Color(0xFF0A7E3E),
                        size: 18,
                      ),
                    ),
                    onPressed: () => _launchAction(member.phone, 'tel'),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.chat_bubble_fill,
                        color: Colors.green,
                        size: 18,
                      ),
                    ),
                    onPressed: () => _launchAction(member.phone, 'whatsapp'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
