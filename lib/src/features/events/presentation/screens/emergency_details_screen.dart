import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/events/data/models/emergency_model.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_event.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_state.dart';
import 'package:ntk_project/src/features/events/presentation/screens/event_details_screen.dart'; // For DoughnutPainter
import 'package:ntk_project/src/features/events/domain/repositories/event_repository.dart';
import 'package:ntk_project/src/injection_container.dart';

class EmergencyDetailsScreen extends StatefulWidget {
  const EmergencyDetailsScreen({super.key});

  @override
  State<EmergencyDetailsScreen> createState() => _EmergencyDetailsScreenState();
}

class _EmergencyDetailsScreenState extends State<EmergencyDetailsScreen> {
  EmergencyModel? _alert;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_alert == null) {
      _alert = ModalRoute.of(context)?.settings.arguments as EmergencyModel?;
      if (_alert != null) {
        context.read<EventBloc>().add(
          FetchEmergencyResponses(emergencyRequestId: _alert!.id),
        );
        _loadEmergencyDetails();
      }
    }
  }

  Future<void> _loadEmergencyDetails() async {
    final alertId = _alert?.id;
    if (alertId == null || alertId.isEmpty) return;
    try {
      final details = await sl<EventRepository>().getEmergencyRequestDetails(
        id: alertId,
      );
      if (!mounted) return;
      setState(() => _alert = details);
    } catch (_) {
      // Keep the route argument data visible if the details endpoint is unavailable.
    }
  }

  String _formatDateTime(String? dt) {
    if (dt == null) return 'N/A';
    try {
      final date = DateTime.parse(dt);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final ampm = date.hour < 12 ? 'AM' : 'PM';
      final minute = date.minute.toString().padLeft(2, '0');
      return '${months[date.month - 1]} ${date.day}, ${date.year} • $hour:$minute $ampm';
    } catch (_) {
      return dt;
    }
  }

  void _onRespond(String status) {
    if (_alert != null) {
      context.read<EventBloc>().add(
        RespondToEmergency(emergencyRequestId: _alert!.id, status: status),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_alert == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No emergency data found')),
      );
    }

    final totalResponses = _alert!.going + _alert!.maybe + _alert!.notGoing;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Emergency Details'),
        actions: [
          IconButton(icon: const Icon(CupertinoIcons.share), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: NTKColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'URGENT REQUIRED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: NTKColors.error,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_alert!.title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _onRespond('UNABLE'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: NTKColors.error,
                            side: const BorderSide(
                              color: NTKColors.error,
                              width: 1.2,
                            ),
                            minimumSize: const Size(0, 48),
                          ),
                          child: const Text('NOT AVAILABLE'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _onRespond('COMING'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          child: const Text('I\'M AVAILABLE'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Emergency Info',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  _buildDetailTile(
                    context,
                    CupertinoIcons.person,
                    'Contact Person',
                    _alert!.contactName.isNotEmpty
                        ? _alert!.contactName
                        : 'N/A',
                  ),
                  _buildDetailTile(
                    context,
                    CupertinoIcons.phone,
                    'Contact Number',
                    _alert!.contactPhone.isNotEmpty
                        ? _alert!.contactPhone
                        : 'N/A',
                  ),
                  _buildDetailTile(
                    context,
                    CupertinoIcons.time,
                    'Expires On',
                    _formatDateTime(_alert!.expiryDate),
                  ),
                  _buildDetailTile(
                    context,
                    CupertinoIcons.location,
                    'Location',
                    _alert!.locationName,
                  ),

                  const SizedBox(height: 16),
                  Text(_alert!.description, style: theme.textTheme.bodyMedium),

                  const SizedBox(height: 32),
                  const Text(
                    'Responses Overview',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  if (totalResponses > 0)
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CustomPaint(
                            painter: DoughnutPainter(
                              going: _alert!.going,
                              maybe: _alert!.maybe,
                              notGoing: _alert!.notGoing,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLegendItem(
                                'Available',
                                _alert!.going,
                                totalResponses,
                                NTKColors.primary,
                              ),
                              const SizedBox(height: 8),
                              _buildLegendItem(
                                'Maybe',
                                _alert!.maybe,
                                totalResponses,
                                Colors.orange,
                              ),
                              const SizedBox(height: 8),
                              _buildLegendItem(
                                'Not Available',
                                _alert!.notGoing,
                                totalResponses,
                                NTKColors.error,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    const Text("No responses yet."),

                  const SizedBox(height: 32),

                  // View Responses Button (opens bottom sheet with tabs)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NTKColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _showResponsesSheet(context),
                      child: const Text(
                        'VIEW RESPONSES',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, int total, Color color) {
    final percentage = (count / total * 100).toStringAsFixed(0);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(
          '$count ($percentage%)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDetailTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: NTKColors.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: NTKColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showResponsesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return BlocBuilder<EventBloc, EventState>(
          bloc: context.read<EventBloc>(),
          builder: (context, state) {
            final goingList = state.emergencyResponses
                .where((r) => r.status == 'COMING' || r.status == 'GOING')
                .toList();
            final notGoingList = state.emergencyResponses
                .where((r) => r.status == 'UNABLE' || r.status == 'NOT_GOING')
                .toList();

            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Emergency Responses',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    labelColor: NTKColors.primary,
                    unselectedLabelColor: NTKColors.textSecondary,
                    indicatorColor: NTKColors.primary,
                    tabs: [
                      Tab(text: 'AVAILABLE (${goingList.length})'),
                      Tab(text: 'NOT AVAILABLE (${notGoingList.length})'),
                    ],
                  ),
                  Expanded(
                    child: state.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : TabBarView(
                            children: [
                              _buildMemberList(goingList),
                              _buildMemberList(notGoingList),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMemberList(List<EmergencyResponseModel> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No members found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final member = list[index].member;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: NTKColors.primary.withOpacity(0.1),
            child: Text(
              member.name[0].toUpperCase(),
              style: const TextStyle(color: NTKColors.primary),
            ),
          ),
          title: Text(
            member.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(member.phone),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  CupertinoIcons.phone_circle,
                  color: NTKColors.primary,
                  size: 28,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  CupertinoIcons.chat_bubble_2,
                  color: Colors.green,
                  size: 28,
                ),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }
}
