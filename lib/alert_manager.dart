import 'package:flutter/material.dart';

class AlertDialogManager {
  final GlobalKey<NavigatorState> navigatorKey;

  /// Constructor that requires a `GlobalKey<NavigatorState>`
  AlertDialogManager(this.navigatorKey);

  /// Displays a simple alert dialog with a title, content, and a single "OK" button.
  void showAlert({
    required String title,
    required String content,
    VoidCallback? onOkPressed,
  }) {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) {
      throw Exception('Navigator context is not available.');
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                if (onOkPressed != null) onOkPressed();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Displays a confirmation dialog with "Yes" and "No" buttons.
  void showConfirmation({
    required String title,
    required String content,
    required VoidCallback onConfirmed,
    VoidCallback? onCancelled,
  }) {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) {
      throw Exception('Navigator context is not available.');
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                if (onCancelled != null) onCancelled();
              },
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                onConfirmed();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  /// Displays a custom alert dialog with any widget content.
  void showCustomDialog({
    required Widget content,
    List<Widget>? actions,
  }) {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) {
      throw Exception('Navigator context is not available.');
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: content,
          actions: actions ?? [],
        );
      },
    );
  }
}
