import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Reusable Enterprise Bento Box Card Primitive
class BentoCard extends StatefulWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? icon;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool enableHover;

  const BentoCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.all(24.0),
    this.backgroundColor,
    this.onTap,
    this.enableHover = false,
  });

  @override
  State<BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<BentoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: _isHovered && widget.enableHover
          ? AppColors.metallicBorderHover
          : AppColors.metallicBorder,
      width: 1.2,
    );

    final cardContent = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: border,
        boxShadow: [
          BoxShadow(
            color: _isHovered && widget.enableHover
                ? AppColors.primaryTeal.withValues(alpha: 0.16)
                : AppColors.accentNavy.withValues(alpha: 0.035),
            blurRadius: _isHovered && widget.enableHover ? 32 : 24,
            offset: Offset(0, _isHovered && widget.enableHover ? 10 : 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (_isHovered && widget.enableHover)
            Positioned(
              top: -widget.padding.vertical / 2,
              left: 20,
              right: 20,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.gradientPill),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
          if (widget.title != null || widget.icon != null || widget.trailing != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (widget.icon != null) ...[
                        widget.icon!,
                        const SizedBox(width: 12),
                      ],
                      if (widget.title != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title!,
                                style: AppFonts.googleSans(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              if (widget.subtitle != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  widget.subtitle!,
                                  style: AppFonts.googleSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
            const SizedBox(height: 18),
          ],
          widget.child,
        ],
      ),
    ],
  ),
);

    if (widget.onTap != null || widget.enableHover) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isHovered && widget.enableHover ? 1.015 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: cardContent,
          ),
        ),
      );
    }

    return cardContent;
  }
}

/// Hero Banner for Section Headers
class BentoHeroBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? statusLabel;
  final Widget? trailing;

  const BentoHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.statusLabel,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.gradientBrand,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentNavy.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;

          final mainRow = Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: AppFonts.googleSans(
                              fontSize: isWide ? 20 : 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        if (statusLabel != null) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.electricMint.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.electricMint.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              statusLabel!,
                              style: AppFonts.googleSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.electricMint,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppFonts.googleSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (!isWide && trailing != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                mainRow,
                const SizedBox(height: 14),
                trailing!,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: mainRow),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing!,
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Metric KPI Tile for Top Grid
class BentoMetricTile extends StatefulWidget {
  final String label;
  final String value;
  final String? trendText;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback? onTap;

  const BentoMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.trendText,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.onTap,
  });

  @override
  State<BentoMetricTile> createState() => _BentoMetricTileState();
}

class _BentoMetricTileState extends State<BentoMetricTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isHovered
                    ? AppColors.primaryTeal.withValues(alpha: 0.3)
                    : AppColors.metallicBorder,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? AppColors.primaryTeal.withValues(alpha: 0.16)
                      : AppColors.accentNavy.withValues(alpha: 0.035),
                  blurRadius: _isHovered ? 30 : 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (_isHovered)
                  Positioned(
                    top: -20,
                    left: 15,
                    right: 15,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.gradientPill),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryTeal.withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.iconBgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(widget.icon, color: widget.iconColor, size: 20),
                    ),
                    if (widget.trendText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.trendText!,
                          style: AppFonts.googleSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      )
                    else if (widget.onTap != null)
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: AppColors.textMuted.withValues(alpha: 0.6),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.value,
                  style: AppFonts.googleSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.label,
                  style: AppFonts.googleSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}
