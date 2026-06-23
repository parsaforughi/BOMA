import 'package:flutter/material.dart';
import '../models/sticker_item.dart';
import '../models/text_style_preset.dart';
import 'canvas_state.dart';
import 'storage_service.dart';

const int maxDrafts = 10;

/// از JSON ممکنه int یا double بیاد
double? _numToDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return null;
}

int? _numToInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return null;
}

/// پیش‌نویس جدید را به ابتدای تاریخچه اضافه می‌کند و حداکثر [maxDrafts] مورد نگه می‌دارد.
Future<void> addDraft(StorageService storage, Map<String, dynamic> draft) async {
  final list = List<Map<String, dynamic>>.from(storage.getHistory());
  list.insert(0, draft);
  if (list.length > maxDrafts) list.removeRange(maxDrafts, list.length);
  await storage.saveHistory(list);
}

/// آخرین پیش‌نویس خودکار ذخیره‌شده (اگر وجود داشته باشد).
Map<String, dynamic>? findAutoSavedDraft(StorageService storage) {
  for (final item in storage.getHistory()) {
    if (item['_autoSaved'] == true) return item;
  }
  return null;
}

/// پیش‌نویس خودکار را نگه می‌دارد و با تغییرات بعدی همان مورد را آپدیت می‌کند.
Future<void> upsertAutoDraft(StorageService storage, Map<String, dynamic> draft) async {
  final list = List<Map<String, dynamic>>.from(storage.getHistory());
  list.removeWhere((item) => item['_autoSaved'] == true);
  list.insert(0, {
    ...draft,
    '_autoSaved': true,
    'updatedAt': DateTime.now().toIso8601String(),
  });
  if (list.length > maxDrafts) list.removeRange(maxDrafts, list.length);
  await storage.saveHistory(list);
}

/// یک پیش‌نویس = یک وضعیت کانواس قابل ذخیره و بازیابی
Map<String, dynamic> canvasToDraftMap(CanvasState s) {
  return {
    'text': s.text,
    'fontFamily': s.fontFamily,
    'fontSize': s.fontSize,
    'letterSpacing': s.letterSpacing,
    'wordSpacing': s.wordSpacing,
    'lineHeight': s.lineHeight,
    'opacity': s.opacity,
    'fontWeight': s.fontWeight.index,
    'textAlign': s.textAlign.index,
    'textColor': s.textColor.toARGB32(),
    'backgroundColor': s.backgroundColor.toARGB32(),
    'backgroundGradient': s.backgroundGradient?.map((c) => c.toARGB32()).toList(),
    'backgroundGradientStops': s.backgroundGradientStops,
    'strokeColor': s.strokeColor?.toARGB32(),
    'strokeWidth': s.strokeWidth,
    'shadowColor': s.shadowColor?.toARGB32(),
    'shadowOffsetX': s.shadowOffset.dx,
    'shadowOffsetY': s.shadowOffset.dy,
    'shadowBlur': s.shadowBlur,
    'hasBubble': s.hasBubble,
    'bubbleColor': s.bubbleColor?.toARGB32(),
    'bubbleGradient': s.bubbleGradient?.map((c) => c.toARGB32()).toList(),
    'gradientColors': s.gradientColors?.map((c) => c.toARGB32()).toList(),
    'activePresetId': s.activePreset?.id,
    'stickers': s.stickers.map((p) => {
      'assetPath': p.sticker.assetPath,
      'dx': p.position.dx,
      'dy': p.position.dy,
      'scale': p.scale,
      'rotation': p.rotation,
    }).toList(),
  };
}

CanvasState draftMapToCanvasState(Map<String, dynamic> map) {
  final stickers = <PlacedSticker>[];
  final list = map['stickers'];
  if (list is List) {
    for (final e in list) {
      if (e is! Map<String, dynamic>) continue;
      final path = e['assetPath'] as String?;
      if (path == null) continue;
      final found = StickerItem.allStickers.where((s) => s.assetPath == path).toList();
      if (found.isNotEmpty) {
        final sticker = found.first;
        stickers.add(PlacedSticker(
          sticker: sticker,
          position: Offset(
            _numToDouble(e['dx']) ?? 0,
            _numToDouble(e['dy']) ?? 0,
          ),
          scale: _numToDouble(e['scale']) ?? 1,
          rotation: _numToDouble(e['rotation']) ?? 0,
        ));
      }
    }
  }

  final fwIndex = map['fontWeight'] as int?;
  final fontWeight = fwIndex != null && fwIndex >= 0 && fwIndex <= FontWeight.values.length - 1
      ? FontWeight.values[fwIndex]
      : FontWeight.normal;

  final taIndex = map['textAlign'] as int?;
  final textAlign = taIndex != null && taIndex >= 0 && taIndex <= TextAlign.values.length - 1
      ? TextAlign.values[taIndex]
      : TextAlign.center;

  List<Color>? gradColors;
  final gc = map['backgroundGradient'];
  if (gc is List) {
    gradColors = gc.map((v) => Color(_numToInt(v) ?? 0)).toList();
  }
  List<double>? gradStops;
  final gs = map['backgroundGradientStops'];
  if (gs is List) {
    gradStops = gs.map((v) => _numToDouble(v) ?? 0.0).toList();
  }

  List<Color>? gradientColorsList;
  final gcl = map['gradientColors'];
  if (gcl is List) {
    gradientColorsList = gcl.map((v) => Color(_numToInt(v) ?? 0)).toList();
  }

  List<Color>? bubbleGradientColors;
  final bgc = map['bubbleGradient'];
  if (bgc is List) {
    bubbleGradientColors = bgc.map((v) => Color(_numToInt(v) ?? 0)).toList();
  }

  TextStylePreset? activePreset;
  final presetId = map['activePresetId'] as String?;
  if (presetId != null) {
    for (final p in TextStylePreset.allPresets) {
      if (p.id == presetId) {
        activePreset = p;
        break;
      }
    }
  }

  return CanvasState(
    text: map['text'] as String? ?? '',
    fontFamily: map['fontFamily'] as String? ?? 'Vazir',
    fontSize: _numToDouble(map['fontSize']) ?? 28,
    letterSpacing: _numToDouble(map['letterSpacing']) ?? 0,
    wordSpacing: _numToDouble(map['wordSpacing']) ?? 0,
    lineHeight: _numToDouble(map['lineHeight']) ?? 1.5,
    opacity: _numToDouble(map['opacity']) ?? 1,
    fontWeight: fontWeight,
    textAlign: textAlign,
    textColor: Color(_numToInt(map['textColor']) ?? 0xFFFFFFFF),
    backgroundColor: Color(_numToInt(map['backgroundColor']) ?? 0xFF324F9D),
    backgroundGradient: gradColors,
    backgroundGradientStops: gradStops,
    activePreset: activePreset,
    stickers: stickers,
    strokeColor: map['strokeColor'] != null ? Color(_numToInt(map['strokeColor'])!) : null,
    strokeWidth: _numToDouble(map['strokeWidth']) ?? 0,
    shadowColor: map['shadowColor'] != null ? Color(_numToInt(map['shadowColor'])!) : null,
    shadowOffset: Offset(
      _numToDouble(map['shadowOffsetX']) ?? 0,
      _numToDouble(map['shadowOffsetY']) ?? 0,
    ),
    shadowBlur: _numToDouble(map['shadowBlur']) ?? 0,
    hasBubble: map['hasBubble'] as bool? ?? false,
    bubbleColor: map['bubbleColor'] != null ? Color(_numToInt(map['bubbleColor'])!) : null,
    bubbleGradient: bubbleGradientColors,
    gradientColors: gradientColorsList,
  );
}
