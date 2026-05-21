import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/members/data/models/member_model.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_bloc.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_event.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_state.dart';

class MemberProfileScreen extends StatefulWidget {
  const MemberProfileScreen({super.key});

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  int? _memberId;
  bool _hasFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasFetched) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        _memberId = args;
        context.read<MemberBloc>().add(LoadMemberDetails(id: _memberId!));
      }
      _hasFetched = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<MemberBloc, MemberState>(
      builder: (context, state) {
        // Show loading state while fetching
        if (state.isLoadingDetails && state.selectedMember == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Member Profile')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Show error state
        if (state.detailsError != null && state.selectedMember == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Member Profile')),
            body: Center(
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
                      'Failed to load member',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.detailsError!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (_memberId != null) {
                          context.read<MemberBloc>().add(
                            LoadMemberDetails(id: _memberId!),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 45),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final member = state.selectedMember;
        if (member == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('No member data found')),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Member Profile'),
            actions: [
              IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
            ],
          ),
          body: Column(
            children: [
              // Subtle loading indicator while fetching fresh details
              if (state.isLoadingDetails)
                LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(NTKColors.primary),
                  minHeight: 2,
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // ── Top Profile Card ─────────────────────────────
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Avatar with Online Status
                            Stack(
                              children: [
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: NTKColors.primary,
                                      width: 2.5,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFF1F5F9),
                                    ),
                                    child: Center(
                                      child: Text(
                                        member.name.isNotEmpty
                                            ? member.name[0]
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: NTKColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  bottom: 8,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              member.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildBadge(
                                  member.role?.toUpperCase() ?? 'MEMBER',
                                  const Color(0xFFDCFCE7),
                                  const Color(0xFF166534),
                                ),
                                const SizedBox(width: 8),
                                _buildBadge(
                                  '${member.bloodGroup ?? 'N/A'} Positive',
                                  const Color(0xFFFEE2E2),
                                  const Color(0xFF991B1B),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(
                                  CupertinoIcons.phone,
                                  'Call',
                                ),
                                _buildActionButton(
                                  CupertinoIcons.chat_bubble,
                                  'Message',
                                ),
                                _buildActionButton(
                                  CupertinoIcons.asterisk_circle,
                                  'SOS Info',
                                  color: const Color(0xFFFEE2E2),
                                  iconColor: const Color(0xFF991B1B),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Contact Information Card ─────────────────────
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.doc_text,
                                  size: 20,
                                  color: Color(0xFF166534),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'CONTACT INFORMATION',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildInfoItem(
                              CupertinoIcons.person_badge_plus,
                              'Role',
                              member.role?.toUpperCase() ?? 'MEMBER',
                            ),
                            const Divider(height: 32, color: Color(0xFFF1F5F9)),
                            _buildInfoItem(
                              CupertinoIcons.check_mark_circled_solid,
                              'Approval Status',
                              member.approvalStatus?.toUpperCase() ?? 'UNKNOWN',
                            ),
                            const Divider(height: 32, color: Color(0xFFF1F5F9)),
                            _buildInfoItem(
                              CupertinoIcons.person,
                              'Profession',
                              member.professionName ?? 'Not specified',
                            ),
                            const Divider(height: 32, color: Color(0xFFF1F5F9)),
                            _buildInfoItem(
                              CupertinoIcons.phone,
                              'Phone Number',
                              member.phone ?? 'Not available',
                            ),
                            const Divider(height: 32, color: Color(0xFFF1F5F9)),
                            _buildInfoItem(
                              CupertinoIcons.location_solid,
                              'Area / Location',
                              member.location?.name ?? 'Not specified',
                            ),
                            const Divider(height: 32, color: Color(0xFFF1F5F9)),
                            _buildInfoItem(
                              CupertinoIcons.drop_fill,
                              'Blood Group',
                              member.bloodGroup ?? 'Not specified',
                            ),
                            const Divider(height: 32, color: Color(0xFFF1F5F9)),
                            _buildInfoItem(
                              CupertinoIcons.calendar,
                              'Joined',
                              member.createdAt != null
                                  ? '${member.createdAt!.day.toString().padLeft(2, '0')}-${member.createdAt!.month.toString().padLeft(2, '0')}-${member.createdAt!.year}'
                                  : 'Unknown',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label, {
    Color? color,
    Color? iconColor,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color ?? const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor ?? const Color(0xFF1E293B),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
