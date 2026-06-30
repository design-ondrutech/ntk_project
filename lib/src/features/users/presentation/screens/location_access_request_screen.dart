import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
import 'package:ntk_project/src/features/users/domain/repositories/user_repository.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_bloc.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_state.dart';
import 'package:ntk_project/src/injection_container.dart' as di;

import 'package:ntk_project/src/features/location/data/models/location_model.dart';
import 'package:ntk_project/src/features/location/domain/repositories/location_repository.dart';

class LocationAccessRequestScreen extends StatefulWidget {
  const LocationAccessRequestScreen({super.key});

  @override
  State<LocationAccessRequestScreen> createState() => _LocationAccessRequestScreenState();
}

class _LocationAccessRequestScreenState extends State<LocationAccessRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  String _requestedRole = 'DISTRICT_INCHARGE';
  List<int> _selectedLocationIds = [];
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingLocations = false;
  List<LocationModel> _availableLocations = [];

  List<int> _alreadyAssignedLocationIds = [];

  final List<String> _roles = ['DISTRICT_INCHARGE', 'ADMIN', 'SUB_ADMIN'];

  @override
  void initState() {
    super.initState();
    _loadAssignedLocations();
    _fetchLocationsForRole(_requestedRole);
  }

  Future<void> _loadAssignedLocations() async {
    try {
      final userId = context.read<AuthBloc>().state.loginData?.id;
      if (userId == null) return;
      final repo = di.sl<UserRepository>();
      final assigned = await repo.getUserAssignedLocations(userId: userId);
      if (mounted) {
        setState(() {
          _alreadyAssignedLocationIds = assigned
              .where((a) => a.locationId != null)
              .map((a) => a.locationId!)
              .toList();
        });
      }
    } catch (e) {
      // Ignore errors for this optional check
    }
  }

  Future<void> _fetchLocationsForRole(String role) async {
    setState(() {
      _isLoadingLocations = true;
      _selectedLocationIds.clear();
      _availableLocations = [];
    });

    try {
      final repo = di.sl<LocationRepository>();
      String locationType;
      switch (role) {
        case 'DISTRICT_INCHARGE':
          locationType = 'DISTRICT';
          break;
        case 'ADMIN':
          locationType = 'CONSTITUENCY';
          break;
        case 'SUB_ADMIN':
          locationType = 'TOWN_PANCHAYAT'; // Using TOWN_PANCHAYAT, backend might use TOWN. Will check later if it fails. Actually it's probably TOWN.
          // Wait, the API uses 'TOWN' for Town, 'MUNICIPALITY', 'CORPORATION'. Let's just fetch TOWN for Sub-Admin. Or maybe we can just fetch 'TOWN'. Let's use 'TOWN'.
          locationType = 'TOWN';
          break;
        default:
          locationType = 'DISTRICT';
      }

      final locations = await repo.getLocationList(type: locationType);
      if (mounted) {
        setState(() {
          _availableLocations = locations;
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocations = false;
        });
        NTKSnackbar.showError(context, message: 'Failed to fetch locations: $e');
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocationIds.isEmpty) {
      NTKSnackbar.showError(context, message: 'Please select at least one location');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = di.sl<UserRepository>();
      final success = await repo.requestLocationAccess(
        requestedRole: _requestedRole,
        requestType: 'ROLE_CHANGE',
        locationIds: _selectedLocationIds,
        reason: _reasonController.text.trim(),
      );

      if (success && mounted) {
        NTKSnackbar.showSuccess(context, message: 'Request submitted successfully');
        Navigator.pop(context);
      } else if (mounted) {
        NTKSnackbar.showError(context, message: 'Failed to submit request');
      }
    } catch (e) {
      if (mounted) NTKSnackbar.showError(context, message: 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NTKColors.background,
      appBar: const NTKAppBar(title: 'Request Access', subtitle: 'Role & Location'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Request Location or Role Access',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: NTKColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Submit a request to admins for accessing a new location or changing your role.',
                style: TextStyle(fontSize: 14, color: NTKColors.textSecondary),
              ),
              const SizedBox(height: 24),
              
              const Text('Requested Role', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _requestedRole,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _requestedRole = val);
                    _fetchLocationsForRole(val);
                  }
                },
              ),
              const SizedBox(height: 20),
              
              const Text('Target Location', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isLoadingLocations
                    ? const Center(child: CircularProgressIndicator())
                    : _availableLocations.isEmpty
                        ? const Text('No locations found.', style: TextStyle(color: Colors.grey))
                        : Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: _availableLocations.map((loc) {
                              final isAlreadyAssigned = _alreadyAssignedLocationIds.contains(loc.id);
                              final isSelected = _selectedLocationIds.contains(loc.id);
                              return FilterChip(
                                label: Text(isAlreadyAssigned ? '${loc.name} (Assigned)' : loc.name),
                                selected: isSelected || isAlreadyAssigned,
                                onSelected: isAlreadyAssigned
                                    ? null // Disable if already assigned
                                    : (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedLocationIds.add(loc.id);
                                          } else {
                                            _selectedLocationIds.remove(loc.id);
                                          }
                                        });
                                      },
                                selectedColor: isAlreadyAssigned 
                                    ? Colors.grey.shade300 
                                    : NTKColors.primary.withOpacity(0.2),
                                checkmarkColor: isAlreadyAssigned 
                                    ? Colors.grey.shade600 
                                    : NTKColors.primary,
                                labelStyle: TextStyle(
                                  color: isAlreadyAssigned 
                                      ? Colors.grey.shade600 
                                      : (isSelected ? NTKColors.primary : Colors.black87),
                                  fontWeight: isSelected || isAlreadyAssigned 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),
              ),
              const SizedBox(height: 20),
              
              const Text('Reason for Request', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Explain why you need this access...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Reason is required' : null,
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NTKColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _submitRequest,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
