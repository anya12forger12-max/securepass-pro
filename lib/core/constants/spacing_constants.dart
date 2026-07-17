import 'package:flutter/widgets.dart';

abstract final class SpacingConstants {
  SpacingConstants._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  static const double zero = 0.0;
  static const double hairline = 1.0;
  static const double thin = 0.5;

  static const double touchTargetMin = 44.0;
  static const double touchTargetComfortable = 48.0;

  static const double iconSizeXs = 12.0;
  static const double iconSizeSm = 16.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
  static const double iconSizeXl = 48.0;

  static const double borderWidthThin = 0.5;
  static const double borderWidthRegular = 1.0;
  static const double borderWidthMedium = 2.0;
  static const double borderWidthThick = 3.0;

  static const double elevationNone = 0.0;
  static const double elevationLow = 1.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  static const double elevationHighest = 16.0;

  static const double dividerThickness = 1.0;
  static const double listDividerIndent = 16.0;
  static const double cardMinHeight = 56.0;
  static const double appBarHeight = 56.0;
  static const double bottomBarHeight = 56.0;
  static const double bottomSheetMaxHeight = 512.0;
  static const double dialogMinWidth = 280.0;
  static const double dialogMaxWidth = 560.0;

  static const double maxContentWidth = 600.0;
  static const double maxFormWidth = 480.0;
  static const double sidePanelWidth = 320.0;
}

abstract final class AppPadding {
  AppPadding._();

  static const EdgeInsets none = EdgeInsets.zero;

  static const EdgeInsets allXs = EdgeInsets.all(SpacingConstants.xs);
  static const EdgeInsets allSm = EdgeInsets.all(SpacingConstants.sm);
  static const EdgeInsets allMd = EdgeInsets.all(SpacingConstants.md);
  static const EdgeInsets allLg = EdgeInsets.all(SpacingConstants.lg);
  static const EdgeInsets allXl = EdgeInsets.all(SpacingConstants.xl);

  static const EdgeInsets pageHorizontal =
      EdgeInsets.symmetric(horizontal: SpacingConstants.md);
  static const EdgeInsets pageHorizontalLg =
      EdgeInsets.symmetric(horizontal: SpacingConstants.lg);
  static const EdgeInsets pageAll =
      EdgeInsets.symmetric(horizontal: SpacingConstants.md, vertical: SpacingConstants.md);

  static const EdgeInsets cardContent =
      EdgeInsets.all(SpacingConstants.md);
  static const EdgeInsets listItem =
      EdgeInsets.symmetric(horizontal: SpacingConstants.md, vertical: SpacingConstants.sm);
  static const EdgeInsets buttonHorizontal =
      EdgeInsets.symmetric(horizontal: SpacingConstants.lg, vertical: SpacingConstants.sm);

  static const EdgeInsets screenTop = EdgeInsets.only(top: SpacingConstants.md);
  static const EdgeInsets screenBottom = EdgeInsets.only(bottom: SpacingConstants.md);
}

abstract final class AppMargin {
  AppMargin._();

  static const EdgeInsets none = EdgeInsets.zero;

  static const EdgeInsets allXs = EdgeInsets.all(SpacingConstants.xs);
  static const EdgeInsets allSm = EdgeInsets.all(SpacingConstants.sm);
  static const EdgeInsets allMd = EdgeInsets.all(SpacingConstants.md);
  static const EdgeInsets allLg = EdgeInsets.all(SpacingConstants.lg);
  static const EdgeInsets allXl = EdgeInsets.all(SpacingConstants.xl);

  static const EdgeInsets horizontalSm =
      EdgeInsets.symmetric(horizontal: SpacingConstants.sm);
  static const EdgeInsets horizontalMd =
      EdgeInsets.symmetric(horizontal: SpacingConstants.md);
  static const EdgeInsets horizontalLg =
      EdgeInsets.symmetric(horizontal: SpacingConstants.lg);

  static const EdgeInsets verticalSm =
      EdgeInsets.symmetric(vertical: SpacingConstants.sm);
  static const EdgeInsets verticalMd =
      EdgeInsets.symmetric(vertical: SpacingConstants.md);
  static const EdgeInsets verticalLg =
      EdgeInsets.symmetric(vertical: SpacingConstants.lg);

  static const EdgeInsets topSm = EdgeInsets.only(top: SpacingConstants.sm);
  static const EdgeInsets topMd = EdgeInsets.only(top: SpacingConstants.md);
  static const EdgeInsets topLg = EdgeInsets.only(top: SpacingConstants.lg);
  static const EdgeInsets bottomSm = EdgeInsets.only(bottom: SpacingConstants.sm);
  static const EdgeInsets bottomMd = EdgeInsets.only(bottom: SpacingConstants.md);
  static const EdgeInsets bottomLg = EdgeInsets.only(bottom: SpacingConstants.lg);
}

abstract final class AppBorderRadius {
  AppBorderRadius._();

  static const BorderRadius none = BorderRadius.zero;
  static const BorderRadius xs = BorderRadius.all(Radius.circular(2.0));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(4.0));
  static const BorderRadius md = BorderRadius.all(Radius.circular(8.0));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius xxl = BorderRadius.all(Radius.circular(24.0));
  static const BorderRadius full = BorderRadius.all(Radius.circular(999.0));

  static const BorderRadius topMd = BorderRadius.vertical(top: Radius.circular(8.0));
  static const BorderRadius topLg = BorderRadius.vertical(top: Radius.circular(12.0));
  static const BorderRadius bottomMd = BorderRadius.vertical(bottom: Radius.circular(8.0));
  static const BorderRadius bottomLg = BorderRadius.vertical(bottom: Radius.circular(12.0));
}
