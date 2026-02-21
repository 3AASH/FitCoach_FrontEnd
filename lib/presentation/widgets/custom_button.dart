import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

enum ButtonVariant {
  primary,
  secondary,
  outline,
  text,
  danger,
  ghost,
  link,
}

enum ButtonSize {
  small,
  medium,
  large,
}

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final button = _buildButton(isDisabled);

    return Listener(
      onPointerDown: isDisabled ? null : (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          opacity: isDisabled ? 0.85 : 1,
          child: button,
        ),
      ),
    );
  }

  Widget _buildButton(bool isDisabled) {
    final buttonChild = widget.isLoading
        ? SizedBox(
            height: _getIconSize(),
            width: _getIconSize(),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getLoadingColor(),
              ),
            ),
          )
        : Row(
            mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: _getIconSize()),
                const SizedBox(width: 8),
              ],
              Text(widget.text),
            ],
          );

    switch (widget.variant) {
      case ButtonVariant.primary:
        return SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          child: ElevatedButton(
            onPressed: isDisabled ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: _getPadding(),
              textStyle: _getTextStyle(),
              elevation: isDisabled ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: buttonChild,
          ),
        );
        
      case ButtonVariant.secondary:
        return SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          child: OutlinedButton(
            onPressed: isDisabled ? null : widget.onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.secondaryForeground,
              padding: _getPadding(),
              textStyle: _getTextStyle(),
              side: BorderSide(
                color: isDisabled ? AppColors.border : AppColors.secondaryForeground,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
            ),
            child: buttonChild,
          ),
        );
        
      case ButtonVariant.outline:
        return SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          child: OutlinedButton(
            onPressed: isDisabled ? null : widget.onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: _getPadding(),
              textStyle: _getTextStyle(),
              side: BorderSide(
                color: isDisabled ? AppColors.border : AppColors.primary,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: buttonChild,
          ),
        );
        
      case ButtonVariant.text:
        return SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          child: TextButton(
            onPressed: isDisabled ? null : widget.onPressed,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: _getPadding(),
              textStyle: _getTextStyle(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: buttonChild,
          ),
        );
        
      case ButtonVariant.danger:
        return SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          child: ElevatedButton(
            onPressed: isDisabled ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: _getPadding(),
              textStyle: _getTextStyle(),
              elevation: isDisabled ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: buttonChild,
          ),
        );
        
      case ButtonVariant.ghost:
        return SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          child: TextButton(
            onPressed: isDisabled ? null : widget.onPressed,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: _getPadding(),
              textStyle: _getTextStyle(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: buttonChild,
          ),
        );
        
      case ButtonVariant.link:
        return SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          child: TextButton(
            onPressed: isDisabled ? null : widget.onPressed,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: _getPadding(),
              textStyle: _getTextStyle(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: buttonChild,
          ),
        );
    }
  }

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  EdgeInsetsGeometry _getPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }
  
  TextStyle _getTextStyle() {
    switch (widget.size) {
      case ButtonSize.small:
        return const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
      case ButtonSize.medium:
        return const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
      case ButtonSize.large:
        return const TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
    }
  }
  
  double _getIconSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }
  
  Color _getLoadingColor() {
    switch (widget.variant) {
      case ButtonVariant.primary:
      case ButtonVariant.secondary:
      case ButtonVariant.danger:
        return Colors.white;
      case ButtonVariant.outline:
      case ButtonVariant.text:
      case ButtonVariant.ghost:
        return AppColors.primary;
      case ButtonVariant.link:
        return AppColors.primary;
    }
  }
}
