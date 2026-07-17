import 'package:flutter/animation.dart';

abstract final class AnimationConstants {
  AnimationConstants._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration verySlow = Duration(milliseconds: 600);

  static const Duration instant = Duration(milliseconds: 50);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration dialogOpen = Duration(milliseconds: 200);
  static const Duration dialogClose = Duration(milliseconds: 150);
  static const Duration toastShow = Duration(milliseconds: 250);
  static const Duration toastHide = Duration(milliseconds: 200);

  static const Curve standard = Curves.easeInOut;
  static const Curve decelerate = Curves.easeOut;
  static const Curve accelerate = Curves.easeIn;
  static const Curve sharp = Curves.easeInOutCubicEmphasized;

  static const Curve bounceIn = Curves.elasticOut;
  static const Curve bounceOut = Curves.elasticIn;
  static const Curve spring = Curves.easeOutBack;

  static const double scaleMin = 0.95;
  static const double scaleMax = 1.05;
  static const double scaleDefault = 1.0;
  static const double scalePressed = 0.96;
  static const double scaleIcon = 1.2;
  static const double scalePageEnter = 1.02;

  static const double opacityHidden = 0.0;
  static const double opacityVisible = 1.0;
  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.6;
  static const double opacityHint = 0.7;

  static const double slideDistance = 30.0;
  static const double slideDistanceShort = 16.0;
  static const double slideDistanceLong = 60.0;

  static const double fadeBegin = 0.0;
  static const double fadeEnd = 1.0;

  static const double staggerInterval = 0.05;
  static const int staggerMaxItems = 12;
}
