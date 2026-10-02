/// The six-digit verification code box.
///
/// It looks like six separate boxes, and it used to *be* six separate
/// `TextField`s. That is the one shape the platform cannot autofill: both iOS
/// and Android hand the whole code to a single field, so a screen made of six
/// one-character fields gets the code dropped into the first box and the rest
/// left empty. Everyone typed it in by hand.
///
/// So there is one real field here, holding all six digits, and the boxes are
/// drawn from its text. The field is transparent and sits over the boxes to
/// catch taps. That is what makes [AutofillHints.oneTimeCode] work:
///
///  * on iOS the keyboard offers the code straight from the SMS — one tap;
///  * on Android the autofill service fills it from the message notification.
///
/// Fully hands-free reading on Android additionally needs the SMS Retriever
/// API, which means appending an 11-character app-signature hash to the
/// message body and matching it per signing key. That is a backend change,
/// not something this widget can do on its own.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_palette.dart';

class OtpInput extends StatefulWidget {
  /// Holds the whole code, not one digit.
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final int length;

  /// Called once the last digit lands, however it got there — typed, pasted
  /// or autofilled.
  final Future<void> Function()? onCompleted;

  const OtpInput({
    super.key,
    required this.controller,
    required this.focusNode,
    this.enabled = true,
    this.length = 6,
    this.onCompleted,
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  /// Guards against firing the submit twice when the field settles.
  bool _completionFired = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (!mounted) return;
    setState(() {});
    final code = widget.controller.text;
    if (code.length < widget.length) {
      // Backspacing out of a complete code re-arms the callback.
      _completionFired = false;
      return;
    }
    if (_completionFired) return;
    _completionFired = true;
    widget.focusNode.unfocus();
    widget.onCompleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final digits = widget.controller.text.split('');
    final focused = widget.focusNode.hasFocus;

    return AutofillGroup(
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (index) {
              final filled = index < digits.length;
              // The box the next digit will land in, so there is still a
              // visible caret equivalent without a real cursor.
              final isNext = focused && index == digits.length;
              return Container(
                width: 42,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isNext
                        ? Theme.of(context).colorScheme.primary
                        : context.palette.border,
                    width: isNext ? 2 : 1,
                  ),
                ),
                child: Text(
                  filled ? digits[index] : '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ),
          // The field that actually holds the code. Invisible, on top, and
          // the only thing the platform needs to see to offer the SMS code.
          Positioned.fill(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: widget.enabled,
              autofillHints: const [AutofillHints.oneTimeCode],
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              showCursor: false,
              enableInteractiveSelection: false,
              textAlign: TextAlign.center,
              // Transparent rather than hidden: a field with no size or no
              // place in the tree is a field the autofill service skips.
              style: const TextStyle(color: Colors.transparent),
              cursorColor: Colors.transparent,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              onTap: () {
                // Always type at the end; the boxes fill left to right and a
                // caret dropped in the middle would be invisible anyway.
                widget.controller.selection = TextSelection.collapsed(
                  offset: widget.controller.text.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
