import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_stats.dart';

class OcrResult {
  final String result;
  final String duration;
  final List<PlayerDetection> players;
  OcrResult({required this.result, required this.duration, required this.players});
}

class PlayerDetection {
  final PlayerStats stats;
  final Rect heroRect;
  final List<Rect> itemRects;
  PlayerDetection({required this.stats, required this.heroRect, required this.itemRects});
}

Future<List<int>> _prepareImageInIsolate(List<int> bytes) async {
  final rawImage = img.decodeImage(Uint8List.fromList(bytes));
  if (rawImage == null) return [];
  final image = img.bakeOrientation(rawImage);
  var processed = img.copyResize(image, width: image.width * 2, interpolation: img.Interpolation.linear);
  processed = img.invert(img.grayscale(processed));
  return img.encodePng(processed);
}

class OcrParser {
  static final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  static Future<OcrResult?> parseWithCropping(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final processedBytes = await compute(_prepareImageInIsolate, bytes);
    if (processedBytes.isEmpty) return null;

    final tempFile = File('${Directory.systemTemp.path}/full_ocr.png');
    await tempFile.writeAsBytes(processedBytes);
    
    final info = img.decodeImage(bytes); 
    if (info == null) return null;
    final w = info.width;
    final h = info.height;

    final prefs = await SharedPreferences.getInstance();
    Map<int, Rect> calib = {};
    for (int i = 1; i <= 28; i++) {
      double? l = prefs.getDouble('calib_${i}_l');
      double? t = prefs.getDouble('calib_${i}_t');
      double? r = prefs.getDouble('calib_${i}_r');
      double? b = prefs.getDouble('calib_${i}_b');
      if (l != null) calib[i] = Rect.fromLTRB(l, t!, r!, b!);
    }
    if (calib.isEmpty) return null;

    final recognizedText = await textRecognizer.processImage(InputImage.fromFile(tempFile));
    
    List<RecognizedTextElement> allElements = [];
    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        for (var el in line.elements) {
          allElements.add(RecognizedTextElement(
            text: el.text,
            relL: el.boundingBox.left / (w * 2),
            relT: el.boundingBox.top / (h * 2),
            relW: el.boundingBox.width / (w * 2),
            relH: el.boundingBox.height / (h * 2),
          ));
        }
      }
    }

    String gameResult = _cleanResult(_findTextInZone(allElements, calib[1]!));
    String duration = _cleanDuration(_findTextInZone(allElements, calib[28]!));
    if (duration.isEmpty) duration = "00:00";

    List<PlayerDetection> playersList = [];

    for (int team = 0; team < 2; team++) {
      int baseS = team == 0 ? 4 : 16;
      Rect teamZone = calib[team == 0 ? 2 : 3]!;
      double rowH = teamZone.height / 5;

      for (int i = 0; i < 5; i++) {
        double rowT = teamZone.top + (i * rowH);
        Rect rowR = Rect.fromLTWH(teamZone.left, rowT, teamZone.width, rowH);
        
        Map<String, Rect> rowTargets = {
          'nick': _getAbsTarget(rowR, calib[baseS + 1]!),
          'k': _getAbsTarget(rowR, _getKdaSubZone(calib[baseS + 2]!, 0)),
          'd': _getAbsTarget(rowR, _getKdaSubZone(calib[baseS + 2]!, 1)),
          'a': _getAbsTarget(rowR, _getKdaSubZone(calib[baseS + 2]!, 2)),
          'gold': _getAbsTarget(rowR, calib[baseS + 3]!),
          'score': _getAbsTarget(rowR, calib[baseS + 4]!),
        };

        Map<String, List<String>> bucket = {'nick':[], 'k':[], 'd':[], 'a':[], 'gold':[], 'score':[]};
        var rowElements = allElements.where((e) => e.relY >= rowR.top && e.relY <= rowR.bottom);

        for (var el in rowElements) {
          // ЕСЛИ БЛОК ПЕРЕСЕКАЕТ НЕСКОЛЬКО ЗОН ИЛИ СОДЕРЖИТ ЦИФРЫ - РАСЩЕПЛЯЕМ ЕГО
          bool spansMultiple = false;
          int zonesHit = 0;
          rowTargets.values.forEach((z) { if (Rect.fromLTWH(el.relL, el.relT, el.relW, el.relH).overlaps(z)) zonesHit++; });
          if (zonesHit > 1 || RegExp(r'[0-9]').hasMatch(el.text)) spansMultiple = true;

          if (spansMultiple && el.text.length > 1) {
            double charW = el.relW / el.text.length;
            for (int cIdx = 0; cIdx < el.text.length; cIdx++) {
              double cx = el.relL + (cIdx + 0.5) * charW;
              _distribute(el.text[cIdx], cx, el.relY, rowTargets, bucket);
            }
          } else {
            _distribute(el.text, el.relX, el.relY, rowTargets, bucket);
          }
        }

        playersList.add(PlayerDetection(
          stats: PlayerStats(
            nickname: _cleanNickname(bucket['nick']!.join(" ")),
            hero: 'unknown',
            kda: "${_cleanDigits(bucket['k']!.join(""))}/${_cleanDigits(bucket['d']!.join(""))}/${_cleanDigits(bucket['a']!.join(""))}",
            gold: _cleanDigits(bucket['gold']!.join("")),
            items: '',
            score: _cleanScore(bucket['score']!.join("")),
            isEnemy: team == 1,
            isUser: false,
          ),
          heroRect: _getGlobalRect(rowR, calib[baseS]!, w, h),
          itemRects: List.generate(7, (j) => _getGlobalRect(rowR, calib[team == 0 ? 9 + j : 21 + j]!, w, h)),
        ));
      }
    }
    return OcrResult(result: gameResult.contains('VIC') ? 'VICTORY' : 'DEFEAT', duration: duration, players: playersList);
  }

  static void _distribute(String text, double x, double y, Map<String, Rect> targets, Map<String, List<String>> bucket) {
    Offset point = Offset(x, y);
    String? bestKey;
    double minD = 999;
    targets.forEach((key, zone) {
      if (zone.contains(point)) {
        double d = (x - zone.center.dx).abs();
        if (d < minD) { minD = d; bestKey = key; }
      }
    });
    if (bestKey != null) bucket[bestKey!]!.add(text);
  }

  static String _findTextInZone(List<RecognizedTextElement> elements, Rect zone) {
    var matches = elements.where((e) => zone.contains(Offset(e.relX, e.relY))).toList();
    matches.sort((a, b) => a.relX.compareTo(b.relX));
    return matches.map((e) => e.text).join(" ");
  }

  static Rect _getAbsTarget(Rect row, Rect rel) => Rect.fromLTWH(row.left + rel.left * row.width, row.top + rel.top * row.height, rel.width * row.width, rel.height * row.height);
  static Rect _getKdaSubZone(Rect kda, int p) => Rect.fromLTWH(kda.left + (kda.width / 3) * p, kda.top, kda.width / 3, kda.height);
  static Rect _getGlobalRect(Rect row, Rect rel, int w, int h) => Rect.fromLTWH((row.left + rel.left * row.width) * w, (row.top + rel.top * row.height) * h, rel.width * row.width * w, rel.height * row.height * h);
  
  static String _cleanResult(String r) => r.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
  static String _cleanNickname(String r) => r.replaceAll(RegExp(r'(MVP|SVP|Lv\.\d+|Level \d+)', caseSensitive: false), '').trim();
  static String _cleanDigits(String r) => r.toUpperCase().replaceAll('O', '0').replaceAll('D', '0').replaceAll('I', '1').replaceAll(RegExp(r'[^0-9]'), '');
  static String _cleanScore(String r) => r.toUpperCase().replaceAll('O', '0').replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
  static String _cleanDuration(String r) => r.toUpperCase().replaceAll('O', '0').replaceAll('.', ':').replaceAll(RegExp(r'[^0-9:]'), '').trim();
}

class RecognizedTextElement {
  final String text;
  final double relL, relT, relW, relH;
  RecognizedTextElement({required this.text, required this.relL, required this.relT, required this.relW, required this.relH});
  double get relX => relL + relW / 2;
  double get relY => relT + relH / 2;
}