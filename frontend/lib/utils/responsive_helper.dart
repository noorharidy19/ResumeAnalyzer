import 'package:flutter/material.dart'; 

/// Responsive Helper for handling different screen sizes
class ResponsiveHelper {
  static const double mobileBreakpoint = 480;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1200;

  /// Check if screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  /// Check if screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  /// Check if screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(12);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(20);
    } else {
      return const EdgeInsets.all(30);
    }
  }

  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context,
      {required double mobileSize,
      required double tabletSize,
      required double desktopSize}) {
    if (isMobile(context)) {
      return mobileSize;
    } else if (isTablet(context)) {
      return tabletSize;
    } else {
      return desktopSize;
    }
  }

  /// Get responsive grid columns
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }

  /// Get responsive sidebar width
  static double getSidebarWidth(BuildContext context) {
    if (isMobile(context)) {
      return 0; // No sidebar on mobile
    } else if (isTablet(context)) {
      return 200;
    } else {
      return 250;
    }
  }

  /// Get screen width percentage
  static double getScreenWidthPercentage(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height percentage
  static double getScreenHeightPercentage(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}

/// Device orientation helper
class OrientationHelper {
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
}
