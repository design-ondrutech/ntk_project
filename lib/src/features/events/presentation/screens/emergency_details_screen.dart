import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/events/data/models/emergency_model.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_bloc.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_event.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_state.dart';
import 'package:ntk_project/src/features/events/presentation/screens/event_details_screen.dart'; // For DoughnutPainter
import 'package:ntk_project/src/features/events/domain/repositories/event_repository.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/requests_broadcasts/domain/repositories/request_repository.dart';
import 'package:ntk_project/src/injection_container.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyDetailsScreen extends StatefulWidget {
  const EmergencyDetailsScreen({super.key});

  @override
  State<EmergencyDetailsScreen> createState() => _EmergencyDetailsScreenState();
}

class _EmergencyDetailsScreenState extends State<EmergencyDetailsScreen> {
  EmergencyModel? _alert;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_alert == null) {
      _alert = ModalRoute.of(context)?.settings.arguments as EmergencyModel?;
      if (_alert != null) {
        context.read<EventBloc>().add(
          FetchEmergencyResponses(emergencyRequestId: _alert!.id),
        );
        _loadEmergencyDetails();
      }
    }
  }

  Future<void> _loadEmergencyDetails() async {
    final alertId = _alert?.id;
    if (alertId == null || alertId.isEmpty) return;
    try {
      final details = await sl<EventRepository>().getEmergencyRequestDetails(
        id: alertId,
      );
      if (!mounted) return;
      setState(() => _alert = details);
    } catch (_) {
      // Keep the route argument data visible if the details endpoint is unavailable.
    }
  }

  String _formatDateTime(String? dt) {
    if (dt == null) return 'N/A';
    try {
      final date = DateTime.parse(dt);
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
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final ampm = date.hour < 12 ? 'AM' : 'PM';
      final minute = date.minute.toString().padLeft(2, '0');
      return '${months[date.month - 1]} ${date.day}, ${date.year} • $hour:$minute $ampm';
    } catch (_) {
      return dt;
    }
  }

  String? _extractBloodGroup(String title, String description) {
    final combined = '$title $description'.toUpperCase();
    final RegExp regExp = RegExp(
      r'\b(A1|A2|A1B|A2B|A|B|AB|O)[\s]?[+-](?:\b|(?=\s))|O\s?(?:positive|negative)|A\s?(?:positive|negative)|B\s?(?:positive|negative)',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(combined);
    if (match != null) {
      return match.group(0)?.toUpperCase().replaceAll('POSITIVE', '+').replaceAll('NEGATIVE', '-').replaceAll(' ', '');
    }
    return null;
  }

  void _onRespond(String status) {
    if (_alert != null) {
      context.read<EventBloc>().add(
        RespondToEmergency(emergencyRequestId: _alert!.id, status: status),
      );
    }
  }

  Future<void> _launchAction(String? phone, String scheme) async {
    final cleanPhone = phone?.replaceAll(RegExp(r'\s+'), '');
    if (cleanPhone == null || cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    if (scheme == 'whatsapp') {
      var finalPhone = cleanPhone;
      if (!finalPhone.startsWith('+') && finalPhone.length == 10) {
        finalPhone = '91$finalPhone';
      }
      final url = 'https://wa.me/$finalPhone';
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open WhatsApp')),
        );
      }
    } else {
      final uri = Uri(scheme: scheme, path: cleanPhone);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              scheme == 'tel'
                  ? 'Unable to open phone dialer'
                  : 'Unable to open messaging app',
            ),
          ),
        );
      }
    }
  }

  bool _isReviewing = false;

  bool get _isResolved {
    final status = _alert?.status?.toUpperCase();
    return status == 'ACCEPTED' || status == 'APPROVED' || status == 'REJECTED';
  }

  Future<void> _onReviewRequest(String action) async {
    final alertId = _alert?.id;
    if (alertId == null || alertId.isEmpty) return;
    setState(() => _isReviewing = true);
    try {
      final updated = await sl<RequestRepository>().reviewEmergencyRequest(
        id: int.parse(alertId),
        action: action,
      );
      // Reload emergency details to get updated status/info
      await _loadEmergencyDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alert successfully reviewed: ${updated.status}'),
            backgroundColor: const Color(0xFF004D2A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to review alert: $e'),
            backgroundColor: NTKColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReviewing = false);
      }
    }
  }

  Future<void> _showRejectDialog() async {
    final controller = TextEditingController();
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Reject Emergency Request'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Reason for rejection (optional)',
            maxLines: 3,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result == true) {
      final reason = controller.text.trim();
      final alertId = _alert?.id;
      if (alertId == null || alertId.isEmpty) return;
      setState(() => _isReviewing = true);
      try {
        final updated = await sl<RequestRepository>().reviewEmergencyRequest(
          id: int.parse(alertId),
          action: 'REJECT',
          rejectReason: reason.isNotEmpty ? reason : null,
        );
        await _loadEmergencyDetails();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Alert successfully rejected: ${updated.status}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject alert: $e'),
              backgroundColor: NTKColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isReviewing = false);
        }
      }
    }
  }

  Future<void> _onCloseEmergency() async {
    final alertId = _alert?.id;
    if (alertId == null || alertId.isEmpty) return;
    setState(() => _isReviewing = true);
    try {
      await sl<RequestRepository>().updateRequestStatus(
        id: int.parse(alertId),
        status: 'CLOSED',
      );
      await _loadEmergencyDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency closed successfully'),
            backgroundColor: Color(0xFF004D2A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to close emergency: $e'),
            backgroundColor: NTKColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReviewing = false);
      }
    }
  }

  Widget _buildActionsSection(String userRole, int? userId) {
    final isCreator = _alert?.creatorId != null && userId != null && _alert?.creatorId == userId;

    if (isCreator) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Edit functionality coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(
                    'EDIT',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showResponsesSheet(context),
                  icon: const Icon(Icons.people_outline, size: 18),
                  label: const Text(
                    'RESPONSES',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF004D2A),
                    side: const BorderSide(color: Color(0xFF004D2A), width: 1.5),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text('Close Emergency Request'),
                  content: const Text(
                    'Are you sure you want to close this emergency request? This will mark it as resolved/closed.',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () {
                        Navigator.pop(context);
                        _onCloseEmergency();
                      },
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text(
              'CLOSE EMERGENCY',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      );
    }

    if (userRole == 'MEMBER') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _onRespond('UNABLE'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(
                  color: Color(0xFFFCA5A5),
                  width: 1.5,
                ),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'NOT AVAILABLE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _onRespond('COMING'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004D2A),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'I\'M AVAILABLE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    if (_isResolved) {
      final status = _alert?.status?.toUpperCase() ?? '';
      final isAccepted = status == 'ACCEPTED' || status == 'APPROVED';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isAccepted ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAccepted ? const Color(0xFFA7F3D0) : const Color(0xFFFCA5A5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isAccepted ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isAccepted ? const Color(0xFF059669) : const Color(0xFFDC2626),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isAccepted
                    ? 'This Emergency Alert has been ACCEPTED.'
                    : 'This Emergency Alert has been REJECTED.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isAccepted ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_isReviewing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    String? forwardLabel;
    if (userRole == 'SUB_ADMIN') {
      forwardLabel = 'FORWARD TO ADMIN';
    } else if (userRole == 'ADMIN') {
      forwardLabel = 'FORWARD TO SUPER ADMIN';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _showRejectDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'REJECT',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _onReviewRequest('ACCEPT'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF004D2A),
                  side: const BorderSide(color: Color(0xFF004D2A), width: 1.5),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ACCEPT',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        if (forwardLabel != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _onReviewRequest('FORWARD'),
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: Text(
              forwardLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEE2E2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFCE8E6), // light pink
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bloodtype_rounded,
                  color: Color(0xFFC5221F),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
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
                            _alert!.title,
                            style: const TextStyle(
                              color: Color(0xFFC5221F),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _alert!.statusBadgeBgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _alert!.statusBadgeText,
                            style: TextStyle(
                              color: _alert!.statusBadgeTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFFEE2E2), height: 1),
          const SizedBox(height: 16),
          
          _buildDetailRow('Created By', _alert!.createdBy ?? 'N/A'),
          _buildDetailRow('Created Time', _alert!.createdAt != null && _alert!.createdAt!.isNotEmpty ? _formatDateTime(_alert!.createdAt) : 'N/A'),
          _buildDetailRow('Blood Group', _extractBloodGroup(_alert!.title, _alert!.description) ?? (_alert!.type == 'BLOOD_REQUIRED' ? 'Required' : 'N/A')),
          _buildDetailRow('Location', _alert!.locationName),
          _buildDetailRow('Contact Name', _alert!.contactName.isNotEmpty ? _alert!.contactName : 'N/A'),
          _buildDetailRow('Contact Number', _alert!.contactPhone.isNotEmpty ? _alert!.contactPhone : 'N/A'),
          _buildDetailRow('Reason', _alert!.description.isNotEmpty ? _alert!.description : 'N/A'),
          _buildDetailRow('Current Level', _alert!.currentLevelText, isBlueValue: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBlueValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isBlueValue ? const Color(0xFF1967D2) : const Color(0xFF1E293B),
                fontSize: 14,
                fontWeight: isBlueValue ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(
          '$count ($percentage%)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    final userRole = authState.loginData?.role ?? 'MEMBER';
    final userId = authState.loginData?.id;

    if (_alert == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No emergency data found')),
      );
    }

    final totalResponses = _alert!.going + _alert!.maybe + _alert!.notGoing;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004D2A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Emergency Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.share, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailsCard(),
                  const SizedBox(height: 24),
                  _buildActionsSection(userRole, userId),
                  const SizedBox(height: 32),
                  const Text(
                    'Responses Overview',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: totalResponses > 0
                        ? Row(
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CustomPaint(
                                  painter: DoughnutPainter(
                                    going: _alert!.going,
                                    maybe: _alert!.maybe,
                                    notGoing: _alert!.notGoing,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLegendItem(
                                      'Available',
                                      _alert!.going,
                                      totalResponses,
                                      const Color(0xFF004D2A),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildLegendItem(
                                      'Maybe',
                                      _alert!.maybe,
                                      totalResponses,
                                      Colors.orange,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildLegendItem(
                                      'Not Available',
                                      _alert!.notGoing,
                                      totalResponses,
                                      const Color(0xFFDC2626),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                "No responses yet.",
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004D2A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _showResponsesSheet(context),
                      child: const Text(
                        'VIEW RESPONSES',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResponsesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return BlocBuilder<EventBloc, EventState>(
          bloc: context.read<EventBloc>(),
          builder: (context, state) {
            final goingList = state.emergencyResponses
                .where((r) => r.status == 'COMING' || r.status == 'GOING')
                .toList();
            final notGoingList = state.emergencyResponses
                .where((r) => r.status == 'UNABLE' || r.status == 'NOT_GOING')
                .toList();

            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Emergency Responses',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    labelColor: NTKColors.primary,
                    unselectedLabelColor: NTKColors.textSecondary,
                    indicatorColor: NTKColors.primary,
                    tabs: [
                      Tab(text: 'AVAILABLE (${goingList.length})'),
                      Tab(text: 'NOT AVAILABLE (${notGoingList.length})'),
                    ],
                  ),
                  Expanded(
                    child: state.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : TabBarView(
                            children: [
                              _buildMemberList(goingList),
                              _buildMemberList(notGoingList),
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

  Widget _buildMemberList(List<EmergencyResponseModel> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No members found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final member = list[index].member;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: NTKColors.primary.withOpacity(0.1),
            child: Text(
              member.name[0].toUpperCase(),
              style: const TextStyle(color: NTKColors.primary),
            ),
          ),
          title: Text(
            member.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(member.phone),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  CupertinoIcons.phone_circle,
                  color: NTKColors.primary,
                  size: 28,
                ),
                onPressed: () => _launchAction(member.phone, 'tel'),
              ),
              IconButton(
                icon: const Icon(
                  CupertinoIcons.chat_bubble_2,
                  color: Colors.green,
                  size: 28,
                ),
                onPressed: () => _launchAction(member.phone, 'whatsapp'),
              ),
            ],
          ),
        );
      },
    );
  }
}
