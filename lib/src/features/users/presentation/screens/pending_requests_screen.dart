import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/pending_requests_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_event.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  final Map<int, String> _processingRequests = {};

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final role = authState.loginData?.role ?? 'MEMBER';
    final dashState = context.read<DashboardBloc>().state;

    // Use globalLocation if set, otherwise fallback to role based defaults
    final locationId =
        dashState.globalLocation?.id ??
        (role == 'SUB_ADMIN' ? authState.loginData?.locationId : null);

    context.read<PendingRequestsBloc>().add(
      LoadPendingRequests(
        locationId: locationId,
        role: role == 'SUB_ADMIN' ? 'MEMBER' : 'All',
      ),
    );
  }

  Future<void> _updateStatus(int requestId, String status) async {
    if (_processingRequests.containsKey(requestId)) return;

    setState(() {
      _processingRequests[requestId] = status;
    });

    if (status == 'APPROVED') {
      context.read<PendingRequestsBloc>().add(
        ApproveRequest(id: requestId, type: 'Member'),
      );
    } else {
      context.read<PendingRequestsBloc>().add(
        RejectRequest(id: requestId, type: 'Member'),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    final date = DateTime.tryParse(dateString);
    if (date != null) {
      return 'Requested on ${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
    final fallback = dateString.split('T').first;
    return 'Requested on $fallback';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: NTKColors.background,
      appBar: NTKAppBar(
        title: 'Pending Requests',
        subtitle:
            context.read<AuthBloc>().state.loginData?.locationName ??
            'Admin Portal',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<PendingRequestsBloc, PendingRequestsState>(
        listener: (context, state) {
          if (state.message != null) {
            NTKSnackbar.showSuccess(context, message: state.message!);
            setState(() => _processingRequests.removeWhere((key, value) => true));
            final authState = context.read<AuthBloc>().state;
            final dashState = context.read<DashboardBloc>().state;
            context.read<DashboardBloc>().add(
              LoadDashboardStats(dashState.globalLocation?.id ?? authState.loginData?.locationId),
            );
          }
          if (state.error != null) {
            NTKSnackbar.showError(context, message: state.error!);
            setState(() => _processingRequests.removeWhere((key, value) => true));
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: NTKColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.error!.contains('SocketException') || state.error!.contains('Failed host lookup') || state.error!.contains('ClientException')
                          ? 'Network error. Please check your internet connection and try again.'
                          : (state.error!.contains('OperationException') 
                              ? 'An unexpected server error occurred. Please try again later.' 
                              : state.error!),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final authState = context.read<AuthBloc>().state;
                        final role = authState.loginData?.role ?? 'MEMBER';
                        final dashState = context.read<DashboardBloc>().state;

                        final locationId =
                            dashState.globalLocation?.id ??
                            (role == 'SUB_ADMIN'
                                ? authState.loginData?.locationId
                                : null);

                        context.read<PendingRequestsBloc>().add(
                          LoadPendingRequests(
                            locationId: locationId,
                            role: role == 'SUB_ADMIN' ? 'MEMBER' : 'All',
                          ),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state.requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.person_crop_circle_badge_checkmark,
                    size: 64,
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Pending Requests',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final authState = context.read<AuthBloc>().state;
              final role = authState.loginData?.role ?? 'MEMBER';
              final dashState = context.read<DashboardBloc>().state;

              final locationId =
                  dashState.globalLocation?.id ??
                  (role == 'SUB_ADMIN'
                      ? authState.loginData?.locationId
                      : null);

              context.read<PendingRequestsBloc>().add(
                LoadPendingRequests(
                  locationId: locationId,
                  role: role == 'SUB_ADMIN' ? 'MEMBER' : 'All',
                ),
              );
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: state.requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildRequestCard(state.requests[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(dynamic request) {
    final theme = Theme.of(context);
    final name = request.name ?? 'Unknown';
    final phone = request.phone ?? '';
    final location = request.location?.name ?? 'Unknown Location';
    final requestDate = request.createdAt as String?;

    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, '/profile', arguments: request.id);
        if (mounted) {
          final authState = context.read<AuthBloc>().state;
          final role = authState.loginData?.role ?? 'MEMBER';
          final dashState = context.read<DashboardBloc>().state;
          final locationId = dashState.globalLocation?.id ??
              (role == 'SUB_ADMIN' ? authState.loginData?.locationId : null);
          context.read<PendingRequestsBloc>().add(
            LoadPendingRequests(
              locationId: locationId,
              role: role == 'SUB_ADMIN' ? 'MEMBER' : 'All',
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: NTKColors.emerald50,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: const TextStyle(
                        color: NTKColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        location,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          phone,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            color: NTKColors.textTertiary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(requestDate),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 10,
                          color: NTKColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _processingRequests.containsKey(request.id)
                        ? null
                        : () => _updateStatus(request.id, 'REJECTED'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NTKColors.error,
                    ),
                    child: _processingRequests[request.id] == 'REJECTED'
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: NTKColors.error,
                            ),
                          )
                        : const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _processingRequests.containsKey(request.id)
                        ? null
                        : () => _updateStatus(request.id, 'APPROVED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NTKColors.primary,
                    ),
                    child: _processingRequests[request.id] == 'APPROVED'
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
