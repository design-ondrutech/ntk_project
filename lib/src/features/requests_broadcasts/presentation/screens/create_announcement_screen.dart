import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
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
  DateTime? _selectedExpiryDateTime;
  bool _collectResponse = true;

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
      final assignedDistrict = LocationModel(
        id: authLocationId,
        name: authState.loginData?.locationName ?? 'Assigned District',
      );
      setState(() {
        _selectedDistrict = assignedDistrict;
        _districts = [assignedDistrict];
      });
      await _loadConstituencies(authLocationId);
      if (globalLocation != null) {
        setState(() => _selectedConstituency = globalLocation);
        await _loadAreas(globalLocation.id);
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
    final streetId = _selectedStreet?.id;

    if (title.isEmpty || message.isEmpty) {
      NTKSnackbar.showError(context, message: 'Title and message are required');
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
        streetId: streetId,
      ),
    );
    _titleController.clear();
    _messageController.clear();
    setState(() => _selectedStreet = null);
  }

  void _sendEmergency() {
    final title = _emergencyTitleController.text.trim();
    final description = _emergencyDescriptionController.text.trim();
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

    context.read<EventBloc>().add(
      CreateEmergency(
        title: title,
        description: description.isNotEmpty ? description : null,
        type: type,
        locationId: locationId,
        contactName: contactName.isNotEmpty ? contactName : null,
        contactPhone: contactPhone.isNotEmpty ? contactPhone : null,
        expiryDate: _selectedExpiryDateTime?.toIso8601String(),
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
      _selectedExpiryDateTime = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  String _formatDateTime(String dt) {
    try {
      final date = DateTime.parse(dt);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final ampm = date.hour < 12 ? 'AM' : 'PM';
      final minute = date.minute.toString().padLeft(2, '0');
      return '${months[date.month - 1]} ${date.day}, ${date.year} • $hour:$minute $ampm';
    } catch (_) {
      return dt;
    }
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
        : _formatDateTime(_selectedExpiryDateTime!.toIso8601String());
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
    final isSubAdmin = userRole == 'SUB_ADMIN';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Target Location Hierarchy',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 16),
        if (!isSubAdmin) ...[
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
            isEnabled: _selectedDistrict != null &&
                (userRole == 'SUPER_ADMIN' || userRole == 'ADMIN'),
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
            isEnabled: _selectedConstituency != null,
            isLoading: _loadingAreas,
            disabledHint: _selectedConstituency == null
                ? 'Select Constituency first'
                : 'Select Area',
            allLabel: 'All Areas',
            selectHint: 'Select Area',
          ),
        ],
        _buildLocationSelectorField(
          label: 'Street',
          items: _streets,
          selectedValue: _selectedStreet,
          onChanged: _onStreetChanged,
          isEnabled: _selectedArea != null,
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
            controller: _titleController,
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
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: TextField(
            controller: _messageController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Type your message here...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: false,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildLocationSelectorsSection(userRole),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
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
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEmergencyForm(RequestState requestState, EventState eventState, String userRole) {
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
            controller: _emergencyTitleController,
            maxLength: 100,
            decoration: const InputDecoration(
              hintText: 'Enter alert title',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: false,
              counterText: '',
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: TextField(
            controller: _emergencyDescriptionController,
            maxLines: 5,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText: 'Type emergency description here...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: false,
              counterText: '',
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildLocationSelectorsSection(userRole),
        const SizedBox(height: 20),
        const Text('Contact Person', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: TextField(
            controller: _contactPersonController,
            decoration: const InputDecoration(
              hintText: "Enter contact person's name",
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: false,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Contact Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: TextField(
            controller: _contactPhoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
              hintText: 'Enter contact phone number',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: false,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildExpiryPicker(),
        const SizedBox(height: 24),
        _buildResponseRequiredRadio(),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
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
      ),
      body: BlocConsumer<RequestBloc, RequestState>(
        listener: (context, state) {
          if (state.submitSuccess) {
            NTKSnackbar.showSuccess(context, message: 'Sent successfully!');
            Navigator.pop(context);
          }
          if (state.error != null) {
            NTKSnackbar.showError(context, message: state.error!);
          }
        },
        builder: (context, requestState) {
          final eventState = context.watch<EventBloc>().state;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormToggle(),
                if (_activeFormType == 'BROADCAST')
                  _buildBroadcastForm(requestState, userRole)
                else
                  _buildEmergencyForm(requestState, eventState, userRole),
              ],
            ),
          );
        },
      ),
    );
  }
}
