import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_event.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_state.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';
import 'package:ntk_project/src/features/location/domain/repositories/location_repository.dart';
import 'package:ntk_project/src/injection_container.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();

  bool _isSubmitting = false;

  // Hierarchical location lists
  final List<String> _states = ['Tamil Nadu'];
  String? _selectedState = 'Tamil Nadu';

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

  final List<String> _professions = ['Doctor', 'Engineer', 'Teacher', 'Lawyer', 'Farmer', 'Volunteer'];
  final List<String> _selectedProfessions = [];

  late LocationRepository _locationRepo;

  @override
  void initState() {
    super.initState();
    _locationRepo = sl<LocationRepository>();
    final authState = context.read<AuthBloc>().state;
    final role = authState.loginData?.role ?? '';
    final locationId = authState.loginData?.locationId;

    if (role == 'SUB_ADMIN' && locationId != null) {
      // Sub Admin's locationId IS their Area — load streets directly
      _loadStreetsForSubAdmin(locationId);
    } else if (role == 'ADMIN' && locationId != null) {
      // Admin's locationId IS their Constituency — load areas directly
      _loadAreasForAdmin(locationId);
    } else {
      _loadDistricts();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadDistricts() async {
    setState(() => _loadingDistricts = true);
    try {
      final list = await _locationRepo.getLocationList(type: 'DISTRICT');
      setState(() {
        _districts = list;
        _loadingDistricts = false;
      });
    } catch (_) {
      setState(() => _loadingDistricts = false);
    }
  }

  Future<void> _loadAreasForAdmin(int constituencyId) async {
    setState(() => _loadingAreas = true);
    try {
      final list = await _locationRepo.getLocationList(
        type: 'AREA',
        parentId: constituencyId,
      );
      setState(() {
        _areas = list;
        _loadingAreas = false;
      });
    } catch (_) {
      setState(() => _loadingAreas = false);
    }
  }

  Future<void> _loadStreetsForSubAdmin(int areaId) async {
    setState(() => _loadingStreets = true);
    try {
      final list = await _locationRepo.getLocationList(
        type: 'STREET',
        parentId: areaId,
      );
      setState(() {
        _streets = list;
        _loadingStreets = false;
      });
    } catch (_) {
      setState(() => _loadingStreets = false);
    }
  }

  Future<void> _onDistrictChanged(LocationModel? district) async {
    setState(() {
      _selectedDistrict = district;
      _selectedConstituency = null;
      _selectedArea = null;
      _selectedStreet = null;
      _constituencies = [];
      _areas = [];
      _streets = [];
    });
    if (district == null) return;
    setState(() => _loadingConstituencies = true);
    try {
      final list = await _locationRepo.getLocationList(
        type: 'TALUK',
        parentId: district.id,
      );
      setState(() {
        _constituencies = list;
        _loadingConstituencies = false;
      });
    } catch (_) {
      setState(() => _loadingConstituencies = false);
    }
  }

  Future<void> _onConstituencyChanged(LocationModel? taluk) async {
    setState(() {
      _selectedConstituency = taluk;
      _selectedArea = null;
      _selectedStreet = null;
      _areas = [];
      _streets = [];
    });
    if (taluk == null) return;
    setState(() => _loadingAreas = true);
    try {
      final list = await _locationRepo.getLocationList(
        type: 'AREA',
        parentId: taluk.id,
      );
      setState(() {
        _areas = list;
        _loadingAreas = false;
      });
    } catch (_) {
      setState(() => _loadingAreas = false);
    }
  }

  Future<void> _onAreaChanged(LocationModel? area) async {
    setState(() {
      _selectedArea = area;
      _selectedStreet = null;
      _streets = [];
    });
    if (area == null) return;
    setState(() => _loadingStreets = true);
    try {
      final list = await _locationRepo.getLocationList(
        type: 'STREET',
        parentId: area.id,
      );
      setState(() {
        _streets = list;
        _loadingStreets = false;
      });
    } catch (_) {
      setState(() => _loadingStreets = false);
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF004D2A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF004D2A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    // Build as local time, then convert to UTC so the backend and
    // DateHelper.parseUtcToLocal() both receive an unambiguous UTC string.
    final dtLocal = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    _dateController.text = dtLocal.toUtc().toIso8601String(); // ends with 'Z'
    setState(() {});
  }

  String _formatDateTimeDisplay(String dt) {
    return DateHelper.formatDateTime(dt);
  }

  void _onCreateEvent() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dateController.text.isEmpty) {
      NTKSnackbar.showError(context, message: 'Please select Date & Time');
      return;
    }

    final authState = context.read<AuthBloc>().state;
    final userRole = authState.loginData?.role ?? '';

    // For Sub Admin, use their area locationId; street is optional
    int? eventLocationId;
    if (userRole == 'SUB_ADMIN') {
      eventLocationId = _selectedStreet?.id ?? authState.loginData?.locationId;
    } else if (userRole == 'ADMIN') {
      eventLocationId = _selectedStreet?.id ?? _selectedArea?.id ?? authState.loginData?.locationId;
    } else {
      final finalLocation =
          _selectedStreet ??
          _selectedArea ??
          _selectedConstituency ??
          _selectedDistrict;
      if (finalLocation == null) {
        NTKSnackbar.showError(
          context,
          message: 'Please select a target location',
        );
        return;
      }
      eventLocationId = finalLocation.id;
    }

    setState(() {
      _isSubmitting = true;
    });

    context.read<EventBloc>().add(
      CreateEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _dateController.text.trim(),
        locationId: eventLocationId!,
        professionNames: _selectedProfessions.isNotEmpty ? _selectedProfessions : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004D2A), // Dark Green
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(context.read<AuthBloc>().state.loginData?.locationName ?? 'Admin Portal', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 1.2)),
          ],
        ),
      ),
      body: BlocListener<EventBloc, EventState>(
        listener: (context, state) {
          if (state.message == 'Event created successfully') {
            NTKSnackbar.showSuccess(context, message: 'Event created successfully.');
            context.read<EventBloc>().add(const ClearEventMessage());
            Navigator.pop(context);
          }
          if (state.error != null) {
            NTKSnackbar.showError(context, message: state.error!);
            context.read<EventBloc>().add(const ClearEventError());
            setState(() {
              _isSubmitting = false;
            });
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form title
                const Text(
                  'New Event Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Fill in the information to schedule a new community event.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 28),

                // Title input
                _buildFormLabel('Event Title *'),
                TextFormField(
                  controller: _titleController,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Please enter event title'
                      : null,
                  decoration: _inputDecoration('e.g., General Body Meeting'),
                ),
                const SizedBox(height: 20),

                // Description input
                _buildFormLabel('Description *'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Please enter event description'
                      : null,
                  decoration: _inputDecoration(
                    'Add event details, agenda, and specifications...',
                  ),
                ),
                const SizedBox(height: 20),

                // Date & Time picker
                _buildFormLabel('Date & Time *'),
                GestureDetector(
                  onTap: () => _selectDateTime(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.calendar,
                          color: Color(0xFF004D2A),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _dateController.text.isEmpty
                                ? 'Select Date & Time'
                                : _formatDateTimeDisplay(_dateController.text),
                            style: TextStyle(
                              color: _dateController.text.isEmpty
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF1F2937),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.chevron_down,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 24),

                // Build location fields based on role
                Builder(
                  builder: (context) {
                    final authState = context.read<AuthBloc>().state;
                    final userRole = authState.loginData?.role ?? '';
                    final isSubAdmin = userRole == 'SUB_ADMIN';
                    final isAdmin = userRole == 'ADMIN';

                    if (isSubAdmin) {
                      // Sub Admin: show only Street selector (Area is auto-set from their location)
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormLabel('Street'),
                          _loadingStreets
                              ? _buildLoadingField('Street')
                              : _buildDropdownField<LocationModel>(
                                  items: _streets,
                                  value: _selectedStreet,
                                  onChanged: (val) =>
                                      setState(() => _selectedStreet = val),
                                  itemLabel: (item) => item.name,
                                  hintText: 'Select Street (Optional)',
                                ),
                        ],
                      );
                    }

                    if (isAdmin) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormLabel('State'),
                          _buildDisabledField('Tamil Nadu'),
                          const SizedBox(height: 16),
                          _buildFormLabel('District'),
                          _buildDisabledField('Your District'),
                          const SizedBox(height: 16),
                          _buildFormLabel('Constituency (Taluk)'),
                          _buildDisabledField(authState.loginData?.locationName ?? 'Your Constituency'),
                          const SizedBox(height: 16),
                          _buildFormLabel('Area (Town)'),
                          _loadingAreas
                              ? _buildLoadingField('Area')
                              : _buildDropdownField<LocationModel>(
                                  items: _areas,
                                  value: _selectedArea,
                                  onChanged: _onAreaChanged,
                                  itemLabel: (item) => item.name,
                                  hintText: 'Select Area',
                                ),
                          const SizedBox(height: 16),
                          _buildFormLabel('Street'),
                          _loadingStreets
                              ? _buildLoadingField('Street')
                              : _selectedArea == null
                              ? _buildDisabledField('Select Area first')
                              : _buildDropdownField<LocationModel>(
                                  items: _streets,
                                  value: _selectedStreet,
                                  onChanged: (val) =>
                                      setState(() => _selectedStreet = val),
                                  itemLabel: (item) => item.name,
                                  hintText: 'Select Street (Optional)',
                                ),
                        ],
                      );
                    }

                    // Non-Sub Admin / Non-Admin: full hierarchy
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. State
                        _buildFormLabel('State'),
                        _buildDropdownField<String>(
                          items: _states,
                          value: _selectedState,
                          onChanged: (val) =>
                              setState(() => _selectedState = val),
                          itemLabel: (item) => item,
                          hintText: 'Select State',
                        ),
                        const SizedBox(height: 16),

                        // 2. District
                        _buildFormLabel('District *'),
                        _loadingDistricts
                            ? _buildLoadingField('District')
                            : _buildDropdownField<LocationModel>(
                                items: _districts,
                                value: _selectedDistrict,
                                onChanged: _onDistrictChanged,
                                itemLabel: (item) => item.name,
                                hintText: 'Select District',
                              ),
                        const SizedBox(height: 16),

                        // 3. Constituency (Taluk)
                        _buildFormLabel('Constituency (Taluk)'),
                        _loadingConstituencies
                            ? _buildLoadingField('Constituency')
                            : _selectedDistrict == null
                            ? _buildDisabledField('Select District first')
                            : _buildDropdownField<LocationModel>(
                                items: _constituencies,
                                value: _selectedConstituency,
                                onChanged: _onConstituencyChanged,
                                itemLabel: (item) => item.name,
                                hintText: 'Select Constituency',
                              ),
                        const SizedBox(height: 16),

                        // 4. Area (Town)
                        _buildFormLabel('Area (Town)'),
                        _loadingAreas
                            ? _buildLoadingField('Area')
                            : _selectedConstituency == null
                            ? _buildDisabledField('Select Constituency first')
                            : _buildDropdownField<LocationModel>(
                                items: _areas,
                                value: _selectedArea,
                                onChanged: _onAreaChanged,
                                itemLabel: (item) => item.name,
                                hintText: 'Select Area',
                              ),
                        const SizedBox(height: 16),

                        // 5. Street
                        _buildFormLabel('Street'),
                        _loadingStreets
                            ? _buildLoadingField('Street')
                            : _selectedArea == null
                            ? _buildDisabledField('Select Area first')
                            : _buildDropdownField<LocationModel>(
                                items: _streets,
                                value: _selectedStreet,
                                onChanged: (val) =>
                                    setState(() => _selectedStreet = val),
                                itemLabel: (item) => item.name,
                                hintText: 'Select Street (Optional)',
                              ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                const SizedBox(height: 48),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004D2A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isSubmitting ? null : _onCreateEvent,
                    child: _isSubmitting
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : const Text(
                            'CREATE EVENT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF004D2A), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required List<T> items,
    required T? value,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemLabel,
    required String hintText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            CupertinoIcons.chevron_down,
            size: 16,
            color: Color(0xFF6B7280),
          ),
          hint: Text(
            hintText,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLoadingField(String label) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Color(0xFF004D2A)),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Loading...',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledField(String message) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.lock, size: 14, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          Text(
            message,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
