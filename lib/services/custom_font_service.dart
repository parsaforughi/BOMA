import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/custom_font.dart';
import 'storage_service.dart';

class CustomFontService {
  final StorageService _storage;

  CustomFontService(this._storage);

  List<CustomFont> loadFromStorage() {
    return _storage
        .getCustomFonts()
        .map((m) => CustomFont.fromJson(m))
        .toList();
  }

  Future<Directory> _fontsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/custom_fonts');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> registerFonts(List<CustomFont> fonts) async {
    final dir = await _fontsDirectory();
    for (final font in fonts) {
      final file = File('${dir.path}/${font.fileName}');
      if (!await file.exists()) continue;
      try {
        final bytes = await file.readAsBytes();
        await _loadFontBytes(font.family, bytes);
      } catch (_) {
        // Skip corrupt or missing files
      }
    }
  }

  Future<void> _loadFontBytes(String family, Uint8List bytes) async {
    final loader = FontLoader(family);
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }

  Future<CustomFont?> importFromPicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    Uint8List? bytes = picked.bytes;
    if (bytes == null && picked.path != null) {
      bytes = await File(picked.path!).readAsBytes();
    }
    if (bytes == null || bytes.isEmpty) return null;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final family = 'BOMACustom_$id';
    final originalName = picked.name;
    final displayName = _displayNameFromFileName(originalName);
    final ext = originalName.toLowerCase().endsWith('.otf') ? 'otf' : 'ttf';
    final fileName = '$id.$ext';

    final dir = await _fontsDirectory();
    await File('${dir.path}/$fileName').writeAsBytes(bytes);

    await _loadFontBytes(family, bytes);

    final customFont = CustomFont(
      id: id,
      displayName: displayName,
      family: family,
      fileName: fileName,
    );

    final list = loadFromStorage()..add(customFont);
    await _storage.saveCustomFonts(list.map((f) => f.toJson()).toList());

    return customFont;
  }

  String _displayNameFromFileName(String name) {
    var base = name;
    final dot = base.lastIndexOf('.');
    if (dot > 0) base = base.substring(0, dot);
    if (base.length > 24) base = '${base.substring(0, 22)}…';
    return base.isEmpty ? 'فونت' : base;
  }
}
