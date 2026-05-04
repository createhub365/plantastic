import 'dart:async';

import 'package:flutter/foundation.dart';

/// Web: fire-and-forget catalog loads must not surface as uncaught futures.
void guardCatalogFuture(Future<void> future, [String label = 'Catalog']) {
  unawaited(
    future.catchError((Object error, StackTrace stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'plantastic/catalog',
          context: ErrorDescription(label),
          silent: true,
        ),
      );
    }),
  );
}
