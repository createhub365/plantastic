import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

/// Lets mouse / stylus drag content (not only wheel), which Flutter Web/Desktop
/// often omits from the default material scroll behaviour.
final class PlantasticScrollBehavior extends MaterialScrollBehavior {
  const PlantasticScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
  };
}

/// Smooth vertical scroll; keeps gesture scroll working over short lists.
const ScrollPhysics plantasticViewportPhysics = AlwaysScrollableScrollPhysics(
  parent: ClampingScrollPhysics(),
);
