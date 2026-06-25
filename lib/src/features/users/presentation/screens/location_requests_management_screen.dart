import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:ntk_project/src/features/users/data/models/location_access_request.dart';
import 'package:ntk_project/src/features/users/domain/repositories/user_repository.dart';
import 'package:ntk_project/src/injection_container.dart' as di;

class LocationRequestsManagementScreen extends StatefulWidget {
  const LocationRequestsManagementScreen({super.key});

  @override
  State<LocationRequestsManagementScreen> createState() =>
      _LocationRequestsManagementScreenState();
}

class _LocationRequestsManagementScreenState
    extends State<LocationRequestsManagementScreen> {
  bool _isLoading = true;
  String? _error;
  List<LocationAccessRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = di.sl<UserRepository>();
      final requests = await repo.getPendingLocationAccessRequests();
      if (mounted) {
        setState(() {
          _requests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reviewRequest(
    int requestId,
    String action, {
    String? rejectionReason,
  }) async {
    try {
      final repo = di.sl<UserRepository>();
      final success = await repo.reviewLocationAccessRequest(
        requestId: requestId,
        action: action, // 'APPROVE' or 'REJECT'
        rejectionReason: rejectionReason,
      );
      if (success && mounted) {
        NTKSnackbar.showSuccess(
          context,
          message: 'Request ${action.toLowerCase()}d successfully',
        );
        _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        NTKSnackbar.showError(context, message: 'Error: $e');
      }
    }
  }

  void _promptRejectionReason(int requestId) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Request'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              hintText: 'Enter rejection reason',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  NTKSnackbar.showError(
                    context,
                    message: 'Rejection reason is required',
                  );
                  return;
                }
                Navigator.pop(context);
                _reviewRequest(requestId, 'REJECT', rejectionReason: reason);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Reject',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NTKColors.background,
      appBar: const NTKAppBar(
        title: 'Location Requests',
        subtitle: 'Review and Approve',
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState.loginData?.role?.toUpperCase() != 'SUPER_ADMIN') {
            return const Center(
              child: Text(
                'Permission Denied. Only Super Admins can access this screen.',
                style: TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null) {
            return Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            );
          }
          if (_requests.isEmpty) {
            return const Center(
              child: Text(
                'No pending requests',
                style: TextStyle(color: NTKColors.textSecondary),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadRequests,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final request = _requests[index];
                final user = request.user;
                final requestedLocations = request.requestedLocations
                    .map((e) => e.location?.name)
                    .whereType<String>()
                    .join(', ');

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: NTKColors.emerald50,
                              child: Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: NTKColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    user?.phone ?? '',
                                    style: const TextStyle(
                                      color: NTKColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          'Current Role:',
                          request.currentRole ?? 'None',
                        ),
                        _buildInfoRow('Requested Role:', request.requestedRole),
                        _buildInfoRow(
                          'Requested Locations:',
                          requestedLocations.isEmpty
                              ? 'None'
                              : requestedLocations,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Reason:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          request.reason ?? 'No reason provided',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  _promptRejectionReason(request.id),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  _reviewRequest(request.id, 'APPROVE'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: NTKColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: NTKColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
