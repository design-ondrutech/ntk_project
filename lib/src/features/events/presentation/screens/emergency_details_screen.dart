import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/l10n/app_localizations.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';
import 'package:ntk_project/src/features/events/data/models/emergency_model.dart';
import 'package:ntk_project/src/core/utils/date_helper.dart';
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
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is EmergencyModel) {
        _alert = arg;
      } else if (arg is int) {
        _alert = EmergencyModel(
          id: arg.toString(),
          title: 'Loading...',
          description: '',
          type: '',
          contactName: '',
          contactPhone: '',
          expiryDate: '',
          collectResponse: false,
          locationName: '',
          going: 0,
          maybe: 0,
          notGoing: 0,
        );
      }

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
    return DateHelper.formatDateTime(dt);
  }

  String? _extractBloodGroup(String title, String description) {
    final combined = '$title $description'.toUpperCase();
    final RegExp regExp = RegExp(
      r'\b(A1|A2|A1B|A2B|A|B|AB|O)[\s]?[+-](?:\b|(?=\s))|O\s?(?:positive|negative)|A\s?(?:positive|negative)|B\s?(?:positive|negative)',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(combined);
    if (match != null) {
      return match
          .group(0)
          ?.toUpperCase()
          .replaceAll('POSITIVE', '+')
          .replaceAll('NEGATIVE', '-')
          .replaceAll(' ', '');
    }
    return null;
  }

  void _onRespond(String status) {
    if (_alert != null) {
      final authState = context.read<AuthBloc>().state;
      final userId = authState.loginData?.id?.toString();
      context.read<EventBloc>().add(
        RespondToEmergency(
          emergencyRequestId: _alert!.id,
          status: status,
          userId: userId,
        ),
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
  bool _isCompleting = false;

  bool get _isResolved {
    final status = _alert?.status?.toUpperCase();
    return status == 'ACCEPTED' ||
        status == 'APPROVED' ||
        status == 'REJECTED' ||
        status == 'COMPLETED' ||
        status == 'CLOSED';
  }

  bool get _isExpiredOrCompleted {
    return (_alert?.isExpired ?? false) || (_alert?.isCompleted ?? false);
  }

  Future<void> _onMarkCompleted() async {
    final alertId = _alert?.id;
    if (alertId == null || alertId.isEmpty) return;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Mark as Completed'),
        content: const Text(
          'Are you sure? This will mark the emergency request as COMPLETED and remove it from active alerts.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark Completed'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isCompleting = true);
    try {
      await sl<RequestRepository>().updateRequestStatus(
        id: int.parse(alertId),
        status: 'COMPLETED',
      );
      await _loadEmergencyDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency request marked as Completed ✅'),
            backgroundColor: Color(0xFF0369A1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
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

  Future<void> _onDeleteEmergency() async {
    final alertId = _alert?.id;
    if (alertId == null || alertId.isEmpty) return;
    setState(() => _isReviewing = true);
    try {
      await sl<EventRepository>().deleteEmergencyRequest(id: alertId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency request recalled successfully'),
            backgroundColor: Color(0xFF004D2A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Go back after recall
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to recall emergency request: $e'),
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

  Widget _buildRSVPActions(bool hasResponded, String myStatus) {
    Widget buildRSVPButton(String text, String statusValue, Color color) {
      final isSelected = myStatus == statusValue;
      return Expanded(
        child: ElevatedButton(
          onPressed: hasResponded ? null : () => _onRespond(statusValue),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? color : Colors.white,
            foregroundColor: isSelected ? Colors.white : color,
            disabledBackgroundColor: isSelected ? color.withOpacity(0.8) : Colors.grey.shade100,
            disabledForegroundColor: isSelected ? Colors.white : Colors.grey.shade400,
            side: BorderSide(
              color: hasResponded 
                  ? (isSelected ? color.withOpacity(0.8) : Colors.grey.shade300) 
                  : color, 
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            buildRSVPButton('COMING', 'COMING', const Color(0xFF004D2A)),
            const SizedBox(width: 8),
            buildRSVPButton('ON THE WAY', 'ON_THE_WAY', const Color(0xFFEAB308)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            buildRSVPButton('REACHED', 'REACHED', const Color(0xFF2563EB)),
            const SizedBox(width: 8),
            buildRSVPButton('UNABLE', 'UNABLE', const Color(0xFFDC2626)),
          ],
        ),
        if (hasResponded) ...[
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  myStatus == 'UNABLE' ? Icons.cancel_rounded : Icons.check_circle_rounded,
                  color: myStatus == 'UNABLE' ? const Color(0xFFDC2626) : const Color(0xFF004D2A),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Response submitted: $myStatus',
                  style: TextStyle(
                    color: myStatus == 'UNABLE' ? const Color(0xFFDC2626) : const Color(0xFF004D2A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionsSection(String userRoleRaw, int? userId) {
    final authState = context.read<AuthBloc>().state;
    final userName = authState.loginData?.name;
    final userRole = userRoleRaw.toUpperCase();
    
    final status = _alert?.status?.toUpperCase() ?? 'PENDING';
    final isCreator = _alert?.isCreatedBy(userId, userName: userName) ?? false;
    final isCompleted = status == 'COMPLETED' || status == 'CLOSED';
    final isRejected = status == 'REJECTED';
    final isExpired = _alert?.isExpired ?? false;

    // 1. Terminal States
    if (isCompleted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              children: const [
                Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 48),
                SizedBox(height: 12),
                Text(
                  'Request Completed / கோரிக்கை முடிவடைந்தது',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'This request has been marked as completed.',
                  style: TextStyle(color: Color(0xFF15803D), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showResponsesSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D2A),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'VIEW RESPONSES / ரெஸ்பான்ஸ்களைக் காண்',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    if (isExpired) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Row(
          children: const [
            Icon(Icons.timer_off_rounded, color: Color(0xFF6B7280), size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This request has expired. RSVP options are disabled.',
                style: TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isRejected) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: const [
            Icon(
              Icons.highlight_off_rounded,
              color: Color(0xFFDC2626),
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This emergency request has been rejected.',
                style: TextStyle(
                  color: Color(0xFF991B1B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    List<Widget> actionWidgets = [];

    // 2. Admin Logic
    final isAdminRole =
        userRole == 'ADMIN' ||
        userRole == 'SUB_ADMIN' ||
        userRole == 'SUPER_ADMIN';

    if (isAdminRole) {
      bool showApprove = false;
      bool showForward = false;
      bool showReject = false;
      String? forwardLabel;
      Color forwardColor = const Color(0xFF2563EB);

      if (userRole == 'SUB_ADMIN') {
        if (status == 'PENDING' || status == 'PENDING_SUB_ADMIN') {
          showApprove = !isCreator;
          showForward = true;
          showReject = !isCreator;
          forwardLabel = 'FORWARD TO ADMIN';
          forwardColor = const Color(0xFFEA580C);
        } else if (status == 'APPROVED_SUB_ADMIN' || status == 'ACCEPTED') {
          showApprove = false;
          showForward = true;
          showReject = !isCreator;
          forwardLabel = 'FORWARD TO ADMIN';
          forwardColor = const Color(0xFFEA580C);
        }
      } else if (userRole == 'ADMIN') {
        if (status == 'PENDING_ADMIN' || status == 'PENDING' || status == 'PENDING_SUB_ADMIN') {
          showApprove = !isCreator;
          showForward = true;
          showReject = !isCreator;
          forwardLabel = 'FORWARD TO SUPER ADMIN';
          forwardColor = const Color(0xFF9333EA);
        } else if (status == 'APPROVED_ADMIN' || status == 'ACCEPTED' || status == 'APPROVED_SUB_ADMIN') {
          showApprove = false;
          showForward = true;
          showReject = !isCreator;
          forwardLabel = 'FORWARD TO SUPER ADMIN';
          forwardColor = const Color(0xFF9333EA);
        }
      } else if (userRole == 'SUPER_ADMIN') {
        if (status == 'PENDING_SUPER_ADMIN' || status == 'PENDING' || status == 'PENDING_ADMIN') {
          showApprove = true;
          showReject = true;
        } else if (status == 'APPROVED_SUPER_ADMIN' || status == 'ACCEPTED' || status == 'APPROVED_ADMIN') {
          showApprove = false;
          showReject = true;
        }
      }

      if (showApprove || showForward || showReject) {
        if (_isReviewing) {
          actionWidgets.add(
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        } else {
          actionWidgets.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isCreator)
                  const Text(
                    'Action Required',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                if (!isCreator) const SizedBox(height: 12),
                Row(
                  children: [
                    if (showApprove)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _onReviewRequest('APPROVE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F5A29),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'APPROVE REQUEST',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    if (showApprove && showReject) const SizedBox(width: 12),
                    if (showReject)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _showRejectDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'REJECT REQUEST',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                if (showForward && forwardLabel != null) ...[
                  if (showApprove || showReject) const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _onReviewRequest('FORWARD'),
                    icon: Icon(Icons.arrow_forward, size: 18, color: forwardColor),
                    label: Text(
                      forwardLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: forwardColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: forwardColor,
                      side: BorderSide(color: forwardColor, width: 1.5),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }
      } else {
        // If no admin action buttons → check if emergency collects responses
        final isApprovedFallback =
            status == 'APPROVED' ||
            status == 'APPROVED_ADMIN' ||
            status == 'APPROVED_SUB_ADMIN' ||
            status == 'APPROVED_STATE' ||
            status == 'ACCEPTED';

        final collectResponseFallback = _alert?.collectResponse ?? false;
        if (collectResponseFallback && isApprovedFallback && !isCreator) {
          final eventState = context.watch<EventBloc>().state;
          final localStatus = eventState.myEmergencyResponses[_alert?.id ?? ''];
          final myResponse = eventState.emergencyResponses
              .where((r) => r.member.id == userId?.toString())
              .firstOrNull;
          
          final hasResponded = localStatus != null || myResponse != null;
          final myStatus = (localStatus ?? myResponse?.status ?? '').toUpperCase();
          
          actionWidgets.add(_buildRSVPActions(hasResponded, myStatus));
        } else if (!isCreator) {
          // No matching condition — show informational message
          actionWidgets.add(
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFEA580C), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This request has been forwarded or is under review at a higher level.',
                      style: TextStyle(color: Color(0xFFC2410C), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } else { // end isAdminRole
      // 3. Member Logic
      final isApprovedState =
          status == 'APPROVED' ||
          status == 'APPROVED_SUB_ADMIN' ||
          status == 'APPROVED_ADMIN' ||
          status == 'APPROVED_STATE' ||
          status == 'ACCEPTED';

      if (isApprovedState) {
        final bool collectResponse = _alert?.collectResponse ?? false;
        if (collectResponse && !isCreator) {
          final eventState = context.watch<EventBloc>().state;
          final localStatus = eventState.myEmergencyResponses[_alert?.id ?? ''];
          final myResponse = eventState.emergencyResponses
              .where((r) => r.member.id == userId?.toString())
              .firstOrNull;
              
          final hasResponded = localStatus != null || myResponse != null;
          final myStatus = (localStatus ?? myResponse?.status ?? '').toUpperCase();
          
          actionWidgets.add(_buildRSVPActions(hasResponded, myStatus));
        }
      } else if (status.startsWith('PENDING') && !isCreator) {
        actionWidgets.add(
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFEA580C),
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This request is currently under review by administrators.',
                    style: TextStyle(
                      color: Color(0xFFC2410C),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // 4. Append Creator Logic at the bottom
    if (isCreator) {
      if (actionWidgets.isNotEmpty) {
        actionWidgets.add(const SizedBox(height: 16));
      }
      
      // Determine if we should show the "View Responses" button (only if it collects responses)
      final bool collectResponseFallback = _alert?.collectResponse ?? false;
      
      actionWidgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (collectResponseFallback && !isCompleted) ...[
              ElevatedButton(
                onPressed: () => _showResponsesSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004D2A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppLocalizations.of(context)!.viewResponses,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (!isCompleted && !isRejected && !isExpired && userRole != 'SUPER_ADMIN') ...[
              OutlinedButton.icon(
                onPressed: () => _onReviewRequest('FORWARD'),
                icon: const Icon(Icons.arrow_forward, size: 18, color: Color(0xFF2563EB)),
                label: Text(
                  AppLocalizations.of(context)!.forwardRequest,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
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
              const SizedBox(height: 12),
            ],
            if (status != 'PENDING' && !status.startsWith('PENDING_') && !isCompleted)
              ElevatedButton.icon(
                onPressed: _isCompleting ? null : _onMarkCompleted,
                icon: _isCompleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  AppLocalizations.of(context)!.markAsCompleted,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0369A1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            if (status != 'PENDING' && !status.startsWith('PENDING_') && !isCompleted)
              const SizedBox(height: 12),
            if (!isCompleted)
              _buildDeleteButton(),
          ],
        ),
      );
    }

    if (actionWidgets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: actionWidgets,
    );
  }

  Widget _buildDeleteButton() {
    return OutlinedButton.icon(
      onPressed: () {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Recall Emergency Request'),
            content: const Text(
              'Are you sure you want to recall this emergency request? This action will permanently remove it.',
            ),
            actions: [
              CupertinoDialogAction(
                child: Text(AppLocalizations.of(context)!.cancel),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _onDeleteEmergency();
                },
                child: const Text('Recall'),
              ),
            ],
          ),
        );
      },
      icon: const Icon(CupertinoIcons.trash, size: 18),
      label: Text(
        AppLocalizations.of(context)!.recallEmergency,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFDC2626),
        side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Map<String, dynamic>? _parseDescription(String? description) {
    if (description == null || description.isEmpty) return null;
    try {
      final decoded = jsonDecode(description);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  Map<String, String> _extractEmergencyFields() {
    final Map<String, String> fields = {};
    final rawDesc = _alert?.description ?? '';
    Map<String, dynamic>? parsedDesc;
    try {
      final decoded = jsonDecode(rawDesc);
      if (decoded is Map<String, dynamic>) {
        parsedDesc = decoded;
      }
    } catch (_) {}

    if (parsedDesc != null) {
      fields['hospital'] =
          parsedDesc['hospitalName']?.toString() ??
          parsedDesc['hospital']?.toString() ??
          '';
      fields['condition'] = parsedDesc['patientCondition']?.toString() ?? '';
      fields['contactName'] =
          parsedDesc['contactName']?.toString() ?? _alert?.contactName ?? '';
      fields['contactPhone'] =
          parsedDesc['contactPhone']?.toString() ??
          parsedDesc['contactNumber']?.toString() ??
          _alert?.contactPhone ??
          '';
      fields['notes'] =
          parsedDesc['additionalInfo']?.toString() ??
          parsedDesc['additionalNotes']?.toString() ??
          parsedDesc['notes']?.toString() ??
          '';
    } else {
      final lines = rawDesc.split('\n');
      for (final line in lines) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim().toLowerCase();
          final val = parts.sublist(1).join(':').trim();
          if (key.contains('hospital'))
            fields['hospital'] = val;
          else if (key.contains('patient condition') ||
              key.contains('condition'))
            fields['condition'] = val;
          else if (key.contains('contact number') ||
              key.contains('contact phone') ||
              key.contains('phone'))
            fields['contactPhone'] = val;
          else if (key.contains('contact name'))
            fields['contactName'] = val;
          else if (key.contains('additional info') ||
              key.contains('additional notes') ||
              key.contains('notes'))
            fields['notes'] = val;
        }
      }
    }

    if ((fields['contactName'] ?? '').isEmpty &&
        _alert?.contactName != null &&
        _alert!.contactName.isNotEmpty) {
      fields['contactName'] = _alert!.contactName;
    }
    if ((fields['contactPhone'] ?? '').isEmpty &&
        _alert?.contactPhone != null &&
        _alert!.contactPhone.isNotEmpty) {
      fields['contactPhone'] = _alert!.contactPhone;
    }
    if ((fields['notes'] ?? '').isEmpty &&
        (fields['hospital'] ?? '').isEmpty &&
        (fields['condition'] ?? '').isEmpty) {
      fields['notes'] = rawDesc;
    }
    return fields;
  }

  Widget _buildTimeline() {
    final status = _alert?.status?.toUpperCase() ?? 'PENDING';
    final isRejected = status == 'REJECTED';
    final isAccepted =
        status == 'ACCEPTED' ||
        status == 'APPROVED' ||
        status.startsWith('APPROVED_');
    final isCompleted = status == 'COMPLETED' || status == 'CLOSED';

    int currentIndex = 0;
    if (status == 'COMPLETED' || status == 'CLOSED') {
      currentIndex = 4;
    } else if (status == 'APPROVED_STATE' ||
        status == 'APPROVED_SUPER_ADMIN' ||
        status == 'APPROVED' ||
        status == 'ACCEPTED') {
      currentIndex = 3;
    } else if (status == 'APPROVED_ADMIN') {
      currentIndex = 2;
    } else if (status == 'APPROVED_SUB_ADMIN') {
      currentIndex = 1;
    } else {
      final levelText = _alert?.currentLevelText ?? 'Sub Admin Review';
      if (levelText.contains('Super Admin'))
        currentIndex = 3;
      else if (levelText.contains('Admin Review') || levelText == 'Admin')
        currentIndex = 2;
      else
        currentIndex = 1;
    }

    final steps = [
      {
        'title': 'Created',
        'icon': Icons.lock_outline,
        'color': const Color(0xFF64748B),
      },
      {
        'title': 'Sub Admin',
        'icon': Icons.person_outline,
        'color': const Color(0xFF2563EB),
      },
      {
        'title': 'Admin',
        'icon': Icons.shield_outlined,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Super Admin',
        'icon': Icons.workspace_premium_outlined,
        'color': const Color(0xFF9333EA),
      },
      {
        'title': 'Completed',
        'icon': Icons.check,
        'color': const Color(0xFF16A34A),
      },
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index % 2 != 0) {
            final stepIndex = index ~/ 2;
            Color lineColor = const Color(0xFFE2E8F0);
            if (stepIndex < currentIndex - 1) {
              lineColor = const Color(0xFF16A34A);
            } else if (stepIndex == currentIndex - 1) {
              if (isRejected) {
                lineColor = const Color(0xFFE2E8F0);
              } else {
                lineColor = steps[currentIndex]['color'] as Color;
              }
            }
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 14),
                height: 2,
                color: lineColor,
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final step = steps[stepIndex];
          final bool isPassed = stepIndex < currentIndex;
          final bool isActive = stepIndex == currentIndex;

          Color circleColor = const Color(0xFFE2E8F0);
          Color iconColor = const Color(0xFF94A3B8);
          Color textColor = const Color(0xFF94A3B8);
          IconData iconData = step['icon'] as IconData;

          if (isPassed) {
            circleColor = const Color(0xFF16A34A);
            iconColor = const Color(0xFF16A34A);
            textColor = const Color(0xFF16A34A);
            iconData = Icons.check;
          } else if (isActive) {
            if (isRejected) {
              circleColor = const Color(0xFFDC2626);
              iconColor = const Color(0xFFDC2626);
              textColor = const Color(0xFFDC2626);
              iconData = Icons.close;
            } else if (isAccepted) {
              circleColor = step['color'] as Color;
              iconColor = step['color'] as Color;
              textColor = step['color'] as Color;
              iconData = Icons.check;
            } else {
              circleColor = step['color'] as Color;
              iconColor = step['color'] as Color;
              textColor = step['color'] as Color;
            }
          }

          if (stepIndex == 0) {
            iconData = Icons.lock_outline;
            if (isPassed || isActive) {
              circleColor = const Color(0xFF64748B);
              iconColor = const Color(0xFF64748B);
              textColor = const Color(0xFF64748B);
            }
          }

          return SizedBox(
            width: 50,
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: circleColor, width: 2),
                    color: Colors.white,
                  ),
                  child: Icon(iconData, size: 16, color: iconColor),
                ),
                const SizedBox(height: 8),
                Text(
                  step['title'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive || isPassed
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDetailsCard() {
    final type = _alert!.type.toUpperCase();
    final createdBy = _alert!.createdBy ?? 'N/A';
    final createdTime =
        _alert!.createdAt != null && _alert!.createdAt!.isNotEmpty
        ? _formatDateTime(_alert!.createdAt)
        : 'N/A';
    final location = _alert!.locationName;

    final hospital = _alert!.hospitalName ?? 'N/A';
    final condition = _alert!.patientCondition ?? 'N/A';
    final contactName = _alert!.contactName.isNotEmpty
        ? _alert!.contactName
        : 'N/A';
    final contactPhone = _alert!.contactPhone.isNotEmpty
        ? _alert!.contactPhone
        : 'N/A';
    final notes = _alert!.description.isNotEmpty ? _alert!.description : 'N/A';

    String statusText = _alert!.statusBadgeText;
    if (statusText == 'Pending' &&
        _alert!.status?.toUpperCase() == 'FORWARDED') {
      statusText = 'Under Review';
    } else if (statusText == 'Forwarded') {
      statusText = 'Under Review';
    } else if (statusText == 'Pending' &&
        _alert!.currentLevelText != 'Sub Admin Review') {
      statusText = 'Under Review';
    } else if (statusText == 'Pending') {
      statusText = 'Pending';
    }

    Color badgeBgColor = _alert!.statusBadgeBgColor;
    Color badgeTextColor = _alert!.statusBadgeTextColor;
    if (statusText == 'Under Review') {
      badgeBgColor = const Color(0xFFEFF6FF);
      badgeTextColor = const Color(0xFF2563EB);
    } else if (statusText == 'Pending') {
      badgeBgColor = const Color(0xFFFFF7ED);
      badgeTextColor = const Color(0xFFEA580C);
    }

    Color currentLevelColor = const Color(0xFF2563EB);
    final currentLvl = _alert!.currentLevelText;
    if (currentLvl == 'Admin Review') {
      currentLevelColor = const Color(0xFFF59E0B);
    } else if (currentLvl == 'Super Admin Review') {
      currentLevelColor = const Color(0xFF9333EA);
    } else if (_alert!.status?.toUpperCase() == 'REJECTED') {
      currentLevelColor = const Color(0xFFDC2626);
    } else if (_alert!.status?.toUpperCase() == 'COMPLETED' ||
        _alert!.status?.toUpperCase() == 'CLOSED' ||
        currentLvl.contains('Approved') ||
        currentLvl == 'Accepted') {
      currentLevelColor = const Color(0xFF16A34A);
    }

    Widget buildField(String label, String value, {Color valueColor = const Color(0xFF1F2937)}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor)),
        ],
      );
    }

    Widget buildSectionHeader(IconData icon, String title) {
      return Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
        ],
      );
    }

    List<Widget> sections = [];

    // 1. Type Row
    sections.add(Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionHeader(_alert!.typeIcon, 'Type'),
              const SizedBox(height: 8),
              Text(_alert!.typeLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
        if (type == 'BLOOD_REQUIRED' && _alert!.bloodGroup != null)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionHeader(Icons.bloodtype_outlined, 'Blood Group'),
                const SizedBox(height: 8),
                Text(_alert!.bloodGroup!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFDC2626))),
              ],
            ),
          ),
        if (type == 'DISASTER_SUPPORT' && _alert!.disasterType != null)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionHeader(Icons.thunderstorm_outlined, 'Disaster Type'),
                const SizedBox(height: 8),
                Text(_alert!.disasterType!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        if (type == 'VOLUNTEER_NEEDED' && _alert!.volunteerType != null)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionHeader(Icons.handshake_outlined, 'Volunteer Type'),
                const SizedBox(height: 8),
                Text(_alert!.volunteerType!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
      ],
    ));

    // 2. Request Info
    sections.add(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionHeader(CupertinoIcons.info_circle, 'Request Info'),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: buildField('Created By', createdBy)),
            Expanded(child: buildField('Created On', createdTime)),
          ],
        ),
      ],
    ));

    // 3. Location / Hospital Details
    if (type == 'MEDICAL_EMERGENCY' || type == 'BLOOD_REQUIRED') {
      if (hospital != 'N/A') {
        sections.add(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionHeader(Icons.local_hospital_outlined, 'Hospital Details'),
            const SizedBox(height: 12),
            Text(hospital, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(location, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13)),
          ],
        ));
      } else {
        sections.add(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionHeader(Icons.location_on_outlined, 'Location Details'),
            const SizedBox(height: 12),
            Text(location, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13)),
          ],
        ));
      }

      if (condition != 'N/A' || (type == 'BLOOD_REQUIRED' && _alert!.unitsRequired != null)) {
        sections.add(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionHeader(Icons.personal_injury_outlined, 'Patient Details'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (condition != 'N/A') Expanded(child: buildField('Condition', condition)),
                if (type == 'BLOOD_REQUIRED' && _alert!.unitsRequired != null)
                  Expanded(child: buildField('Units Required', _alert!.unitsRequired!)),
              ],
            ),
          ],
        ));
      }
    } else {
      sections.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionHeader(Icons.location_on_outlined, 'Location Details'),
          const SizedBox(height: 12),
          if (type == 'DISASTER_SUPPORT' && _alert!.affectedArea != null && _alert!.affectedArea!.isNotEmpty) ...[
            Text(_alert!.affectedArea!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
          ],
          Text(location, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13)),
        ],
      ));

      if (_alert!.requiredSupport != null && _alert!.requiredSupport!.isNotEmpty) {
        sections.add(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionHeader(Icons.support_outlined, 'Required Support'),
            const SizedBox(height: 12),
            Text(_alert!.requiredSupport!, style: const TextStyle(fontSize: 14)),
          ],
        ));
      }
    }

    // 4. Contact Details
    sections.add(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionHeader(Icons.contact_phone_outlined, 'Contact Details'),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: buildField('Contact Person', contactName)),
            Expanded(child: buildField('Contact Number', contactPhone, valueColor: const Color(0xFF2563EB))),
          ],
        ),
      ],
    ));

    // 5. Additional Notes
    if (notes.isNotEmpty && notes != 'N/A') {
      sections.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionHeader(Icons.edit_note_outlined, 'Additional Notes'),
          const SizedBox(height: 12),
          Text(notes, style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
        ],
      ));
    }

    List<Widget> cardChildren = [];
    for (int i = 0; i < sections.length; i++) {
      cardChildren.add(sections[i]);
      if (i < sections.length - 1) {
        cardChildren.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
              _buildTimeline(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _alert!.typeBgColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _alert!.typeColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_alert!.typeIcon, color: _alert!.typeColor, size: 14),
                        const SizedBox(width: 6),
                        Text(_alert!.typeLabel, style: TextStyle(color: _alert!.typeColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(6)),
                    child: Text(statusText, style: TextStyle(color: badgeTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 100,
                    child: Text('Level', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    child: Text(
                      _alert!.status?.toUpperCase() == 'COMPLETED' ? 'Completed' : currentLvl,
                      style: TextStyle(color: currentLevelColor, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Request Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
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
            children: cardChildren,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBlueValue = false,
  }) {
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
                color: isBlueValue
                    ? const Color(0xFF1967D2)
                    : const Color(0xFF1E293B),
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
    final percentage = total > 0
        ? (count / total * 100).toStringAsFixed(0)
        : '0';
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
                  // Show Responses Overview to: creator (any role) + admins/sub-admins
                  Builder(
                    builder: (context) {
                      final isCreator = _alert?.isCreatedBy(userId) ?? false;
                      final canSeeResponses =
                          isCreator; // Creator-ku mattum show aaganum
                      final collectResponse = _alert?.collectResponse ?? false;
                      if (!canSeeResponses || !collectResponse)
                        return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                      );
                    },
                  ),
                ], // closes inner Column's children: [
              ), // closes inner Column(
            ), // closes Padding(
          ], // closes outer Column's children: [
        ), // closes outer Column(
      ), // closes SingleChildScrollView(
    ); // closes Scaffold(
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
                .where((r) => r.status == 'COMING' || r.status == 'GOING' || r.status == 'ON_THE_WAY' || r.status == 'REACHED')
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
