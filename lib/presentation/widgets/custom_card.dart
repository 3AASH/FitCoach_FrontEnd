import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Border? border;
  final bool showBorder;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.elevation,
    this.borderRadius,
    this.border,
    this.showBorder = true, // Default to true to match React
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showShadow = elevation == null || elevation! > 0;
    final cardDecoration = BoxDecoration(
      color: color ?? theme.cardColor,
      borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.large),
      border: border ??
          (showBorder ? Border.all(color: theme.dividerColor, width: 1) : null),
      boxShadow: showShadow && theme.brightness != Brightness.dark
          ? [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );

    final cardChild = onTap == null
        ? child
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius:
                  borderRadius ?? BorderRadius.circular(AppRadius.large),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ),
          );

    return Container(
      margin: margin,
      decoration: cardDecoration,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: theme.colorScheme.onSurface),
        child: IconTheme.merge(
          data: IconThemeData(color: theme.colorScheme.onSurface),
          child: onTap == null
              ? Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: cardChild,
                )
              : cardChild,
        ),
      ),
    );
  }
}
