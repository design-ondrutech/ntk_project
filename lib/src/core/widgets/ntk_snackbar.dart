import 'package:flutter/material.dart';

class NTKSnackbar {
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
      type: _SnackbarType.success,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
      type: _SnackbarType.error,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
      type: _SnackbarType.warning,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    required Duration duration,
    required _SnackbarType type,
  }) {
    // Hide current snackbar if any
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    Color iconColor;
    Widget iconWidget;

    switch (type) {
      case _SnackbarType.success:
        iconColor = const Color(0xFF10B981); // Success Green
        iconWidget = Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 2),
          ),
          child: Icon(
            Icons.check,
            color: iconColor,
            size: 14,
          ),
        );
        break;
      case _SnackbarType.error:
        iconColor = const Color(0xFFEF4444); // Error Red
        iconWidget = Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 2),
          ),
          child: Icon(
            Icons.close,
            color: iconColor,
            size: 14,
          ),
        );
        break;
      case _SnackbarType.warning:
        iconColor = const Color(0xFFF59E0B); // Warning Amber
        iconWidget = Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 2),
          ),
          child: Icon(
            Icons.priority_high,
            color: iconColor,
            size: 14,
          ),
        );
        break;
      case _SnackbarType.info:
        iconColor = const Color(0xFF3B82F6); // Info Blue
        iconWidget = Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 2),
          ),
          child: Icon(
            Icons.notifications_active,
            color: iconColor,
            size: 14,
          ),
        );
        break;
    }

    final snackBar = SnackBar(
      backgroundColor: const Color(0xFF1E2A44), // Dark Navy
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: duration,
      content: Row(
        children: [
          iconWidget,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                if (onActionPressed != null) {
                  onActionPressed();
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ],
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void showNotification(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message: message,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
      type: _SnackbarType.info,
    );
  }
}

enum _SnackbarType { success, error, warning, info }
