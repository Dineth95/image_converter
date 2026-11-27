import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_converter/image_converter.dart';
import 'package:image_converter/image_converter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelImageConverter();
  const channel = MethodChannel('image_converter');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'imagesToPdf':
              return Uint8List.fromList([1, 2, 3]);
            case 'pdfToImages':
              return [
                Uint8List.fromList([4]),
                Uint8List.fromList([5]),
              ];
            case 'pdfPageCount':
              return 7;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('imagesToPdf sends images, page size and margin', () async {
    final img = Uint8List.fromList([9, 9]);
    final pdf = await platform.imagesToPdf(
      [img],
      pageSize: PdfPageSize.a4,
      margin: 12,
    );

    expect(pdf, [1, 2, 3]);
    expect(calls.single.method, 'imagesToPdf');
    expect(calls.single.arguments, {
      'images': [img],
      'pageSize': {'width': 595.28, 'height': 841.89},
      'margin': 12.0,
    });
  });

  test('imagesToPdf sends null page size for fit-to-image', () async {
    await platform.imagesToPdf([Uint8List(1)]);
    expect((calls.single.arguments as Map)['pageSize'], isNull);
  });

  test('pdfToImages sends options and returns pages', () async {
    final pdf = Uint8List.fromList([0]);
    final pages = await platform.pdfToImages(
      pdf,
      dpi: 300,
      format: ImageFormat.jpeg,
      quality: 70,
      pages: [0, 2],
    );

    expect(pages, [
      [4],
      [5],
    ]);
    expect(calls.single.arguments, {
      'pdf': pdf,
      'dpi': 300.0,
      'format': 'jpeg',
      'quality': 70,
      'pages': [0, 2],
    });
  });

  test('pdfPageCount', () async {
    expect(await platform.pdfPageCount(Uint8List(1)), 7);
  });
}
