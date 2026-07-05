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
      borderRadius: borderRadius ??
          BorderRadius.circular(AppRadius.medium), // 10px to match React
      border: border ??
          (showBorder ? Border.all(color: theme.dividerColor, width: 1) : null),
      boxShadow: showShadow
          ? [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.16 : 0.05,
                ), // Subtle shadow like React
                blurRadius: 10,
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
                  borderRadius ?? BorderRadius.circular(AppRadius.medium),
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
