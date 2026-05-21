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
  final TextEditingController _messageController = TextEditingController();
  String _selectedTarget = 'All Members';
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Compose Section ────────────────────────────────
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Target Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTargetChip('All Members', Icons.people_alt, _selectedTarget == 'All Members'),
                        const SizedBox(width: 10),
                        _buildTargetChip('Emergency Team', Icons.shield_outlined, _selectedTarget == 'Emergency Team'),
                        const SizedBox(width: 10),
                        _buildTargetChip('South District', Icons.location_on_outlined, _selectedTarget == 'South District'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Message Input
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _messageController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Type your broadcast message here...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF065F46),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                              onPressed: () {
                                final message = _messageController.text.trim();
                                if (message.isEmpty) return;

                                final type = _selectedTarget == 'Emergency Team' ? 'EMERGENCY' : 'NORMAL';
                                final audience = _selectedTarget == 'Emergency Team' ? 'EMERGENCY_TEAM' : 'ALL_MEMBERS';

                                // TODO: Get actual locationId from user state if available
                                const locationId = 1; 

                                context.read<RequestBloc>().add(
                                  CreateRequest(
                                    title: message,
                                    description: '',
                                    type: type,
                                    locationId: locationId,
                                    audience: audience,
                                  ),
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Broadcast sent successfully!')),
                                );
                                _messageController.clear();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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
            BlocBuilder<RequestBloc, RequestState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state.error != null) {
                  return Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: Text('Error: ${state.error}')),
                  );
                }
                
                final requests = state.requests.where((r) {
                  if (_selectedTab == 'Emergency Alerts') {
                    return r.type == 'EMERGENCY';
                  }
                  return true;
                }).toList();

                if (requests.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: Text('No requests found')),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
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
            const SizedBox(height: 30),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildTargetChip(String label, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTarget = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF065F46) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFDBEAFE)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF1E293B)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
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
