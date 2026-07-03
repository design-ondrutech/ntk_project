import 'package:flutter/material.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/users/domain/repositories/user_repository.dart';
import 'package:ntk_project/src/features/users/data/models/user_location_assignment.dart';
import 'package:ntk_project/src/features/location/domain/repositories/location_repository.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
import 'package:ntk_project/src/injection_container.dart' as di;

class UserLocationsManagementScreen extends StatefulWidget {
  final int userId;

  const UserLocationsManagementScreen({super.key, required this.userId});

  @override
  State<UserLocationsManagementScreen> createState() =>
      _UserLocationsManagementScreenState();
}

class _UserLocationsManagementScreenState
    extends State<UserLocationsManagementScreen> {
  bool _isLoading = true;
  String? _error;
  List<UserLocationAssignment> _assignedLocations = [];

  // For adding new location
  bool _isAdding = false;
  String _selectedRoleForLocation =
      'ADMIN'; // used to filter Location type based on role context
  LocationModel? _selectedNewLocation;
  List<LocationModel> _availableLocations = [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = di.sl<UserRepository>();
      final locations = await repo.getUserAssignedLocations(
        userId: widget.userId,
      );
      if (mounted) {
        setState(() {
          _assignedLocations = locations;
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

  Future<void> _fetchAvailableLocations(String role) async {
    setState(() => _isAdding = true);
    try {
      String targetType;
      switch (role) {
        case 'ADMIN':
          targetType = 'DISTRICT';
          break;
        case 'SUB_ADMIN':
          targetType = 'TALUK';
          break;
        default:
          targetType = 'STREET';
      }
      final locRepo = di.sl<LocationRepository>();
      final locs = await locRepo.getLocationList(type: targetType);

      // Filter out already assigned locations
      final assignedIds = _assignedLocations.map((e) => e.locationId).toSet();
      _availableLocations = locs
          .where((l) => !assignedIds.contains(l.id))
          .toList();
      _selectedNewLocation = null;
    } catch (e) {
      NTKSnackbar.showError(context, message: 'Failed to fetch locations: $e');
    } finally {
      setState(() => _isAdding = false);
    }
  }

  Future<void> _assignLocation(bool isPrimary) async {
    if (_selectedNewLocation == null) return;

    setState(() => _isLoading = true);
    try {
      final repo = di.sl<UserRepository>();
      final success = await repo.assignUserLocations(
        userId: widget.userId,
        locationIds: [_selectedNewLocation!.id],
        isPrimary: isPrimary ? 1 : 0,
      );
      if (success) {
        NTKSnackbar.showSuccess(
          context,
          message: 'Location assigned successfully',
        );
        _selectedNewLocation = null;
        _availableLocations.clear();
        await _loadLocations();
      } else {
        NTKSnackbar.showError(context, message: 'Failed to assign location');
      }
    } catch (e) {
      NTKSnackbar.showError(context, message: 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmRemoveLocation(UserLocationAssignment assigned) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Location'),
          content: Text(
            'Are you sure you want to remove ${assigned.location?.name ?? 'this location'}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _removeLocation(assigned.locationId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeLocation(int locationId) async {
    setState(() => _isLoading = true);
    try {
      final repo = di.sl<UserRepository>();
      final success = await repo.removeUserLocation(
        userId: widget.userId,
        locationId: locationId,
      );
      if (success) {
        NTKSnackbar.showSuccess(
          context,
          message: 'Location removed successfully',
        );
        await _loadLocations();
      } else {
        NTKSnackbar.showError(context, message: 'Failed to remove location');
      }
    } catch (e) {
      NTKSnackbar.showError(context, message: 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddLocationDialog() async {
    _selectedRoleForLocation = 'ADMIN';
    _availableLocations.clear();
    _fetchAvailableLocations(_selectedRoleForLocation);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assign New Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Context Role',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedRoleForLocation,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: ['ADMIN', 'SUB_ADMIN']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() {
                          _selectedRoleForLocation = val;
                        });
                        _fetchAvailableLocations(val).then((_) {
                          setSheetState(() {});
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Select Location',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_isAdding)
                    const Center(child: CircularProgressIndicator())
                  else if (_availableLocations.isEmpty)
                    const Text(
                      'No locations available to assign.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    DropdownButtonFormField<LocationModel>(
                      value: _selectedNewLocation,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Choose a location'),
                      isExpanded: true,
                      items: _availableLocations
                          .map(
                            (loc) => DropdownMenuItem(
                              value: loc,
                              child: Text(loc.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setSheetState(() => _selectedNewLocation = val);
                        setState(() => _selectedNewLocation = val);
                      },
                    ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _selectedNewLocation == null
                            ? null
                            : () {
                                Navigator.pop(context);
                                // Defaulting to non-primary. Can expand UI if primary selection is needed.
                                _assignLocation(false);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NTKColors.primary,
                        ),
                        child: const Text('Assign Location'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NTKColors.background,
      appBar: const NTKAppBar(
        title: 'Manage Locations',
        subtitle: 'User Assigned Locations',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLocationDialog,
        backgroundColor: NTKColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : _assignedLocations.isEmpty
          ? const Center(
              child: Text(
                'No locations assigned.',
                style: TextStyle(color: NTKColors.textSecondary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadLocations,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _assignedLocations.length,
                itemBuilder: (context, index) {
                  final assigned = _assignedLocations[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: assigned.isPrimary
                            ? NTKColors.primary.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        child: Icon(
                          Icons.location_on,
                          color: assigned.isPrimary
                              ? NTKColors.primary
                              : Colors.grey,
                        ),
                      ),
                      title: Text(
                        assigned.location?.name ?? 'Unknown Location',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${assigned.location?.type ?? ''} ${assigned.isPrimary ? "(Primary)" : ""}'
                            .trim(),
                        style: TextStyle(
                          color: assigned.isPrimary
                              ? NTKColors.primary
                              : Colors.grey,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmRemoveLocation(assigned),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
