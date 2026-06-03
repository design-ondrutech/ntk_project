import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/request_bloc.dart';
import 'package:ntk_project/src/injection_container.dart';

class RequestsBroadcastsScreen extends StatefulWidget {
  const RequestsBroadcastsScreen({super.key});

  @override
  State<RequestsBroadcastsScreen> createState() => _RequestsBroadcastsScreenState();
}

class _RequestsBroadcastsScreenState extends State<RequestsBroadcastsScreen> {
  String _selectedTab = 'All Messages';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocProvider(
      create: (context) => sl<RequestBloc>()..add(const LoadRequests()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: NTKAppBar(
          title: 'Broadcast Update',
          subtitle: context.read<AuthBloc>().state.loginData?.locationName ?? 'Tamil Nadu',
        ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // ── Tabs Section ──────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTab('All Messages', true),
                _buildTab('Emergency Alerts', false),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── History List ───────────────────────────────────
          Expanded(
            child: BlocBuilder<RequestBloc, RequestState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.error != null) {
                  return Center(child: Text('Error: ${state.error}'));
                }
                
                final requests = state.requests.where((r) {
                  if (_selectedTab == 'Emergency Alerts') {
                    return r.type == 'EMERGENCY';
                  }
                  return true;
                }).toList();

                final userRole = context.read<AuthBloc>().state.loginData?.role ?? 'MEMBER';
                final canCreate = userRole != 'MEMBER';

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: requests.length + 1, // +1 for header
                  separatorBuilder: (context, index) =>
                      index == 0 ? const SizedBox() : const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Broadcasts',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            if (canCreate)
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/create_announcement');
                                },
                                icon: const Icon(
                                  CupertinoIcons.plus,
                                  size: 16,
                                  color: Color(0xFF1E293B),
                                ),
                                label: const Text(
                                  'Create Broadcast',
                                  style: TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }
                    if (requests.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: Text('No requests found')),
                      );
                    }
                    
                    final request = requests[index - 1];
                    return _buildBroadcastItem(
                      request.title,
                      request.locationName ?? 'Unknown Location',
                      request.createdAt ?? 'Unknown Time',
                      request.status,
                      request.type == 'EMERGENCY' ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                      request.type == 'EMERGENCY' ? Icons.warning_amber_rounded : Icons.description_outlined,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }


  Widget _buildTab(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF64748B),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBroadcastItem(String title, String location, String time, String status, Color statusColor, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        fontSize: 15,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(location, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(time, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
