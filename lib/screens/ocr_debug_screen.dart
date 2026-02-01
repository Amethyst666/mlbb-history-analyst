import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OcrDebugScreen extends StatefulWidget {
  const OcrDebugScreen({super.key});

  @override
  State<OcrDebugScreen> createState() => _OcrDebugScreenState();
}

class _OcrDebugScreenState extends State<OcrDebugScreen> {
  File? _image;
  final picker = ImagePicker();
  Map<String, double> _calib = {};
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCalib();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _loadCalib() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, double> data = {};
    for (int i = 1; i <= 28; i++) {
      data['calib_${i}_l'] = prefs.getDouble('calib_${i}_l') ?? 0.0;
      data['calib_${i}_t'] = prefs.getDouble('calib_${i}_t') ?? 0.0;
      data['calib_${i}_r'] = prefs.getDouble('calib_${i}_r') ?? 0.0;
      data['calib_${i}_b'] = prefs.getDouble('calib_${i}_b') ?? 0.0;
    }
    setState(() {
      _calib = data;
      _isLoaded = true;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_image != null) Positioned.fill(child: Image.file(_image!, fit: BoxFit.fill))
          else Center(child: ElevatedButton(onPressed: _pickImage, child: const Text("Выбрать скриншот"))),

          if (_image != null && _isLoaded) Positioned.fill(child: IgnorePointer(child: _DebugOverlay(calib: _calib))),

          Positioned(
            top: 10, left: 10,
            child: CircleAvatar(backgroundColor: Colors.black54, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context))),
          ),
        ],
      ),
    );
  }
}

class _DebugOverlay extends StatelessWidget {
  final Map<String, double> calib;
  const _DebugOverlay({required this.calib});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double w = constraints.maxWidth;
      double h = constraints.maxHeight;
      List<Widget> overlays = [];

      overlays.add(_box(1, w, h, Colors.white));
      overlays.add(_box(28, w, h, Colors.yellowAccent)); // Duration

      // Левая команда
      overlays.addAll(_team(2, [4, 5, 6, 7, 8], [9, 10, 11, 12, 13, 14, 15], w, h));
      // Правая команда
      overlays.addAll(_team(3, [16, 17, 18, 19, 20], [21, 22, 23, 24, 25, 26, 27], w, h));

      return Stack(children: overlays);
    });
  }

  List<Widget> _team(int teamS, List<int> textS, List<int> itemS, double w, double h) {
    List<Widget> list = [];
    Rect teamRect = _getRect(teamS);
    if (teamRect.width <= 0) return [];
    double rowH = teamRect.height / 5;

    for (int i = 0; i < 5; i++) {
      double rowT = teamRect.top + (i * rowH);
      Rect rowR = Rect.fromLTWH(teamRect.left, rowT, teamRect.width, rowH);

      list.add(_relBox(rowR, _getRect(textS[0]), w, h, Colors.cyanAccent, isCircle: true)); // Hero
      list.add(_relBox(rowR, _getRect(textS[1]), w, h, Colors.greenAccent)); // Nick
      list.add(_relBox(rowR, _getRect(textS[2]), w, h, Colors.yellowAccent, split: 3)); // KDA
      list.add(_relBox(rowR, _getRect(textS[3]), w, h, Colors.orangeAccent)); // Gold
      list.add(_relBox(rowR, _getRect(textS[4]), w, h, Colors.pinkAccent)); // Score
      
      for (int isIdx in itemS) {
        list.add(_relBox(rowR, _getRect(isIdx), w, h, Colors.blueAccent, isCircle: true)); // Items
      }
    }
    return list;
  }

  Widget _box(int s, double w, double h, Color col) {
    Rect r = _getRect(s);
    return Positioned(left: r.left * w, top: r.top * h, width: r.width * w, height: r.height * h, child: Container(decoration: BoxDecoration(border: Border.all(color: col, width: 1.5))));
  }

  Widget _relBox(Rect parent, Rect rel, double w, double h, Color col, {int split = 1, bool isCircle = false}) {
    double l = parent.left + (rel.left * parent.width);
    double t = parent.top + (rel.top * parent.height);
    double width = rel.width * parent.width;
    double height = rel.height * parent.height;

    return Positioned(
      left: l * w, top: t * h, width: width * w, height: height * h,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: col.withOpacity(0.8), width: 1.0),
          borderRadius: isCircle ? BorderRadius.circular(100) : BorderRadius.zero,
        ),
        child: split > 1 ? Row(
          children: List.generate(split, (i) => Expanded(
            child: Container(decoration: BoxDecoration(border: Border(left: i > 0 ? BorderSide(color: col, width: 1.0) : BorderSide.none))),
          )),
        ) : null,
      ),
    );
  }

  Rect _getRect(int s) => Rect.fromLTRB(calib['calib_${s}_l'] ?? 0, calib['calib_${s}_t'] ?? 0, calib['calib_${s}_r'] ?? 0, calib['calib_${s}_b'] ?? 0);
}