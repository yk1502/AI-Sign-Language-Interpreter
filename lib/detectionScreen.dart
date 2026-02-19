import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/io.dart';
import 'package:image/image.dart' as img;
import 'main.dart';

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
  final String _socketUrl = 'ws://localIP:8000/ws/predict';

  final LinearGradient _uiGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF52B0B7), Color(0xFF085065)],
  );

  @override
  void initState() {
    super.initState();
    _initWebSocket();
    _initCamera();
  }

  // 1. CONNECT TO SERVER
  void _initWebSocket() {
    try {
      _channel = IOWebSocketChannel.connect(_socketUrl);
      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        if (mounted) {
          setState(() {
            _currentLabel = "${data['label']} (${(data['confidence'] * 100).toStringAsFixed(0)}%)";
            _currentConfidence = data['confidence'];
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

  @override
  Widget build(BuildContext context) {
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
        title: Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ShaderMask(
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
        ),
      ),
      body: Flex(
        direction: isPortrait ? Axis.vertical : Axis.horizontal,
        children: [
          Flexible(
            flex: isPortrait ? 7 : 1,
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
                aspectRatio: isPortrait ? 1 / _controller!.value.aspectRatio : _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
          Expanded(
            flex: isPortrait ? 2 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Center(
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => _uiGradient.createShader(bounds),
                  child: Text(
                    // DYNAMIC TEXT UPDATE
                    _currentLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32, // Made slightly bigger for readability
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
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