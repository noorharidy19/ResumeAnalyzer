import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// Responsive Card Widget for consistent styling across all screens
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? elevation;
  final BorderRadius? borderRadius;

  const ResponsiveCard({
    Key? key,
    required this.child,
    this.padding,
    this.elevation,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final effectivePadding = padding ?? EdgeInsets.all(isMobile ? 16 : 24);
    final effectiveElevation = elevation ?? 4.0;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);

    return Card(
      elevation: effectiveElevation,
      shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
      child: Padding(
        padding: effectivePadding,
        child: child,
      ),
    );
  }
}

/// Responsive List Item for candidate/profile lists
class ResponsiveListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isBold;

  const ResponsiveListItem({
    Key? key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.isBold = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final titleSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      mobileSize: 14,
      tabletSize: 16,
      desktopSize: 16,
    );

    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          fontSize: titleSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: isMobile ? 12 : 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: isMobile ? 4 : 8,
      ),
    );
  }
}

/// Responsive Grid View for displaying items in responsive grid
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final double? spacing;

  const ResponsiveGridView({
    Key? key,
    required this.children,
    this.padding,
    this.spacing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveHelper.getGridColumns(context);
    final effectiveSpacing = spacing ?? (ResponsiveHelper.isMobile(context) ? 8 : 16);
    final effectivePadding = padding ?? EdgeInsets.all(ResponsiveHelper.isMobile(context) ? 12 : 16);

    return Padding(
      padding: effectivePadding,
      child: GridView.count(
        crossAxisCount: columns,
        mainAxisSpacing: effectiveSpacing,
        crossAxisSpacing: effectiveSpacing,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: children,
      ),
    );
  }
}

/// Responsive Button
class ResponsiveButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final Color? backgroundColor;

  const ResponsiveButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final button = ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : Icon(icon ?? Icons.check),
      label: Text(isLoading ? 'Loading...' : label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? const Color(0xFF7C8CF8),
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 10 : 12,
          horizontal: isMobile ? 16 : 24,
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
