import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'main.dart'; 

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  final LinearGradient _uiGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF52B0B7),
      Color(0xFF085065),
    ],
  );

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  void _initCamera() {
    try {
      if (cameras.isNotEmpty) {
        _controller = CameraController(
          cameras[0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        _initializeControllerFuture = _controller!.initialize();
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        // 1. GRADIENT BACK SYMBOL
        leading: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => _uiGradient.createShader(bounds),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // 2. GRADIENT SIGN INTERPRETER TEXT
        title: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => _uiGradient.createShader(bounds),
          child: const Text(
            "Sign Language Interpreter",
            style: TextStyle(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
              fontSize: 30,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 10,
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  )
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (_controller == null) {
                    return const Center(child: Text("Camera not found"));
                  }
                  
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Center(
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: CameraPreview(_controller!),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF52B0B7),
                        strokeWidth: 3,
                      ),
                    );
                  }
                },
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => _uiGradient.createShader(bounds),
                    child: const Text(
                      "Hello, how can I help you?",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}