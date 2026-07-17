import 'package:flutter/material.dart';

import '../constants/spacing_constants.dart';

extension WidgetExtensions on Widget {
  Widget paddingAll(double value) {
    return Padding(
      padding: EdgeInsets.all(value),
      child: this,
    );
  }

  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      child: this,
    );
  }

  Widget paddingOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: left, top: top, right: right, bottom: bottom),
      child: this,
    );
  }

  Widget paddingInsets(EdgeInsets padding) {
    return Padding(padding: padding, child: this);
  }

  Widget get paddingPage => paddingInsets(AppPadding.pageAll);

  Widget get paddingPageHorizontal => paddingInsets(AppPadding.pageHorizontal);

  Widget get paddingCard => paddingInsets(AppPadding.cardContent);

  Widget get paddingListItem => paddingInsets(AppPadding.listItem);

  Widget marginAll(double value) {
    return Container(
      margin: EdgeInsets.all(value),
      child: this,
    );
  }

  Widget marginSymmetric({double horizontal = 0, double vertical = 0}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      child: this,
    );
  }

  Widget marginOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return Container(
      margin: EdgeInsets.only(left: left, top: top, right: right, bottom: bottom),
      child: this,
    );
  }

  Widget marginInsets(EdgeInsets margin) {
    return Container(margin: margin, child: this);
  }

  Widget get center => Center(child: this);

  Widget get alignCenter => Align(alignment: Alignment.center, child: this);

  Widget get alignTopLeft => Align(alignment: Alignment.topLeft, child: this);

  Widget get alignTopRight => Align(alignment: Alignment.topRight, child: this);

  Widget get alignBottomLeft => Align(alignment: Alignment.bottomLeft, child: this);

  Widget get alignBottomRight => Align(alignment: Alignment.bottomRight, child: this);

  Widget get alignCenterLeft => Align(alignment: Alignment.centerLeft, child: this);

  Widget get alignCenterRight => Align(alignment: Alignment.centerRight, child: this);

  Widget visibility(bool isVisible) {
    return Visibility(
      visible: isVisible,
      child: this,
    );
  }

  Widget get hidden => const SizedBox.shrink();

  Widget opacity(double value) {
    return Opacity(
      opacity: value.clamp(0.0, 1.0),
      child: this,
    );
  }

  Widget get disabled => AbsorbPointer(child: this);

  Widget get interactive => this;

  Widget sizedBox({double? width, double? height}) {
    return SizedBox(width: width, height: height, child: this);
  }

  Widget get expanded => Expanded(child: this);

  Widget expandedFlex(int flex) => Expanded(flex: flex, child: this);

  Widget get flexible => Flexible(child: this);

  Widget flexibleFlex(int flex) => Flexible(flex: flex, child: this);

  Widget get fadeIn => this;

  Widget constrainedBox({double? minWidth, double? maxWidth, double? minHeight, double? maxHeight}) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth ?? 0,
        maxWidth: maxWidth ?? double.infinity,
        minHeight: minHeight ?? 0,
        maxHeight: maxHeight ?? double.infinity,
      ),
      child: this,
    );
  }

  Widget get scrollable => SingleChildScrollView(child: this);

  Widget scrollableVertically({ScrollPhysics? physics}) {
    return SingleChildScrollView(physics: physics, child: this);
  }

  Widget scrollableHorizontally({ScrollPhysics? physics}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: physics,
      child: this,
    );
  }

  Widget tooltip(String message) {
    return Tooltip(message: message, child: this);
  }

  Widget inkwell({VoidCallback? onTap, VoidCallback? onLongPress, BorderRadius? borderRadius}) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: this,
    );
  }
}
