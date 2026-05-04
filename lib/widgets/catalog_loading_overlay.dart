import 'package:flutter/material.dart';

import 'plantastic_loading.dart';

/// Full-screen blocker while catalogue data (and hero covers) are loading.
class CatalogLoadingOverlay extends StatelessWidget {
  const CatalogLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.34),
        child: Center(
          child: Semantics(
            label: 'Loading catalogue',
            child: PlantasticLoading.fullscreen,
          ),
        ),
      ),
    );
  }
}
