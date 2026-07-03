import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ntk_project/l10n/app_localizations.dart';
import 'package:ntk_project/src/core/widgets/ntk_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/dashboard/data/models/recent_activity_model.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/pending_requests_bloc.dart';
import 'package:ntk_project/src/features/requests_broadcasts/data/models/pending_request_model.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/main_screen.dart';
import 'package:ntk_project/src/core/widgets/async_base64_image.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_state.dart';

Widget buildDashboardAvatar(BuildContext context) {
  return BlocBuilder<AuthBloc, AuthState>(
    builder: (context, authState) {
      final loginData = authState.loginData;
      final imagePath = loginData?.image;
      final name = loginData?.name ?? '';
      final initial = name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();

      Widget avatarChild;
      if (imagePath != null && imagePath.trim().isNotEmpty) {
        if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
          avatarChild = Image.network(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(
              child: Text(
                initial,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          );
        } else {
          try {
            final clean = imagePath.contains('base64,')
                ? imagePath.substring(imagePath.indexOf('base64,') + 7)
                : imagePath;
            avatarChild = AsyncBase64Image(
              base64String: clean,
              fit: BoxFit.cover,
              placeholderBuilder: (_) => Center(
                child: Text(
                  initial,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  initial,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            );
          } catch (_) {
            avatarChild = Center(
              child: Text(
                initial,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            );
          }
        }
      } else {
        avatarChild = Center(
          child: Text(
            initial,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        );
      }

      return Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white24,
        ),
        clipBehavior: Clip.hardEdge,
        child: avatarChild,
      );
    },
  );
}

Widget _buildInitialsText(String name) {
  return Center(
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(
        color: Color(0xFF059669),
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
  );
}

PreferredSizeWidget buildFigmaAppBar(BuildContext context, String subtitle) {
  return AppBar(
    backgroundColor: NTKColors.primary,
    elevation: 0,
    centerTitle: false,
    leading: Padding(
      padding: const EdgeInsets.all(8.0),
      child: buildDashboardAvatar(context),
    ),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NTK Party',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          localizeLocationName(context, subtitle),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
    actions: [
      IconButton(
        icon: const Icon(
          Icons.notifications_none_rounded,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/notifications');
        },
      ),
    ],
  );
}

Widget buildGreetingText(String title, String subtitle) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: NTKColors.primary,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: NTKColors.textSecondary),
      ),
    ],
  );
}

Widget buildStatCardSmall(
  String label,
  String value,
  IconData icon,
  Color color, {
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildStatCardLarge(
  String label,
  String value,
  String subtext,
  IconData icon,
  Color color, {
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.trending_up, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    subtext,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ],
      ),
    ),
  );
}

Widget buildSubAdminActionCard(
  String label,
  IconData icon,
  Color iconColor, {
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildActionBtnHorizontal(String label, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: const Color(0xFF166534),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

Widget buildActionBtnFullWidth(String label, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF166534)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFF166534), size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF166534),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

Widget buildActionCardGrid(
  String label,
  IconData icon, {
  bool isPrimary = false,
  int? badgeCount,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF065F46) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : const Color(0xFF065F46),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isPrimary ? Colors.white : const Color(0xFF065F46),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _formatActivityTime(String? value) {
  if (value == null || value.isEmpty) return '';
  try {
    final date = DateHelper.parseUtcToLocal(value);
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  } catch (_) {
    return value;
  }
}

Widget buildRecentActivitiesList(BuildContext context, List<dynamic> activities) {
  if (activities.isEmpty) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 40,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'No recent activities',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  return Column(
    children: activities.map((activity) {
      String title = 'Activity';
      String subtitle = 'Recent Activity';
      String status = 'COMPLETED';
      String date = '';
      bool isEmergency = false;

      if (activity is RecentActivityModel) {
        isEmergency = activity.action == 'EMERGENCY' || activity.typename == 'EmergencyRequest';
        if (activity.details.isNotEmpty) {
          title = activity.details;
          subtitle = activity.title != null && activity.title!.isNotEmpty
              ? activity.title!
              : (activity.action == 'EVENT'
                  ? 'Event Activity'
                  : activity.action == 'EMERGENCY'
                      ? 'Emergency Request'
                      : activity.action == 'MEMBER'
                          ? 'Member Approval'
                          : activity.action == 'BROADCAST'
                              ? 'Broadcast Notification'
                              : activity.action.toUpperCase());
        } else {
          title = activity.title != null && activity.title!.isNotEmpty
              ? activity.title!
              : activity.action;
          if (activity.action == 'EVENT') {
            subtitle = 'Event Activity';
          } else if (activity.action == 'EMERGENCY') {
            subtitle = 'Emergency Request';
          } else if (activity.action == 'MEMBER') {
            subtitle = 'Member Approval';
          } else if (activity.action == 'BROADCAST') {
            subtitle = 'Broadcast Notification';
          } else {
            subtitle = activity.action.toUpperCase();
          }
        }

        status = activity.status ?? 'COMPLETED';
        date = _formatActivityTime(activity.createdAt);
      } else if (activity is Map) {
        title = activity['title'] ?? 'Activity';
        status = activity['eventStatus'] ?? activity['requestStatus'] ?? 'PENDING';
        date = _formatActivityTime(activity['date'] ?? activity['type'] ?? '');
        isEmergency = activity.containsKey('type');
        subtitle = isEmergency ? 'Emergency Request' : 'Event Activity';
      }

      return buildActivityItem(
        title,
        subtitle,
        date,
        status,
        status == 'COMPLETED' || status == 'APPROVED' || status == 'ACTIVE'
            ? const Color(0xFF059669)
            : const Color(0xFF6B7280),
        icon: isEmergency ? Icons.warning_amber_rounded : Icons.event,
        avatarColor: isEmergency
            ? NTKColors.error.withOpacity(0.1)
            : NTKColors.emerald100,
        iconColor: isEmergency ? NTKColors.error : NTKColors.primary,
      );
    }).toList(),
  );
}

Widget buildRecentActivitiesHeader(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(
        child: Text(
          AppLocalizations.of(context)!.recentActivities,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      TextButton(
        onPressed: () => Navigator.pushNamed(context, '/activity_log'),
        child: Text(
          AppLocalizations.of(context)!.viewAll,
          style: const TextStyle(
            color: Color(0xFF059669),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}

Widget buildActivityItem(
  String title,
  String subtitle,
  String time,
  String status,
  Color statusColor, {
  IconData? icon,
  bool showStatus = true,
  Color? avatarColor,
  Color? iconColor,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: avatarColor ?? Colors.grey[100],
          ),
          child: Icon(
            icon ?? Icons.person,
            color: iconColor ?? Colors.grey[600],
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (showStatus) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildPendingApprovalSection(BuildContext context) {
  return BlocBuilder<PendingRequestsBloc, PendingRequestsState>(
    builder: (context, state) {
      if (state.isLoading) {
        return const Center(child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ));
      }

      if (state.requests.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pending Approval Queue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/pending_requests');
                },
                child: const Text(
                  'View Queue',
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.requests.length > 3 ? 3 : state.requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = state.requests[index];
              return buildRequestCardCompact(context, request);
            },
          ),
        ],
      );
    },
  );
}

Widget buildRequestCardCompact(BuildContext context, PendingRequestModel request) {
  final name = request.name;
  final role = request.role.toUpperCase();
  final location = request.location?.name ?? 'No Location';

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF1F5F9)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFDCFCE7),
              child: ClipOval(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: request.image != null && request.image!.trim().isNotEmpty
                      ? (request.image!.startsWith('http://') || request.image!.startsWith('https://')
                          ? Image.network(
                              request.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildInitialsText(name),
                            )
                          : AsyncBase64Image(
                              base64String: request.image!.contains('base64,')
                                  ? request.image!.substring(request.image!.indexOf('base64,') + 7)
                                  : request.image!,
                              fit: BoxFit.cover,
                              placeholderBuilder: (_) => _buildInitialsText(name),
                              errorBuilder: (_, __, ___) => _buildInitialsText(name),
                            ))
                      : _buildInitialsText(name),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '$role • $location',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'PENDING',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  context.read<PendingRequestsBloc>().add(
                    ApproveRequest(id: request.id, type: request.type),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  context.read<PendingRequestsBloc>().add(
                    RejectRequest(id: request.id, type: request.type),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget buildMemberActionCard(String label, IconData icon) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFE5E7EB),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF166534), size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    ),
  );
}

Widget buildActionCardStandard(
  String label,
  IconData icon,
  VoidCallback onTap,
) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF065F46)),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    ),
  );
}

Widget buildHorizontalActivityCard(String title, String value, Color valueColor, {double? width = 110}) {
  return Container(
    width: width,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[100]!),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            height: 1.2,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    ),
  );
}

Widget buildModernStatCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'View details',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF0F5A29),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 10,
                color: Color(0xFF0F5A29),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget buildModernActionBtn(String title, IconData icon, Color iconColor, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    ),
  );
}
