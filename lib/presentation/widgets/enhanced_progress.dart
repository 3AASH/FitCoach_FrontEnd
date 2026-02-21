import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// Enhanced progress bar that EXACTLY matches React Progress component
class EnhancedProgress extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final bool showLabel;
  final String? customLabel;
  
  const EnhancedProgress({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.height = 8.0,
    this.showLabel = false,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).round();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (customLabel != null)
                Text(
                  customLabel!,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              Text(
                '$percentage%',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.surface,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: MediaQuery.of(context).size.width * value,
                  decoration: BoxDecoration(
                    color: color ?? AppColors.primary,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Circular progress indicator matching React
class EnhancedCircularProgress extends StatelessWidget {
  final double? value; // null for indeterminate
  final Color? color;
  final double size;
  final double strokeWidth;
  
  const EnhancedCircularProgress({
    super.key,
    this.value,
    this.color,
    this.size = 40.0,
    this.strokeWidth = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        value: value,
        color: color ?? AppColors.primary,
        strokeWidth: strokeWidth,
        backgroundColor: AppColors.surface,
      ),
    );
  }
}

/// Badge component matching React Badge
class EnhancedBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;
  final BadgeVariant variant;
  
  const EnhancedBadge({
    super.key,
    required this.text,
    this.color,
    this.textColor,
    this.variant = BadgeVariant.default_,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: variant == BadgeVariant.outline
            ? Border.all(color: _getBorderColor(), width: 1)
            : null,
      ),
      child: Text(
        text,
        style: AppTextStyles.small.copyWith(
          color: _getTextColor(),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (color != null) return color!;
    
    switch (variant) {
      case BadgeVariant.default_:
        return AppColors.primary;
      case BadgeVariant.secondary:
        return AppColors.secondary;
      case BadgeVariant.outline:
        return Colors.transparent;
      case BadgeVariant.destructive:
        return AppColors.error;
      case BadgeVariant.success:
        return AppColors.success;
      case BadgeVariant.warning:
        return AppColors.warning;
    }
  }

  Color _getTextColor() {
    if (textColor != null) return textColor!;
    
    switch (variant) {
      case BadgeVariant.default_:
        return Colors.white;
      case BadgeVariant.secondary:
        return AppColors.secondaryForeground;
      case BadgeVariant.outline:
        return AppColors.textPrimary;
      case BadgeVariant.destructive:
        return Colors.white;
      case BadgeVariant.success:
        return Colors.white;
      case BadgeVariant.warning:
        return Colors.white;
    }
  }

  Color _getBorderColor() {
    return _getBackgroundColor();
  }
}

enum BadgeVariant {
  default_,
  secondary,
  outline,
  destructive,
  success,
  warning,
}

/// Separator matching React Separator
class EnhancedSeparator extends StatelessWidget {
  final String? label;
  final bool vertical;
  final double thickness;
  final Color? color;
  
  const EnhancedSeparator({
    super.key,
    this.label,
    this.vertical = false,
    this.thickness = 1.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (label != null && !vertical) {
      return Row(
        children: [
          Expanded(
            child: Divider(
              thickness: thickness,
              color: color ?? AppColors.border,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label!,
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              thickness: thickness,
              color: color ?? AppColors.border,
            ),
          ),
        ],
      );
    }
    
    if (vertical) {
      return Container(
        width: thickness,
        height: double.infinity,
        color: color ?? AppColors.border,
      );
    }
    
    return Divider(
      thickness: thickness,
      color: color ?? AppColors.border,
    );
  }
}

/// Switch matching React Switch
class EnhancedSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  
  const EnhancedSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? AppColors.primary,
      activeTrackColor: (activeColor ?? AppColors.primary).withValues(alpha: 0.5),
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: AppColors.border,
    );
  }
}

/// Checkbox matching React Checkbox
class EnhancedCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final Color? activeColor;
  
  const EnhancedCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      side: BorderSide(
        color: AppColors.border,
        width: 2,
      ),
    );
  }
}
