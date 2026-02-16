import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'main.dart';
import 'package:google_fonts/google_fonts.dart';

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
    colors: [Color(0xFF52B0B7), Color(0xFF085065)],
  );

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  void _initCamera() {
    if (cameras.isNotEmpty) {
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _initializeControllerFuture = _controller!.initialize();
      _controller!.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
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
              child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && _controller != null) {
                    return AspectRatio(
                      aspectRatio: isPortrait 
                        ? 1 / _controller!.value.aspectRatio 
                        : _controller!.value.aspectRatio,
                      child: CameraPreview(_controller!),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
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
                  child: const Text(
                    "Hello, how can I help you?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
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
}