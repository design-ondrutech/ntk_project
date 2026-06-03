import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
import 'package:ntk_project/src/features/dashboard/data/models/recent_activity_model.dart';
import 'package:ntk_project/src/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';
import 'package:ntk_project/src/features/location/domain/repositories/location_repository.dart';
import 'package:ntk_project/src/injection_container.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  int _currentIndex = 0; // 0=All, 1=Members, 2=Admins, 3=Sub Admins, 4=Events, 5=Broadcast, 6=Emergency, 7=Approvals, 8=Role Changes
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  int _currentPage = 1;
  static const int _pageSize = 10;
  bool _isLoading = false;
  List<RecentActivityModel> _allLoadedActivities = [];

  // Location filter state
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

  LocationModel? _appliedLocationFilter;

  final List<String> _chips = [
    'All',
    'Members',
    'Admins',
    'Sub Admins',
    'Events',
    'Broadcast',
    'Emergency',
    'Approvals',
    'Role Changes'
  ];

  @override
  void initState() {
    super.initState();
    _fetchActivities();
    _loadDistricts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchActivities() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final repo = sl<DashboardRepository>();
      
      String? typeVar;
      if (_currentIndex == 1) typeVar = 'MEMBER';
      else if (_currentIndex == 2) typeVar = 'ADMIN';
      else if (_currentIndex == 3) typeVar = 'SUB_ADMIN';
      else if (_currentIndex == 4) typeVar = 'EVENT';
      else if (_currentIndex == 5) typeVar = 'BROADCAST';
      else if (_currentIndex == 6) typeVar = 'EMERGENCY';
      else if (_currentIndex == 7) typeVar = 'APPROVAL';
      else if (_currentIndex == 8) typeVar = 'ROLE_CHANGE';

      String? fromDateStr = _selectedDateRange?.start.toIso8601String().split('T')[0];
      String? toDateStr = _selectedDateRange?.end.toIso8601String().split('T')[0];

      // Fetch a larger list so we can paginate on the client and get total count easily
      final list = await repo.getRecentActivity(
        locationId: _appliedLocationFilter?.id,
        limit: 500,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        type: typeVar,
        fromDate: fromDateStr,
        toDate: toDateStr,
      );

      if (mounted) {
        setState(() {
          _allLoadedActivities = list;
          _isLoading = false;
          _currentPage = 1; // Reset to page 1 on new query
        });
      }
    } catch (e) {
      debugPrint('Error fetching activities: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Location loaders
  Future<void> _loadDistricts() async {
    if (mounted) setState(() => _loadingDistricts = true);
    try {
      final list = await sl<LocationRepository>().getLocationList(type: 'DISTRICT');
      if (mounted) {
        setState(() {
          _districts = list;
          _loadingDistricts = false;
        });
      }
    } catch (_) {
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
    } catch (_) {
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
    } catch (_) {
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
    } catch (_) {
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
    if (district != null) {
      _loadConstituencies(district.id);
    }
  }

  void _onConstituencyChanged(LocationModel? constituency) {
    setState(() {
      _selectedConstituency = constituency;
      _selectedArea = null;
      _areas = [];
      _selectedStreet = null;
      _streets = [];
    });
    if (constituency != null) {
      _loadAreas(constituency.id);
    }
  }

  void _onAreaChanged(LocationModel? area) {
    setState(() {
      _selectedArea = area;
      _selectedStreet = null;
      _streets = [];
    });
    if (area != null) {
      _loadStreets(area.id);
    }
  }

  void _onStreetChanged(LocationModel? street) {
    setState(() {
      _selectedStreet = street;
    });
  }

  LocationModel? _composeSelectedLocation() {
    if (_selectedStreet != null) return _selectedStreet;
    if (_selectedArea != null) return _selectedArea;
    if (_selectedConstituency != null) return _selectedConstituency;
    if (_selectedDistrict != null) return _selectedDistrict;
    return null;
  }

  void _showLocationFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Filter by Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 20),
                  
                  // District Dropdown
                  const Text('District', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  _buildModalDropdown(
                    items: _districts,
                    value: _selectedDistrict,
                    hint: 'Select District',
                    onChanged: (val) {
                      setModalState(() {
                        _onDistrictChanged(val);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Constituency Dropdown
                  const Text('Constituency (Taluk)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  _buildModalDropdown(
                    items: _constituencies,
                    value: _selectedConstituency,
                    hint: _selectedDistrict == null ? 'Select District first' : 'Select Constituency',
                    isEnabled: _selectedDistrict != null,
                    onChanged: (val) {
                      setModalState(() {
                        _onConstituencyChanged(val);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Area Dropdown
                  const Text('Area (Town)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  _buildModalDropdown(
                    items: _areas,
                    value: _selectedArea,
                    hint: _selectedConstituency == null ? 'Select Constituency first' : 'Select Area',
                    isEnabled: _selectedConstituency != null,
                    onChanged: (val) {
                      setModalState(() {
                        _onAreaChanged(val);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Street Dropdown
                  const Text('Street', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  _buildModalDropdown(
                    items: _streets,
                    value: _selectedStreet,
                    hint: _selectedArea == null ? 'Select Area first' : 'Select Street',
                    isEnabled: _selectedArea != null,
                    onChanged: (val) {
                      setModalState(() {
                        _onStreetChanged(val);
                      });
                    },
                  ),
                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedDistrict = null;
                              _selectedConstituency = null;
                              _selectedArea = null;
                              _selectedStreet = null;
                              _appliedLocationFilter = null;
                            });
                            Navigator.pop(context);
                            _fetchActivities();
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Reset', style: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _appliedLocationFilter = _composeSelectedLocation();
                            });
                            Navigator.pop(context);
                            _fetchActivities();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F5A29),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Apply Filter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalDropdown({
    required List<LocationModel> items,
    required LocationModel? value,
    required String hint,
    bool isEnabled = true,
    required ValueChanged<LocationModel?> onChanged,
  }) {
    if (!isEnabled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(hint, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
      );
    }

    final bool hasSelectedValue = value != null && items.any((item) => item.id == value.id);
    final LocationModel? valueToUse = hasSelectedValue
        ? items.firstWhere((item) => item.id == value.id)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LocationModel?>(
          value: valueToUse,
          isExpanded: true,
          icon: const Icon(CupertinoIcons.chevron_down, size: 16, color: Color(0xFF6B7280)),
          hint: Text(hint, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          items: items.map(
            (item) => DropdownMenuItem<LocationModel?>(
              value: item,
              child: Text(item.name, style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937))),
            ),
          ).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F5A29),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() {
        _selectedDateRange = range;
      });
      _fetchActivities();
    }
  }

  String _formatGroupDate(DateTime date) {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  String _formatTimeOnly(String? dt) {
    if (dt == null) return '';
    try {
      final date = DateTime.parse(dt);
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final ampm = date.hour < 12 ? 'AM' : 'PM';
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute $ampm';
    } catch (_) {
      return '';
    }
  }

  Map<String, List<RecentActivityModel>> _groupActivitiesByDate(List<RecentActivityModel> list) {
    final Map<String, List<RecentActivityModel>> groups = {};
    for (final act in list) {
      try {
        final date = DateTime.parse(act.createdAt);
        final dateStr = _formatGroupDate(date);
        groups.putIfAbsent(dateStr, () => []).add(act);
      } catch (_) {
        groups.putIfAbsent('Unknown Date', () => []).add(act);
      }
    }
    return groups;
  }

  _ActivityStyle _getActivityStyle(RecentActivityModel activity) {
    final String type = activity.action.toUpperCase();
    final String desc = activity.details.toLowerCase();
    
    if (type == 'MEMBER' || (type == 'ROLE_CHANGE' && desc.contains('member') && !desc.contains('promoted'))) {
      return const _ActivityStyle(
        icon: Icons.person_add_outlined,
        badgeText: 'Member',
        color: Color(0xFF166534),
        bgColor: Color(0xFFDCFCE7),
      );
    } else if (activity.user?.role == 'ADMIN' || (type == 'ROLE_CHANGE' && desc.contains('admin') && !desc.contains('sub admin') && !desc.contains('promoted'))) {
      return const _ActivityStyle(
        icon: Icons.person_add_alt_1_outlined,
        badgeText: 'Admin',
        color: Color(0xFF1E3A8A),
        bgColor: Color(0xFFDBEAFE),
      );
    } else if (activity.user?.role == 'SUB_ADMIN' || (type == 'ROLE_CHANGE' && desc.contains('sub admin') && !desc.contains('promoted'))) {
      return const _ActivityStyle(
        icon: Icons.person_add_alt_outlined,
        badgeText: 'Sub Admin',
        color: Color(0xFF0369A1),
        bgColor: Color(0xFFE0F2FE),
      );
    } else if (type == 'EVENT') {
      return const _ActivityStyle(
        icon: Icons.event_note_outlined,
        badgeText: 'Event',
        color: Color(0xFF6B21A8),
        bgColor: Color(0xFFF3E8FF),
      );
    } else if (type == 'EMERGENCY') {
      return const _ActivityStyle(
        icon: Icons.warning_amber_outlined,
        badgeText: 'Emergency',
        color: Color(0xFF991B1B),
        bgColor: Color(0xFFFEE2E2),
      );
    } else if (type == 'BROADCAST') {
      return const _ActivityStyle(
        icon: Icons.campaign_outlined,
        badgeText: 'Broadcast',
        color: Color(0xFF1D4ED8),
        bgColor: Color(0xFFDBEAFE),
      );
    } else if (type == 'APPROVAL') {
      return const _ActivityStyle(
        icon: Icons.verified_user_outlined,
        badgeText: 'Approval',
        color: Color(0xFF15803D),
        bgColor: Color(0xFFDCFCE7),
      );
    } else if (type == 'ROLE_CHANGE' || desc.contains('promoted')) {
      return const _ActivityStyle(
        icon: Icons.swap_horiz_rounded,
        badgeText: 'Role Change',
        color: Color(0xFFC2410C),
        bgColor: Color(0xFFFFEDD5),
      );
    }
    
    return const _ActivityStyle(
      icon: Icons.info_outline_rounded,
      badgeText: 'Activity',
      color: Colors.blueGrey,
      bgColor: Color(0xFFECEFF1),
    );
  }

  Widget _buildRichMessage(String text) {
    final parts = text.split('**');
    final List<TextSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFF1F2937),
            fontSize: 14,
          ),
        ),
      );
    }
    return RichText(
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalItems = _allLoadedActivities.length;
    final int totalPages = ((totalItems - 1) / _pageSize).floor() + 1;
    
    final int startIndex = (_currentPage - 1) * _pageSize;
    final int endIndex = (startIndex + _pageSize) > totalItems ? totalItems : (startIndex + _pageSize);
    
    final List<RecentActivityModel> pageActivities = totalItems > 0 
        ? _allLoadedActivities.sublist(startIndex, endIndex)
        : [];
        
    final groupedActivities = _groupActivitiesByDate(pageActivities);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: NTKAppBar(
        title: 'Activity Log',
        subtitle: 'Dashboard › Activity Log',
        showNotification: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Chips Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(_chips.length, (index) {
                  final isSelected = _currentIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(_chips[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _currentIndex = index;
                          });
                          _fetchActivities();
                        }
                      },
                      selectedColor: const Color(0xFF0F5A29),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF374151),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : const Color(0xFFD1D5DB),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Filters Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                // Date Range Button
                Expanded(
                  child: InkWell(
                    onTap: _pickDateRange,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedDateRange == null
                                  ? 'Select Date Range'
                                  : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                              style: TextStyle(
                                fontSize: 13,
                                color: _selectedDateRange == null ? const Color(0xFF6B7280) : const Color(0xFF111827),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF6B7280)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Search Input
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                        // Simple debounce: wait a little or fetch instantly
                        _fetchActivities();
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search by name or action...',
                        hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                        border: InputBorder.none,
                        prefixIcon: Icon(CupertinoIcons.search, size: 16, color: Color(0xFF6B7280)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Filter button
                InkWell(
                  onTap: _showLocationFilterBottomSheet,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _appliedLocationFilter != null ? const Color(0xFFE8F5E9) : Colors.white,
                      border: Border.all(
                        color: _appliedLocationFilter != null ? const Color(0xFF0F5A29) : const Color(0xFFD1D5DB),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          size: 18,
                          color: _appliedLocationFilter != null ? const Color(0xFF0F5A29) : const Color(0xFF374151),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Filter',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _appliedLocationFilter != null ? const Color(0xFF0F5A29) : const Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main list or loading spinner
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF0F5A29))))
                : totalItems == 0
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            const Text(
                              'No activities found matching filters',
                              style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              itemCount: groupedActivities.keys.length,
                              itemBuilder: (context, dateIndex) {
                                final dateStr = groupedActivities.keys.elementAt(dateIndex);
                                final list = groupedActivities[dateStr]!;
                                
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Date Header
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                                      child: Text(
                                        dateStr,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                    ),
                                    
                                    // Timeline List
                                    ...List.generate(list.length, (itemIndex) {
                                      final activity = list[itemIndex];
                                      final style = _getActivityStyle(activity);
                                      final isLast = dateIndex == groupedActivities.keys.length - 1 && itemIndex == list.length - 1;
                                      
                                      return IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            // Timeline dot and line
                                            Column(
                                              children: [
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: style.bgColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(style.icon, size: 16, color: style.color),
                                                ),
                                                Expanded(
                                                  child: Container(
                                                    width: isLast ? 0 : 2,
                                                    color: isLast ? Colors.transparent : const Color(0xFFE5E7EB),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 16),
                                            
                                            // Content
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(bottom: 24.0),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // Time
                                                    SizedBox(
                                                      width: 70,
                                                      child: Text(
                                                        _formatTimeOnly(activity.createdAt),
                                                        style: const TextStyle(
                                                          color: Color(0xFF6B7280),
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),

                                                    // Text Action Description
                                                    Expanded(
                                                      child: _buildRichMessage(activity.details),
                                                    ),
                                                    const SizedBox(width: 12),

                                                    // Badge Label
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: style.bgColor,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        style.badgeText,
                                                        style: TextStyle(
                                                          color: style.color,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              },
                            ),
                          ),

                          // Pagination row
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Page controls row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Prev page
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left, size: 20),
                                      onPressed: _currentPage > 1
                                          ? () => setState(() => _currentPage--)
                                          : null,
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                    ),
                                    const SizedBox(width: 4),

                                    // Direct page buttons or dots
                                    ...List.generate(totalPages > 5 ? 5 : totalPages, (index) {
                                      final pageNum = index + 1;
                                      final isSelected = _currentPage == pageNum;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                        child: InkWell(
                                          onTap: () => setState(() => _currentPage = pageNum),
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
                                              border: Border.all(
                                                color: isSelected ? const Color(0xFF0F5A29) : Colors.transparent,
                                              ),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              pageNum.toString(),
                                              style: TextStyle(
                                                color: isSelected ? const Color(0xFF0F5A29) : const Color(0xFF4B5563),
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),

                                    if (totalPages > 5) ...[
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 3.0),
                                        child: Text('...', style: TextStyle(color: Color(0xFF9CA3AF))),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                        child: InkWell(
                                          onTap: () => setState(() => _currentPage = totalPages),
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: _currentPage == totalPages ? const Color(0xFFE8F5E9) : Colors.transparent,
                                              border: Border.all(
                                                color: _currentPage == totalPages ? const Color(0xFF0F5A29) : Colors.transparent,
                                              ),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              totalPages.toString(),
                                              style: TextStyle(
                                                color: _currentPage == totalPages ? const Color(0xFF0F5A29) : const Color(0xFF4B5563),
                                                fontWeight: _currentPage == totalPages ? FontWeight.bold : FontWeight.normal,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],

                                    const SizedBox(width: 4),
                                    // Next page
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right, size: 20),
                                      onPressed: _currentPage < totalPages
                                          ? () => setState(() => _currentPage++)
                                          : null,
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                // Status text below controls
                                Text(
                                  'Showing ${startIndex + 1} to $endIndex of $totalItems',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _ActivityStyle {
  final IconData icon;
  final String badgeText;
  final Color color;
  final Color bgColor;

  const _ActivityStyle({
    required this.icon,
    required this.badgeText,
    required this.color,
    required this.bgColor,
  });
}
