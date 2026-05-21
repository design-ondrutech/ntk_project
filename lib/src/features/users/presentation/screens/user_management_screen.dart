import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_management_bloc.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_management_event.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_management_state.dart';
import 'package:ntk_project/src/features/members/data/models/member_model.dart';

class UserManagementScreen extends StatefulWidget {
  final int? locationId;
  final String? locationName;

  const UserManagementScreen({super.key, this.locationId, this.locationName});
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  int _selectedTab = 0; // 0=All, 1=Admin, 2=Sub Admin, 3=Member, 4=Pending
  final List<String> _tabs = ['All', 'Admin', 'Sub Admin', 'Member', 'Pending'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _userRole = 'SUPER_ADMIN';

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
    final authState = context.read<AuthBloc>().state;
    _userRole = authState.loginData?.role ?? 'SUPER_ADMIN';
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
    _loadUsers();
    // Load stats for the specific location to update summary cards
    final targetLocationId =
        widget.locationId ?? authState.loginData?.locationId;
    if (targetLocationId != null) {
      context.read<DashboardBloc>().add(LoadDashboardStats(targetLocationId));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadUsers() {
    final authState = context.read<AuthBloc>().state;
    context.read<UserManagementBloc>().add(
      LoadUsers(
        locationId: widget.locationId ?? authState.loginData?.locationId,
        type: _tabs[_selectedTab],
        streetId: _selectedStreetId,
      ),
    );
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
    var result = users;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: NTKAppBar(
        title: 'Members',
        subtitle:
            widget.locationName ??
            context.read<AuthBloc>().state.loginData?.locationName ??
            _getDashboardLocationName(context) ??
            'Tamil Nadu',
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<UserManagementBloc, UserManagementState>(
                builder: (context, state) {
                  return CustomScrollView(
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

                              // ── Filter Chips ─────────────────────────
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: List.generate(_visibleTabs.length, (
                                    i,
                                  ) {
                                    final tabName = _visibleTabs[i];
                                    final tabIndex = _tabs.indexOf(tabName);
                                    final isSelected = _selectedTab == tabIndex;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(
                                            () => _selectedTab = tabIndex,
                                          );
                                          _loadUsers();
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? NTKColors.primary
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: NTKColors.primary
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        3,
                                                      ),
                                                    ),
                                                  ]
                                                : [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.05,
                                                          ),
                                                      blurRadius: 4,
                                                      offset: const Offset(
                                                        0,
                                                        1,
                                                      ),
                                                    ),
                                                  ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (tabIndex == 0 &&
                                                  isSelected) ...[
                                                const Icon(
                                                  Icons.tune,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                              ],
                                              Text(
                                                tabName,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : const Color(0xFF6B7280),
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ── Admin/Sub Admin Filters (Street, Blood Group, Profession) ──
                              if (_userRole == 'SUB_ADMIN' ||
                                  _userRole == 'ADMIN')
                                BlocBuilder<
                                  UserManagementBloc,
                                  UserManagementState
                                >(
                                  builder: (context, umState) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              // Street filter
                                              _buildFilterChip(
                                                label:
                                                    _selectedStreetName ??
                                                    'Street',
                                                isActive:
                                                    _selectedStreetId != null,
                                                onTap: () => _showStreetPicker(
                                                  context,
                                                  umState.streets,
                                                  umState.isLoadingStreets,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Blood Group filter
                                              _buildFilterChip(
                                                label:
                                                    _selectedBloodGroup ??
                                                    'Blood Group',
                                                isActive:
                                                    _selectedBloodGroup != null,
                                                onTap: () =>
                                                    _showBloodGroupPicker(
                                                      context,
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Profession filter
                                              _buildFilterChip(
                                                label:
                                                    _selectedProfession ??
                                                    'Profession',
                                                isActive:
                                                    _selectedProfession != null,
                                                onTap: () =>
                                                    _showProfessionPicker(
                                                      context,
                                                    ),
                                              ),
                                              if (_selectedStreetId != null ||
                                                  _selectedBloodGroup != null ||
                                                  _selectedProfession !=
                                                      null) ...[
                                                const SizedBox(width: 8),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedStreetId = null;
                                                      _selectedStreetName =
                                                          null;
                                                      _selectedBloodGroup =
                                                          null;
                                                      _selectedProfession =
                                                          null;
                                                    });
                                                    _loadUsers();
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFFFE4E6,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: const Row(
                                                      children: [
                                                        Icon(
                                                          Icons.close,
                                                          size: 14,
                                                          color: Color(
                                                            0xFFBE123C,
                                                          ),
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'Clear',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Color(
                                                              0xFFBE123C,
                                                            ),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    );
                                  },
                                ),

                              // ── Stats Cards ──────────────────────────
                              BlocBuilder<DashboardBloc, DashboardState>(
                                builder: (context, dashState) {
                                  final stats = dashState.stats;
                                  final totalCount = _selectedTab == 1
                                      ? (stats?.totalAdmins ?? 0)
                                      : _selectedTab == 2
                                      ? (stats?.totalSubAdmins ?? 0)
                                      : _selectedTab == 4
                                      ? (stats?.pendingApprovals ?? 0)
                                      : (stats?.totalMembers ?? 0);
                                  final activeCount = state.users
                                      .where((u) => u.isActive)
                                      .length;

                                  final tabLabel = _tabs[_selectedTab]
                                      .toUpperCase();
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          'TOTAL\n$tabLabel',
                                          _formatNumber(totalCount),
                                          const Color(0xFF1F2937),
                                          isHighlight: false,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatCard(
                                          'ACTIVE TODAY',
                                          activeCount.toString(),
                                          NTKColors.primary,
                                          isHighlight: true,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                      // ── User List ────────────────────────────────
                      if (state.isLoading)
                        const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (state.error != null)
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
                                      final user = _filteredUsers(
                                        state.users,
                                      )[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _buildMemberCard(user),
                                      );
                                    },
                                    childCount: _filteredUsers(
                                      state.users,
                                    ).length,
                                  ),
                                ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ── FAB ─────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_userRole == 'SUB_ADMIN') {
            Navigator.pushNamed(context, '/create_member');
          } else {
            _showAddUserSheet(context);
          }
        },
        backgroundColor: NTKColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar ──────────────────────────────────────
          Stack(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: user.isActive
                        ? NTKColors.primary
                        : Colors.grey[300]!,
                    width: 2.5,
                  ),
                  color: const Color(0xFFE8F5E9),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: NTKColors.primary,
                    ),
                  ),
                ),
              ),
              if (user.isActive)
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // ── Info ─────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Role badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleBgColor(user.role),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getRoleLabel(user.role),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getRoleTextColor(user.role),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Location
                if (user.location != null)
                  Text(
                    user.location!.name,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                const SizedBox(height: 8),

                // Blood group + Status badge
                Row(
                  children: [
                    if (user.bloodGroup != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4E6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.bloodGroup!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFBE123C),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusBgColor(user),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusLabel(user),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusTextColor(user),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Action Icons ─────────────────────────────────
          Column(
            children: [
              _actionIcon(
                Icons.phone_outlined,
                NTKColors.primary,
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _actionIcon(
                Icons.chat_bubble_outline_rounded,
                NTKColors.primary,
                onTap: () {},
              ),
            ],
          ),
        ],
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
}
