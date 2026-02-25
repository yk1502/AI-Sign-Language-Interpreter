import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/io.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart'; 
import 'package:speech_to_text/speech_to_text.dart'; 
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart'; 
import 'package:flutter/services.dart';
import 'main.dart';
import 'package:flutter/scheduler.dart'; 

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  CameraController? _controller;
  IOWebSocketChannel? _channel;

  // LOGIC STATE
  bool _isProcessing = false;
  DateTime _lastProcessedTime = DateTime.now();
  String _currentLabel = "Waiting for hands...";

  double _currentConfidence = 0.0;

  // REPLACE WITH NGROK/SERVER URL
  final String _socketUrl = 'ws://192.168.68.110:8000/ws/predict';

  String _pendingSpeechText = "";

  final LinearGradient _uiGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF52B0B7), Color(0xFF085065)],
  );

  final ValueNotifier<String> _speechValueNotifier = ValueNotifier<String>("");

  final TextEditingController _textController = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _speechEnabled = false;

  String _recognizedText = "Waiting for speech...";

  static const platform = MethodChannel('speech_to_text_windows');

  @override
  void initState() {
    super.initState();
    _initSpeech();
   //_initWebSocket();
    //_initCamera();
    platform.setMethodCallHandler(_handleMethodCall);
  }

 // Modify: The MethodChannel handler
// Add this import at the top

Future<void> _handleMethodCall(MethodCall call) async {
  debugPrint("Method called: ${call.method}");
  
  if (call.method == "textRecognition") {
    final Map<dynamic, dynamic>? args = call.arguments as Map<dynamic, dynamic>?;
    if (args != null) {
      // 1. Capture the words
      _pendingSpeechText = args['recognizedWords'] ?? "";
      
      // 2. Update UI immediately so the user sees text as they speak
      _syncAllSpeechUI(_pendingSpeechText);
    }
  } else if (call.method == "notifyStatus") {
    String status = call.arguments as String;
    if (status == "notListening") {
      setState(() => _isListening = false);
    }
  }
}

void _syncAllSpeechUI(String text) {
  if (!mounted || text.isEmpty) return;

  setState(() {
    // This updates the Big Text
    _currentLabel = text;
    
    // This updates the Notifier (if you are still using it)
    _speechValueNotifier.value = text;
    
    // This updates the TextField
    _textController.text = text;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
  });
}

void _updateTextUI(String text) {
  // This schedules the update for the next available frame
  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    
    // Update the controller first
    _textController.text = text;
    
    // Then trigger the UI refresh
    setState(() {
      _currentLabel = text;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    });
    
    // Force the TextField to acknowledge the new text
    _textController.notifyListeners();
  });
}
  // 1. CONNECT TO SERVER
  void _initWebSocket() {
    try {
      _channel = IOWebSocketChannel.connect(_socketUrl);
      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        if (mounted) {
          setState(() {
            _currentLabel = data['label'];
            _isProcessing = false; // Unlock: Ready to send next frame
          });
        }
      }, onError: (error) {
        print("WS Error: $error");
        _isProcessing = false;
      });
    } catch (e) {
      print("Connection Error: $e");
    }
  }

  // 2. START CAMERA & STREAM
  void _initCamera() async {
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[0], // Back camera
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});

      _controller!.startImageStream((CameraImage image) {
        _processCameraImage(image);
      });

    } catch (e) {
      print("Camera Error: $e");
    }
  }

  void _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onError: (val) => print('STT Error: $val'),
      onStatus: (val) => print('STT Status: $val'),
    );
    setState(() {});
  }

  // 3. LOOP TO SEND IMAGE FRAME
  void _processCameraImage(CameraImage image) async {
    // A. Skip some frames to save CPU resource (Limit to ~6 FPS)
    if (_isProcessing || DateTime.now().difference(_lastProcessedTime).inMilliseconds < 150) {
      return;
    }

    _isProcessing = true;
    _lastProcessedTime = DateTime.now();

    try {
      // B. CONVERT & SEND
      List<int> jpegBytes = await convertYUV420toImageColor(image);
      String base64Image = base64Encode(jpegBytes);
      _channel?.sink.add(base64Image);

    } catch (e) {
      print("Processing Error: $e");
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  void _handleTextSubmit() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        _currentLabel = _textController.text;
      });
      _textController.clear();
      FocusScope.of(context).unfocus();
    }
  }

void _onSpeechResult(SpeechRecognitionResult result) {
  // Check if this is the final piece of text
  if (result.finalResult) {
    String finalWords = result.recognizedWords;
    
    // Force the update to the Main Thread
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _textController.text = finalWords;
        _currentLabel = finalWords;
        _isListening = false; // Ensure UI shows it's off
      });
      
      debugPrint("Final text displayed: $finalWords");
    });
  }
}

void _toggleListening() async {
  if (!_speechEnabled) {
    _speechEnabled = await _speech.initialize();
  }

  if (_isListening) {
    await _speech.stop();
    // We don't call setState here; _finalizeSpeech will handle it 
    // when the Windows plugin confirms it has stopped.
  } else {
    _textController.clear();
    _pendingSpeechText = "";
    setState(() {
      _isListening = true;
      _currentLabel = "Listening...";
    });
    
    await _speech.listen(
      onResult: (result) => _pendingSpeechText = result.recognizedWords,
      listenMode: ListenMode.dictation,
      partialResults: true,
    );
  }
}
  @override
  Widget build(BuildContext context) {
    // Determine if we are in portrait or landscape
    final bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => _uiGradient.createShader(bounds),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => _uiGradient.createShader(bounds),
          child: Text(
            "Sign Language Interpreter",
            style: GoogleFonts.poppins(
              letterSpacing: 1,
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
        ),
      ),
      body: Flex(
        // Switches between Vertical (Portrait) and Horizontal (Landscape)
        direction: isPortrait ? Axis.vertical : Axis.horizontal,
        children: [
          // 1. CAMERA SECTION
          Flexible(
            flex: isPortrait ? 6 : 1, // Camera takes more space in portrait
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _controller != null && _controller!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: isPortrait 
                          ? 1 / _controller!.value.aspectRatio 
                          : _controller!.value.aspectRatio,
                      child: CameraPreview(_controller!),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),

          // 2. INTERACTION SECTION (Text Display + Controls)
          Expanded(
            flex: isPortrait ? 4 : 1, // Balanced split for both orientations
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // DISPLAY AREA & SPEAKER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                     ValueListenableBuilder<String>(
              valueListenable: _speechValueNotifier, // Use the Notifier we discussed
              builder: (context, speechValue, _) {
                return ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => _uiGradient.createShader(bounds),
                  child: Text(
                    // Use the incoming speechValue; fall back to _currentLabel if empty
                    speechValue.isEmpty ? _currentLabel : speechValue,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                );
              }
            ),
            
                      IconButton(
                        icon: const Icon(Icons.volume_up, size: 30, color: Color(0xFF52B0B7)),
                        onPressed: () => _flutterTts.speak(_currentLabel),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // BOTTOM INPUT BAR
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Row(
                    children: [
                      // Mic Button
                      GestureDetector(
                        onTap: _toggleListening,
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: _isListening ? Colors.red : const Color(0xFF52B0B7),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none, 
                            color: Colors.white
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Text Input
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          onSubmitted: (_) => _handleTextSubmit(),
                          decoration: InputDecoration(
                            hintText: _isListening ? "Waiting for speech..." : "Type a reply...",
      
                          // OPTIONAL: Improved Clear Button
                          suffixIcon: _textController.text.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () => setState(() => _textController.clear()),
                              ) 
                            : null,
                                              
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                         onChanged: (text) {
                            setState(() {}); 
                          },
                        ),
                      ),
                      const SizedBox(width: 5),
                      // Send Button
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF085065)),
                        onPressed: _handleTextSubmit,
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


  // Convert Raw Camera Data to JPEG
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

    // Back camera portrait position
    img.Image rotated = img.copyRotate(imgBuffer, angle: 90);

    return img.encodeJpg(rotated, quality: 50);
  }
}

