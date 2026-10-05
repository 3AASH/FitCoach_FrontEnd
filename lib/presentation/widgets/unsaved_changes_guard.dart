import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../providers/language_provider.dart';

/// Asks before discarding unsaved work when the user navigates back.
///
/// No screen in this app had a back guard, so the Android system back button
/// discarded in-progress work silently: a coach part-way through a workout or
/// nutrition plan, a client mid-checkout, an admin editing a template. The
/// data is only in widget state until save, so back is destructive.
///
/// Wrap the [Scaffold] and pass [hasUnsavedChanges]. When it is false this is
/// transparent -- back behaves normally.
class UnsavedChangesGuard extends StatelessWidget {
  /// Whether there is work that would be lost. Re-read on every pop attempt,
  /// so pass the live value rather than a snapshot.
  final bool hasUnsavedChanges;

  /// Optional override for the dialog body, when a screen can say something
  /// more specific than the default.
  final String? messageKey;

  final Widget child;

  const UnsavedChangesGuard({
    super.key,
    required this.hasUnsavedChanges,
    required this.child,
    this.messageKey,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await confirmDiscard(context, messageKey: messageKey);
        if (shouldLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}

/// The discard confirmation on its own, for screens that need to run it from
/// their own back button or a custom pop path.
Future<bool> confirmDiscard(
  BuildContext context, {
  String? messageKey,
}) async {
  final lang = context.read<LanguageProvider>();
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(lang.t('unsaved_title')),
      content: Text(lang.t(messageKey ?? 'unsaved_message')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(lang.t('unsaved_keep_editing')),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            lang.t('unsaved_discard'),
            style: TextStyle(color: dialogContext.palette.error),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
