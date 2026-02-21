import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// Wrapper widget that adds React-style focus rings to any widget
/// Matches React's focus-visible:ring-ring/50 focus-visible:ring-[3px]
class FocusWrapper extends StatefulWidget {
  final Widget child;
  final FocusNode? focusNode;
  final BorderRadius? borderRadius;
  final bool showFocusRing;
  final Color? focusColor;
  final double ringWidth;
  final VoidCallback? onFocusChange;
  
  const FocusWrapper({
    super.key,
    required this.child,
    this.focusNode,
    this.borderRadius,
    this.showFocusRing = true,
    this.focusColor,
    this.ringWidth = 3.0,
    this.onFocusChange,
  });

  @override
  State<FocusWrapper> createState() => _FocusWrapperState();
}

class _FocusWrapperState extends State<FocusWrapper> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    widget.onFocusChange?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(AppRadius.medium),
        border: widget.showFocusRing && _isFocused
            ? Border.all(
                color: (widget.focusColor ?? AppColors.ring).withValues(alpha: 0.5),
                width: widget.ringWidth,
              )
            : null,
        boxShadow: widget.showFocusRing && _isFocused
            ? [
                BoxShadow(
                  color: (widget.focusColor ?? AppColors.ring).withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Focus(
        focusNode: _focusNode,
        child: widget.child,
      ),
    );
  }
}

/// Enhanced InputDecoration with React-style focus ring
InputDecoration getFocusedInputDecoration({
  required BuildContext context,
  String? labelText,
  String? hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? errorText,
  bool enabled = true,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    errorText: errorText,
    enabled: enabled,
    filled: true,
    fillColor: enabled ? AppColors.surface : AppColors.surface.withValues(alpha: 0.5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      borderSide: BorderSide(color: AppColors.border, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      borderSide: BorderSide(color: AppColors.border, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      borderSide: BorderSide(color: AppColors.ring, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      borderSide: BorderSide(color: AppColors.error, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      borderSide: BorderSide(color: AppColors.error, width: 2),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5), width: 1),
    ),
  );
}
