import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'razorpay_checkout_types.dart';

extension WindowRzp on web.Window {
  JSFunction? get razorpayConstructor =>
      (this as JSObject).getProperty<JSFunction?>('Razorpay'.toJS);
}

extension type RazorpayCheckout(JSObject _) implements JSObject {
  external void open();

  external void on(String event, JSFunction handler);
}

bool _scriptInjected = false;

Future<void> _ensureRazorpayJs() async {
  if (web.window.razorpayConstructor != null) return;

  if (!_scriptInjected) {
    _scriptInjected = true;
    final script = web.HTMLScriptElement()
      ..src = 'https://checkout.razorpay.com/v1/checkout.js'
      ..async = true;

    final completer = Completer<void>();
    final listener = ((web.Event event) {
      if (!completer.isCompleted) completer.complete();
    }).toJS;

    script.addEventListener('load', listener);

    web.document.head?.appendChild(script);

    try {
      await completer.future.timeout(const Duration(seconds: 30));
    } catch (_) {
      script.removeEventListener('load', listener);
      _scriptInjected = false;
      throw TimeoutException('checkout.js load');
    }
    script.removeEventListener('load', listener);
  }

  for (var i = 0; i < 120; i++) {
    if (web.window.razorpayConstructor != null) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  throw StateError('Razorpay global missing');
}

@JS('JSON.stringify')
external JSString _jsJsonStringify(JSAny? value);

Map<String, dynamic>? _responseMap(JSAny response) {
  try {
    final raw = _jsJsonStringify(response).toDart;
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return null;
}

JSObject _prefill(String contact, String name) {
  final o = JSObject();
  o.setProperty('contact'.toJS, contact.toJS);
  o.setProperty('name'.toJS, name.toJS);
  return o;
}

JSObject _theme(String color) {
  final o = JSObject();
  o.setProperty('color'.toJS, color.toJS);
  return o;
}

JSObject _modal(JSFunction onDismiss) {
  final o = JSObject();
  o.setProperty('ondismiss'.toJS, onDismiss);
  return o;
}

JSObject _checkoutOptions({
  required String keyId,
  required int amountPaise,
  required String customerName,
  required String customerPhone,
  required JSFunction handler,
  required JSFunction onDismiss,
  String? serverOrderId,
}) {
  final o = JSObject();
  o.setProperty('key'.toJS, keyId.toJS);
  o.setProperty('amount'.toJS, amountPaise.toJS);
  o.setProperty('currency'.toJS, 'INR'.toJS);
  o.setProperty('name'.toJS, 'Plantastic'.toJS);
  o.setProperty('description'.toJS, 'Plant order'.toJS);
  o.setProperty('prefill'.toJS, _prefill(customerPhone, customerName));
  o.setProperty('theme'.toJS, _theme('#2E7D32'));
  o.setProperty('handler'.toJS, handler);
  o.setProperty('modal'.toJS, _modal(onDismiss));

  final trimmed = serverOrderId?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    o.setProperty('order_id'.toJS, trimmed.toJS);
  }
  return o;
}

Future<RazorpayCheckoutResult> presentPlantasticRazorpayCheckout({
  required String keyId,
  required int amountPaise,
  required String customerName,
  required String customerPhone,
  String? serverOrderId,
}) async {
  try {
    await _ensureRazorpayJs();
  } catch (_) {
    return RazorpayCheckoutResult.error(
      'Payment gateway could not load. Check network or try again.',
    );
  }

  final ctor = web.window.razorpayConstructor;
  if (ctor == null) {
    return RazorpayCheckoutResult.error('Razorpay is unavailable');
  }

  final completer = Completer<RazorpayCheckoutResult>();

  void completeSuccess(JSAny response) {
    if (completer.isCompleted) return;
    final m = _responseMap(response);
    String? pid;
    String? oid;
    String? sig;
    if (m != null) {
      pid = m['razorpay_payment_id']?.toString();
      oid = m['razorpay_order_id']?.toString();
      sig = m['razorpay_signature']?.toString();
    }
    completer.complete(
      RazorpayCheckoutResult.success(
        paymentId: pid,
        orderId: oid,
        signature: sig,
      ),
    );
  }

  void completeDismiss() {
    if (!completer.isCompleted) {
      completer.complete(RazorpayCheckoutResult.cancelled());
    }
  }

  void completeFailed(JSAny response) {
    if (completer.isCompleted) return;
    final m = _responseMap(response);
    var msg = 'Payment failed';
    if (m != null && m['error'] is Map) {
      final err = m['error'] as Map;
      final d = err['description'];
      if (d != null) msg = '$d';
    }
    completer.complete(RazorpayCheckoutResult.error(msg));
  }

  final handler = ((JSAny response) {
    completeSuccess(response);
  }).toJS;

  final failed = ((JSAny response) {
    completeFailed(response);
  }).toJS;

  final opts = _checkoutOptions(
    keyId: keyId,
    amountPaise: amountPaise,
    customerName: customerName,
    customerPhone: customerPhone,
    handler: handler,
    onDismiss: completeDismiss.toJS,
    serverOrderId: serverOrderId,
  );

  final rawInstance = ctor.callAsConstructor<JSObject>(opts);
  final instance = RazorpayCheckout(rawInstance);

  instance.on('payment.failed', failed);
  instance.open();

  return completer.future;
}
