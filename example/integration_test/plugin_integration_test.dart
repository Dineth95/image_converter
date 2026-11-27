import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_converter/image_converter.dart';
import 'package:integration_test/integration_test.dart';

Future<Uint8List> _png(int w, int h) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF2196F3),
  );
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const converter = ImageConverter();

  testWidgets('images -> pdf -> images round trip', (tester) async {
    final pdf = await converter.imagesToPdf([
      await _png(200, 100),
      await _png(100, 300),
    ]);
    expect(String.fromCharCodes(pdf.take(4)), '%PDF');
    expect(await converter.pdfPageCount(pdf), 2);

    final pages = await converter.pdfToImages(pdf, dpi: 144);
    expect(pages, hasLength(2));
    final codec = await ui.instantiateImageCodec(pages[1]);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 200); // 100 pt * 144/72
    expect(frame.image.height, 600);
  });

  testWidgets('fixed page size and jpeg output', (tester) async {
    final pdf = await converter.imagesToPdf(
      [await _png(50, 50)],
      pageSize: PdfPageSize.a4,
      margin: 36,
    );
    final pages = await converter.pdfToImages(
      pdf,
      dpi: 72,
      format: ImageFormat.jpeg,
      quality: 80,
    );
    expect(pages.single.sublist(0, 2), [0xFF, 0xD8]); // JPEG SOI marker
  });

  testWidgets('errors', (tester) async {
    await expectLater(
      converter.pdfPageCount(Uint8List.fromList([1, 2, 3])),
      throwsA(
        isA<PlatformException>().having((e) => e.code, 'code', 'INVALID_PDF'),
      ),
    );
    final pdf = await converter.imagesToPdf([await _png(10, 10)]);
    await expectLater(
      converter.pdfToImages(pdf, pages: [5]),
      throwsA(
        isA<PlatformException>().having((e) => e.code, 'code', 'INVALID_PAGE'),
      ),
    );
    await expectLater(
      converter.imagesToPdf([
        Uint8List.fromList([0, 1, 2]),
      ]),
      throwsA(
        isA<PlatformException>().having((e) => e.code, 'code', 'INVALID_IMAGE'),
      ),
    );
  });
}
