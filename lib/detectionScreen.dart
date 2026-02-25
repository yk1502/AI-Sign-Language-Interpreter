import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/io.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class DetectionScreen extends StatefulWidget {
  final bool isBlindMode; 
  final List<CameraDescription> availableCameras; 

  const DetectionScreen({
    super.key, 
    this.isBlindMode = false,
    required this.availableCameras, 
  });

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  CameraController? _controller;
  IOWebSocketChannel? _channel;
  int _selectedCameraIndex = 0;
  bool _isProcessing = false;
  DateTime _lastProcessedTime = DateTime.now();
  Timer? _windowsTimer; 

  String _currentLabel = "Waiting for hands..."; 
  String _lastSpokenLabel = ""; 
  String _remoteMessage = ""; 
  late bool _isSpeechEnabled; 
  bool _isListening = false; 
  
  final FlutterTts _flutterTts = FlutterTts(); 
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _textController = TextEditingController();

  final LinearGradient _interpreterGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF52B0B7), Color(0xFF085065)],
  );

  final LinearGradient _remoteGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], 
  );

  @override
  void initState() {
    super.initState();
    _isSpeechEnabled = true; 
    _initTts();
    _initWebSocket();
    _initSpeech();
    _setupInitialCamera();

    // THIS ENSURES IT READS EVERY TIME THE PAGE IS SHOWN
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isBlindMode) {
        _announceBlindMode();
      }
    });
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _announceBlindMode() async {
    // Small delay to let the screen transition finish
    await Future.delayed(const Duration(milliseconds: 500));
    // Use a direct call to speak to bypass the label filters
    await _flutterTts.stop(); 
    await _flutterTts.speak("Blind mode active. Hold the screen to speak.");
  }

  void _speak(String text) async {
    if (!_isSpeechEnabled || text.contains("Waiting")) return;
    
    String wordOnly = text.split(' (')[0];
    
    // Status alerts (Mic/Mode) should ALWAYS be spoken
    bool isStatusAlert = text.contains("Microphone") || text.contains("Blind mode");
    
    if (wordOnly == _lastSpokenLabel && !isStatusAlert) return;

    // If it's a priority alert, stop the current label speech
    if (isStatusAlert) await _flutterTts.stop();

    await _flutterTts.speak(wordOnly);
    _lastSpokenLabel = wordOnly;
  }

  void _listen() async {
    bool available = await _speech.initialize();
    if (available) {
      HapticFeedback.heavyImpact();
      if (widget.isBlindMode) {
        await _flutterTts.stop();
        await _flutterTts.speak("Microphone on"); 
      }
      
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) {
        setState(() {
          _textController.text = val.recognizedWords;
        });
      });
    }
  }

  void _stopListening() async {
    if (_isListening) {
      HapticFeedback.mediumImpact();
      setState(() => _isListening = false);
      await _speech.stop();
      
      if (widget.isBlindMode) {
        await _flutterTts.stop(); // Force stop any other speech
        await _flutterTts.speak("Microphone off");
        
        if (_textController.text.isNotEmpty) {
          _sendReply();
        }
      }
    }
  }

  // --- REPLACING REMAINING METHODS (WEBSOCKET, CAMERA, ETC) ---

  void _initSpeech() async => await _speech.initialize();

  void _initWebSocket() {
    try {
      _channel = IOWebSocketChannel.connect('ws://192.168.68.110:8000/ws/predict');
      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        if (mounted) {
          setState(() {
            if (data['type'] == 'remote') {
              _remoteMessage = data['message'];
              _speak("New message: $_remoteMessage");
            } else {
              _currentLabel = "${data['label']} (${(data['confidence'] * 100).toStringAsFixed(0)}%)";
              _isProcessing = false;
              if (data['confidence'] > 0.8) {
                _speak(data['label']);
              }
            }
          });
        }
      });
    } catch (e) { debugPrint("WS Error: $e"); }
  }

  void _sendReply() {
    if (_textController.text.isNotEmpty) {
      final reply = jsonEncode({"type": "remote", "message": _textController.text});
      _channel?.sink.add(reply);
      setState(() {
        _remoteMessage = _textController.text;
        _textController.clear();
      });
    }
  }

  void _setupInitialCamera() {
    if (widget.availableCameras.isEmpty) return;
    int frontIndex = widget.availableCameras.indexWhere((cam) => cam.lensDirection == CameraLensDirection.front);
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
      widget.availableCameras[index], 
      ResolutionPreset.medium, 
      enableAudio: false,
      imageFormatGroup: Platform.isWindows ? ImageFormatGroup.unknown : ImageFormatGroup.yuv420
    );
    try {
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});
      Platform.isWindows ? _startWindowsCaptureLoop() : _controller!.startImageStream(_processCameraImageAndroid);
    } catch (e) { debugPrint("Camera Err: $e"); }
  }

  void _startWindowsCaptureLoop() {
    _windowsTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) async {
      if (!mounted || _controller == null || _isProcessing || !_controller!.value.isInitialized) return;
      _isProcessing = true;
      try {
        final XFile file = await _controller!.takePicture();
        _channel?.sink.add(base64Encode(await file.readAsBytes()));
      } catch (e) { }
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

  @override
  void dispose() {
    _windowsTimer?.cancel();
    _controller?.dispose();
    _channel?.sink.close();
    _flutterTts.stop();
    _speech.stop();
    _textController.dispose();
    super.dispose();
  }

 @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool isPortrait = mediaQuery.orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => _interpreterGradient.createShader(bounds),
          child: Text(
            widget.isBlindMode ? "Blind Mode" : "Sign Language Interpreter",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        actions: [
          if (!widget.isBlindMode)
            IconButton(
              icon: Icon(_isSpeechEnabled ? Icons.volume_up : Icons.volume_off, color: const Color(0xFF52B0B7)),
              onPressed: () => setState(() => _isSpeechEnabled = !_isSpeechEnabled),
            ),
        ],
      ),
      body: GestureDetector(
        onLongPress: widget.isBlindMode ? _listen : null,
        onLongPressUp: widget.isBlindMode ? _stopListening : null,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Flex(
            direction: isPortrait ? Axis.vertical : Axis.horizontal,
            children: [
              // --- CAMERA SECTION (Strict Ratio) ---
              Flexible(
                flex: isPortrait ? 6 : 1,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: widget.isBlindMode 
                        ? Border.all(color: const Color(0xFF52B0B7), width: 4) 
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _controller != null && _controller!.value.isInitialized
                      ? Center(
                          child: AspectRatio(
                            aspectRatio: _controller!.value.aspectRatio,
                            child: CameraPreview(_controller!),
                          ),
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),

              // --- RESULTS & LISTENING SECTION ---
              Expanded(
                flex: isPortrait ? 4 : 1,
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center, // Centers everything in this area
                        children: [
                          // Main text content
                          SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) => _interpreterGradient.createShader(bounds),
                                  child: Text(
                                    _currentLabel,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 28, 
                                      fontWeight: FontWeight.bold, 
                                      color: Colors.white
                                    ),
                                  ),
                                ),
                                if (_remoteMessage.isNotEmpty) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 15), 
                                    child: Divider(indent: 50, endIndent: 50)
                                  ),
                                  ShaderMask(
                                    blendMode: BlendMode.srcIn,
                                    shaderCallback: (bounds) => _remoteGradient.createShader(bounds),
                                    child: Text(
                                      _remoteMessage,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 22, 
                                        fontWeight: FontWeight.w500, 
                                        color: Colors.white, 
                                        fontStyle: FontStyle.italic
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // LISTENING Indicator - Fixed in the center-right of this section
                          if (widget.isBlindMode && _isListening)
                            Positioned(
                              right: 20,
                              child: RotatedBox(
                                quarterTurns: isPortrait ? 0 : 0, 
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8)
                                  ),
                                  child: const Text(
                                    "LISTENING...", 
                                    style: TextStyle(
                                      color: Colors.red, 
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2
                                    )
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Input Bar (Visible only when NOT in Blind Mode)
                    if (!widget.isBlindMode)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          children: [
                            GestureDetector(
                              onLongPress: _listen,
                              onLongPressUp: _stopListening,
                              child: CircleAvatar(
                                radius: 25,
                                backgroundColor: _isListening ? Colors.red : const Color(0xFF52B0B7),
                                child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                decoration: InputDecoration(
                                  hintText: _isListening ? "Listening..." : "Reply...",
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30), 
                                    borderSide: BorderSide.none
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: const Color(0xFF8E2DE2),
                              child: IconButton(
                                icon: const Icon(Icons.send, color: Colors.white), 
                                onPressed: _sendReply
                              ),
                            )
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
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