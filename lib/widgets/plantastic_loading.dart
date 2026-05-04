import 'package:flutter/widgets.dart';

import 'plantastic_flower_spinner.dart';

/// App-wide loading: left–right swaying rainbow flower ([PlantasticFlowerSpinner]).
/// Centre-of-screen uses the same animation as the global catalogue overlay.
abstract final class PlantasticLoading {
  static const Widget fullscreen = PlantasticFlowerSpinner(
    size: 96,
    showSoftDisk: false,
  );

  /// Admin panes / gate checks / save overlay — identical motion to shopper.
  static Widget get panel => fullscreen;
  static Widget get blocking => fullscreen;
  static Widget get compact => fullscreen;
  static Widget get detailHero => fullscreen;

  static const Widget thumbnail = PlantasticFlowerSpinner(
    size: 26,
    showSoftDisk: false,
  );

  static const Widget gallerySlot = PlantasticFlowerSpinner(
    size: 20,
    showSoftDisk: false,
  );

  static const Widget inline = PlantasticFlowerSpinner(
    size: 20,
    showSoftDisk: false,
  );
}
