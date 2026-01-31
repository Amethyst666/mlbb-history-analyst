import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'dart:math';

class ImageIdentifier {
  static final Map<String, List<double>> _assetCache = {};

  static Future<void> preloadAssets(List<String> ids, String folder) async {
    for (var id in ids) {
      String key = '$folder/$id';
      if (_assetCache.containsKey(key)) continue;
      try {
        final data = await rootBundle.load('assets/$folder/$id.png');
        final assetImg = img.decodeImage(data.buffer.asUint8List());
        if (assetImg != null) {
          _assetCache[key] = _extractGridFeatures(assetImg);
        }
      } catch (_) {}
    }
  }

  static List<double> _extractGridFeatures(img.Image image) {
    int inset = (image.width * 0.1).toInt();
    img.Image cropped = img.copyCrop(image, x: inset, y: inset, width: image.width - inset * 2, height: image.height - inset * 2);
    
    int gridSize = 4; // Set to 4x4 as the sweet spot
    int cellW = (cropped.width / gridSize).floor();
    int cellH = (cropped.height / gridSize).floor();
    List<double> features = [];
    
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        double r = 0, g = 0, b = 0;
        int count = 0;
        for (int y = row * cellH; y < (row + 1) * cellH; y++) {
          for (int x = col * cellW; x < (col + 1) * cellW; x++) {
            final p = cropped.getPixel(x, y);
            r += p.r; g += p.g; b += p.b;
            count++;
          }
        }
        if (count > 0) features.addAll([r / count, g / count, b / count]);
        else features.addAll([0, 0, 0]);
      }
    }
    return features;
  }

  static bool isEmptySlot(img.Image crop) {
    double totalEdgeEnergy = 0;
    double maxVal = 0;
    double minVal = 255;
    double totalLum = 0;

    for (int y = 1; y < crop.height - 1; y++) {
      for (int x = 1; x < crop.width - 1; x++) {
        double current = crop.getPixel(x, y).luminance.toDouble();
        totalLum += current;
        if (current > maxVal) maxVal = current;
        if (current < minVal) minVal = current;
        double diff = (current - crop.getPixel(x + 1, y).luminance.toDouble()).abs() +
                     (current - crop.getPixel(x, y + 1).luminance.toDouble()).abs();
        totalEdgeEnergy += diff;
      }
    }

    int count = (crop.width - 2) * (crop.height - 2);
    double avgEdgeEnergy = totalEdgeEnergy / count;
    double range = maxVal - minVal;

    // САМЫЕ МЯГКИЕ ПОРОГИ ДЛЯ РАБОТОСПОСОБНОСТИ
    if (avgEdgeEnergy < 5.0) return true;
    if (range < 30.0) return true;

    return false;
  }

  static img.Image? cropRect(img.Image screenshot, Rect zone) {
    try {
      if (zone.width < 5 || zone.height < 5) return null;
      return img.copyCrop(screenshot, x: zone.left.toInt(), y: zone.top.toInt(), width: zone.width.toInt(), height: zone.height.toInt());
    } catch (_) { return null; }
  }

  static Future<String> findBestMatch(img.Image target, List<String> ids, String folder) async {
    if (isEmptySlot(target)) return 'unknown';

    List<double> targetF = _extractGridFeatures(target);
    String bestId = 'unknown';
    double minDistance = double.infinity;

    for (var id in ids) {
      final assetF = _assetCache['$folder/$id'];
      if (assetF == null) continue;

      double dist = 0;
      for (int i = 0; i < targetF.length; i++) {
        double weight = (i % 3 == 2) ? 0.4 : 1.0;
        dist += pow(targetF[i] - assetF[i], 2) * weight;
      }
      if (dist < minDistance) {
        minDistance = dist;
        bestId = id;
      }
    }
    
    // Очень высокий порог совпадения (чтобы хоть что-то находил)
    double threshold = (folder == 'heroes') ? 60000 : 45000;
    if (minDistance > threshold) return 'unknown';
    
    return bestId;
  }
}
