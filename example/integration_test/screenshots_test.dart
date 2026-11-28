// Generates the README screenshots in ../doc/screenshots using real native
// conversions. Run on an iOS simulator with:
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshots_test.dart -d <simulator>
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_converter/image_converter_ui.dart';
import 'package:image_converter_example/main.dart' show brandTheme;
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const converter = ImageConverter();

  late List<Uint8List> samples;
  late Uint8List samplePdf;

  Future<void> shoot(WidgetTester tester, String name) async {
    // Let Image.memory finish decoding (that happens off the frame clock).
    await tester.pumpAndSettle();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    await binding.takeScreenshot(name);
  }

  Future<ImageConverterController> show(
    WidgetTester tester, {
    ThemeMode mode = ThemeMode.light,
    ImageConverterThemeData? extension,
    PdfGalleryLayout layout = PdfGalleryLayout.list,
  }) async {
    final controller = ImageConverterController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          extensions: [?extension],
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.dark,
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text('Image Converter')),
          body: ImageConverterView(
            controller: controller,
            onPickImages: () async => samples,
            onPickPdf: () async => samplePdf,
            galleryLayout: layout,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  setUpAll(() async {
    samples = [
      await _render(1200, 800, _paintLandscape),
      await _render(850, 1100, _paintDocument),
      await _render(1000, 1000, _paintChart),
    ];
    samplePdf = await converter.imagesToPdf(
      samples,
      pageSize: PdfPageSize.a4,
      margin: 36,
    );
  });

  testWidgets('screenshots', (tester) async {
    // 1. Default theme, empty.
    await show(tester);
    await shoot(tester, '1_default_empty');

    // 2. Default theme, images -> A4 PDF.
    var c = await show(tester);
    await c.imagesToPdf(samples, pageSize: PdfPageSize.a4, margin: 24);
    await shoot(tester, '2_images_to_pdf');

    // 3. Custom brand theme, grid, PDF -> images.
    c = await show(
      tester,
      extension: brandTheme,
      layout: PdfGalleryLayout.grid,
    );
    await c.pdfToImages(samplePdf, dpi: 100);
    await shoot(tester, '3_custom_theme');

    // 4. Dark mode with an error banner over earlier results.
    c = await show(tester, mode: ThemeMode.dark);
    await c.pdfToImages(samplePdf, dpi: 100);
    await c.pdfToImages(Uint8List.fromList(utf8NotAPdf));
    await shoot(tester, '4_dark_error');
  });
}

final utf8NotAPdf = 'not a pdf'.codeUnits;

Future<Uint8List> _render(
  int w,
  int h,
  void Function(Canvas, Size) paint,
) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder), Size(w.toDouble(), h.toDouble()));
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void _paintLandscape(Canvas canvas, Size s) {
  final sky = Rect.fromLTWH(0, 0, s.width, s.height);
  canvas.drawRect(
    sky,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E3A8A), Color(0xFFF472B6), Color(0xFFFDBA74)],
      ).createShader(sky),
  );
  canvas.drawCircle(
    Offset(s.width * 0.7, s.height * 0.55),
    s.height * 0.12,
    Paint()..color = const Color(0xFFFFF7AE),
  );
  void mountains(double base, double amp, int seed, Color color) {
    final rnd = math.Random(seed);
    final path = Path()..moveTo(0, s.height);
    for (var x = 0.0; x <= s.width; x += s.width / 8) {
      path.lineTo(x, base - rnd.nextDouble() * amp);
    }
    path
      ..lineTo(s.width, s.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  mountains(s.height * 0.72, s.height * 0.25, 1, const Color(0xFF6D28D9));
  mountains(s.height * 0.82, s.height * 0.18, 4, const Color(0xFF3B0764));
  canvas.drawRect(
    Rect.fromLTWH(0, s.height * 0.86, s.width, s.height * 0.14),
    Paint()..color = const Color(0xFF1E1B4B),
  );
}

void _paintDocument(Canvas canvas, Size s) {
  canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFFFFBF0));
  void text(String t, double x, double y, double size, {Color? color}) {
    final b =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(fontSize: size, fontWeight: FontWeight.w700),
          )
          ..pushStyle(ui.TextStyle(color: color ?? const Color(0xFF1F2937)))
          ..addText(t);
    final p = b.build()..layout(ui.ParagraphConstraints(width: s.width));
    canvas.drawParagraph(p, Offset(x, y));
  }

  text('INVOICE', 70, 70, 64, color: const Color(0xFF4338CA));
  text('#2026-118', 70, 150, 30, color: const Color(0xFF6B7280));
  final line = Paint()..color = const Color(0xFFD1D5DB);
  final rnd = math.Random(7);
  for (var i = 0; i < 12; i++) {
    final y = 260.0 + i * 52;
    canvas.drawRRect(
      RRect.fromLTRBR(
        70,
        y,
        70 + 300 + rnd.nextDouble() * 300,
        y + 18,
        const Radius.circular(9),
      ),
      line,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
        s.width - 190,
        y,
        s.width - 70,
        y + 18,
        const Radius.circular(9),
      ),
      line,
    );
  }
  canvas.drawRect(
    Rect.fromLTWH(70, 920, s.width - 140, 4),
    Paint()..color = const Color(0xFF4338CA),
  );
  text('TOTAL  \$1,240.00', 70, 950, 44);
}

void _paintChart(Canvas canvas, Size s) {
  canvas.drawRect(Offset.zero & s, Paint()..color = Colors.white);
  const colors = [
    Color(0xFF0EA5E9),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
  ];
  const values = [0.45, 0.7, 0.55, 0.85, 0.65];
  final w = (s.width - 200) / values.length;
  for (var i = 0; i < values.length; i++) {
    final h = (s.height - 260) * values[i];
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(100 + i * w + 18, s.height - 120 - h, w - 36, h),
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
      ),
      Paint()..color = colors[i],
    );
  }
  canvas.drawRect(
    Rect.fromLTWH(90, s.height - 120, s.width - 180, 5),
    Paint()..color = const Color(0xFF374151),
  );
}
