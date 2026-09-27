import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../providers/language_provider.dart';

/// The line under a catalogue's search box.
///
/// It exists to answer one question the admin screens could not answer before:
/// is this short list everything, or only the first page? A catalogue of 380
/// nutrition plans that hands back 100 of them, grouped so that the first 100
/// are all one market, reads as a catalogue with one market in it.
String catalogResultLabel(
  LanguageProvider lang, {
  required int shown,
  required int total,
  required String query,
}) {
  final args = {
    'shown': '$shown',
    'total': '$total',
    'query': query,
  };
  if (shown < total) {
    return lang.t('catalog_result_truncated', args: args);
  }
  if (query.isNotEmpty) {
    return lang.t('catalog_result_matches', args: args);
  }
  return lang.t('catalog_result_total', args: args);
}

/// The search box that sits at the top of an admin catalogue screen.
///
/// Every catalogue (exercises, workout templates, engine meals, ingredients,
/// engine plans) needs the same three behaviours, and the one screen that had a
/// search box got two of them wrong: it only searched when the keyboard's
/// submit key was pressed, and its clear button never appeared because nothing
/// rebuilt the field as the text changed.
///
///  * search as you type, debounced so a server-backed list does not fire a
///    request per keystroke;
///  * a clear button that shows up exactly while there is something to clear;
///  * an optional result count, which is what tells an admin whether a short
///    list is the whole catalogue or only the first page of it.
class CatalogSearchField extends StatefulWidget {
  final String hintText;

  /// Called with the trimmed query after [debounce] of quiet typing, and
  /// immediately on submit or clear.
  final ValueChanged<String> onChanged;

  /// Shown under the field, e.g. "Showing 50 of 214". Null hides the line.
  final String? resultLabel;

  final String initialValue;
  final Duration debounce;

  const CatalogSearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.resultLabel,
    this.initialValue = '',
    this.debounce = const Duration(milliseconds: 300),
  });

  @override
  State<CatalogSearchField> createState() => _CatalogSearchFieldState();
}

class _CatalogSearchFieldState extends State<CatalogSearchField> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String _lastEmitted = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _lastEmitted = widget.initialValue.trim();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Rebuild for the clear button, which depends on whether the field is empty.
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () => _emit(value));
  }

  void _emit(String value) {
    final query = value.trim();
    // Typing and then deleting back to the same text should not re-run a query
    // that is already on screen.
    if (query == _lastEmitted) return;
    _lastEmitted = query;
    widget.onChanged(query);
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {});
    _emit('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: (value) {
              _debounce?.cancel();
              _emit(value);
            },
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clear,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
            ),
          ),
          if (widget.resultLabel != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 6, start: 4),
              child: Text(
                widget.resultLabel!,
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
