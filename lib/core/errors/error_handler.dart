import 'package:flutter/material.dart';
import 'app_failure.dart';

class ErrorHandler {
  /// Centralized logging for exceptions and stacktraces
  static void logError(Object error, [StackTrace? stackTrace, String? contextHint]) {
    final hint = contextHint != null ? '[$contextHint] ' : '';
    debugPrint('🛑 $hint Error: $error');
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Displays a SnackBar with user-facing message derived from AppFailure and optional retry action
  static void showErrorSnackBar(
    BuildContext context,
    Object error, {
    StackTrace? stackTrace,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final failure = AppFailure.fromException(error, stackTrace);
    logError(error, stackTrace, 'SnackBar');

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                failure.userMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.yellowAccent,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}
