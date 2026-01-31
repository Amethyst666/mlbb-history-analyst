import 'dart:io';
import 'dart:ui';
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

class OcrParser {
  static final textRecognizer = TextRecognizer();

  static Future<OcrResult?> parseWithCropping(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final rawImage = img.decodeImage(bytes);
    if (rawImage == null) return null;
    final image = img.bakeOrientation(rawImage);

    final w = image.width;
    final h = image.height;
    final prefs = await SharedPreferences.getInstance();

    Map<int, Rect> calib = {};
    for (int i = 1; i <= 27; i++) {
      double? l = prefs.getDouble('calib_${i}_l');
      double? t = prefs.getDouble('calib_${i}_t');
      double? r = prefs.getDouble('calib_${i}_r');
      double? b = prefs.getDouble('calib_${i}_b');
      if (l != null) calib[i] = Rect.fromLTRB(l, t!, r!, b!);
    }

    if (calib.isEmpty) return null;

    Rect getRelRect(Rect parent, Rect rel) {
      double l = (parent.left + (rel.left * parent.width)) * w;
      double t = (parent.top + (rel.top * parent.height)) * h;
      double width = (rel.width * parent.width) * w;
      double height = (rel.height * parent.height) * h;
      return Rect.fromLTWH(l, t, width, height);
    }

    // 1. Общие данные
    Rect resR = calib[1]!;
    String gameResult = await _readZone(await _processZone(image, Rect.fromLTWH(resR.left * w, resR.top * h, resR.width * w, resR.height * h)));
    
    List<PlayerDetection> playersList = [];

    // 2. Парсинг игроков
    for (int team = 0; team < 2; team++) {
      int teamStep = team == 0 ? 2 : 3;
      Rect teamZone = calib[teamStep]!;
      double rowH = teamZone.height / 5;
      int baseS = team == 0 ? 4 : 16;
      int itemStartS = team == 0 ? 9 : 21;

      for (int i = 0; i < 5; i++) {
        double rowT = teamZone.top + (i * rowH);
        Rect rowR = Rect.fromLTWH(teamZone.left, rowT, teamZone.width, rowH);

        // NICKNAME
        String nick = _cleanNickname(await _readZone(await _processZone(image, getRelRect(rowR, calib[baseS + 1]!))));

        // KDA SPLIT
        Rect kdaR = getRelRect(rowR, calib[baseS + 2]!);
        double sw = kdaR.width / 3;
        String k = _cleanDigits(await _readZone(await _processZone(image, Rect.fromLTWH(kdaR.left, kdaR.top, sw, kdaR.height), isDigit: true)));
        String d = _cleanDigits(await _readZone(await _processZone(image, Rect.fromLTWH(kdaR.left + sw, kdaR.top, sw, kdaR.height), isDigit: true)));
        String a = _cleanDigits(await _readZone(await _processZone(image, Rect.fromLTWH(kdaR.left + sw * 2, kdaR.top, sw, kdaR.height), isDigit: true)));
        
        // GOLD & SCORE
        String gold = _cleanDigits(await _readZone(await _processZone(image, getRelRect(rowR, calib[baseS + 3]!), isDigit: true)));
        String score = _cleanScore(await _readZone(await _processZone(image, getRelRect(rowR, calib[baseS + 4]!), isDigit: true)));

        playersList.add(PlayerDetection(
          stats: PlayerStats(
            nickname: nick.isEmpty ? "Unknown" : nick, hero: 'unknown',
            kda: "${k.isEmpty ? '0' : k}/${d.isEmpty ? '0' : d}/${a.isEmpty ? '0' : a}",
            gold: gold.isEmpty ? "0" : gold, items: '', score: score.isEmpty ? "0.0" : score,
            isEnemy: team == 1, isUser: false,
          ),
          heroRect: getRelRect(rowR, calib[baseS]!),
          itemRects: List.generate(7, (j) => getRelRect(rowR, calib[itemStartS + j]!)),
        ));
      }
    }

    return OcrResult(result: gameResult.toUpperCase().contains('VIC') ? 'VICTORY' : 'DEFEAT', duration: "15:00", players: playersList);
  }

  static Future<File> _processZone(img.Image source, Rect rect, {bool isDigit = false}) async {
    int x = rect.left.toInt().clamp(0, source.width - 1);
    int y = rect.top.toInt().clamp(0, source.height - 1);
    int width = rect.width.toInt().clamp(1, source.width - x);
    int height = rect.height.toInt().clamp(1, source.height - y);

    var cropped = img.copyCrop(source, x: x, y: y, width: width, height: height);
    
    // 1. Увеличение 3x
    var processed = img.copyResize(cropped, width: cropped.width * 3, interpolation: img.Interpolation.cubic);
    
    // 2. ИНВЕРСИЯ: Делаем ЧЕРНЫЙ текст на БЕЛОМ фоне (самый читаемый формат для ML Kit)
    processed = img.grayscale(processed);
    processed = img.invert(processed); // Теперь цифры черные, фон белый
    processed = img.adjustColor(processed, contrast: 1.5, brightness: 1.2);

    // 3. ДОБАВЛЕНИЕ ПОЛЕЙ (Padding) - чтобы OCR не терял края
    int pad = 20;
    var padded = img.Image(width: processed.width + pad * 2, height: processed.height + pad * 2);
    img.fill(padded, color: img.ColorRgb8(255, 255, 255)); // Белый фон
    img.compositeImage(padded, processed, dstX: pad, dstY: pad);

    final file = File('${Directory.systemTemp.path}/ocr_${DateTime.now().microsecondsSinceEpoch}.png');
    await file.writeAsBytes(img.encodePng(padded));
    return file;
  }

  static Future<String> _readZone(File file) async {
    final inputImage = InputImage.fromFile(file);
    final recognizedText = await textRecognizer.processImage(inputImage);
    return recognizedText.text.trim();
  }

  static String _cleanNickname(String raw) => raw.replaceAll(RegExp(r'(MVP|SVP|Lv\.\d+|Level \d+)', caseSensitive: false), '').trim();

  static String _cleanDigits(String raw) {
    String clean = raw.toUpperCase().replaceAll('O', '0').replaceAll('D', '0').replaceAll('I', '1').replaceAll('L', '1');
    return clean.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static String _cleanScore(String raw) {
    String clean = raw.toUpperCase().replaceAll('O', '0').replaceAll(',', '.');
    return clean.replaceAll(RegExp(r'[^0-9.]'), '');
  }
}