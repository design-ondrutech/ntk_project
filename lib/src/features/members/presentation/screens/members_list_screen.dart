import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/widgets/async_base64_image.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_bloc.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_event.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_state.dart';
import 'package:ntk_project/src/features/members/data/models/member_model.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_bloc.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_event.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_state.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_event.dart';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  String? _searchQuery;
  String? _selectedBloodGroup;
  String? _selectedRole;
  int? _selectedLocationId;
  String? _selectedLocationName;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMembers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final authState = context.read<AuthBloc>().state;
      final locationId = _selectedLocationId ?? authState.loginData?.locationId;
      context.read<MemberBloc>().add(
        LoadMoreMembers(
          locationId: locationId,
          search: _searchQuery,
          bloodGroup: _selectedBloodGroup,
          role: _selectedRole,
        ),
      );
    }
  }

  void _fetchMembers() {
    final authState = context.read<AuthBloc>().state;
    final locationId = _selectedLocationId ?? authState.loginData?.locationId;
    context.read<MemberBloc>().add(
      LoadMembers(
        locationId: locationId,
        search: _searchQuery,
        bloodGroup: _selectedBloodGroup,
        role: _selectedRole,
      ),
    );
  }

  void _showBloodGroupPicker(BuildContext context) {
    final theme = Theme.of(context);
    final bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Blood Group', style: theme.textTheme.titleLarge),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: bloodGroups
                    .map(
                      (bg) => InkWell(
                        onTap: () {
                          setState(() {
                            _selectedBloodGroup = bg;
                          });
                          Navigator.pop(context);
                          _fetchMembers();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedBloodGroup == bg
                                ? theme.colorScheme.primary
                                : theme.dividerColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedBloodGroup == bg
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            bg,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedBloodGroup == bg
                                  ? Colors.white
                                  : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() => _selectedBloodGroup = null);
                  Navigator.pop(context);
                  _fetchMembers();
                },
                child: const Text('Clear Filter'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRolePicker(BuildContext context) {
    final theme = Theme.of(context);
    final roles = ['ADMIN', 'SUB_ADMIN', 'MEMBER', 'SUPER_ADMIN'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Role', style: theme.textTheme.titleLarge),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: roles
                    .map(
                      (role) => InkWell(
                        onTap: () {
                          setState(() {
                            _selectedRole = role;
                          });
                          Navigator.pop(context);
                          _fetchMembers();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedRole == role
                                ? theme.colorScheme.primary
                                : theme.dividerColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedRole == role
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            role,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedRole == role
                                  ? Colors.white
                                  : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() => _selectedRole = null);
                  Navigator.pop(context);
                  _fetchMembers();
                },
                child: const Text('Clear Filter'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getLocationSubtitle(AuthState authState) {
    if (_selectedLocationName != null) {
      return _selectedLocationName!;
    }
    final loginLocationName = authState.loginData?.locationName;
    if (loginLocationName != null &&
        loginLocationName.isNotEmpty &&
        !(authState.loginData?.role == 'SUB_ADMIN' &&
            loginLocationName == 'Tamil Nadu')) {
      return loginLocationName;
    }

    try {
      final dashboardState = BlocProvider.of<DashboardBloc>(context).state;
      final dashboardLocationName = dashboardState.stats?.locationName;
      if (dashboardLocationName != null && dashboardLocationName.isNotEmpty) {
        return dashboardLocationName;
      }
    } catch (_) {}

    return 'Tamil Nadu';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    final locationName = _selectedLocationName ?? authState.loginData?.locationName ?? 'Tamil Nadu';
    final districtFilterValue = (locationName == 'Tamil Nadu') ? 'All Districts' : locationName;

    return Scaffold(
      backgroundColor: NTKColors.background,
      appBar: NTKAppBar(
        title: 'Members',
        subtitle: _getLocationSubtitle(authState),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.bell, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: BlocBuilder<MemberBloc, MemberState>(
        builder: (context, state) {
          return Column(
            children: [
              Container(
                color: NTKColors.surface,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        _searchQuery = value.trim().isNotEmpty ? value : null;
                        _fetchMembers();
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search members...',
                        prefixIcon: Icon(Icons.search, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.5,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        BlocBuilder<LocationBloc, LocationState>(
                          builder: (context, locationState) {
                            return _buildDropdownFilter(
                              title: 'District',
                              value: districtFilterValue,
                              onTap: () => _showDistrictPicker(context, locationState),
                            );
                          },
                        ),
                        _buildDropdownFilter(title: 'Thoguthi', value: 'All Thoguthis', onTap: () {}),
                        _buildDropdownFilter(title: 'Area', value: 'All Areas', onTap: () {}),
                        _buildDropdownFilter(title: 'Street', value: 'All Streets', onTap: () {}),
                        _buildDropdownFilter(title: 'Role', value: _selectedRole ?? 'All', onTap: () => _showRolePicker(context)),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('More Filters', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                Icon(Icons.tune, color: Colors.grey, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (state.isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (state.error != null)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.exclamationmark_triangle,
                            color: theme.colorScheme.error,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load members',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.error!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _fetchMembers,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(120, 45),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (!state.isLoading && state.error == null)
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => _fetchMembers(),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: state.members.length + (state.hasReachedMax ? 0 : 1),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= state.members.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final member = state.members[index];
                        return _buildMemberCard(member);
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/add_member');
          _fetchMembers();
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  void _showDistrictPicker(BuildContext context, LocationState locationState) {
    if (locationState.districts.isEmpty) {
      context.read<LocationBloc>().add(const FetchDistricts());
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return BlocBuilder<LocationBloc, LocationState>(
          builder: (context, state) {
            if (state.isLoadingDistricts) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Select District', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          title: const Text('All Districts', style: TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () {
                            setState(() {
                              _selectedLocationId = 1;
                              _selectedLocationName = 'Tamil Nadu';
                            });
                            Navigator.pop(context);
                            _fetchMembers();
                          },
                        ),
                        ...state.districts.map((d) => ListTile(
                          title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () {
                            setState(() {
                              _selectedLocationId = d.id;
                              _selectedLocationName = d.name;
                            });
                            Navigator.pop(context);
                            _fetchMembers();
                          },
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMemberCard(MemberModel member) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        await Navigator.pushNamed(context, '/profile', arguments: member.id);
        _fetchMembers();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NTKColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: NTKColors.slate900.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: NTKColors.emerald50,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.hardEdge,
              child: member.image != null && member.image!.trim().isNotEmpty
                  ? (member.image!.startsWith('http://') || member.image!.startsWith('https://')
                      ? Image.network(
                          member.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: NTKColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        )
                      : AsyncBase64Image(
                          base64String: member.image!.contains('base64,')
                              ? member.image!.substring(member.image!.indexOf('base64,') + 7)
                              : member.image!,
                          fit: BoxFit.cover,
                          placeholderBuilder: (_) => Center(
                            child: Text(
                              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: NTKColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: NTKColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ))
                  : Center(
                      child: Text(
                        member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: NTKColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
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
                    member.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member.location?.name ?? 'No Location',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (member.bloodGroup != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  member.bloodGroup!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: NTKColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
