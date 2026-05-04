import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartNotifier extends ChangeNotifier {
  final List<CartLine> _lines = [];

  List<CartLine> get lines => List.unmodifiable(_lines);

  int get itemCount => _lines.fold(0, (s, e) => s + e.quantity);

  int get grandTotal => _lines.fold(0, (s, line) => s + line.lineTotal);

  void addOrIncrement(Product product, String kitLineId) {
    if (!product.availableForPurchase) return;
    for (final line in _lines) {
      if (line.product.id == product.id && line.kitLineId == kitLineId) {
        line.quantity += 1;
        notifyListeners();
        return;
      }
    }
    _lines.add(CartLine(product: product, kitLineId: kitLineId));
    notifyListeners();
  }

  void setQuantity(Product product, String kitLineId, int qty) {
    if (qty < 1) {
      removeLine(product.id, kitLineId);
      return;
    }
    if (!product.availableForPurchase) {
      for (final line in _lines) {
        if (line.product.id == product.id && line.kitLineId == kitLineId) {
          if (qty <= line.quantity) {
            line.quantity = qty;
            notifyListeners();
          }
          return;
        }
      }
      return;
    }
    for (final line in _lines) {
      if (line.product.id == product.id && line.kitLineId == kitLineId) {
        line.quantity = qty;
        notifyListeners();
        return;
      }
    }
  }

  void removeLine(String productId, String kitLineId) {
    _lines.removeWhere(
      (l) => l.product.id == productId && l.kitLineId == kitLineId,
    );
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }

  CartLine? findLine(Product product, String kitLineId) {
    for (final line in _lines) {
      if (line.sameKey(product, kitLineId)) return line;
    }
    return null;
  }
}
