import 'product.dart';

/// One line in the cart: product + kit line id + quantity.
class CartLine {
  CartLine({required this.product, required this.kitLineId, this.quantity = 1});

  final Product product;
  final String kitLineId;
  int quantity;

  String get kitLabel => product.kitForLineMaybe(kitLineId)?.label ?? 'Kit';

  int get unitPrice => product.kitForLineMaybe(kitLineId)?.priceInr ?? 0;

  int get lineTotal => unitPrice * quantity;

  bool sameKey(Product p, String lineId) =>
      product.id == p.id && kitLineId == lineId;
}
