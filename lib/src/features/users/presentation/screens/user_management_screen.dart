import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_management_bloc.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_management_event.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_management_state.dart';
import 'package:ntk_project/src/features/members/data/models/member_model.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';
import 'package:ntk_project/src/features/location/domain/repositories/location_repository.dart';
import 'package:ntk_project/src/injection_container.dart';
import 'package:url_launcher/url_launcher.dart';

class UserManagementScreen extends StatefulWidget {
  final int? locationId;
  final String? locationName;
  final String? initialTab;

  static final GlobalKey<UserManagementScreenState> userManagementKey = GlobalKey<UserManagementScreenState>();

  const UserManagementScreen({
    super.key,
    this.locationId,
    this.locationName,
    this.initialTab,
  });
  @override
  State<UserManagementScreen> createState() => UserManagementScreenState();
}

class UserManagementScreenState extends State<UserManagementScreen> {
  void selectTab(String tabName) {
    final tabIndex = _tabs.indexOf(tabName);
    if (tabIndex != -1) {
      setState(() {
        _selectedTab = tabIndex;
      });
      _loadUsers();
    }
  }

  final ScrollController _scrollController = ScrollController();
  int _selectedTab = 0; // 0=All, 1=Admin, 2=Sub Admin, 3=Member, 4=Pending
  final List<String> _tabs = ['All', 'Admin', 'Sub Admin', 'Member', 'Pending'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _userRole = 'MEMBER';
  // Hierarchical locations
  List<LocationModel> _districts = [];
  List<LocationModel> _constituencies = [];
  List<LocationModel> _areas = [];
  List<LocationModel> _streets = [];

  LocationModel? _selectedDistrict;
  LocationModel? _selectedConstituency;
  LocationModel? _selectedArea;
  LocationModel? _selectedStreet;

  // Sub Admin filters
  String? _selectedBloodGroup;
  String? _selectedProfession;
  int? _selectedStreetId;
  String? _selectedStreetName;

  static const List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  static const List<String> _professions = [
    'Farmer',
    'Teacher',
    'Doctor',
    'Engineer',
    'Lawyer',
    'Business',
    'Government Employee',
    'Private Employee',
    'Student',
    'Other',
  ];

  // Sub Admin sees only Member tab
  List<String> get _visibleTabs {
    if (_userRole == 'SUB_ADMIN') return ['Member'];
    return _tabs;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final authState = context.read<AuthBloc>().state;
    _userRole = authState.loginData?.role ?? 'MEMBER';
    if (widget.initialTab != null && _tabs.contains(widget.initialTab)) {
      _selectedTab = _tabs.indexOf(widget.initialTab!);
    }
    
    // Sync initially with Dashboard's globalLocation if any
    final dashState = context.read<DashboardBloc>().state;
    final globalLocation = dashState.globalLocation;
    if (globalLocation != null) {
      final type = globalLocation.type?.toUpperCase();
      if (type == 'DISTRICT') {
        _selectedDistrict = globalLocation;
      } else if (type == 'TALUK') {
        _selectedConstituency = globalLocation;
      } else if (type == 'AREA') {
        _selectedArea = globalLocation;
      } else if (type == 'STREET') {
        _selectedStreet = globalLocation;
      }
    }

    // Sub Admin defaults to Member tab
    if (_userRole == 'SUB_ADMIN' || _userRole == 'ADMIN') {
      if (_userRole == 'SUB_ADMIN') {
        _selectedTab = _tabs.indexOf('Member');
      }
      // Load streets for filter
      final locationId = authState.loginData?.locationId;
      if (locationId != null) {
        context.read<UserManagementBloc>().add(
          LoadStreets(parentId: locationId),
        );
      }
    }
    _loadInitialLocationOptions();

    // If we have selected location, pre-load child options
    if (globalLocation != null) {
      final type = globalLocation.type?.toUpperCase();
      if (type == 'DISTRICT') {
        _loadConstituencies(globalLocation.id);
      } else if (type == 'TALUK') {
        _loadAreas(globalLocation.id);
      } else if (type == 'AREA') {
        _loadStreets(globalLocation.id);
      }
    }

    _loadUsers();
    // Load stats for the specific location to update summary cards
    final targetLocationId =
        widget.locationId ?? authState.loginData?.locationId;
    if (targetLocationId != null) {
      context.read<DashboardBloc>().add(LoadDashboardStats(targetLocationId));
    }
  }

  Future<void> _loadInitialLocationOptions() async {
    try {
      final authState = context.read<AuthBloc>().state;
      final authLocationId = authState.loginData?.locationId;
      final role = authState.loginData?.role;
      final dashState = context.read<DashboardBloc>().state;
      final globalLocation = dashState.globalLocation;
      final statsLocationName = dashState.stats?.locationName;

      if (role == 'SUPER_ADMIN') {
        final districts = await sl<LocationRepository>().getDistricts();
        if (!mounted) return;
        setState(() => _districts = districts);

        // 1) Match by globalLocation ID
        if (globalLocation != null) {
          final type = globalLocation.type?.toUpperCase();
          if (type == 'DISTRICT' && _selectedDistrict == null) {
            final match = districts.where((d) => d.id == globalLocation.id).firstOrNull;
            if (match != null) {
              setState(() => _selectedDistrict = match);
              await _loadConstituencies(match.id, clearSelection: false);
              _loadUsers();
              return;
            }
          }
        }
        // 2) Fall back: match by stats locationName
        if (_selectedDistrict == null && statsLocationName != null && statsLocationName != 'Tamil Nadu') {
          final match = districts.where((d) => d.name.toLowerCase() == statsLocationName.toLowerCase()).firstOrNull;
          if (match != null && mounted) {
            setState(() => _selectedDistrict = match);
            await _loadConstituencies(match.id, clearSelection: false);
            _loadUsers();
          }
        }

      } else if (role == 'ADMIN' && authLocationId != null) {
        final taluks = await sl<LocationRepository>().getLocationList(
          parentId: authLocationId,
          type: 'TALUK',
        );
        if (!mounted) return;
        setState(() => _constituencies = taluks);

        // 1) Match by globalLocation ID
        if (globalLocation != null) {
          final type = globalLocation.type?.toUpperCase();
          if (type == 'TALUK' && _selectedConstituency == null) {
            final match = taluks.where((t) => t.id == globalLocation.id).firstOrNull;
            if (match != null) {
              setState(() => _selectedConstituency = match);
              await _loadAreas(match.id, clearSelection: false);
              _loadUsers();
              return;
            }
          }
        }
        // 2) Fall back: match by stats locationName
        if (_selectedConstituency == null && statsLocationName != null && statsLocationName != 'Tamil Nadu') {
          final match = taluks.where((t) => t.name.toLowerCase() == statsLocationName.toLowerCase()).firstOrNull;
          if (match != null && mounted) {
            setState(() => _selectedConstituency = match);
            await _loadAreas(match.id, clearSelection: false);
            _loadUsers();
          }
        }

      } else if (role == 'SUB_ADMIN' && authLocationId != null) {
        // authLocationId for SUB_ADMIN is their AREA id. Load streets directly.
        final streets = await sl<LocationRepository>().getLocationList(
          parentId: authLocationId,
          type: 'STREET',
        );
        if (!mounted) return;
        setState(() => _streets = streets);

        // Auto-select street if matching globalLocation
        if (globalLocation != null) {
          final type = globalLocation.type?.toUpperCase();
          if (type == 'STREET' && _selectedStreet == null) {
            final match = streets.where((s) => s.id == globalLocation.id).firstOrNull;
            if (match != null) {
              setState(() => _selectedStreet = match);
              _loadUsers();
              return;
            }
          }
        }

      } else {
        final districts = await sl<LocationRepository>().getDistricts();
        if (!mounted) return;
        setState(() => _districts = districts);

        if (_selectedDistrict == null && statsLocationName != null && statsLocationName != 'Tamil Nadu') {
          final match = districts.where((d) => d.name.toLowerCase() == statsLocationName.toLowerCase()).firstOrNull;
          if (match != null && mounted) {
            setState(() => _selectedDistrict = match);
            await _loadConstituencies(match.id, clearSelection: false);
            _loadUsers();
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _loadConstituencies(int districtId, {bool clearSelection = true}) async {
    try {
      final taluks = await sl<LocationRepository>().getLocationList(
        parentId: districtId,
        type: 'TALUK',
      );
      if (mounted) {
        setState(() {
          _constituencies = taluks;
          if (clearSelection) {
            _selectedConstituency = null;
            _areas = [];
            _selectedArea = null;
            _streets = [];
            _selectedStreet = null;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadAreas(int constituencyId, {bool clearSelection = true}) async {
    try {
      final areas = await sl<LocationRepository>().getLocationList(
        parentId: constituencyId,
        type: 'AREA',
      );
      if (mounted) {
        setState(() {
          _areas = areas;
          if (clearSelection) {
            _selectedArea = null;
            _streets = [];
            _selectedStreet = null;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadStreets(int areaId, {bool clearSelection = true}) async {
    try {
      final streets = await sl<LocationRepository>().getLocationList(
        parentId: areaId,
        type: 'STREET',
      );
      if (mounted) {
        setState(() {
          _streets = streets;
          if (clearSelection) _selectedStreet = null;
        });
      }
    } catch (_) {}
  }

  String _getLocationSubtitle(BuildContext context) {
    if (_selectedStreet != null) return _selectedStreet!.name;
    if (_selectedArea != null) return _selectedArea!.name;
    if (_selectedConstituency != null) return _selectedConstituency!.name;
    if (_selectedDistrict != null) return _selectedDistrict!.name;

    if (widget.locationName != null && widget.locationName!.isNotEmpty) {
      return widget.locationName!;
    }
    
    final authState = context.read<AuthBloc>().state;
    final loginLocationName = authState.loginData?.locationName;
    return loginLocationName ?? 'Tamil Nadu';
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      _loadMoreUsers();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll < 0) return false; // Prevent negative scroll trigger (e.g. pull-to-refresh)
    return currentScroll >= (maxScroll - 200);
  }

  int? _getLowestLocationId() {
    if (_selectedStreet != null) return _selectedStreet!.id;
    if (_selectedArea != null) return _selectedArea!.id;
    if (_selectedConstituency != null) return _selectedConstituency!.id;
    if (_selectedDistrict != null) return _selectedDistrict!.id;
    return context.read<AuthBloc>().state.loginData?.locationId;
  }

  void _loadMoreUsers() {
    final bloc = context.read<UserManagementBloc>();
    if (bloc.state.isLoadingMore || bloc.state.hasReachedMax) return;

    bloc.add(
      LoadUsers(
        locationId: widget.locationId ?? _getLowestLocationId(),
        type: _tabs[_selectedTab],
        streetId: _selectedStreet?.id,
        bloodGroup: _selectedBloodGroup,
        profession: _selectedProfession,
        isLoadMore: true,
      ),
    );
  }

  void _loadUsers() {
    final locationId = widget.locationId ?? _getLowestLocationId();
    context.read<UserManagementBloc>().add(
      LoadUsers(
        locationId: locationId,
        type: _tabs[_selectedTab],
        streetId: _selectedStreet?.id,
        bloodGroup: _selectedBloodGroup,
        profession: _selectedProfession,
      ),
    );
    if (locationId != null) {
      context.read<DashboardBloc>().add(LoadDashboardStats(locationId));
    }
  }


  String? _getDashboardLocationName(BuildContext context) {
    try {
      return BlocProvider.of<DashboardBloc>(context).state.stats?.locationName;
    } catch (_) {
      return null;
    }
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'ADMIN':
        return 'Admin';
      case 'SUB_ADMIN':
        return 'Sub Admin';
      case 'MEMBER':
        return 'Member';
      case 'SUPER_ADMIN':
        return 'Super Admin';
      default:
        return role ?? 'Member';
    }
  }

  Color _getRoleBgColor(String? role) {
    switch (role) {
      case 'ADMIN':
        return const Color(0xFFE0E7FF);
      case 'SUB_ADMIN':
        return const Color(0xFFDCFCE7);
      case 'SUPER_ADMIN':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _getRoleTextColor(String? role) {
    switch (role) {
      case 'ADMIN':
        return const Color(0xFF4338CA);
      case 'SUB_ADMIN':
        return const Color(0xFF065F46);
      case 'SUPER_ADMIN':
        return const Color(0xFF92400E);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusLabel(MemberModel user) {
    if (user.approvalStatus == 'PENDING') return 'Pending';
    if (user.approvalStatus == 'APPROVED' && user.isActive) return 'Verified';
    if (!user.isActive) return 'Inactive';
    return 'Active';
  }

  Color _getStatusBgColor(MemberModel user) {
    if (user.approvalStatus == 'PENDING') return const Color(0xFFFEF3C7);
    if (!user.isActive) return const Color(0xFFF3F4F6);
    return const Color(0xFFDCFCE7);
  }

  Color _getStatusTextColor(MemberModel user) {
    if (user.approvalStatus == 'PENDING') return const Color(0xFF92400E);
    if (!user.isActive) return const Color(0xFF6B7280);
    return const Color(0xFF065F46);
  }

  List<MemberModel> _filteredUsers(List<MemberModel> users) {
    var result = List<MemberModel>.from(users);

    // Filter by role based on the selected tab/type
    final currentTabType = _tabs[_selectedTab];
    if (currentTabType == 'Member') {
      result = result
          .where(
            (u) =>
                u.role == null ||
                u.role!.isEmpty ||
                u.role!.toUpperCase() == 'MEMBER',
          )
          .toList();
    } else if (currentTabType == 'Admin') {
      result = result.where((u) => u.role?.toUpperCase() == 'ADMIN').toList();
    } else if (currentTabType == 'Sub Admin') {
      result = result
          .where((u) => u.role?.toUpperCase() == 'SUB_ADMIN')
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (u) =>
                u.name.toLowerCase().contains(q) ||
                (u.phone ?? '').contains(q) ||
                (u.location?.name.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    if (_selectedBloodGroup != null) {
      result = result
          .where((u) => u.bloodGroup == _selectedBloodGroup)
          .toList();
    }
    if (_selectedProfession != null) {
      result = result
          .where(
            (u) =>
                (u.professionName ?? '').toLowerCase() ==
                _selectedProfession!.toLowerCase(),
          )
          .toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DashboardBloc, DashboardState>(
          listenWhen: (previous, current) => previous.globalLocation != current.globalLocation,
          listener: (context, state) {
            final globalLocation = state.globalLocation;
            if (globalLocation != null) {
              final type = globalLocation.type?.toUpperCase();
              if (type == 'DISTRICT' && globalLocation != _selectedDistrict) {
                setState(() {
                  _selectedDistrict = globalLocation;
                  _constituencies = [];
                  _selectedConstituency = null;
                  _areas = [];
                  _selectedArea = null;
                  _streets = [];
                  _selectedStreet = null;
                });
                _loadConstituencies(globalLocation.id);
                _loadUsers();
              } else if (type == 'TALUK' && globalLocation != _selectedConstituency) {
                setState(() {
                  _selectedConstituency = globalLocation;
                  _areas = [];
                  _selectedArea = null;
                  _streets = [];
                  _selectedStreet = null;
                });
                _loadAreas(globalLocation.id);
                _loadUsers();
              } else if (type == 'AREA' && globalLocation != _selectedArea) {
                setState(() {
                  _selectedArea = globalLocation;
                  _streets = [];
                  _selectedStreet = null;
                });
                _loadStreets(globalLocation.id);
                _loadUsers();
              } else if (type == 'STREET' && globalLocation != _selectedStreet) {
                setState(() {
                  _selectedStreet = globalLocation;
                });
                _loadUsers();
              }
            } else {
              setState(() {
                _selectedDistrict = null;
                _constituencies = [];
                _selectedConstituency = null;
                _areas = [];
                _selectedArea = null;
                _streets = [];
                _selectedStreet = null;
              });
              _loadUsers();
            }
          },
        ),
        BlocListener<UserManagementBloc, UserManagementState>(
          listenWhen: (previous, current) => previous.error != current.error && current.error != null,
          listener: (context, state) {
            if (state.users.isNotEmpty) {
              NTKSnackbar.showError(
                context,
                message: state.error!,
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
      appBar: NTKAppBar(
        title: 'Members',
        subtitle: _getLocationSubtitle(context),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<UserManagementBloc, UserManagementState>(
                builder: (context, state) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      _loadUsers();
                    },
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Search Bar ──────────────────────────
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.06,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (v) =>
                                      setState(() => _searchQuery = v),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Search members by name or street...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.grey[400],
                                      size: 22,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // ── New Filter Grid ─────────────────────────
                              _buildFilterGrid(),
                              const SizedBox(height: 12),
                              
                              // ── Breadcrumbs ─────────────────────────────
                              _buildBreadcrumbs(),
                              const SizedBox(height: 16),

                              // ── Horizontal Stats Row ────────────────────
                              _buildHorizontalStats(),
                              const SizedBox(height: 20),
                              
                              // ── List Header ─────────────────────────────
                              _buildListHeader(state),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),

                      // ── User List ────────────────────────────────
                      if (state.isLoading)
                        const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (state.error != null && state.users.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    state.error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadUsers,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          sliver: _filteredUsers(state.users).isEmpty
                              ? SliverFillRemaining(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.people_outline,
                                          size: 56,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No users found',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final filteredList = _filteredUsers(
                                        state.users,
                                      );
                                      if (index >= filteredList.length) {
                                        return const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      final user = filteredList[index];
                                      return _buildMemberCard(user);
                                    },
                                    childCount:
                                        _filteredUsers(state.users).length +
                                        (state.isLoadingMore ? 1 : 0),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddUserSheet(context),
          backgroundColor: NTKColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  // ── Stat Card ──────────────────────────────────────────
  Widget _buildStatCard(
    String label,
    String value,
    Color valueColor, {
    required bool isHighlight,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Member Card ────────────────────────────────────────
  Widget _buildMemberCard(MemberModel user) {
    final initials = user.name.isNotEmpty
        ? user.name
              .trim()
              .split(' ')
              .map((w) => w.isNotEmpty ? w[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : '?';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/profile', arguments: user.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar ──────────────────────────────────────
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE8F5E9),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: NTKColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // ── Info ─────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleBgColor(user.role),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getRoleLabel(user.role),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _getRoleTextColor(user.role),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.location?.name ?? 'Unknown Location',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.phone ?? 'No Phone',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Action Buttons ────────────────────────────────
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.phone, color: Color(0xFF166534), size: 18),
                      onPressed: () async {
                        final phone = user.phone;
                        if (phone == null || phone.isEmpty) return;
                        final uri = Uri(scheme: 'tel', path: phone);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.wechat_rounded, color: Color(0xFF166534), size: 18),
                      onPressed: () async {
                        final phone = user.phone;
                        if (phone == null || phone.isEmpty) return;
                        // Remove leading 0 or + and add country code +91
                        final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
                        final number = cleaned.startsWith('91')
                            ? cleaned
                            : '91$cleaned';
                        final uri = Uri.parse('https://wa.me/$number');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return n.toString();
  }

  // ── Filter chip widget ────────────────────────────────
  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? NTKColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? NTKColors.primary : const Color(0xFFE5E7EB),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? NTKColors.primary : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isActive ? NTKColors.primary : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  // ── Street picker ─────────────────────────────────────
  void _showStreetPicker(BuildContext context, List streets, bool isLoading) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Street',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (streets.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No streets available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: const Text('All Streets'),
                      leading: Icon(
                        _selectedStreetId == null
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: NTKColors.primary,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedStreetId = null;
                          _selectedStreetName = null;
                        });
                        Navigator.pop(context);
                        _loadUsers();
                      },
                    ),
                    ...streets.map(
                      (s) => ListTile(
                        title: Text(s.name),
                        leading: Icon(
                          _selectedStreetId == s.id
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: NTKColors.primary,
                        ),
                        onTap: () {
                          setState(() {
                            _selectedStreetId = s.id as int;
                            _selectedStreetName = s.name as String;
                          });
                          Navigator.pop(context);
                          _loadUsers();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Blood Group picker ────────────────────────────────
  void _showBloodGroupPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Blood Group',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedBloodGroup = null);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedBloodGroup == null
                          ? NTKColors.primary
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'All',
                      style: TextStyle(
                        color: _selectedBloodGroup == null
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                ..._bloodGroups.map(
                  (bg) => GestureDetector(
                    onTap: () {
                      setState(() => _selectedBloodGroup = bg);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedBloodGroup == bg
                            ? const Color(0xFFFFE4E6)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedBloodGroup == bg
                              ? const Color(0xFFBE123C)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        bg,
                        style: TextStyle(
                          color: _selectedBloodGroup == bg
                              ? const Color(0xFFBE123C)
                              : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Profession picker ─────────────────────────────────
  void _showProfessionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Profession',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('All Professions'),
                    leading: Icon(
                      _selectedProfession == null
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: NTKColors.primary,
                    ),
                    onTap: () {
                      setState(() => _selectedProfession = null);
                      Navigator.pop(context);
                    },
                  ),
                  ..._professions.map(
                    (p) => ListTile(
                      title: Text(p),
                      leading: Icon(
                        _selectedProfession == p
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: NTKColors.primary,
                      ),
                      onTap: () {
                        setState(() => _selectedProfession = p);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddUserSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New User',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Super Admin can add Admin
            if (_userRole == 'SUPER_ADMIN') ...[
              _addOption(Icons.admin_panel_settings_outlined, 'Add Admin', () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/create_admin');
              }),
              const SizedBox(height: 12),
            ],
            // Super Admin and Admin can add Sub Admin
            if (_userRole == 'SUPER_ADMIN' || _userRole == 'ADMIN') ...[
              _addOption(Icons.badge_outlined, 'Add Sub Admin', () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/create_sub_admin');
              }),
              const SizedBox(height: 12),
            ],
            // All roles can add Member
            _addOption(Icons.person_add_outlined, 'Add Member', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/create_member');
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _addOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: NTKColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: NTKColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  // ── New UI Helpers ────────────────────────────────────────────────────────

  Widget _buildFilterGrid() {
    final authState = context.read<AuthBloc>().state;
    final role = authState.loginData?.role.toUpperCase() ?? '';

    List<Widget> filters = [];

    if (role != 'ADMIN' && role != 'SUB_ADMIN') {
      filters.add(
        _buildGridDropdown(
          'District',
          'All Districts',
          _districts,
          _selectedDistrict,
          (val) {
            setState(() => _selectedDistrict = val);
            if (val != null) {
              _loadConstituencies(val.id);
            } else {
              setState(() {
                _constituencies = [];
                _selectedConstituency = null;
                _areas = [];
                _selectedArea = null;
                _streets = [];
                _selectedStreet = null;
              });
            }
            _loadUsers();
          },
        ),
      );
    }

    if (role != 'SUB_ADMIN') {
      filters.add(
        _buildGridDropdown(
          'Thoguthi',
          'All Thoguthis',
          _constituencies,
          _selectedConstituency,
          (val) {
            setState(() => _selectedConstituency = val);
            if (val != null) {
              _loadAreas(val.id);
            } else {
              setState(() {
                _areas = [];
                _selectedArea = null;
                _streets = [];
                _selectedStreet = null;
              });
            }
            _loadUsers();
          },
        ),
      );
    }

    if (role != 'SUB_ADMIN') {
      filters.add(
        _buildGridDropdown(
          'Area',
          'All Areas',
          _areas,
          _selectedArea,
          (val) {
            setState(() => _selectedArea = val);
            if (val != null) {
              _loadStreets(val.id);
            } else {
              setState(() {
                _streets = [];
                _selectedStreet = null;
              });
            }
            _loadUsers();
          },
        ),
      );
    }

    filters.add(
      _buildGridDropdown(
        'Street',
        'All Streets',
        _streets,
        _selectedStreet,
        (val) {
          setState(() => _selectedStreet = val);
          _loadUsers();
        },
      ),
    );

    filters.add(
      _buildRoleDropdown(),
    );

    filters.add(
      GestureDetector(
        onTap: _showMoreFiltersSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'More Filters',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const Icon(Icons.tune_rounded, size: 16, color: Colors.black54),
            ],
          ),
        ),
      ),
    );

    List<Widget> rows = [];
    for (int i = 0; i < filters.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: filters[i]),
            const SizedBox(width: 8),
            if (i + 1 < filters.length) Expanded(child: filters[i + 1]) else const Expanded(child: SizedBox()),
          ],
        ),
      );
      if (i + 2 < filters.length) {
        rows.add(const SizedBox(height: 8));
      }
    }

    return Column(children: rows);
  }
  Widget _buildGridDropdown(
    String label,
    String hint,
    List<LocationModel> items,
    LocationModel? selectedItem,
    ValueChanged<LocationModel?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<LocationModel?>(
              value: selectedItem != null && items.any((item) => item.id == selectedItem.id)
                  ? items.firstWhere((item) => item.id == selectedItem.id)
                  : null,
              isExpanded: true,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black54),
              hint: Text(
                hint,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              selectedItemBuilder: (_) {
                return [
                  Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  ...items.map(
                    (item) => Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ];
              },
              items: [
                DropdownMenuItem<LocationModel?>(
                  value: null,
                  child: Text(
                    hint,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                ...items.map(
                  (item) => DropdownMenuItem<LocationModel?>(
                    value: item,
                    child: Text(
                      item.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildStaticGridDropdown(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black54),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown() {
    final currentTab = _tabs[_selectedTab];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 4),
          const Text(
            'Role',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentTab,
              isExpanded: true,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black54),
              selectedItemBuilder: (_) => _visibleTabs.map(
                (tab) => Text(
                  tab,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ).toList(),
              items: _visibleTabs.map(
                (tab) => DropdownMenuItem<String>(
                  value: tab,
                  child: Text(tab, style: const TextStyle(fontSize: 12)),
                ),
              ).toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _selectedTab = _tabs.indexOf(val);
                });
                _loadUsers();
              },
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    final parts = <String>['Tamil Nadu'];
    if (_selectedDistrict != null) parts.add(_selectedDistrict!.name);
    if (_selectedConstituency != null) parts.add(_selectedConstituency!.name);
    if (_selectedArea != null) parts.add(_selectedArea!.name);
    if (_selectedStreet != null) parts.add(_selectedStreet!.name);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        parts.join(' > '),
        style: const TextStyle(
          color: Color(0xFF166534),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHorizontalStats() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, dashState) {
        final stats = dashState.stats;
        final total = (stats?.totalAdmins ?? 0) + (stats?.totalSubAdmins ?? 0) + (stats?.totalMembers ?? 0);
        return Row(
          children: [
            Expanded(child: _buildSmallStatCard('Admins', stats?.totalAdmins ?? 0, const Color(0xFF166534))),
            const SizedBox(width: 8),
            Expanded(child: _buildSmallStatCard('Sub Admins', stats?.totalSubAdmins ?? 0, const Color(0xFF1E40AF))),
            const SizedBox(width: 8),
            Expanded(child: _buildSmallStatCard('Members', stats?.totalMembers ?? 0, const Color(0xFF065F46))),
            const SizedBox(width: 8),
            Expanded(child: _buildSmallStatCard('Total', total, const Color(0xFFB45309))),
          ],
        );
      },
    );
  }

  Widget _buildSmallStatCard(String label, int value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatNumber(value),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader(UserManagementState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Member List',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        Row(
          children: [
            const Text(
              'Sort',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.sort, size: 16, color: Colors.grey[600]),
          ],
        ),
      ],
    );
  }

  void _showMoreFiltersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'More Filters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Blood Group', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedBloodGroup,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('All')),
                      ..._bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))),
                    ],
                    onChanged: (val) => setSheetState(() => _selectedBloodGroup = val),
                  ),
                  const SizedBox(height: 16),
                  const Text('Profession', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedProfession,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('All')),
                      ..._professions.map((p) => DropdownMenuItem(value: p, child: Text(p))),
                    ],
                    onChanged: (val) => setSheetState(() => _selectedProfession = val),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              _selectedBloodGroup = null;
                              _selectedProfession = null;
                            });
                            setState(() {
                              _selectedBloodGroup = null;
                              _selectedProfession = null;
                            });
                            _loadUsers();
                            Navigator.pop(context);
                          },
                          child: const Text('Clear Filters'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {}); // to rebuild the calling widget if needed
                            _loadUsers();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F5A29),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

