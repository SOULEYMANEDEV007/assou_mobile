import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final List<BoxShadow>? boxShadow;
  final bool hasBorder;
  final double? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.boxShadow,
    this.hasBorder = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardWidget = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
        border:
            hasBorder ? Border.all(color: AppColors.border, width: 1) : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }
}

class AppVoucherCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String? status;
  final Color? statusColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AppVoucherCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.status,
    this.statusColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      // Use a default shadow if AppShadows.medium is not defined
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: statusColor ?? AppColors.primary,
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (status != null) ...[
                  const SizedBox(height: 4.0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (statusColor ?? AppColors.primary).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      status!,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: statusColor ?? AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (trailing != null) ...[
                const SizedBox(height: 4.0),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class AppStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;

  const AppStatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: backgroundColor ?? AppColors.surface,
      // Use a default shadow if AppShadows.small is not defined
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primary,
                  size: 20,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: iconColor ?? AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4.0),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4.0),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
