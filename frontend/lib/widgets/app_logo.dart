import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom App Logo Widget for Music AI Voice Clone Application
class AppLogo extends StatefulWidget {
  final double size;
  final bool animated;
  final Color? primaryColor;
  final Color? secondaryColor;

  const AppLogo({
    super.key,
    this.size = 100.0,
    this.animated = true,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    if (widget.animated) {
      _rotationController = AnimationController(
        duration: const Duration(seconds: 8),
        vsync: this,
      );
      
      _pulseController = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      );

      _rotationAnimation = Tween<double>(
        begin: 0,
        end: 2 * math.pi,
      ).animate(CurvedAnimation(
        parent: _rotationController,
        curve: Curves.linear,
      ));

      _pulseAnimation = Tween<double>(
        begin: 0.9,
        end: 1.1,
      ).animate(CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ));

      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    if (widget.animated) {
      _rotationController.dispose();
      _pulseController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.primaryColor;
    final secondaryColor = widget.secondaryColor ?? theme.colorScheme.secondary;

    Widget logo = CustomPaint(
      size: Size(widget.size, widget.size),
      painter: LogoPainter(
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        rotationAngle: widget.animated ? _rotationAnimation.value : 0,
      ),
    );

    if (widget.animated) {
      return AnimatedBuilder(
        animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: logo,
          );
        },
      );
    }

    return logo;
  }
}

/// Custom Painter for the Music AI Logo
class LogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double rotationAngle;

  LogoPainter({
    required this.primaryColor,
    required this.secondaryColor,
    this.rotationAngle = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Save the canvas state
    canvas.save();

    // Translate to center for rotation
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);
    canvas.translate(-center.dx, -center.dy);

    // Draw outer gradient circle (AI neural network representation)
    _drawOuterRing(canvas, center, radius);

    // Draw sound waves
    _drawSoundWaves(canvas, center, radius);

    // Draw central microphone/voice icon
    _drawMicrophone(canvas, center, radius);

    // Draw AI circuit pattern
    _drawCircuitPattern(canvas, center, radius);

    // Draw musical notes
    _drawMusicalNotes(canvas, center, radius);

    // Restore canvas state
    canvas.restore();
  }

  void _drawOuterRing(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.3),
          primaryColor.withOpacity(0.8),
          secondaryColor.withOpacity(0.6),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Draw multiple concentric circles for depth
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        center,
        radius * (0.85 - i * 0.1),
        paint..strokeWidth = 3.0 - i * 0.5,
      );
    }
  }

  void _drawSoundWaves(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = secondaryColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Draw concentric sound wave arcs
    for (int i = 0; i < 4; i++) {
      final waveRadius = radius * (0.4 + i * 0.08);
      final sweepAngle = math.pi / 3;
      
      // Right side waves
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: waveRadius),
        -sweepAngle / 2,
        sweepAngle,
        false,
        paint..strokeWidth = 2.0 - i * 0.3,
      );
      
      // Left side waves (mirrored)
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: waveRadius),
        math.pi - sweepAngle / 2,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  void _drawMicrophone(Canvas canvas, Offset center, double radius) {
    final micPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final micStrokePaint = Paint()
      ..color = primaryColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final micRadius = radius * 0.15;
    final micHeight = radius * 0.25;

    // Microphone capsule (rounded rectangle)
    final micRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - micHeight / 4),
        width: micRadius * 2,
        height: micHeight,
      ),
      Radius.circular(micRadius),
    );
    
    canvas.drawRRect(micRect, micPaint);
    canvas.drawRRect(micRect, micStrokePaint);

    // Microphone stand
    final standPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx, center.dy + micHeight / 4),
      Offset(center.dx, center.dy + radius * 0.3),
      standPaint,
    );

    // Base
    canvas.drawLine(
      Offset(center.dx - radius * 0.1, center.dy + radius * 0.3),
      Offset(center.dx + radius * 0.1, center.dy + radius * 0.3),
      standPaint,
    );
  }

  void _drawCircuitPattern(Canvas canvas, Offset center, double radius) {
    final circuitPaint = Paint()
      ..color = primaryColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final nodeRadius = 2.0;
    final nodePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    // Draw circuit lines in a neural network pattern
    final angles = [0, math.pi / 3, 2 * math.pi / 3, math.pi, 4 * math.pi / 3, 5 * math.pi / 3];
    final innerRadius = radius * 0.5;
    final outerRadius = radius * 0.75;

    // Draw connections between nodes
    for (int i = 0; i < angles.length; i++) {
      final angle1 = angles[i];
      final angle2 = angles[(i + 1) % angles.length];
      
      final point1 = Offset(
        center.dx + innerRadius * math.cos(angle1),
        center.dy + innerRadius * math.sin(angle1),
      );
      
      final point2 = Offset(
        center.dx + innerRadius * math.cos(angle2),
        center.dy + innerRadius * math.sin(angle2),
      );

      final outerPoint = Offset(
        center.dx + outerRadius * math.cos(angle1),
        center.dy + outerRadius * math.sin(angle1),
      );

      // Inner connections
      canvas.drawLine(point1, point2, circuitPaint);
      
      // Outer connections
      canvas.drawLine(point1, outerPoint, circuitPaint);
      
      // Draw nodes
      canvas.drawCircle(point1, nodeRadius, nodePaint);
      canvas.drawCircle(outerPoint, nodeRadius * 0.7, nodePaint);
    }
  }

  void _drawMusicalNotes(Canvas canvas, Offset center, double radius) {
    final notePaint = Paint()
      ..color = secondaryColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final noteSize = radius * 0.06;
    
    // Draw musical notes around the logo
    final notePositions = [
      Offset(center.dx + radius * 0.6, center.dy - radius * 0.5),
      Offset(center.dx - radius * 0.6, center.dy - radius * 0.3),
      Offset(center.dx + radius * 0.4, center.dy + radius * 0.6),
      Offset(center.dx - radius * 0.5, center.dy + radius * 0.4),
    ];

    for (final pos in notePositions) {
      // Note head
      canvas.drawOval(
        Rect.fromCenter(center: pos, width: noteSize, height: noteSize * 0.8),
        notePaint,
      );
      
      // Note stem
      canvas.drawLine(
        Offset(pos.dx + noteSize * 0.4, pos.dy),
        Offset(pos.dx + noteSize * 0.4, pos.dy - noteSize * 2),
        Paint()
          ..color = secondaryColor.withOpacity(0.7)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(LogoPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
           oldDelegate.primaryColor != primaryColor ||
           oldDelegate.secondaryColor != secondaryColor;
  }
}

/// Logo with text component
class AppLogoWithText extends StatelessWidget {
  final double logoSize;
  final double fontSize;
  final bool animated;
  final Color? primaryColor;
  final Color? secondaryColor;
  final String appName;
  final String? tagline;

  const AppLogoWithText({
    super.key,
    this.logoSize = 80.0,
    this.fontSize = 24.0,
    this.animated = true,
    this.primaryColor,
    this.secondaryColor,
    this.appName = 'Music AI',
    this.tagline = 'Voice Clone Studio',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(
          size: logoSize,
          animated: animated,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
        ),
        const SizedBox(height: 12),
        Text(
          appName,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: primaryColor ?? Theme.of(context).primaryColor,
            letterSpacing: 1.2,
          ),
        ),
        if (tagline != null) ...[
          const SizedBox(height: 4),
          Text(
            tagline!,
            style: TextStyle(
              fontSize: fontSize * 0.5,
              fontWeight: FontWeight.w400,
              color: (secondaryColor ?? Theme.of(context).colorScheme.secondary)
                  .withOpacity(0.8),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ],
    );
  }
}
