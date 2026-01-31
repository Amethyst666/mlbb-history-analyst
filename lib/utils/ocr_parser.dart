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

    // Загружаем всю калибровку
    Map<int, Rect> calib = {};
    for (int i = 1; i <= 27; i++) {
      double? l = prefs.getDouble('calib_${i}_l');
      double? t = prefs.getDouble('calib_${i}_t');
      double? r = prefs.getDouble('calib_${i}_r');
      double? b = prefs.getDouble('calib_${i}_b');
      if (l != null) calib[i] = Rect.fromLTRB(l, t!, r!, b!);
    }

    if (calib.isEmpty) return null; // Не откалибровано

    Rect getAbsRect(int step) {
      Rect r = calib[step] ?? const Rect.fromLTWH(0.45, 0.45, 0.1, 0.1);
      return Rect.fromLTWH(r.left * w, r.top * h, r.width * w, r.height * h);
    }

    // Результирующий Rect относительно строки игрока
    Rect getRelRect(Rect parent, Rect rel) {
      double l = parent.left + (rel.left * parent.width);
      double t = parent.top + (rel.top * parent.height);
      double width = rel.width * parent.width;
      double height = rel.height * parent.height;
      return Rect.fromLTWH(l * w, t * h, width * w, height * h);
    }

    // 1. Общие данные
    final resultRect = getAbsRect(1);
    String gameResult = await _readZone(await _processZone(image, resultRect));
    
    // Duration обычно под результатом, попробуем взять чуть ниже
    final durationRect = Rect.fromLTWH(resultRect.left, resultRect.bottom, resultRect.width, resultRect.height * 0.7);
    String duration = await _readZone(await _processZone(image, durationRect));

    List<PlayerDetection> playersList = [];

    // 2. Парсинг команд
    for (int team = 0; team < 2; team++) {
      int teamStep = team == 0 ? 2 : 3;
      Rect teamZone = calib[teamStep] ?? const Rect.fromLTWH(0, 0, 1, 1);
      double rowH = teamZone.height / 5;

      // Смещения шагов для команды
      int baseS = team == 0 ? 4 : 16;
      int itemStartS = team == 0 ? 9 : 21;

      for (int i = 0; i < 5; i++) {
        double rowT = teamZone.top + (i * rowH);
        Rect rowR = Rect.fromLTWH(teamZone.left, rowT, teamZone.width, rowH);

        // Текстовые поля
        String nick = _cleanNickname(await _readZone(await _processZone(image, getRelRect(rowR, calib[baseS + 1]!))));
        String kda = _formatKda(await _readZone(await _processZone(image, getRelRect(rowR, calib[baseS + 2]!))));
        String gold = _cleanDigits(await _readZone(await _processZone(image, getRelRect(rowR, calib[baseS + 3]!))));
        String score = _cleanScore(await _readZone(await _processZone(image, getRelRect(rowR, calib[baseS + 4]!))));

        // Иконка героя
        Rect heroRect = getRelRect(rowR, calib[baseS]!);

        // Предметы
        List<Rect> itemRects = [];
        for (int j = 0; j < 7; j++) {
          itemRects.add(getRelRect(rowR, calib[itemStartS + j]!));
        }

        playersList.add(PlayerDetection(
          stats: PlayerStats(
            nickname: nick.isEmpty ? "Unknown" : nick,
            hero: 'unknown',
            kda: kda.isEmpty ? "0/0/0" : kda,
            gold: gold.isEmpty ? "0" : gold,
            items: '',
            score: score.isEmpty ? "0.0" : score,
            isEnemy: team == 1,
            isUser: false,
          ),
          heroRect: heroRect,
          itemRects: itemRects,
        ));
      }
    }

    return OcrResult(
      result: gameResult.toUpperCase().contains('VIC') ? 'VICTORY' : 'DEFEAT',
      duration: _cleanDuration(duration),
      players: playersList,
    );
  }

  static Future<File> _processZone(img.Image source, Rect rect) async {
    int x = rect.left.toInt().clamp(0, source.width - 1);
    int y = rect.top.toInt().clamp(0, source.height - 1);
    int width = rect.width.toInt().clamp(1, source.width - x);
    int height = rect.height.toInt().clamp(1, source.height - y);

    var cropped = img.copyCrop(source, x: x, y: y, width: width, height: height);
    var upscaled = img.copyResize(cropped, width: cropped.width * 3, interpolation: img.Interpolation.cubic);
    
    final file = File('${Directory.systemTemp.path}/ocr_${DateTime.now().microsecondsSinceEpoch}.png');
    await file.writeAsBytes(img.encodePng(upscaled));
    return file;
  }

  static Future<String> _readZone(File file) async {
    final inputImage = InputImage.fromFile(file);
    final recognizedText = await textRecognizer.processImage(inputImage);
    return recognizedText.text.trim();
  }

  static String _cleanNickname(String raw) {
    return raw.replaceAll(RegExp(r'(MVP|SVP|Lv\.\d+|Level \d+)', caseSensitive: false), '').trim();
  }

  static String _cleanDigits(String raw) {
    String clean = raw.toUpperCase().replaceAll('O', '0').replaceAll('D', '0').replaceAll('I', '1').replaceAll('L', '1');
    return clean.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static String _cleanScore(String raw) {
    String clean = raw.toUpperCase().replaceAll('O', '0').replaceAll(',', '.');
    return clean.replaceAll(RegExp(r'[^0-9.]'), '');
  }

  static String _formatKda(String raw) {
    String clean = raw.toUpperCase().replaceAll('O', '0');
    // Оставляем только цифры и слэши
    return clean.replaceAll(RegExp(r'[^0-9/]'), '');
  }

  static String _cleanDuration(String raw) {
    String clean = raw.toUpperCase().replaceAll('O', '0').replaceAll('.', ':');
    return clean.replaceAll(RegExp(r'[^0-9:]'), '');
  }
}