import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/members/data/models/member_model.dart';
import 'package:ntk_project/src/features/members/domain/repositories/member_repository.dart';
import 'package:ntk_project/src/injection_container.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  final _memberRepo = sl<MemberRepository>();
  List<MemberModel> _members = [];
  bool _isLoading = true;
  String? _error;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadPendingMembers();
  }

  Future<void> _loadPendingMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final locationId = context.read<AuthBloc>().state.loginData?.locationId;
      final members = await _memberRepo.getPendingMembers(locationId: locationId);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(MemberModel member, String status) async {
    setState(() => _isUpdating = true);
    try {
      await _memberRepo.updateMemberStatus(id: member.id, status: status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'APPROVED'
                  ? '${member.name} அனுமதிக்கப்பட்டார்'
                  : '${member.name} நிராகரிக்கப்பட்டார்',
            ),
            backgroundColor:
                status == 'APPROVED' ? NTKColors.primary : NTKColors.error,
          ),
        );
        await _loadPendingMembers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: NTKColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return 'Requested on ${date.day}.${date.month}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: NTKColors.background,
      appBar: AppBar(
        backgroundColor: NTKColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Pending Members',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: NTKColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadPendingMembers,
                      child: const Text('மீண்டும் முயற்சி'),
                    ),
                  ],
                ),
              ),
            )
          : _members.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.person_crop_circle_badge_checkmark,
                    size: 64,
                    color: theme.dividerColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'நிலுவையில் உறுப்பினர்கள் இல்லை',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadPendingMembers,
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _buildMemberCard(_members[index]),
              ),
            ),
    );
  }

  Widget _buildMemberCard(MemberModel member) {
    final theme = Theme.of(context);
    final locationLabel = member.location != null
        ? '${member.role ?? 'Member'} / ${member.location!.name}'
        : member.role ?? 'Member';

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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: NTKColors.emerald50,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    member.name.isNotEmpty ? member.name[0] : '?',
                    style: const TextStyle(
                      color: NTKColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locationLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                    if (member.phone != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        member.phone!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: NTKColors.textTertiary,
                        ),
                      ),
                    ],
                    if (member.bloodGroup != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Blood: ${member.bloodGroup}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          color: NTKColors.textTertiary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(member.createdAt),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 10,
                        color: NTKColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isUpdating
                      ? null
                      : () => _updateStatus(member, 'REJECTED'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NTKColors.error,
                    side: BorderSide(color: NTKColors.error.withOpacity(0.5)),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'REJECT',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isUpdating
                      ? null
                      : () => _updateStatus(member, 'APPROVED'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NTKColors.primary,
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'APPROVE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
