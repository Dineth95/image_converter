// Uses only the core (UI-free) library: no widgets are pumped, and one
// conversion runs on a background isolate.
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_converter/image_converter.dart';
import 'package:integration_test/integration_test.dart';

Future<Uint8List> _png(int w, int h) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF4CAF50),
  );
  final image = await recorder.endRecording().toImage(w, h);
  return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
      .asUint8List();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('core API works without any widget tree', () async {
    const converter = ImageConverter();
    final pdf = await converter.imagesToPdf([await _png(300, 200)]);
    expect(await converter.pdfPageCount(pdf), 1);
    final pages = await converter.pdfToImages(pdf, dpi: 72);
    expect(pages.single.sublist(1, 4), 'PNG'.codeUnits);
  });

  test('works from a background isolate', () async {
    final token = RootIsolateToken.instance!;
    final image = await _png(120, 80);

    final pageCount = await Isolate.run(() async {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
      const converter = ImageConverter();
      final pdf = await converter.imagesToPdf([image, image, image]);
      final pages = await converter.pdfToImages(pdf, dpi: 72, pages: [1]);
      return (await converter.pdfPageCount(pdf)) * 10 + pages.length;
    });

    expect(pageCount, 31); // 3 pages, 1 rendered
  });

  test('controller is usable without widgets', () async {
    final controller = ImageConverterController();
    final states = <ConversionState>[];
    controller.addListener(() => states.add(controller.state));

    final pdf = await controller.imagesToPdf([await _png(50, 50)]);
    expect(pdf, isNotNull);
    expect(controller.pages, hasLength(1)); // preview rendered
    expect(states, [ConversionState.converting, ConversionState.success]);

    final failed = await controller.pdfToImages(Uint8List.fromList([1, 2]));
    expect(failed, isNull);
    expect(controller.state, ConversionState.error);
    expect((controller.error! as PlatformException).code, 'INVALID_PDF');
    controller.dispose();
  });
}
