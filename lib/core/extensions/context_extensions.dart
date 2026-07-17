import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => theme.colorScheme;

  TextTheme get textTheme => theme.textTheme;

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  double get screenWidth => mediaQuery.size.width;

  double get screenHeight => mediaQuery.size.height;

  EdgeInsets get viewPadding => mediaQuery.viewPadding;

  double get topPadding => mediaQuery.viewPadding.top;

  double get bottomPadding => mediaQuery.viewPadding.bottom;

  Brightness get brightness => mediaQuery.platformBrightness;

  bool get isDarkMode => brightness == Brightness.dark;

  Localizations get localizations => Localizations.of(this, Localizations) as Localizations;

  NavigatorState get navigator => Navigator.of(this);

  GoRouterState get goRouterState => GoRouterState.of(this);

  void goPush(String location, {Object? extra}) {
    GoRouter.of(this).push(location, extra: extra);
  }

  void goReplace(String location, {Object? extra}) {
    GoRouter.of(this).go(location, extra: extra);
  }

  void goBack() {
    final router = GoRouter.of(this);
    if (router.canPop()) {
      router.pop();
    }
  }

  bool get isMobile => screenWidth < 600;

  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;

  bool get isDesktop => screenWidth >= 1024;

  bool get isLandscape => mediaQuery.orientation == Orientation.landscape;

  bool get isPortrait => mediaQuery.orientation == Orientation.portrait;

  double get responsiveWidthFactor {
    if (isDesktop) return 0.6;
    if (isTablet) return 0.8;
    return 0.95;
  }

  void unfocus() {
    FocusScope.of(this).unfocus();
  }
}
