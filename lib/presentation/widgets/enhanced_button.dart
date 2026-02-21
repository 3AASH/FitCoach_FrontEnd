import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// Enhanced button that EXACTLY matches React button design
/// - Exact heights (h-8=32px, h-9=36px, h-10=40px)
/// - Exact padding
/// - Focus rings like React
/// - Smooth hover transitions
/// - All variants match shadcn/ui
class EnhancedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final Widget? icon;
  final bool fullWidth;
  final FocusNode? focusNode;
  
  const EnhancedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    this.focusNode,
  });

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  late FocusNode _focusNode;

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
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Focus(
        focusNode: _focusNode,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: widget.fullWidth ? double.infinity : null,
          height: _getExactHeight(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.small), // 6px for buttons
            border: _isFocused
                ? Border.all(
                    color: _getFocusRingColor().withValues(alpha: 0.5),
                    width: 3,
                  )
                : null,
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: _getFocusRingColor().withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(AppRadius.small),
              child: Container(
                decoration: BoxDecoration(
                  color: _getBackgroundColor(isDisabled),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  border: _getBorder(isDisabled),
                ),
                padding: _getExactPadding(),
                child: _buildButtonContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (widget.isLoading) {
      return SizedBox(
        height: _getIconSize(),
        width: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getTextColor(false)),
        ),
      );
    }

    return Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          widget.icon!,
          const SizedBox(width: 8),
        ],
        Text(
          widget.text,
          style: TextStyle(
            fontSize: _getFontSize(),
            fontWeight: FontWeight.w500, // React uses medium (500)
            color: _getTextColor(widget.onPressed == null),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// EXACT React heights: h-8 = 32px, h-9 = 36px, h-10 = 40px
  double _getExactHeight() {
    switch (widget.size) {
      case ButtonSize.small:
        return 32.0; // h-8
      case ButtonSize.medium:
        return 36.0; // h-9
      case ButtonSize.large:
        return 40.0; // h-10
    }
  }

  /// EXACT React padding
  EdgeInsetsGeometry _getExactPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        // h-8 px-3 in React = height 32, padding 12 horizontal
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case ButtonSize.medium:
        // h-9 px-4 in React = height 36, padding 16 horizontal
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.large:
        // h-10 px-6 in React = height 40, padding 24 horizontal
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 10);
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 14; // text-sm in React
      case ButtonSize.medium:
        return 14; // text-sm in React (buttons use sm)
      case ButtonSize.large:
        return 16; // text-base in React
    }
  }

  double _getIconSize() {
    return 16.0; // React uses size-4 (16px) for all button icons
  }

  Color _getBackgroundColor(bool isDisabled) {
    if (isDisabled) {
      return AppColors.surface.withValues(alpha: 0.5);
    }

    switch (widget.variant) {
      case ButtonVariant.primary:
        return _isHovered
            ? AppColors.primary.withValues(alpha: 0.9)
            : AppColors.primary;
      case ButtonVariant.secondary:
        return _isHovered
            ? AppColors.secondary.withValues(alpha: 0.8)
            : AppColors.secondary;
      case ButtonVariant.outline:
      case ButtonVariant.ghost:
        return _isHovered
            ? AppColors.accent.withValues(alpha: 0.1)
            : Colors.transparent;
      case ButtonVariant.text:
      case ButtonVariant.link:
        return Colors.transparent;
      case ButtonVariant.danger:
        return _isHovered
            ? AppColors.error.withValues(alpha: 0.9)
            : AppColors.error;
    }
  }

  Color _getTextColor(bool isDisabled) {
    if (isDisabled) {
      return AppColors.textDisabled;
    }

    switch (widget.variant) {
      case ButtonVariant.primary:
        return Colors.white;
      case ButtonVariant.secondary:
        return AppColors.secondaryForeground;
      case ButtonVariant.outline:
      case ButtonVariant.ghost:
      case ButtonVariant.link:
        return _isHovered
            ? AppColors.accentLight
            : AppColors.textPrimary;
      case ButtonVariant.text:
        return AppColors.primary;
      case ButtonVariant.danger:
        return Colors.white;
    }
  }

  Border? _getBorder(bool isDisabled) {
    if (widget.variant == ButtonVariant.outline) {
      return Border.all(
        color: isDisabled ? AppColors.border : AppColors.border,
        width: 1,
      );
    }
    return null;
  }

  Color _getFocusRingColor() {
    switch (widget.variant) {
      case ButtonVariant.danger:
        return AppColors.error;
      default:
        return AppColors.ring; // Purple focus ring
    }
  }
}

enum ButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  text,
  link,
  danger,
}

enum ButtonSize {
  small,
  medium,
  large,
}
