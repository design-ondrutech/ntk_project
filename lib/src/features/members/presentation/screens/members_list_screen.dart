import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_bloc.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_event.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_state.dart';
import 'package:ntk_project/src/features/members/data/models/member_model.dart';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  String? _searchQuery;
  String? _selectedBloodGroup;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  void _fetchMembers() {
    final authState = context.read<AuthBloc>().state;
    context.read<MemberBloc>().add(
      LoadMembers(
        locationId: authState.loginData?.locationId,
        search: _searchQuery,
        bloodGroup: _selectedBloodGroup,
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
                children: bloodGroups.map((bg) => 
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedBloodGroup = bg;
                      });
                      Navigator.pop(context);
                      _fetchMembers();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedBloodGroup == bg ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedBloodGroup == bg ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        bg, 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _selectedBloodGroup == bg ? Colors.white : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  )
                ).toList(),
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
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: NTKColors.background,
      appBar: NTKAppBar(
        title: 'Members',
        subtitle: context.read<AuthBloc>().state.loginData?.locationName ?? 'Tamil Nadu',

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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            'All',
                            isSelected: _selectedBloodGroup == null,
                            icon: Icons.tune,
                            onTap: () {
                              if (_selectedBloodGroup != null) {
                                setState(() => _selectedBloodGroup = null);
                                _fetchMembers();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            _selectedBloodGroup ?? 'Blood Group',
                            isSelected: _selectedBloodGroup != null,
                            icon: Icons.bloodtype_outlined,
                            onTap: () => _showBloodGroupPicker(context),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Street',
                            isSelected: false,
                            icon: Icons.location_on_outlined,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (state.isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator())),
              if (state.error != null)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.exclamationmark_triangle, color: theme.colorScheme.error, size: 48),
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
                            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 45)),
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
                      padding: const EdgeInsets.all(20),
                      itemCount: state.members.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
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
        onPressed: () => Navigator.pushNamed(context, '/add_member'),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label, {required bool isSelected, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? NTKColors.primary : NTKColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? NTKColors.primary : NTKColors.border,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: NTKColors.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              size: 16, 
              color: isSelected ? Colors.white : NTKColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : NTKColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(MemberModel member) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/profile', arguments: member),
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
              child: Center(
                child: Text(
                  member.name[0],
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            const Icon(Icons.arrow_forward_ios, size: 14, color: NTKColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
