import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ExportService {
  static const MethodChannel _clipboardChannel =
      MethodChannel('com.boma.app/clipboard');

  /// Capture a widget to image bytes using a RepaintBoundary key
  static Future<Uint8List?> captureWidget(GlobalKey key, {double pixelRatio = 3.0}) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing widget: $e');
      return null;
    }
  }

  /// Save image to device gallery
  static Future<bool> saveToGallery(Uint8List imageBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/boma_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes);
      await Gal.putImage(file.path, album: 'Bstory');
      return true;
    } catch (e) {
      debugPrint('Error saving to gallery: $e');
      return false;
    }
  }

  /// Share image to other apps
  static Future<void> shareImage(Uint8List imageBytes, {String? text}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/boma_share_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
    }
  }

  /// Copy a PNG image to the system clipboard (for pasting styled text in Instagram Stories).
  static Future<bool> copyImageToClipboard(Uint8List imageBytes) async {
    try {
      final result = await _clipboardChannel.invokeMethod<bool>(
        'copyImage',
        {'bytes': imageBytes},
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Error copying image to clipboard: $e');
      return false;
    }
  }

  /// Save to temp file and return path
  static Future<String?> saveToTemp(Uint8List imageBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/boma_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes);
      return file.path;
    } catch (e) {
      debugPrint('Error saving to temp: $e');
      return null;
    }
  }
}
