import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/io.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Ensure flutter_tts is in pubspec.yaml
import 'main.dart'; 

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  // --- STATE ---
  CameraController? _controller;
  IOWebSocketChannel? _channel;
  int _selectedCameraIndex = 0;
  bool _isProcessing = false;
  DateTime _lastProcessedTime = DateTime.now();
  Timer? _windowsTimer; 

  // --- UI & SPEECH STATE ---
  String _currentLabel = "Waiting for hands...";
  String _lastSpokenLabel = ""; 
  bool _isListening = false;
  bool _isSpeechEnabled = false; // Speaker Toggle
  final FlutterTts _flutterTts = FlutterTts(); 
  final TextEditingController _textController = TextEditingController();

  final String _socketUrl = 'ws://192.168.68.110:8000/ws/predict';
  static const platform = MethodChannel('speech_to_text_windows');

  final LinearGradient _uiGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF52B0B7), Color(0xFF085065)],
  );

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler(_handleMethodCall);
    _initWebSocket();
    _setupInitialCamera();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); 
    await _flutterTts.setVolume(1.0);
  }

  void _speak(String text) async {
    // Only speak if speaker is ON and it's a new word
    if (!_isSpeechEnabled || text == _lastSpokenLabel || text.contains("Waiting")) return;
    
    String wordOnly = text.split(' (')[0]; // Cleans "Hello (90%)" to just "Hello"
    await _flutterTts.speak(wordOnly);
    _lastSpokenLabel = text;
  }

  // --- CAMERA INITIALIZATION ---
  void _setupInitialCamera() {
    if (cameras.isEmpty) return;
    int frontIndex = cameras.indexWhere((cam) => cam.lensDirection == CameraLensDirection.front);
    _selectedCameraIndex = frontIndex != -1 ? frontIndex : 0;
    _initCamera(_selectedCameraIndex);
  }

  Future<void> _initCamera(int index) async {
    _windowsTimer?.cancel(); 
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      await Future.delayed(Duration(milliseconds: Platform.isWindows ? 1200 : 200));
    }

    _controller = CameraController(
      cameras[index],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isWindows ? ImageFormatGroup.unknown : ImageFormatGroup.yuv420,
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});
      Platform.isWindows ? _startWindowsCaptureLoop() : _controller!.startImageStream(_processCameraImageAndroid);
    } catch (e) {
      if (Platform.isWindows && e.toString().contains('camera_error')) {
        Future.delayed(const Duration(seconds: 2), () => _initCamera(index));
      }
    }
  }

  void _startWindowsCaptureLoop() {
    _windowsTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) async {
      if (!mounted || _controller == null || _isProcessing || !_controller!.value.isInitialized) return;
      _isProcessing = true;
      try {
        final XFile file = await _controller!.takePicture();
        final bytes = await file.readAsBytes();
        _channel?.sink.add(base64Encode(bytes));
      } catch (e) { debugPrint("Capture Error: $e"); }
      _isProcessing = false;
    });
  }

  void _processCameraImageAndroid(CameraImage image) async {
    if (_isProcessing || DateTime.now().difference(_lastProcessedTime).inMilliseconds < 150) return;
    _isProcessing = true;
    _lastProcessedTime = DateTime.now();
    try {
      List<int> jpegBytes = await convertYUV420toImageColor(image);
      _channel?.sink.add(base64Encode(jpegBytes));
    } finally { _isProcessing = false; }
  }

  // --- WEBSOCKET & STT ---
  void _initWebSocket() {
    try {
      _channel = IOWebSocketChannel.connect(_socketUrl);
      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        if (mounted) {
          String newLabel = "${data['label']} (${(data['confidence'] * 100).toStringAsFixed(0)}%)";
          setState(() {
            _currentLabel = newLabel;
            _isProcessing = false; 
          });
          _speak(newLabel); // Automatic speech trigger
        }
      });
    } catch (e) { debugPrint("WS Error: $e"); }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != "textRecognition") return;
    final String words = call.arguments['recognizedWords']?.toString() ?? "";
    setState(() { _currentLabel = words; _textController.text = words; });
  }

  @override
  void dispose() {
    _windowsTimer?.cancel();
    _controller?.dispose();
    _channel?.sink.close();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => _uiGradient.createShader(bounds),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => _uiGradient.createShader(bounds),
          child: Text("Sign Interpreter", 
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white)),
        ),
        actions: [
          // SPEAKER TOGGLE BUTTON
          IconButton(
            icon: Icon(
              _isSpeechEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _isSpeechEnabled ? const Color(0xFF52B0B7) : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isSpeechEnabled = !_isSpeechEnabled;
                if (!_isSpeechEnabled) _flutterTts.stop();
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Flex(
        direction: isPortrait ? Axis.vertical : Axis.horizontal,
        children: [
          Flexible(
            flex: isPortrait ? 7 : 1,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24)),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _controller != null && _controller!.value.isInitialized
                      ? Center(child: AspectRatio(
                          aspectRatio: isPortrait ? 1 / _controller!.value.aspectRatio : _controller!.value.aspectRatio,
                          child: CameraPreview(_controller!),
                        ))
                      : const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
          Expanded(
            flex: isPortrait ? 3 : 1,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => _uiGradient.createShader(bounds),
                      child: Text(_currentLabel, 
                        textAlign: TextAlign.center, 
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF52B0B7),
                        child: const Icon(Icons.mic_none, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: "Type or speak...", 
                            filled: true, 
                            fillColor: Colors.grey[100], 
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<int>> convertYUV420toImageColor(CameraImage image) async {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int? uvPixelStride = image.planes[1].bytesPerPixel;
    var imgBuffer = img.Image(width: width, height: height);
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex = (uvPixelStride! * (x / 2).floor()) + (uvRowStride * (y / 2).floor());
        final int index = y * width + x;
        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        imgBuffer.setPixelRgb(x, y, r, g, b);
      }
    }
    return img.encodeJpg(img.copyRotate(imgBuffer, angle: 90), quality: 50);
  }
}