import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// Responsive Scaffold for consistent layout across all pages
class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback? onMenuTap;
  final bool showBackButton;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;

  const ResponsiveScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.onMenuTap,
    this.showBackButton = false,
    this.actions,
    this.backgroundColor,
    this.appBar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getResponsivePadding(context);

    return WillPopScope(
      onWillPop: () async => !isMobile,
      child: Scaffold(
        backgroundColor: backgroundColor ?? const Color(0xFFF5F7FF),
        appBar: appBar ??
            AppBar(
              title: Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobileSize: 18,
                    tabletSize: 20,
                    desktopSize: 24,
                  ),
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              backgroundColor: const Color(0xFF7C8CF8),
              elevation: isMobile ? 2 : 0,
              leading: isMobile && showBackButton
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    )
                  : null,
              actions: actions,
            ),
        body: SingleChildScrollView(
          padding: padding,
          child: body,
        ),
      ),
    );
  }
}
