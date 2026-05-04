import 'dart:io' show File, Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'gallery_pick_types.dart';

Future<Uint8List?> _platformFileBytes(PlatformFile f) async {
  final direct = f.bytes;
  if (direct != null && direct.isNotEmpty) {
    return Uint8List.fromList(direct);
  }
  final path = f.path?.trim();
  if (path == null || path.isEmpty) return null;
  try {
    final b = await File(path).readAsBytes();
    return b.isEmpty ? null : b;
  } catch (_) {
    return null;
  }
}

Future<List<GalleryPick>> _pickWithFilePicker() async {
  final fp = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: true,
    withData: true,
  );
  if (fp == null || fp.files.isEmpty) return [];
  final out = <GalleryPick>[];
  for (final f in fp.files) {
    final raw = await _platformFileBytes(f);
    if (raw == null || raw.isEmpty) continue;
    final n = f.name.trim().isEmpty ? 'photo.jpg' : f.name.trim();
    out.add(GalleryPick(bytes: raw, name: n));
  }
  return out;
}

Future<List<GalleryPick>> pickGalleryImages() async {
  final useDesktopPicker =
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  if (useDesktopPicker) {
    return _pickWithFilePicker();
  }

  var imgs = <XFile>[];
  try {
    imgs = await ImagePicker().pickMultiImage(imageQuality: 88);
  } on MissingPluginException catch (_) {
    imgs = <XFile>[];
  }

  final out = <GalleryPick>[];
  if (imgs.isNotEmpty) {
    for (final x in imgs) {
      final b = await x.readAsBytes();
      if (b.isEmpty) continue;
      final n = x.name.trim().isNotEmpty ? x.name : 'photo.jpg';
      out.add(GalleryPick(bytes: b, name: n));
    }
    if (out.isNotEmpty) return out;
  }

  return _pickWithFilePicker();
}
