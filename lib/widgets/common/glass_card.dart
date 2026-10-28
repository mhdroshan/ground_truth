import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 2026 Liquid Glass Card
/// Features Gaussian optical blur, translucent liquid gradient, specular edge highlights,
/// and subtle ambient diffused glow.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final double blur;
  final bool hasGlow;
  final Color? glowColor;
  final Gradient? gradient;
  final BoxBorder? customBorder;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 22,
    this.onTap,
    this.blur = 16,
    this.hasGlow = false,
    this.glowColor,
    this.gradient,
    this.customBorder,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = customBorder ??
        Border.all(
          color: borderColor ?? AppColors.liquidGlassBorderSubtle,
          width: 0.9,
        );

    final effectiveGradient = gradient ??
        (backgroundColor != null
            ? null
            : AppColors.liquidGlassGradient);

    Widget cardBody = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor ?? (effectiveGradient == null ? AppColors.liquidGlassFill : null),
            gradient: effectiveGradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: effectiveBorder,
          ),
          child: child,
        ),
      ),
    );

    // Ambient diffused shadow (2026 floating glass aesthetic)
    Widget positionedCard = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: glowColor ?? const Color(0x0A0F172A),
            blurRadius: hasGlow ? 24 : 16,
            spreadRadius: hasGlow ? 1 : 0,
            offset: const Offset(0, 6),
          ),
          if (hasGlow)
            BoxShadow(
              color: (glowColor ?? AppColors.primaryNavy).withValues(alpha: 0.08),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: cardBody,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.primaryNavy.withValues(alpha: 0.06),
          highlightColor: AppColors.primaryNavy.withValues(alpha: 0.03),
          child: positionedCard,
        ),
      );
    }

    return positionedCard;
  }
}

/// 2026 Bento Card Component
/// Modular asymmetric card with sharp geometric hierarchy, micro-labels, and crisp rounded corners.
class BentoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final String? microLabel;
  final IconData? microIcon;
  final Color? accentColor;
  final Widget? trailing;

  const BentoCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius = 22,
    this.onTap,
    this.microLabel,
    this.microIcon,
    this.accentColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (microLabel != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (microIcon != null) ...[
                    Icon(
                      microIcon,
                      size: 13,
                      color: accentColor ?? AppColors.primaryNavy,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    microLabel!.toUpperCase(),
                    style: TextStyle(
                      color: accentColor ?? AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                    ),
                  ),
                ],
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      );
    }

    Widget container = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.bentoSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.bentoBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: AppColors.primaryNavy.withValues(alpha: 0.04),
        child: container,
      );
    }

    return container;
  }
}
