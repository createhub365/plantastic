// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert' show base64Decode;
import 'dart:html' as html;
import 'dart:typed_data';

import 'gallery_pick_types.dart';

Future<Uint8List> _readFileBytesViaDataUrl(html.File file) async {
  final reader = html.FileReader();
  reader.readAsDataUrl(file);
  await reader.onLoad.first;
  final dataUrl = reader.result as String? ?? '';
  final comma = dataUrl.indexOf(',');
  if (comma < 0 || comma >= dataUrl.length - 1) {
    throw StateError('Invalid data URL from FileReader.');
  }
  return Uint8List.fromList(base64Decode(dataUrl.substring(comma + 1)));
}

Future<Uint8List> _readFileBytes(html.File file) async {
  try {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;
    final raw = reader.result;
    if (raw is ByteBuffer) return Uint8List.view(raw);
    if (raw is Uint8List) return raw;
    return Uint8List.view(raw as ByteBuffer);
  } catch (_) {
    return _readFileBytesViaDataUrl(file);
  }
}

/// Browser `<input type="file">`. Listens before [click] so fast `change` events are not lost.
Future<List<GalleryPick>> pickGalleryImages() async {
  final inp = html.FileUploadInputElement()
    ..multiple = true
    ..accept =
        'image/jpeg,image/jpg,image/png,image/webp,image/gif,.jpg,.jpeg,.png,.webp';

  final host = html.document.body ?? html.document.documentElement;
  host?.append(inp);
  inp.style
    ..display = 'none'
    ..visibility = 'hidden';

  List<html.File>? chosen;
  try {
    final change = inp.onChange.first.timeout(const Duration(seconds: 120));
    inp.click();
    await change;
    chosen = inp.files;
  } on TimeoutException {
    chosen = null;
  } finally {
    inp.remove();
  }

  if (chosen == null || chosen.isEmpty) return [];

  final out = <GalleryPick>[];
  for (final file in chosen) {
    try {
      final bytes = await _readFileBytes(file);
      if (bytes.isEmpty) continue;
      final n = file.name.trim().isEmpty ? 'photo.jpg' : file.name;
      out.add(GalleryPick(bytes: bytes, name: n));
    } catch (_) {
      //
    }
  }
  return out;
}
