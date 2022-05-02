import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tv/core/resources/color_constants.dart';

extension ColorExtension on Color {
  Color getForegroundColor() {
    return computeLuminance() < 0.5
        ? ColorConstants.kWhite
        : ColorConstants.kBlack;
  }

  MaterialColor toMaterialColor() {
    final Color color = this;
    return MaterialColor(color.value, {
      50: tintColor(0.9),
      100: tintColor(0.8),
      200: tintColor(0.6),
      300: tintColor(0.4),
      400: tintColor(0.2),
      500: color,
      600: shade(0.1),
      700: shade(0.2),
      800: shade(0.3),
      900: shade(0.4),
    });
  }

  int tintValue(int value, double factor) =>
      max(0, min((value + ((255 - value) * factor)).round(), 255));

  Color tintColor(double factor) => Color.fromRGBO(tintValue(red, factor),
      tintValue(green, factor), tintValue(blue, factor), 1);

  int shadeValue(int value, double factor) =>
      max(0, min(value - (value * factor).round(), 255));

  Color shade(double factor) => Color.fromRGBO(shadeValue(red, factor),
      shadeValue(green, factor), shadeValue(blue, factor), 1);
}
