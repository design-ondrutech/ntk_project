import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';
import 'package:ntk_project/src/core/widgets/ntk_snackbar.dart';
import 'package:ntk_project/src/core/widgets/async_base64_image.dart';
import 'package:ntk_project/src/features/auth/data/models/admin_login_model.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/injection_container.dart' as di;
import 'package:ntk_project/l10n/app_localizations.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/language_cubit.dart';

// ─── Role color helpers ───────────────────────────────────────────────────────
Color _roleColor(String role) {
  switch (role.toUpperCase()) {
    case 'SUPER_ADMIN':
      return const Color(0xFF7C3AED);
    case 'ADMIN':
      return const Color(0xFF2563EB);
    case 'SUB_ADMIN':
      return const Color(0xFF0891B2);
    default:
      return NTKColors.primary;
  }
}

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'APPROVED':
      return NTKColors.primary;
    case 'PENDING':
      return const Color(0xFFF59E0B);
    case 'REJECTED':
      return const Color(0xFFDC2626);
    default:
      return NTKColors.textSecondary;
  }
}

IconData _roleIcon(String role) {
  switch (role.toUpperCase()) {
    case 'SUPER_ADMIN':
      return Icons.verified_rounded;
    case 'ADMIN':
      return Icons.admin_panel_settings_rounded;
    case 'SUB_ADMIN':
      return Icons.manage_accounts_rounded;
    default:
      return Icons.person_rounded;
  }
}

String _formatRole(String role) => role
    .split('_')
    .map(
      (w) => w.isEmpty
          ? w
          : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
    )
    .join(' ');

String _formatStatus(String s) => s
    .split('_')
    .map(
      (w) => w.isEmpty
          ? w
          : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
    )
    .join(' ');

String _formatDate(String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  try {
    final dt = DateHelper.parseUtcToLocal(raw);
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return raw;
  }
}

// ─── MeScreen ─────────────────────────────────────────────────────────────────
class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(LoadMeRequested());
    });
  }

  Future<void> _refresh() async {
    context.read<AuthBloc>().add(LoadMeRequested());
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    NTKSnackbar.showSuccess(context, message: msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NTKColors.background,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final profile = state.loginData;

          if (profile == null && state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (profile == null) {
            return _EmptyProfile(
              message: state.error ?? 'Profile data not found',
              onRetry: _refresh,
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Gradient SliverAppBar ─────────────────────────────────
                SliverAppBar(
                  expandedHeight: 260,
                  pinned: true,
                  backgroundColor: NTKColors.primary,
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.bell,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/notifications'),
                    ),
                    const SizedBox(width: 4),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: _ProfileHeroSection(profile: profile),
                    title: Text(
                      profile.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
                  ),
                ),

                // ── Error banner ──────────────────────────────────────────
                if (state.error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _ErrorBanner(message: state.error!),
                    ),
                  ),

                // ── Content ───────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats row
                        _StatsRow(profile: profile),
                        const SizedBox(height: 24),

                        // User info card
                        _SectionLabel('User Information'),
                        const SizedBox(height: 12),
                        _UserInfoCard(profile: profile),
                        const SizedBox(height: 24),

                        // Quick actions
                        _SectionLabel('Quick Actions'),
                        const SizedBox(height: 12),
                        _QuickActionsCard(
                          profile: profile,
                          onLogout: _logout,
                          onSnack: _showSnack,
                        ),
                        const SizedBox(height: 24),

                        // Settings
                        _SectionLabel('Settings'),
                        const SizedBox(height: 12),
                        _SettingsCard(onSnack: _showSnack),
                        const SizedBox(height: 12),

                        // Version info
                        Center(
                          child: Text(
                            'NTK Platform · v1.0.0',
                            style: const TextStyle(
                              fontSize: 12,
                              color: NTKColors.textTertiary,
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
        },
      ),
    );
  }
}

// ─── Hero section inside the flexible space ───────────────────────────────────
class _ProfileHeroSection extends StatelessWidget {
  final AdminLoginModel profile;
  const _ProfileHeroSection({required this.profile});

  Widget _buildProfileImage(String? imagePath, String initial) {
    if (imagePath == null || imagePath.isEmpty) {
      return _InitialAvatar(initial: initial);
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _InitialAvatar(initial: initial),
      );
    }
    try {
      final clean = imagePath.contains('base64,')
          ? imagePath.substring(imagePath.indexOf('base64,') + 7)
          : imagePath;
      return AsyncBase64Image(
        base64String: clean,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => _InitialAvatar(initial: initial),
        errorBuilder: (_, __, ___) => _InitialAvatar(initial: initial),
      );
    } catch (e) {
      return _InitialAvatar(initial: initial);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = [
      profile.name,
      if ((profile.surname ?? '').trim().isNotEmpty) profile.surname!.trim(),
    ].join(' ');

    final roleColor = _roleColor(profile.role);
    final statusColor = _statusColor(profile.approvalStatus);
    final initial = profile.name.trim().isEmpty
        ? 'U'
        : profile.name.trim()[0].toUpperCase();

    return Container(
      decoration: const BoxDecoration(color: NTKColors.primary),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _buildProfileImage(profile.image, initial),
                  ),
                ),
                // Role icon badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: roleColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    _roleIcon(profile.role),
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              fullName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profile.phone ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            // Role + Status chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _HeroBadge(
                  label: _formatRole(profile.role),
                  color: roleColor,
                  icon: _roleIcon(profile.role),
                ),
                const SizedBox(width: 8),
                _HeroBadge(
                  label: _formatStatus(profile.approvalStatus),
                  color: statusColor,
                  icon: profile.approvalStatus.toUpperCase() == 'APPROVED'
                      ? Icons.check_circle_rounded
                      : profile.approvalStatus.toUpperCase() == 'REJECTED'
                      ? Icons.cancel_rounded
                      : Icons.pending_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String initial;
  const _InitialAvatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NTKColors.primary,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _HeroBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final AdminLoginModel profile;
  const _StatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isApproved = profile.approvalStatus.toUpperCase() == 'APPROVED';

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Status',
            value: isApproved ? 'Active' : 'Inactive',
            icon: Icons.circle,
            iconColor: isApproved ? NTKColors.primary : const Color(0xFFF59E0B),
            valueColor: isApproved
                ? NTKColors.primary
                : const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Role',
            value: _formatRole(profile.role),
            icon: _roleIcon(profile.role),
            iconColor: _roleColor(profile.role),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Member ID',
            value: '#${profile.id}',
            icon: Icons.badge_rounded,
            iconColor: const Color(0xFF7C3AED),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: NTKColors.slate900.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? NTKColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: NTKColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ─── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: NTKColors.textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }
}

// ─── User Info Card ────────────────────────────────────────────────────────────
class _UserInfoCard extends StatelessWidget {
  final AdminLoginModel profile;
  const _UserInfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(profile.approvalStatus);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: NTKColors.slate900.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.badge_outlined,
            iconBg: const Color(0xFFEDE9FE),
            iconColor: const Color(0xFF7C3AED),
            label: 'Member ID',
            value: '#${profile.id}',
            isFirst: true,
          ),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            iconBg: NTKColors.emerald50,
            iconColor: NTKColors.primary,
            label: 'Full Name',
            value: [
              profile.name,
              if ((profile.surname ?? '').trim().isNotEmpty)
                profile.surname!.trim(),
            ].join(' '),
          ),
          _InfoRow(
            icon: Icons.call_outlined,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
            label: 'Mobile Number',
            value: profile.phone ?? '—',
          ),
          _InfoRow(
            icon: _roleIcon(profile.role),
            iconBg: _roleColor(profile.role).withValues(alpha: 0.1),
            iconColor: _roleColor(profile.role),
            label: 'Role',
            value: _formatRole(profile.role),
          ),
          _InfoRow(
            icon: Icons.location_on_outlined,
            iconBg: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFF97316),
            label: 'Location',
            value: profile.locationName ?? '—',
          ),
          _InfoRow(
            icon: Icons.fact_check_outlined,
            iconBg: statusColor.withValues(alpha: 0.1),
            iconColor: statusColor,
            label: 'Approval Status',
            value: _formatStatus(profile.approvalStatus),
            valueColor: statusColor,
          ),
          _InfoRow(
            icon: Icons.group_add_outlined,
            iconBg: NTKColors.slate100,
            iconColor: NTKColors.textSecondary,
            label: 'Added By',
            value: profile.addedBy ?? '—',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isFirst;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: NTKColors.slate100)),
        borderRadius: isFirst
            ? const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              )
            : isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: NTKColors.textTertiary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? NTKColors.textPrimary,
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

// ─── Account Card ──────────────────────────────────────────────────────────────
class AccountCard extends StatelessWidget {
  final AdminLoginModel profile;
  const AccountCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final isActive = profile.isActive ?? true;
    final isApproved = profile.approvalStatus.toUpperCase() == 'APPROVED';

    // Profile completion
    int filled = 0;
    final fields = [
      profile.name.isNotEmpty,
      (profile.surname ?? '').isNotEmpty,
      (profile.phone ?? '').isNotEmpty,
      (profile.locationName ?? '').isNotEmpty,
      (profile.image ?? '').isNotEmpty,
      (profile.addedBy ?? '').isNotEmpty,
    ];
    filled = fields.where((v) => v).length;
    final completionPct = (filled / fields.length).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: NTKColors.slate900.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Completion
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile Completion',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: NTKColors.textPrimary,
                  ),
                ),
                Text(
                  '${(completionPct * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: completionPct >= 0.8
                        ? NTKColors.primary
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: completionPct,
                minHeight: 8,
                backgroundColor: NTKColors.slate100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  completionPct >= 0.8
                      ? NTKColors.primary
                      : const Color(0xFFF59E0B),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: NTKColors.slate100, height: 1),
            const SizedBox(height: 16),
            // Status row
            Row(
              children: [
                Expanded(
                  child: AccountStat(
                    label: 'Account',
                    value: isActive ? 'Active' : 'Inactive',
                    icon: Icons.radio_button_checked_rounded,
                    color: isActive
                        ? NTKColors.primary
                        : NTKColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AccountStat(
                    label: 'Verification',
                    value: isApproved ? 'Verified' : 'Pending',
                    icon: isApproved
                        ? Icons.verified_rounded
                        : Icons.pending_rounded,
                    color: isApproved
                        ? NTKColors.primary
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AccountStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const AccountStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: NTKColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions Card ────────────────────────────────────────────────────────
class _QuickActionsCard extends StatelessWidget {
  final AdminLoginModel profile;
  final VoidCallback onLogout;
  final void Function(String) onSnack;

  const _QuickActionsCard({
    required this.profile,
    required this.onLogout,
    required this.onSnack,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final actions = [
      _ActionItem(
        icon: Icons.edit_outlined,
        label: loc.editProfile,
        iconBg: NTKColors.emerald50,
        iconColor: NTKColors.primary,
        onTap: () => onSnack('${loc.editProfile} coming soon'),
      ),
      _ActionItem(
        icon: Icons.lock_outline_rounded,
        label: loc.changePassword,
        iconBg: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
        onTap: () => onSnack('${loc.changePassword} coming soon'),
      ),
      _ActionItem(
        icon: Icons.location_on_outlined,
        label: loc.viewLocation,
        iconBg: const Color(0xFFFFF7ED),
        iconColor: const Color(0xFFF97316),
        onTap: () => onSnack('${loc.viewLocation} coming soon'),
      ),
      _ActionItem(
        icon: Icons.support_agent_rounded,
        label: loc.contactAdmin,
        iconBg: const Color(0xFFF5F3FF),
        iconColor: const Color(0xFF7C3AED),
        onTap: () => onSnack('${loc.contactAdmin} coming soon'),
      ),
      _ActionItem(
        icon: Icons.logout_rounded,
        label: loc.logout,
        iconBg: const Color(0xFFFEF2F2),
        iconColor: const Color(0xFFDC2626),
        onTap: onLogout,
        isDestructive: true,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: NTKColors.slate900.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: actions.asMap().entries.map((entry) {
          final i = entry.key;
          final action = entry.value;
          return _ActionTile(
            item: action,
            isFirst: i == 0,
            isLast: i == actions.length - 1,
          );
        }).toList(),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
    this.isDestructive = false,
  });
}

class _ActionTile extends StatelessWidget {
  final _ActionItem item;
  final bool isFirst;
  final bool isLast;

  const _ActionTile({
    required this.item,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: NTKColors.slate100)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, size: 20, color: item.iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: item.isDestructive
                      ? const Color(0xFFDC2626)
                      : NTKColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: item.isDestructive
                  ? const Color(0xFFDC2626).withValues(alpha: 0.5)
                  : NTKColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Settings Card ────────────────────────────────────────────────────────────
class _SettingsCard extends StatefulWidget {
  final void Function(String) onSnack;
  const _SettingsCard({required this.onSnack});

  @override
  State<_SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<_SettingsCard> {
  bool _notifications = true;
  String _languageCode = 'en';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _languageCode = prefs.getString('languageCode') ?? 'en';
    });
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final loc = AppLocalizations.of(context)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(loc.selectLanguage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: const Text('English'),
                trailing: _languageCode == 'en' ? const Icon(Icons.check, color: NTKColors.primary) : null,
                onTap: () => _setLanguage('en'),
              ),
              ListTile(
                title: const Text('தமிழ்'),
                trailing: _languageCode == 'ta' ? const Icon(Icons.check, color: NTKColors.primary) : null,
                onTap: () => _setLanguage('ta'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _setLanguage(String code) async {
    Navigator.pop(context);
    context.read<LanguageCubit>().changeLanguage(code);
    di.sl<GraphQLService>().setLanguage(code);
    setState(() {
      _languageCode = code;
    });
    NTKSnackbar.showSuccess(context,
        message: code == 'ta' ? 'மொழி மாற்றப்பட்டது' : 'Language changed');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: NTKColors.slate900.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Notifications toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: NTKColors.slate100)),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: NTKColors.emerald50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    size: 20,
                    color: NTKColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    loc.notifications,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: NTKColors.textPrimary,
                    ),
                  ),
                ),
                CupertinoSwitch(
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                  activeColor: NTKColors.primary,
                ),
              ],
            ),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
            label: loc.privacySettings,
            onTap: () => widget.onSnack('${loc.privacySettings} coming soon'),
          ),
          _SettingsTile(
            icon: Icons.language_rounded,
            iconBg: const Color(0xFFF5F3FF),
            iconColor: const Color(0xFF7C3AED),
            label: loc.language,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: NTKColors.slate100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _languageCode == 'ta' ? 'தமிழ்' : 'English',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: NTKColors.textSecondary,
                ),
              ),
            ),
            onTap: _showLanguagePicker,
          ),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            iconBg: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFF97316),
            label: loc.helpSupport,
            onTap: () => widget.onSnack('${loc.helpSupport} coming soon'),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool isLast;

  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.trailing,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: NTKColors.slate100)),
          borderRadius: isLast
              ? const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: NTKColors.textPrimary,
                ),
              ),
            ),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: NTKColors.textTertiary,
                ),
          ],
        ),
      ),
    );
  }
}

// ─── Error + Empty states ──────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NTKColors.red500.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NTKColors.red500.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: NTKColors.red500, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: NTKColors.red500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProfile extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _EmptyProfile({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: NTKColors.emerald50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_off_outlined,
                size: 48,
                color: NTKColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: NTKColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: NTKColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
