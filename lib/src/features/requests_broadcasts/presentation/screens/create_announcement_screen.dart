import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_event.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_state.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';
import 'package:ntk_project/src/features/location/domain/repositories/location_repository.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/request_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:ntk_project/src/injection_container.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // Emergency Form State
  String _activeFormType = 'BROADCAST'; // 'BROADCAST' or 'EMERGENCY'
  String _selectedEmergencyType = 'BLOOD_REQUIRED';
  final TextEditingController _emergencyTitleController =
      TextEditingController();
  final TextEditingController _emergencyDescriptionController =
      TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  
  // Type-specific field controllers
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _unitsRequiredController = TextEditingController();
  final TextEditingController _hospitalNameController = TextEditingController();
  final TextEditingController _patientConditionController = TextEditingController();
  final TextEditingController _disasterTypeController = TextEditingController();
  final TextEditingController _affectedAreaController = TextEditingController();
  final TextEditingController _requiredSupportController = TextEditingController();
  final TextEditingController _volunteerTypeController = TextEditingController();
  final TextEditingController _volunteerLocationController = TextEditingController();
  final TextEditingController _volunteerContactDetailsController = TextEditingController();

  DateTime? _selectedExpiryDateTime;
  bool _collectResponse = true;

  // Focus Nodes to keep cursor focus persistent and stable across rebuilds
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _messageFocusNode = FocusNode();
  final FocusNode _emergencyTitleFocusNode = FocusNode();
  final FocusNode _emergencyDescriptionFocusNode = FocusNode();
  final FocusNode _contactNameFocusNode = FocusNode();
  final FocusNode _contactPhoneFocusNode = FocusNode();

  List<LocationModel> _districts = [];
  LocationModel? _selectedDistrict;
  bool _loadingDistricts = false;

  List<LocationModel> _constituencies = [];
  LocationModel? _selectedConstituency;
  bool _loadingConstituencies = false;

  List<LocationModel> _areas = [];
  LocationModel? _selectedArea;
  bool _loadingAreas = false;

  List<LocationModel> _streets = [];
  LocationModel? _selectedStreet;
  bool _loadingStreets = false;
  bool _isLocationInitialized = false;

  @override
  void initState() {
    super.initState();
    context.read<RequestBloc>().add(ClearSubmitStatus());
    context.read<EventBloc>().add(const ClearEventMessage());
    context.read<EventBloc>().add(const ClearEventError());
    final authState = context.read<AuthBloc>().state;
    final userRole = authState.loginData?.role ?? 'MEMBER';
    if (userRole == 'MEMBER') {
      _activeFormType = 'EMERGENCY';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocationSelectors();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _emergencyTitleController.dispose();
    _emergencyDescriptionController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    
    // Dispose type-specific controllers
    _bloodGroupController.dispose();
    _unitsRequiredController.dispose();
    _hospitalNameController.dispose();
    _patientConditionController.dispose();
    _disasterTypeController.dispose();
    _affectedAreaController.dispose();
    _requiredSupportController.dispose();
    _volunteerTypeController.dispose();
    _volunteerLocationController.dispose();
    _volunteerContactDetailsController.dispose();

    _titleFocusNode.dispose();
    _messageFocusNode.dispose();
    _emergencyTitleFocusNode.dispose();
    _emergencyDescriptionFocusNode.dispose();
    _contactNameFocusNode.dispose();
    _contactPhoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initLocationSelectors() async {
    final authState = context.read<AuthBloc>().state;
    final role = authState.loginData?.role;
    if (role == null) return;
    if (_isLocationInitialized) return;
    _isLocationInitialized = true;

    final authLocationId = authState.loginData?.locationId;
    final globalLocation =
        context.read<DashboardBloc>().state.globalLocation;

    if (role == 'SUPER_ADMIN') {
      await _loadDistricts();
      if (globalLocation != null) {
        setState(() => _selectedDistrict = globalLocation);
        await _loadConstituencies(globalLocation.id);
      }
    } else if (role == 'ADMIN' && authLocationId != null) {
      final assignedConstituency = LocationModel(
        id: authLocationId,
        name: authState.loginData?.locationName ?? 'Assigned Constituency',
      );
      setState(() {
        _selectedConstituency = assignedConstituency;
        _constituencies = [assignedConstituency];
      });
      await _loadAreas(authLocationId);
      if (globalLocation != null) {
        setState(() => _selectedArea = globalLocation);
        await _loadStreets(globalLocation.id);
      }

      // Fetch parent district
      try {
        final districts = await sl<LocationRepository>().getLocationList(
          type: 'DISTRICT',
        );
        for (final district in districts) {
          final taluks = await sl<LocationRepository>().getLocationList(
            parentId: district.id,
            type: 'TALUK',
          );
          if (taluks.any((t) => t.id == authLocationId)) {
            if (mounted) {
              setState(() {
                _selectedDistrict = district;
                _districts = [district];
              });
            }
            break;
          }
        }
      } catch (e) {
        debugPrint('Error finding parent district: $e');
      }
    } else if (role == 'SUB_ADMIN' && authLocationId != null) {
      final assignedArea = LocationModel(
        id: authLocationId,
        name: authState.loginData?.locationName ?? 'Assigned Area',
      );
      setState(() {
        _selectedArea = assignedArea;
        _areas = [assignedArea];
      });
      await _loadStreets(authLocationId);
      if (globalLocation != null) {
        setState(() => _selectedArea = globalLocation);
        await _loadStreets(globalLocation.id);
      }

      try {
        final districts = await sl<LocationRepository>().getLocationList(
          type: 'DISTRICT',
        );
        bool found = false;
        for (final district in districts) {
          final taluks = await sl<LocationRepository>().getLocationList(
            parentId: district.id,
            type: 'TALUK',
          );
          for (final taluk in taluks) {
            final areas = await sl<LocationRepository>().getLocationList(
              parentId: taluk.id,
              type: 'AREA',
            );
            if (areas.any((a) => a.id == authLocationId)) {
              if (mounted) {
                setState(() {
                  _selectedDistrict = district;
                  _districts = [district];
                  _selectedConstituency = taluk;
                  _constituencies = [taluk];
                });
              }
              found = true;
              break;
            }
          }
          if (found) break;
        }
      } catch (e) {
        debugPrint('Error finding parent district/taluk: $e');
      }
    } else if (role == 'MEMBER' && authLocationId != null) {
      final assignedStreet = LocationModel(
        id: authLocationId,
        name: authState.loginData?.locationName ?? 'Assigned Street',
      );
      setState(() {
        _selectedStreet = assignedStreet;
        _streets = [assignedStreet];
      });

      // Traverse up parent hierarchy for member (Street -> Area -> Taluk -> District)
      try {
        final districts = await sl<LocationRepository>().getLocationList(
          type: 'DISTRICT',
        );
        bool found = false;
        for (final district in districts) {
          final taluks = await sl<LocationRepository>().getLocationList(
            parentId: district.id,
            type: 'TALUK',
          );
          for (final taluk in taluks) {
            final areas = await sl<LocationRepository>().getLocationList(
              parentId: taluk.id,
              type: 'AREA',
            );
            for (final area in areas) {
              final streets = await sl<LocationRepository>().getLocationList(
                parentId: area.id,
                type: 'STREET',
              );
              if (streets.any((s) => s.id == authLocationId)) {
                if (mounted) {
                  setState(() {
                    _selectedDistrict = district;
                    _districts = [district];
                    _selectedConstituency = taluk;
                    _constituencies = [taluk];
                    _selectedArea = area;
                    _areas = [area];
                  });
                }
                found = true;
                break;
              }
            }
            if (found) break;
          }
          if (found) break;
        }
      } catch (e) {
        debugPrint('Error finding parent hierarchy for member: $e');
      }
    }
  }

  Future<void> _loadDistricts() async {
    if (mounted) setState(() => _loadingDistricts = true);
    try {
      final list = await sl<LocationRepository>().getLocationList(
        type: 'DISTRICT',
      );
      if (mounted) {
        setState(() {
          _districts = list;
          _loadingDistricts = false;
        });
        if (_selectedDistrict == null) {
          final dashState = context.read<DashboardBloc>().state;
          final statsLocation = dashState.stats?.locationName;
          if (statsLocation != null && statsLocation != 'Tamil Nadu') {
            LocationModel? match;
            for (final d in list) {
              if (d.name.toLowerCase() == statsLocation.toLowerCase()) {
                match = d;
                break;
              }
            }
            if (match != null) {
              setState(() => _selectedDistrict = match);
              _loadConstituencies(match.id);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loadingDistricts = false);
    }
  }

  Future<void> _loadConstituencies(int districtId) async {
    if (mounted) setState(() => _loadingConstituencies = true);
    try {
      final list = await sl<LocationRepository>().getLocationList(
        parentId: districtId,
        type: 'TALUK',
      );
      if (mounted) {
        setState(() {
          _constituencies = list;
          _loadingConstituencies = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingConstituencies = false);
    }
  }

  Future<void> _loadAreas(int constituencyId) async {
    if (mounted) setState(() => _loadingAreas = true);
    try {
      final list = await sl<LocationRepository>().getLocationList(
        parentId: constituencyId,
        type: 'AREA',
      );
      if (mounted) {
        setState(() {
          _areas = list;
          _loadingAreas = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingAreas = false);
    }
  }

  Future<void> _loadStreets(int areaId) async {
    if (mounted) setState(() => _loadingStreets = true);
    try {
      final list = await sl<LocationRepository>().getLocationList(
        parentId: areaId,
        type: 'STREET',
      );
      if (mounted) {
        setState(() {
          _streets = list;
          _loadingStreets = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingStreets = false);
    }
  }

  void _onDistrictChanged(LocationModel? district) {
    setState(() {
      _selectedDistrict = district;
      _selectedConstituency = null;
      _constituencies = [];
      _selectedArea = null;
      _areas = [];
      _selectedStreet = null;
      _streets = [];
    });
    if (district != null) _loadConstituencies(district.id);
  }

  void _onConstituencyChanged(LocationModel? constituency) {
    setState(() {
      _selectedConstituency = constituency;
      _selectedArea = null;
      _areas = [];
      _selectedStreet = null;
      _streets = [];
    });
    if (constituency != null) _loadAreas(constituency.id);
  }

  void _onAreaChanged(LocationModel? area) {
    setState(() {
      _selectedArea = area;
      _selectedStreet = null;
      _streets = [];
    });
    if (area != null) _loadStreets(area.id);
  }

  void _onStreetChanged(LocationModel? street) {
    setState(() => _selectedStreet = street);
  }

  int? _composeLocationId() {
    if (_selectedStreet != null) return _selectedStreet!.id;
    if (_selectedArea != null) return _selectedArea!.id;
    if (_selectedConstituency != null) return _selectedConstituency!.id;
    if (_selectedDistrict != null) return _selectedDistrict!.id;
    return context.read<AuthBloc>().state.loginData?.locationId;
  }

  void _sendBroadcast() {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    final locationId = _composeLocationId();

    if (title.isEmpty || message.isEmpty) {
      NTKSnackbar.showError(context, message: 'Title and message are required');
      return;
    }
    if (message.length > 500) {
      NTKSnackbar.showError(context, message: 'Broadcast message cannot exceed 500 characters.');
      return;
    }
    if (locationId == null) {
      NTKSnackbar.showError(context, message: 'Please select a location');
      return;
    }

    context.read<RequestBloc>().add(
      CreateBroadcastMessage(
        title: title,
        message: message,
        locationId: locationId,
      ),
    );
    _titleController.clear();
    _messageController.clear();
    setState(() => _selectedStreet = null);
  }

  void _sendEmergency() {
    final title = _emergencyTitleController.text.trim();
    final contactName = _contactPersonController.text.trim();
    final contactPhone = _contactPhoneController.text.trim();
    final type = _selectedEmergencyType;
    final locationId = _composeLocationId();

    if (title.isEmpty) {
      NTKSnackbar.showError(context, message: 'Title is required');
      return;
    }
    if (locationId == null) {
      NTKSnackbar.showError(context, message: 'Please select a location');
      return;
    }
    final remarks = _emergencyDescriptionController.text.trim();
    if (remarks.length > 500) {
      NTKSnackbar.showError(context, message: 'Additional remarks cannot exceed 500 characters.');
      return;
    }

    // Type-specific field validation & compilation
    String? finalDescription;
    final Map<String, String> customFields = {};

    if (type == 'BLOOD_REQUIRED') {
      final bloodGroup = _bloodGroupController.text.trim();
      final units = _unitsRequiredController.text.trim();
      final hospital = _hospitalNameController.text.trim();
      
      if (bloodGroup.isEmpty) {
        NTKSnackbar.showError(context, message: 'Please select blood group');
        return;
      }
      if (units.isEmpty) {
        NTKSnackbar.showError(context, message: 'Units Required is required');
        return;
      }
      if (hospital.isEmpty) {
        NTKSnackbar.showError(context, message: 'Hospital Name is required');
        return;
      }
      if (contactPhone.isEmpty) {
        NTKSnackbar.showError(context, message: 'Contact Number is required');
        return;
      }
      customFields['bloodGroup'] = bloodGroup;
      customFields['unitsRequired'] = units;
      customFields['hospitalName'] = hospital;
      customFields['contactNumber'] = contactPhone;
    } else if (type == 'MEDICAL_HELP') {
      final patientCondition = _patientConditionController.text.trim();
      final hospital = _hospitalNameController.text.trim();
      
      if (patientCondition.isEmpty) {
        NTKSnackbar.showError(context, message: 'Patient Condition is required');
        return;
      }
      if (hospital.isEmpty) {
        NTKSnackbar.showError(context, message: 'Hospital Name is required');
        return;
      }
      if (contactPhone.isEmpty) {
        NTKSnackbar.showError(context, message: 'Contact Number is required');
        return;
      }
      customFields['patientCondition'] = patientCondition;
      customFields['hospitalName'] = hospital;
      customFields['contactNumber'] = contactPhone;
    } else if (type == 'DISASTER_SUPPORT') {
      final disasterType = _disasterTypeController.text.trim();
      final affectedArea = _affectedAreaController.text.trim();
      final reqSupport = _requiredSupportController.text.trim();
      
      if (disasterType.isEmpty) {
        NTKSnackbar.showError(context, message: 'Disaster Type is required');
        return;
      }
      if (affectedArea.isEmpty) {
        NTKSnackbar.showError(context, message: 'Affected Area is required');
        return;
      }
      if (reqSupport.isEmpty) {
        NTKSnackbar.showError(context, message: 'Required Support is required');
        return;
      }
      customFields['disasterType'] = disasterType;
      customFields['affectedArea'] = affectedArea;
      customFields['requiredSupport'] = reqSupport;
    } else if (type == 'VOLUNTEER_NEEDED') {
      final volunteerType = _volunteerTypeController.text.trim();
      final location = _volunteerLocationController.text.trim();
      final contactDetails = _volunteerContactDetailsController.text.trim();
      
      if (volunteerType.isEmpty) {
        NTKSnackbar.showError(context, message: 'Volunteer Type is required');
        return;
      }
      if (location.isEmpty) {
        NTKSnackbar.showError(context, message: 'Location is required');
        return;
      }
      if (contactDetails.isEmpty) {
        NTKSnackbar.showError(context, message: 'Contact Details are required');
        return;
      }
      customFields['volunteerType'] = volunteerType;
      customFields['location'] = location;
      customFields['contactDetails'] = contactDetails;
    }

    if (type != 'OTHER') {
      if (remarks.isNotEmpty) {
        customFields['additionalInfo'] = remarks;
      }
      finalDescription = jsonEncode(customFields);
    } else {
      if (remarks.isEmpty) {
        NTKSnackbar.showError(context, message: 'Description is required');
        return;
      }
      finalDescription = remarks;
    }

    context.read<EventBloc>().add(
      CreateEmergency(
        title: title,
        description: finalDescription,
        type: type,
        locationId: locationId,
        contactName: contactName.isNotEmpty ? contactName : null,
        contactPhone: contactPhone.isNotEmpty ? contactPhone : null,
        expiryDate: _selectedExpiryDateTime?.toUtc().toIso8601String(), // UTC with 'Z'
        collectResponse: _collectResponse,
      ),
    );
  }

  Future<void> _pickExpiryDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate:
          _selectedExpiryDateTime ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFEF4444),
            onPrimary: Colors.white,
            onSurface: Color(0xFF1F2937),
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !context.mounted) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _selectedExpiryDateTime ?? DateTime.now().add(const Duration(hours: 1)),
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFEF4444),
            onPrimary: Colors.white,
            onSurface: Color(0xFF1F2937),
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      // Store as local DateTime for display, but we'll convert to UTC on submit.
      _selectedExpiryDateTime = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  String _formatDateTime(String dt) {
    return DateHelper.formatDateTime(dt);
  }

  /// Formats a local [DateTime] for display in the picker label.
  /// Uses the local fields directly — no UTC conversion — so the
  /// user always sees the exact time they picked.
  String _formatExpiryForDisplay(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour:$minute $ampm';
  }

  // ─── UI BUILDERS ───────────────────────────────────────────────

  Widget _buildFormToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeFormType = 'BROADCAST'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _activeFormType == 'BROADCAST'
                      ? const Color(0xFF0F5A29)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.campaign_rounded,
                      color: _activeFormType == 'BROADCAST'
                          ? Colors.white
                          : const Color(0xFF6B7280),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Broadcast',
                      style: TextStyle(
                        color: _activeFormType == 'BROADCAST'
                            ? Colors.white
                            : const Color(0xFF1F2937),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeFormType = 'EMERGENCY'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _activeFormType == 'EMERGENCY'
                      ? const Color(0xFFEF4444)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: _activeFormType == 'EMERGENCY'
                          ? Colors.white
                          : const Color(0xFF6B7280),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Emergency',
                      style: TextStyle(
                        color: _activeFormType == 'EMERGENCY'
                            ? Colors.white
                            : const Color(0xFF1F2937),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTypeSelector() {
    final types = [
      {'key': 'BLOOD_REQUIRED', 'label': 'Blood', 'icon': Icons.bloodtype_rounded},
      {'key': 'MEDICAL_HELP', 'label': 'Medical', 'icon': Icons.medical_services_rounded},
      {'key': 'VOLUNTEER_NEEDED', 'label': 'Volunteer', 'icon': Icons.people_alt_rounded},
      {'key': 'DISASTER_SUPPORT', 'label': 'Disaster', 'icon': Icons.thunderstorm_rounded},
      {'key': 'OTHER', 'label': 'Other', 'icon': Icons.more_horiz_rounded},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emergency Type *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: types.map((t) {
              final isSelected = _selectedEmergencyType == t['key'];
              return GestureDetector(
                onTap: () => setState(() => _selectedEmergencyType = t['key'] as String),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFEF2F2) : Colors.white,
                    border: Border.all(
                      color: isSelected ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        t['icon'] as IconData,
                        color: isSelected ? const Color(0xFFEF4444) : const Color(0xFF4B5563),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t['label'] as String,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF991B1B) : const Color(0xFF1F2937),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildResponseRequiredRadio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Collect Member Responses? *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _collectResponse = true),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _collectResponse ? const Color(0xFFFEF2F2) : Colors.white,
                    border: Border.all(
                      color: _collectResponse ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB),
                      width: _collectResponse ? 1.5 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: _collectResponse,
                        activeColor: const Color(0xFFEF4444),
                        onChanged: (val) { if (val != null) setState(() => _collectResponse = val); },
                      ),
                      const Text('Yes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _collectResponse = false),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: !_collectResponse ? const Color(0xFFFEF2F2) : Colors.white,
                    border: Border.all(
                      color: !_collectResponse ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB),
                      width: !_collectResponse ? 1.5 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Radio<bool>(
                        value: false,
                        groupValue: _collectResponse,
                        activeColor: const Color(0xFFEF4444),
                        onChanged: (val) { if (val != null) setState(() => _collectResponse = val); },
                      ),
                      const Text('No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpiryPicker() {
    final String label = _selectedExpiryDateTime == null
        ? 'Select Expiry Date & Time'
        : _formatExpiryForDisplay(_selectedExpiryDateTime!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expiry Date & Time',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickExpiryDateTime,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.calendar, color: Color(0xFFEF4444), size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: _selectedExpiryDateTime == null ? const Color(0xFF9CA3AF) : const Color(0xFF1F2937),
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_selectedExpiryDateTime != null)
                  GestureDetector(
                    onTap: () => setState(() => _selectedExpiryDateTime = null),
                    child: const Icon(CupertinoIcons.clear_circled_solid, color: Colors.grey, size: 18),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151))),
    );
  }

  Widget _buildDropdownField({
    required List<LocationModel> items,
    required LocationModel? value,
    required ValueChanged<LocationModel?> onChanged,
    required String hintText,
    required String allLabel,
  }) {
    final bool hasSelectedValue = value != null && items.any((item) => item.id == value.id);
    final LocationModel? valueToUse = hasSelectedValue ? items.firstWhere((item) => item.id == value.id) : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LocationModel?>(
          value: valueToUse,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 24, color: Color(0xFF6B7280)),
          hint: Text(hintText, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          items: [
            DropdownMenuItem<LocationModel?>(
              value: null,
              child: Text(allLabel, style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937))),
            ),
            ...items.map(
              (item) => DropdownMenuItem<LocationModel?>(
                value: item,
                child: Text(item.name, style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937))),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDisabledField(String hintText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 12),
          Text(hintText, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLoadingField(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF0A7E3E))),
          ),
          const SizedBox(width: 12),
          Text('Loading $label...', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLocationSelectorField({
    required String label,
    required List<LocationModel> items,
    required LocationModel? selectedValue,
    required ValueChanged<LocationModel?> onChanged,
    required bool isEnabled,
    required bool isLoading,
    required String disabledHint,
    required String allLabel,
    required String selectHint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormLabel(label),
        isLoading
            ? _buildLoadingField(label.replaceAll(' *', ''))
            : !isEnabled
                ? _buildDisabledField(selectedValue?.name ?? disabledHint)
                : _buildDropdownField(
                    items: items,
                    value: selectedValue,
                    onChanged: onChanged,
                    hintText: selectHint,
                    allLabel: allLabel,
                  ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLocationSelectorsSection(String userRole) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Target Location Hierarchy',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 16),
        _buildLocationSelectorField(
          label: 'District *',
          items: _districts,
          selectedValue: _selectedDistrict,
          onChanged: _onDistrictChanged,
          isEnabled: userRole == 'SUPER_ADMIN',
          isLoading: _loadingDistricts,
          disabledHint: 'Select District',
          allLabel: 'All Districts',
          selectHint: 'Select District',
        ),
        _buildLocationSelectorField(
          label: 'Constituency (Taluk)',
          items: _constituencies,
          selectedValue: _selectedConstituency,
          onChanged: _onConstituencyChanged,
          isEnabled: _selectedDistrict != null && userRole == 'SUPER_ADMIN',
          isLoading: _loadingConstituencies,
          disabledHint: _selectedDistrict == null
              ? 'Select District first'
              : 'Select Constituency',
          allLabel: 'All Constituencies',
          selectHint: 'Select Constituency',
        ),
        _buildLocationSelectorField(
          label: 'Area (Town)',
          items: _areas,
          selectedValue: _selectedArea,
          onChanged: _onAreaChanged,
          isEnabled: _selectedConstituency != null &&
              (userRole == 'SUPER_ADMIN' || userRole == 'ADMIN'),
          isLoading: _loadingAreas,
          disabledHint: _selectedConstituency == null
              ? 'Select Constituency first'
              : 'Select Area',
          allLabel: 'All Areas',
          selectHint: 'Select Area',
        ),
        _buildLocationSelectorField(
          label: 'Street',
          items: _streets,
          selectedValue: _selectedStreet,
          onChanged: _onStreetChanged,
          isEnabled: _selectedArea != null && userRole != 'MEMBER',
          isLoading: _loadingStreets,
          disabledHint: _selectedArea == null ? 'Select Area first' : 'Select Street',
          allLabel: 'All Streets',
          selectHint: 'Select Street',
        ),
      ],
    );
  }

  Widget _buildBroadcastForm(RequestState state, String userRole) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCFCE7)),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFF0F5A29),
                child: Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Broadcast (No Response)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F5A29), fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Send announcements to your members. No response will be collected.', style: TextStyle(fontSize: 12, color: Color(0xFF374151))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text('Broadcast Title *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: TextField(
            key: const ValueKey('broadcast_title_field'),
            controller: _titleController,
            focusNode: _titleFocusNode,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Enter broadcast title',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: false,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Message *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _messageController,
          builder: (context, value, child) {
            final isExceeded = value.text.length > 500;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(12), 
                border: Border.all(color: isExceeded ? Colors.red : const Color(0xFFE5E7EB))
              ),
              child: TextField(
                key: const ValueKey('broadcast_message_field'),
                controller: _messageController,
                focusNode: _messageFocusNode,
                maxLines: 5,
                maxLength: 500,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  filled: false,
                  errorText: isExceeded ? 'Broadcast message cannot exceed 500 characters.' : null,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        _buildLocationSelectorsSection(userRole),
        const SizedBox(height: 36),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: state.isSubmitting ? null : _sendBroadcast,
                  icon: state.isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  label: Text(state.isSubmitting ? 'SENDING...' : 'SEND BROADCAST',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5A29),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTypeSpecificFields() {
    final type = _selectedEmergencyType;
    if (type == 'BLOOD_REQUIRED') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('Blood Group *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const ValueKey('blood_group_field'),
                value: _bloodGroupController.text.isNotEmpty && [
                  'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
                ].contains(_bloodGroupController.text) ? _bloodGroupController.text : null,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 24, color: Color(0xFF6B7280)),
                hint: const Text(
                  'Select Blood Group',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                ),
                items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((group) {
                  return DropdownMenuItem<String>(
                    value: group,
                    child: Text(
                      group,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _bloodGroupController.text = val ?? '';
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Units Required *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: TextField(
              key: const ValueKey('units_required_field'),
              controller: _unitsRequiredController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter number of units required',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Hospital Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: TextField(
              key: const ValueKey('hospital_name_field'),
              controller: _hospitalNameController,
              decoration: const InputDecoration(
                hintText: 'Enter hospital name & address',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      );
    } else if (type == 'MEDICAL_HELP') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('Patient Condition *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: TextField(
              key: const ValueKey('patient_condition_field'),
              controller: _patientConditionController,
              decoration: const InputDecoration(
                hintText: 'Enter patient condition (e.g. Critical, ICU)',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Hospital Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: TextField(
              key: const ValueKey('medical_hospital_field'),
              controller: _hospitalNameController,
              decoration: const InputDecoration(
                hintText: 'Enter hospital name & address',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      );
    } else if (type == 'DISASTER_SUPPORT') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('Disaster Type *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: TextField(
              key: const ValueKey('disaster_type_field'),
              controller: _disasterTypeController,
              decoration: const InputDecoration(
                hintText: 'Enter disaster type (e.g. Flood, Cyclone, Fire)',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Affected Area *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: TextField(
              key: const ValueKey('affected_area_field'),
              controller: _affectedAreaController,
              decoration: const InputDecoration(
                hintText: 'Enter affected area location details',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Required Support *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: TextField(
              key: const ValueKey('required_support_field'),
              controller: _requiredSupportController,
              decoration: const InputDecoration(
                hintText: 'Enter required support (e.g. Food, Rescue, Shelter)',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      );
    } else if (type == 'VOLUNTEER_NEEDED') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('Volunteer Type *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: TextField(
              key: const ValueKey('volunteer_type_field'),
              controller: _volunteerTypeController,
              decoration: const InputDecoration(
                hintText: 'Enter volunteer work description',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Location *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: TextField(
              key: const ValueKey('volunteer_location_field'),
              controller: _volunteerLocationController,
              decoration: const InputDecoration(
                hintText: 'Enter location / address of volunteer work',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Contact Details *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: TextField(
              key: const ValueKey('volunteer_contact_details_field'),
              controller: _volunteerContactDetailsController,
              decoration: const InputDecoration(
                hintText: 'Enter contact details / info for volunteers',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmergencyForm(RequestState requestState, EventState eventState, String userRole) {
    final showContact = _selectedEmergencyType == 'BLOOD_REQUIRED' ||
        _selectedEmergencyType == 'MEDICAL_HELP' ||
        _selectedEmergencyType == 'OTHER';
    final isContactRequired = _selectedEmergencyType == 'BLOOD_REQUIRED' ||
        _selectedEmergencyType == 'MEDICAL_HELP';
    final descLabel = _selectedEmergencyType == 'OTHER'
        ? 'Description *'
        : 'Additional Remarks (Optional)';
    final descHint = _selectedEmergencyType == 'OTHER'
        ? 'Type emergency description here...'
        : 'Type any additional comments/remarks here...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFEE2E2)),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFEF4444),
                child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Emergency Alert (Response Required)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF991B1B), fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Send urgent alerts and collect responses from members.', style: TextStyle(fontSize: 12, color: Color(0xFF374151))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _buildEmergencyTypeSelector(),
        const SizedBox(height: 24),
        const Text('Alert Title *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: TextField(
            key: const ValueKey('emergency_title_field'),
            controller: _emergencyTitleController,
            focusNode: _emergencyTitleFocusNode,
            maxLength: 100,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Enter alert title',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: false,
              counterText: '',
            ),
          ),
        ),
        _buildTypeSpecificFields(),
        const SizedBox(height: 20),
        Text(descLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _emergencyDescriptionController,
          builder: (context, value, child) {
            final isExceeded = value.text.length > 500;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(12), 
                border: Border.all(color: isExceeded ? Colors.red : const Color(0xFFE5E7EB))
              ),
              child: TextField(
                key: const ValueKey('emergency_desc_field'),
                controller: _emergencyDescriptionController,
                focusNode: _emergencyDescriptionFocusNode,
                maxLines: 5,
                maxLength: 500,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: descHint,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  filled: false,
                  errorText: isExceeded ? 'Additional remarks cannot exceed 500 characters.' : null,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        _buildLocationSelectorsSection(userRole),
        if (showContact) ...[
          const SizedBox(height: 20),
          Text(
            isContactRequired ? 'Contact Name *' : 'Contact Name',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: TextField(
              key: const ValueKey('emergency_contact_name_field'),
              controller: _contactPersonController,
              focusNode: _contactNameFocusNode,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: isContactRequired ? "Enter contact name *" : "Enter contact name",
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: false,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isContactRequired ? 'Contact Number *' : 'Contact Number',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: TextField(
              key: const ValueKey('emergency_contact_phone_field'),
              controller: _contactPhoneController,
              focusNode: _contactPhoneFocusNode,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                hintText: isContactRequired ? 'Enter contact phone number *' : 'Enter contact phone number',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: false,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildExpiryPicker(),
        const SizedBox(height: 24),
        _buildResponseRequiredRadio(),
        const SizedBox(height: 36),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: eventState.isLoading ? null : _sendEmergency,
                  icon: eventState.isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Icon(CupertinoIcons.paperplane_fill, color: Colors.white, size: 18),
                  label: Text(eventState.isLoading ? 'SENDING...' : 'SEND ALERT',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userRole = authState.loginData?.role ?? 'MEMBER';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: NTKAppBar(
        title: 'Create Announcement',
        subtitle: authState.loginData?.locationName ?? 'Tamil Nadu',
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<EventBloc, EventState>(
            listener: (context, state) {
              if (state.message == 'Emergency Alert created successfully') {
                NTKSnackbar.showSuccess(context, message: 'Sent successfully!');
                context.read<EventBloc>().add(const ClearEventMessage());
                Navigator.pop(context);
              }
              if (state.error != null && _activeFormType == 'EMERGENCY') {
                NTKSnackbar.showError(context, message: state.error!);
              }
            },
          ),
          BlocListener<RequestBloc, RequestState>(
            listener: (context, state) {
              if (state.submitSuccess) {
                NTKSnackbar.showSuccess(context, message: 'Sent successfully!');
                context.read<RequestBloc>().add(ClearSubmitStatus());
                Navigator.pop(context);
              }
              if (state.error != null && _activeFormType == 'BROADCAST') {
                NTKSnackbar.showError(context, message: state.error!);
              }
            },
          ),
        ],
        child: BlocBuilder<RequestBloc, RequestState>(
          builder: (context, requestState) {
            final eventState = context.watch<EventBloc>().state;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (userRole != 'MEMBER') _buildFormToggle(),
                  if (_activeFormType == 'BROADCAST')
                    _buildBroadcastForm(requestState, userRole)
                  else
                    _buildEmergencyForm(requestState, eventState, userRole),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
