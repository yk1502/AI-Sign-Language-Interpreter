import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Required for SemanticsService
import 'package:flutter/services.dart';  // Required for HapticFeedback
import 'detectionScreen.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(), 
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _floatController;
  late AnimationController _vibrationController;
  late AnimationController _shimmerController;
  late AnimationController _flickerController;
  final math.Random _random = math.Random();
  
  // NEW: Added TTS engine
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _vibrationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 10000))..repeat(reverse: true);
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _flickerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100))..repeat(reverse: true);

    _initBlindModeVoice();
  }

  // NEW: This ensures the app actually speaks out loud on entry
  Future<void> _initBlindModeVoice() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    
    // Announce instruction audibly
    Future.delayed(const Duration(milliseconds: 800), () {
      _flutterTts.speak("Welcome. For blind mode, tap the left side of the screen.");
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatController.dispose();
    _vibrationController.dispose();
    _shimmerController.dispose();
    _flickerController.dispose();
    _flutterTts.stop(); // Stop speaking if user leaves
    super.dispose();
  }

  Widget _buildVibratingShimmer(String text, double fontSize, FontWeight weight, List<Color> colors, double textHeight) {
    return AnimatedBuilder(
      animation: _vibrationController,
      builder: (context, child) {
        double slide = _vibrationController.value;
        return Stack(
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors[1], colors[2]],
              ).createShader(bounds),
              child: Text(
                text,
                style: TextStyle(fontSize: fontSize, fontWeight: weight, height: textHeight),
              ),
            ),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  tileMode: TileMode.decal,
                  colors: [Colors.transparent, Colors.white.withOpacity(0.2), Colors.transparent],
                  stops: [slide - 0.3, slide, slide + 0.3],
                ).createShader(bounds);
              },
              child: Text(
                text,
                style: TextStyle(fontSize: fontSize, fontWeight: weight, height: textHeight, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  
  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF9),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: BackgroundPatternPainter())),

          // Background floating circles
          AnimatedBuilder(
            animation: Listenable.merge([_mainController, _floatController]),
            builder: (context, child) {
              double t = _floatController.value * 2 * math.pi;
              double breathingScale = 1.0 + (_mainController.value * 0.3);
              return Stack(
                children: [
                  _positionedCircle(screen, t, 0, -0.15, -0.15, 400, breathingScale, const Color.fromARGB(255, 120, 219, 222), 0.5),
                  _positionedCircle(screen, t, 1, 0.8, -0.1, 350, breathingScale, const Color.fromARGB(255, 130, 213, 216), 0.5),
                  _positionedCircle(screen, t, 2, -0.2, 0.45, 320, breathingScale, const Color.fromARGB(255, 116, 201, 204), 0.4),
                  _positionedCircle(screen, t, 3, 0.85, 0.4, 340, breathingScale, const Color.fromARGB(255, 131, 196, 198), 0.55),
                  _positionedCircle(screen, t, 4, -0.1, 0.85, 380, breathingScale, const Color.fromARGB(255, 105, 200, 203), 0.6),
                  _positionedCircle(screen, t, 5, 0.75, 0.8, 420, breathingScale, const Color.fromARGB(255, 145, 218, 220), 0.45),
                ],
              );
            },
          ),

          // Central Glow
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_mainController, _flickerController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_mainController.value * 0.4),
                  child: _glowCircle(600, const Color.fromARGB(255, 102, 190, 193), 0.6),
                );
              },
            ),
          ),

          // Upload Button (Top Right)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 65, right: 20),
              child: _buildProfessionalUploadButton(context),
            ),
          ),

          // Main Text Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 45),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildVibratingShimmer("AI", 100, FontWeight.w900, [Colors.white, const Color(0xFF52A1B3), const Color(0xFF085065)], 0.9),
                    Positioned(
                      top: -10,
                      left: 103,
                      child: AnimatedBuilder(
                        animation: _flickerController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: 0.35 + (_random.nextDouble() * 0.65),
                            child: SvgPicture.asset(
                              'assets/welcome_bg.svg',
                              width: 120,
                              fit: BoxFit.contain,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                _buildVibratingShimmer("Sign Language", 40, FontWeight.w700, [const Color(0xFF5299B7), const Color(0xFF1B4043), const Color(0xFF0D6E89)], 1.35),
                _buildVibratingShimmer("Interpreter", 40, FontWeight.w700, [const Color(0xFF5299B7), const Color(0xFF1B4043), const Color(0xFF52A1B7)], 1.35),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 35),
                  child: Text(
                    "real-time sign language recognition",
                    style: GoogleFonts.handlee(
                      color: const Color.fromARGB(255, 6, 78, 98),
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                _buildSlim3DButton(context, const Color(0xFF52B0B7), const Color(0xFF1B3D43)),
              ],
            ),
          ),

          // --- FIXED BLIND MODE TRIGGER ---
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.3,
              heightFactor: 1.0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque, // FIX: Ensures the empty space is clickable
                onTap: () {
                  HapticFeedback.heavyImpact(); 
                  _flutterTts.speak("Blind mode starting."); // Confirmation voice
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetectionScreen(isBlindMode: true,availableCameras: cameras),
                    ),
                  );
                },
                child: const SizedBox.expand(), // Fills the left half of the screen
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlim3DButton(BuildContext context, Color color, Color shadowColor) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetectionScreen(availableCameras: cameras))),
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return Container(
            width: 190,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: shadowColor.withOpacity(0.4), offset: const Offset(0, 6)),
                BoxShadow(color: color.withOpacity(0.2), offset: const Offset(0, 10), blurRadius: 15),
              ],
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, shadowColor],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ShaderMask(
                    blendMode: BlendMode.srcOver,
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.transparent, Colors.white.withOpacity(0.15), Colors.transparent],
                      stops: [_shimmerController.value - 0.2, _shimmerController.value, _shimmerController.value + 0.2],
                    ).createShader(bounds),
                    child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const Center(
                  child: Text(
                    "OPEN CAMERA",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _glowCircle(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        backgroundBlendMode: BlendMode.multiply,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), color.withOpacity(opacity * 0.5), color.withOpacity(0)],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
    );
  }

  Widget _positionedCircle(Size screen, double t, int i, double x, double y, double size, double scale, Color color, double op) {
    return Positioned(
      left: (screen.width * x) + (150 * math.sin(t + i)),
      top: (screen.height * y) + (150 * math.cos(t + i)),
      child: Transform.scale(scale: scale, child: _glowCircle(size, color, 0.7)),
    );
  }
}
Widget _buildProfessionalUploadButton(BuildContext context) {
  const Color color1 = Color(0xFF52B0B7);
  const Color color2 = Color.fromARGB(255, 43, 120, 135);
  final Gradient gradient = LinearGradient(colors: [color1, color2]);

  return GestureDetector(
    onTap: () => Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const DataCollectionFlow())
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        // This creates the gradient border effect
        border: Border.all(color: Colors.transparent), 
      ),
      child: CustomPaint(
        painter: GradientOutlinePainter(
          gradient: gradient,
          strokeWidth: 2,
          radius: 30,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => gradient.createShader(bounds),
                child: const Icon(Icons.upload_file, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (bounds) => gradient.createShader(bounds),
                child: Text(
                  "UPLOAD SIGN VIDEO",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 35, 178, 181),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF52B788).withOpacity(0.2)..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += 30) {
      for (double y = 0; y < size.height; y += 30) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



class DataCollectionFlow extends StatefulWidget {
  const DataCollectionFlow({super.key});

  @override
  State<DataCollectionFlow> createState() => _DataCollectionFlowState();
}

class _DataCollectionFlowState extends State<DataCollectionFlow> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form Fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _certName;
  String? _videoName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF085065)),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF52B0B7), Color(0xFF1B3D43)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            _currentPage == 0 ? "Step 1: Credentials" : "Step 2: Sign Video",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              height: 2,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBackgroundEffect(),
          SafeArea( 
            child: Center(
              // Removed SingleChildScrollView from here
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  // In landscape, we limit height so it doesn't push off-screen
                  maxHeight: MediaQuery.of(context).orientation == Orientation.landscape 
                      ? MediaQuery.of(context).size.height * 0.7 
                      : 550,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05), 
                      blurRadius: 20, 
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) => setState(() => _currentPage = page),
                    children: [
                      // Ensure these methods wrap their content in a SingleChildScrollView
                      _buildPersonalPage(),
                      _buildVideoPage(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // MATCHES THE "GLOWY CIRCLE" THEME OF THE MAIN SCREEN
  Widget _buildBackgroundEffect() {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFF7FBF9)),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: _glowCircle(400, const Color(0xFF78DBDE).withOpacity(0.4)),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: _glowCircle(350, const Color(0xFF52B0B7).withOpacity(0.3)),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }

  // --- PAGE 1: PERSONAL & CERT ---
  Widget _buildPersonalPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // Use spaceBetween to push the button to the bottom
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [
                  Column( // Wrap top content in its own Column
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _styledTextField("Contributor Name", Icons.person_outline, _nameController),
                      const SizedBox(height: 25),
                      _uploadTile("Related Certificate", _certName, Icons.badge_outlined, () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                        );

                        if (result != null) {
                          setState(() {
                            _certName = result.files.single.name;
                          });
                          // You can access the path via result.files.single.path
                        }
                                            }),
                    ],
                  ),
                  
                  // Use a fixed gap instead of Spacer to avoid the RenderBox error
                  const SizedBox(height: 40), 
                  
                  Align(
                    alignment: Alignment.bottomRight,
                    child: SizedBox(
                      width: 180,
                      child: _actionButton(
                        "NEXT STEP", 
                        const Color(0xFF52B0B7), 
                        const Color(0xFF1B3D43), 
                        () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 400), 
                          curve: Curves.easeInOut,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildVideoPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Fixes the overlap/crash
                children: [
                  Column(
                    children: [
                      _uploadTile("Sign Language Video", _videoName, Icons.videocam_outlined, () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.video, // Filters specifically for video files
                        );

                        if (result != null) {
                          setState(() {
                            _videoName = result.files.single.name;
                          });
                        }
                      }),
                      const SizedBox(height: 25),
                      _styledTextField("Sign Description (Label)", Icons.label_important_outline, _descController, maxLines: 3),
                    ],
                  ),

                  // Updated Button Row
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Aligns Back to left, Submit to right
                      children: [
                        _actionButton(
                          "BACK",
                          Colors.grey,
                          Colors.blueGrey,
                          () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          ),
                        ),
                        _actionButton(
                          "SUBMIT",
                          const Color(0xFF52B0B7),
                          const Color(0xFF085065),
                          () => Navigator.pop(context),
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
    );
  }
  
  // --- UI COMPONENTS ---

  Widget _styledTextField(String label, IconData icon, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF52B0B7), size: 20), // Standard icon size
            const SizedBox(width: 10),
            Text(
              label, 
              style: const TextStyle(
                fontSize: 20, // Matching logo text size
                fontWeight: FontWeight.bold, 
                color: Color(0xFF085065)
              )
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 20),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.5),
            contentPadding: const EdgeInsets.all(15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: const BorderSide(color: Colors.white)
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: const BorderSide(color: Color(0xFF52B0B7))
            ),
          ),
        ),
      ],
    );
  }

  Widget _uploadTile(String title, String? fileName, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF52B0B7), size: 20), // Matches TextField Icon size
              const SizedBox(width: 10),
              Text(
                title, 
                style: const TextStyle(
                  fontSize: 20, // Matches TextField Label size
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFF085065)
                )
              ),
              const Spacer(),
              const Icon(Icons.add_circle_outline, color: Color(0xFF52B0B7), size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white),
            ),
            child: Text(
              fileName ?? "Tap to select file", 
              style: TextStyle(
                color: fileName != null ? const Color(0xFF085065) : Colors.grey.shade600, 
                fontSize: 15 // Kept smaller per request
              )
            ),
          ),
        ],
      ),
    );
  }
  Widget _actionButton(String label, Color topColor, Color bottomColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: IntrinsicWidth( // Ensures the button width matches the text length
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 30), // Side padding for the "wrap" look
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: bottomColor.withOpacity(0.4), 
                offset: const Offset(0, 6)
              ), 
              BoxShadow(
                color: topColor.withOpacity(0.2), 
                offset: const Offset(0, 10), 
                blurRadius: 15
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [topColor, bottomColor],
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: 16, 
                letterSpacing: 1.2
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GradientOutlinePainter extends CustomPainter {
  final Gradient gradient;
  final double strokeWidth;
  final double radius;

  GradientOutlinePainter({required this.gradient, required this.strokeWidth, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = Offset.zero & size;
    Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}



