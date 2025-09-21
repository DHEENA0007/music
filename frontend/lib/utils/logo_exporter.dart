import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'app_logo.dart';
import 'simple_logo.dart';

/// Utility class to export logos as images for various purposes
class LogoExporter {
  /// Export the main logo as PNG for different sizes
  static Future<Uint8List?> exportMainLogo({
    double size = 512,
    Color? primaryColor,
    Color? secondaryColor,
    bool transparent = true,
  }) async {
    final widget = Container(
      width: size,
      height: size,
      color: transparent ? Colors.transparent : Colors.white,
      child: Center(
        child: AppLogo(
          size: size * 0.8,
          animated: false,
          primaryColor: primaryColor ?? const Color(0xFF6C63FF),
          secondaryColor: secondaryColor ?? const Color(0xFF00D4FF),
        ),
      ),
    );

    return await _widgetToImage(widget, size);
  }

  /// Export simple logo for app icons
  static Future<Uint8List?> exportSimpleLogo({
    double size = 512,
    Color? color,
    bool withBackground = true,
  }) async {
    final widget = Container(
      width: size,
      height: size,
      decoration: withBackground ? BoxDecoration(
        color: color ?? const Color(0xFF6C63FF),
        borderRadius: BorderRadius.circular(size * 0.2),
      ) : null,
      child: Center(
        child: SimpleLogo(
          size: size * 0.7,
          color: withBackground ? Colors.white : (color ?? const Color(0xFF6C63FF)),
        ),
      ),
    );

    return await _widgetToImage(widget, size);
  }

  /// Export favicon for web
  static Future<Uint8List?> exportFavicon({
    double size = 32,
    Color? color,
  }) async {
    final widget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF6C63FF),
        borderRadius: BorderRadius.circular(size * 0.15),
      ),
      child: Center(
        child: SimpleLogo(
          size: size * 0.7,
          color: Colors.white,
        ),
      ),
    );

    return await _widgetToImage(widget, size);
  }

  /// Convert widget to image bytes
  static Future<Uint8List?> _widgetToImage(Widget widget, double size) async {
    try {
      final repaintBoundary = RenderRepaintBoundary();
      final renderView = RenderView(
        child: RenderPositionedBox(
          alignment: Alignment.center,
          child: repaintBoundary,
        ),
        configuration: ViewConfiguration(
          size: Size(size, size),
          devicePixelRatio: 1.0,
        ),
        window: WidgetsBinding.instance.window,
      );

      final pipelineOwner = PipelineOwner();
      final buildOwner = BuildOwner(focusManager: FocusManager());

      pipelineOwner.rootNode = renderView;
      renderView.prepareInitialFrame();

      final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: widget,
      ).attachToRenderTree(buildOwner);

      buildOwner.buildScope(rootElement);
      buildOwner.finalizeTree();

      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();

      final image = await repaintBoundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error exporting logo: $e');
      return null;
    }
  }

  /// Generate all common logo sizes
  static Future<Map<String, Uint8List?>> generateAllSizes() async {
    final results = <String, Uint8List?>{};

    // App icons (Android)
    final androidSizes = [48, 72, 96, 144, 192];
    for (final size in androidSizes) {
      results['android_${size}x$size'] = await exportSimpleLogo(
        size: size.toDouble(),
        withBackground: true,
      );
    }

    // iOS app icons
    final iosSizes = [29, 40, 58, 60, 80, 87, 120, 152, 167, 180, 1024];
    for (final size in iosSizes) {
      results['ios_${size}x$size'] = await exportSimpleLogo(
        size: size.toDouble(),
        withBackground: true,
      );
    }

    // Web favicons
    final webSizes = [16, 32, 48, 64, 128, 256];
    for (final size in webSizes) {
      results['favicon_${size}x$size'] = await exportFavicon(
        size: size.toDouble(),
      );
    }

    // High-res logos
    final logoSizes = [256, 512, 1024];
    for (final size in logoSizes) {
      results['logo_${size}x$size'] = await exportMainLogo(
        size: size.toDouble(),
      );
    }

    return results;
  }
}

/// Helper class for logo generation configuration
class LogoConfig {
  static const Map<String, Map<String, dynamic>> presets = {
    'app_icon': {
      'size': 512.0,
      'withBackground': true,
      'primaryColor': Color(0xFF6C63FF),
    },
    'favicon': {
      'size': 32.0,
      'withBackground': true,
      'primaryColor': Color(0xFF6C63FF),
    },
    'splash_logo': {
      'size': 256.0,
      'transparent': true,
      'primaryColor': Color(0xFF6C63FF),
      'secondaryColor': Color(0xFF00D4FF),
    },
    'web_logo': {
      'size': 128.0,
      'transparent': true,
      'primaryColor': Color(0xFF6C63FF),
      'secondaryColor': Color(0xFF00D4FF),
    },
  };
}
