import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// Enhanced card that EXACTLY matches React card design
/// - Exact border radius (10px)
/// - Exact border color and width
/// - Exact shadow (0.05 opacity, 10px blur)
/// - Hover effects matching React
class EnhancedCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final bool showBorder;
  final bool hoverEffect;
  final BorderRadius? borderRadius;
  
  const EnhancedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.showBorder = true,
    this.hoverEffect = true,
    this.borderRadius,
  });

  @override
  State<EnhancedCard> createState() => _EnhancedCardState();
}

class _EnhancedCardState extends State<EnhancedCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: widget.margin,
        transform: widget.hoverEffect && _isHovered && widget.onTap != null
            ? Matrix4.translationValues(0, -2, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: widget.color ?? Colors.white,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(AppRadius.medium), // 10px
          border: widget.showBorder
              ? Border.all(
                  color: AppColors.border,
                  width: 1,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.hoverEffect && _isHovered && widget.onTap != null
                    ? 0.1
                    : 0.05,),
              blurRadius: widget.hoverEffect && _isHovered && widget.onTap != null ? 20 : 10,
              offset: Offset(0, widget.hoverEffect && _isHovered && widget.onTap != null ? 4 : 2),
            ),
          ],
        ),
        child: widget.onTap != null
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(AppRadius.medium),
                  child: Padding(
                    padding: widget.padding ?? const EdgeInsets.all(16),
                    child: widget.child,
                  ),
                ),
              )
            : Padding(
                padding: widget.padding ?? const EdgeInsets.all(16),
                child: widget.child,
              ),
      ),
    );
  }
}

/// Card header matching React CardHeader
class CardHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  
  const CardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h3,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Card content matching React CardContent
class CardContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  
  const CardContent({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );
  }
}

/// Card footer matching React (if needed)
class CardFooter extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  
  const CardFooter({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(top: 16),
      child: child,
    );
  }
}
