import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../providers/language_provider.dart';

/// The title row of a modal bottom sheet, with the button that closes it.
///
/// A sheet opened with `isScrollControlled: true` covers most of the screen, so
/// the scrim is a sliver at the very top and dragging a scrolling sheet back
/// down is not something a user discovers. Several form sheets offered no way
/// out at all except submitting them, which is a bad place to be if you opened
/// one by mistake. The admin editors already drew this row by hand; this is
/// that row, in one place, so every sheet closes the same way.
class SheetHeader extends StatelessWidget {
  final String title;

  /// What the close button does. Defaults to popping the sheet.
  final VoidCallback? onClose;

  /// Optional trailing controls, placed before the close button.
  final List<Widget> actions;

  const SheetHeader({
    super.key,
    required this.title,
    this.onClose,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.h2,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ...actions,
        IconButton(
          tooltip: lang.t('close'),
          onPressed: onClose ?? () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

/// A close button on its own, for a sheet that leads with something other than
/// a title — a product photo, say — where a [SheetHeader] would either sit
/// above the image or repeat a heading the content already shows.
class SheetCloseButton extends StatelessWidget {
  final VoidCallback? onClose;

  const SheetCloseButton({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: IconButton(
        tooltip: lang.t('close'),
        onPressed: onClose ?? () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close),
      ),
    );
  }
}

/// The grab handle at the top of a draggable sheet.
///
/// Purely an affordance: it tells the user the sheet can be pulled down. It is
/// not a substitute for [SheetHeader]'s close button, which is the part that
/// can be tapped.
class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// The "leave without doing anything" action for a chooser dialog.
///
/// Dialogs that are a list of choices had no such action: every row did
/// something, and the only way out was tapping the scrim. That is fine on a
/// phone and invisible everywhere else, and it is a poor place to leave someone
/// who opened a dialog that overwrites their work.
Widget dialogCancelAction(BuildContext context, {String? labelKey}) {
  final lang = context.watch<LanguageProvider>();
  return TextButton(
    onPressed: () => Navigator.of(context).pop(),
    child: Text(lang.t(labelKey ?? 'cancel')),
  );
}
