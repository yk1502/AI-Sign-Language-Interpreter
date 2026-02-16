import 'package:flutter/material.dart';
import 'detectionScreen.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:camera/camera.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Populate the global list
  try {
    cameras = await availableCameras();
  } catch (e) {
    print("Error fetching cameras: $e");
  }

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

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _vibrationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 10000))..repeat(reverse: true);
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _flickerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatController.dispose();
    _vibrationController.dispose();
    _shimmerController.dispose();
    _flickerController.dispose(); // Dispose the new controller
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
          // 1. BACKGROUND PATTERN
          Positioned.fill(child: CustomPaint(painter: BackgroundPatternPainter())),

          // 2. THE FLOATING BACKGROUND CIRCLES
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

          // 3. CENTRAL HUB: Pulsing Circle + Flickering Neon SVG (Behind Text)
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_mainController, _flickerController]),
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center, // Keeps the circle centered
                  children: [
                    // The Glowing Pulse Circle (Stays centered)
                    Transform.scale(
                      scale: 1.0 + (_mainController.value * 0.4),
                      child: _glowCircle(600, const Color.fromARGB(255, 102, 190, 193), 0.6),
                    ),
                  ],
                );
              },
            ),
          ),

     
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
                    
                    // The SVG positioned relative to the "AI" text
                    Positioned(
                      top: -10,  // Adjust to move higher/lower relative to 'AI'
                      left: 103, // Adjust to move further right from 'AI'
                      child: AnimatedBuilder(
                        animation: _flickerController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: 0.35 + (_random.nextDouble() * 0.65),
                            child: SvgPicture.asset(
                              'assets/welcome_bg.svg',
                              width: 120, // Scaled down to fit beside text
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
        ],
      ),
    );
  }

  Widget _buildSlim3DButton(BuildContext context, Color color, Color shadowColor) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetectionScreen()),),
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





