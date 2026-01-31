import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_strings.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  File? _image;
  final picker = ImagePicker();
  int _currentStep = 0;
  static const int totalSteps = 27;

  Map<int, Rect> _zones = {
    1: const Rect.fromLTRB(0.3, 0.05, 0.7, 0.15), 
    2: const Rect.fromLTRB(0.05, 0.2, 0.45, 0.9), 
    3: const Rect.fromLTRB(0.55, 0.2, 0.95, 0.9), 
    // Defaults for details will be filled in load
  };

  Offset? _startPoint;

  @override
  void initState() {
    super.initState();
    _setOrientation();
    _loadExistingCalibration();
  }

  Future<void> _loadExistingCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (int i = 1; i <= totalSteps; i++) {
        double? l = prefs.getDouble('calib_${i}_l');
        double? t = prefs.getDouble('calib_${i}_t');
        double? r = prefs.getDouble('calib_${i}_r');
        double? b = prefs.getDouble('calib_${i}_b');
        if (l != null) _zones[i] = Rect.fromLTRB(l, t!, r!, b!);
        else if (!_zones.containsKey(i)) {
          // Default empty rect if never calibrated
          _zones[i] = const Rect.fromLTRB(0.45, 0.45, 0.55, 0.55);
        }
      }
    });
  }

  Future<void> _setOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _currentStep = 1;
      });
    }
  }

  void _adjust(double dl, double dt, double dr, double db) {
    setState(() {
      Rect c = _zones[_currentStep]!;
      _zones[_currentStep] = Rect.fromLTRB(
        (c.left + dl).clamp(-1.0, 2.0),
        (c.top + dt).clamp(-1.0, 2.0),
        (c.right + dr).clamp(-1.0, 2.0),
        (c.bottom + db).clamp(-1.0, 2.0),
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (_startPoint == null) return;
    double px = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
    double py = (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);
    Rect drawn = Rect.fromPoints(_startPoint!, Offset(px, py));

    setState(() {
      if (_currentStep >= 4) {
        int teamIdx = _currentStep <= 15 ? 2 : 3;
        Rect teamZone = _zones[teamIdx]!;
        double rowH = teamZone.height / 5;
        Rect row1 = Rect.fromLTWH(teamZone.left, teamZone.top, teamZone.width, rowH);
        _zones[_currentStep] = Rect.fromLTRB(
          (drawn.left - row1.left) / (row1.width > 0 ? row1.width : 1.0),
          (drawn.top - row1.top) / (row1.height > 0 ? row1.height : 1.0),
          (drawn.right - row1.left) / (row1.width > 0 ? row1.width : 1.0),
          (drawn.bottom - row1.top) / (row1.height > 0 ? row1.height : 1.0),
        );
      } else {
        _zones[_currentStep] = drawn;
      }
    });
  }

  void _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (var key in _zones.keys) {
      Rect r = _zones[key]!;
      await prefs.setDouble('calib_${key}_l', r.left);
      await prefs.setDouble('calib_${key}_t', r.top);
      await prefs.setDouble('calib_${key}_r', r.right);
      await prefs.setDouble('calib_${key}_b', r.bottom);
    }
    await prefs.setBool('is_calibrated_v2', true);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C2C),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return Stack(
            children: [
              if (_image != null) Positioned.fill(child: Image.file(_image!, fit: BoxFit.fill)),
              if (_image != null && _currentStep > 0)
                IgnorePointer(child: _ActiveZonePainter(currentRect: _zones[_currentStep]!, step: _currentStep, allZones: _zones, constraints: constraints)),
              if (_image != null && _currentStep > 0)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) => _startPoint = Offset(details.localPosition.dx / constraints.maxWidth, details.localPosition.dy / constraints.maxHeight),
                    onPanUpdate: (details) => _onPanUpdate(details, constraints),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              if (_image == null)
                Center(child: ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.photo_library), label: Text(AppStrings.get(context, 'calib_step0')))),
              if (_image != null)
                Positioned(
                  left: 10, right: 10, bottom: 10,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFineTuneControls(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)), child: Text("${_currentStep}/$totalSteps: ${AppStrings.get(context, 'calib_step$_currentStep')}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                          const SizedBox(width: 10),
                          ElevatedButton(onPressed: () => _currentStep < totalSteps ? setState(() => _currentStep++) : _saveAll(), style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black), child: Text(_currentStep < totalSteps ? AppStrings.get(context, 'next') : AppStrings.get(context, 'finish'))),
                        ],
                      ),
                    ],
                  ),
                ),
              if (_image != null)
                Positioned(top: 10, right: 10, child: CircleAvatar(backgroundColor: Colors.black54, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)))),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildFineTuneControls() {
    return Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)), child: Wrap(spacing: 4, children: [
      _tuneBtn("L-", () => _adjust(-0.001, 0, 0, 0)), 
      _tuneBtn("L+", () => _adjust(0.001, 0, 0, 0)), 
      _tuneBtn("T-", () => _adjust(0, -0.0025, 0, 0)), 
      _tuneBtn("T+", () => _adjust(0, 0.0025, 0, 0)), 
      _tuneBtn("R-", () => _adjust(0, 0, -0.001, 0)), 
      _tuneBtn("R+", () => _adjust(0, 0, 0.001, 0)), 
      _tuneBtn("B-", () => _adjust(0, 0, 0, -0.0025)), 
      _tuneBtn("B+", () => _adjust(0, 0, 0, 0.0025))
    ]));
  }

  Widget _tuneBtn(String label, VoidCallback tap) => SizedBox(width: 35, height: 30, child: ElevatedButton(onPressed: tap, style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: Colors.white12), child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white))));
}

class _ActiveZonePainter extends StatelessWidget {
  final Rect currentRect;
  final int step;
  final Map<int, Rect> allZones;
  final BoxConstraints constraints;
  const _ActiveZonePainter({required this.currentRect, required this.step, required this.allZones, required this.constraints});

  @override
  Widget build(BuildContext context) {
    double w = constraints.maxWidth;
    double h = constraints.maxHeight;
    int teamIdx = (step >= 4 && step <= 15) ? 2 : (step >= 16 ? 3 : 0);
    
    Rect drawRect;
    if (teamIdx != 0) {
      Rect teamZone = allZones[teamIdx]!;
      double rowH = teamZone.height / 5;
      drawRect = Rect.fromLTRB(
        teamZone.left + (currentRect.left * teamZone.width),
        teamZone.top + (currentRect.top * rowH),
        teamZone.left + (currentRect.right * teamZone.width),
        teamZone.top + (currentRect.bottom * rowH),
      );
    } else {
      drawRect = currentRect;
    }

    bool isCircle = (step == 4 || step == 16) || (step >= 9 && step <= 15) || (step >= 21);

    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.srcOut),
          child: Stack(children: [
            Container(decoration: const BoxDecoration(color: Colors.black, backgroundBlendMode: BlendMode.dstOut)),
            Positioned(
              left: drawRect.left * w, 
              top: drawRect.top * h, 
              width: (drawRect.width * w).clamp(1.0, w), 
              height: (drawRect.height * h).clamp(1.0, h), 
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: isCircle ? BorderRadius.circular(100) : BorderRadius.circular(2)
                )
              )
            ),
          ]),
        ),
        Positioned(
          left: drawRect.left * w, 
          top: drawRect.top * h, 
          width: (drawRect.width * w).clamp(1.0, w), 
          height: (drawRect.height * h).clamp(1.0, h), 
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.cyanAccent, width: 2),
              borderRadius: isCircle ? BorderRadius.circular(100) : BorderRadius.zero,
            ), 
            child: _buildSubGrid()
          )
        ),
        if (teamIdx != 0) ..._buildFullTeamPreview(w, h, teamIdx, isCircle),
      ],
    );
  }

  Widget _buildSubGrid() {
    if (step == 2 || step == 3) {
      return Column(children: List.generate(5, (i) => Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 0.8))))));
    }
    if (step == 6 || step == 18) {
      return Row(children: List.generate(3, (i) => Expanded(child: Container(decoration: BoxDecoration(border: Border(left: i > 0 ? const BorderSide(color: Colors.yellowAccent, width: 1.5) : BorderSide.none))))));
    }
    return const SizedBox.shrink();
  }

  List<Widget> _buildFullTeamPreview(double w, double h, int teamIdx, bool isCircle) {
    List<Widget> list = [];
    Rect teamZone = allZones[teamIdx]!;
    double rowH = teamZone.height / 5;
    for (int i = 0; i < 5; i++) {
      if (i == 0) continue;
      list.add(Positioned(
        left: (teamZone.left + (currentRect.left * teamZone.width)) * w,
        top: (teamZone.top + (i * rowH) + (currentRect.top * rowH)) * h,
        width: (currentRect.width * teamZone.width) * w,
        height: (currentRect.height * rowH) * h,
        child: Container(decoration: BoxDecoration(
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1),
          borderRadius: isCircle ? BorderRadius.circular(100) : BorderRadius.zero,
        )),
      ));
    }
    return list;
  }
}
