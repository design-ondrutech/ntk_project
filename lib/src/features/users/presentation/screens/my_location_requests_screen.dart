import 'package:flutter/material.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/users/data/models/location_access_request.dart';
import 'package:ntk_project/src/features/users/domain/repositories/user_repository.dart';
import 'package:ntk_project/src/injection_container.dart' as di;

class MyLocationRequestsScreen extends StatefulWidget {
  const MyLocationRequestsScreen({super.key});

  @override
  State<MyLocationRequestsScreen> createState() => _MyLocationRequestsScreenState();
}

class _MyLocationRequestsScreenState extends State<MyLocationRequestsScreen> {
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
      final requests = await repo.getMyLocationAccessRequests();
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'PENDING':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NTKColors.background,
      appBar: const NTKAppBar(title: 'My Location Requests', subtitle: 'Role & Location Changes'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _requests.isEmpty
                  ? const Center(child: Text('You have no location requests.', style: TextStyle(color: NTKColors.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: _loadRequests,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final request = _requests[index];
                          final requestedLocations = request.requestedLocations.map((e) => e.location?.name).whereType<String>().join(', ');

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Requested Role: ${request.requestedRole}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(request.status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: _getStatusColor(request.status)),
                                        ),
                                        child: Text(
                                          request.status,
                                          style: TextStyle(
                                            color: _getStatusColor(request.status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Locations: ${requestedLocations.isEmpty ? 'N/A' : requestedLocations}',
                                    style: const TextStyle(color: NTKColors.textSecondary),
                                  ),
                                  if (request.reason != null && request.reason!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text('Reason: ${request.reason}'),
                                  ],
                                  if (request.status == 'REJECTED' && request.rejectionReason != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.info_outline, color: Colors.red, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Rejection Reason: ${request.rejectionReason}',
                                              style: const TextStyle(color: Colors.red, fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    'Date: ${request.createdAt ?? 'Unknown'}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
