import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';

/// A text field that suggests entries from an existing library as you type.
///
/// The coach plan builders used to take a free-text exercise or meal name,
/// which meant a plan could reference something the engine has never heard of:
/// the name looked right to the coach and matched no recipe or exercise id on
/// the way out. This keeps typing available (a coach can still write a custom
/// entry) but lets them pick a real library row, which is what carries the id.
///
/// The admin screens do the same thing with a bare [Autocomplete]; this widget
/// exists so the four coach screens share one copy, with the suggestion list
/// styled rather than left to the Material default.
class LibraryPickerField<T extends Object> extends StatelessWidget {
  final String initialValue;
  final String labelText;
  final List<T> options;

  /// Shown as the suggestion's main line, and written into the field on pick.
  final String Function(T option) optionLabel;

  /// Optional second line, e.g. the recipe id or the muscle group.
  final String? Function(T option)? optionDetail;

  /// Defaults to a case-insensitive contains over [optionLabel] and
  /// [optionDetail], which is enough for names and ids in either language.
  final bool Function(T option, String query)? matches;

  final bool enabled;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<T> onSelected;

  const LibraryPickerField({
    super.key,
    required this.initialValue,
    required this.labelText,
    required this.options,
    required this.optionLabel,
    required this.onTextChanged,
    required this.onSelected,
    this.optionDetail,
    this.matches,
    this.enabled = true,
  });

  bool _defaultMatches(T option, String query) {
    if (query.isEmpty) return true;
    final needle = query.toLowerCase();
    if (optionLabel(option).toLowerCase().contains(needle)) return true;
    final detail = optionDetail?.call(option);
    return detail != null && detail.toLowerCase().contains(needle);
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return TextFormField(
        initialValue: initialValue,
        enabled: false,
        decoration: InputDecoration(labelText: labelText),
      );
    }

    return Autocomplete<T>(
      initialValue: TextEditingValue(text: initialValue),
      displayStringForOption: optionLabel,
      optionsBuilder: (value) {
        final query = value.text.trim();
        final test = matches ?? _defaultMatches;
        // An empty query still lists the library so the field works as a
        // browsable dropdown, not only as a search box.
        return options.where((option) => test(option, query));
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onTextChanged,
          onFieldSubmitted: (_) => onSubmitted(),
          decoration: InputDecoration(
            labelText: labelText,
            suffixIcon: const Icon(Icons.search, size: 20),
          ),
        );
      },
      optionsViewBuilder: (context, onSelectedOption, results) {
        final items = results.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: ConstrainedBox(
              // Without a cap the overlay grows past the screen on a long
              // library and the list cannot be scrolled to the end.
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 520),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final option = items[index];
                  final detail = optionDetail?.call(option);
                  return ListTile(
                    dense: true,
                    title: Text(
                      optionLabel(option),
                      style: AppTextStyles.smallMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: detail == null || detail.isEmpty
                        ? null
                        : Text(
                            detail,
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                    onTap: () => onSelectedOption(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
