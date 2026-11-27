import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_converter/image_converter.dart';
import 'package:image_converter/image_converter_method_channel.dart';
import 'package:image_converter/image_converter_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePlatform
    with MockPlatformInterfaceMixin
    implements ImageConverterPlatform {
  List<Uint8List>? lastImages;
  List<int>? lastPages;

  @override
  Future<Uint8List> imagesToPdf(
    List<Uint8List> images, {
    PdfPageSize? pageSize,
    double margin = 0,
  }) async {
    lastImages = images;
    return Uint8List.fromList('%PDF'.codeUnits);
  }

  @override
  Future<List<Uint8List>> pdfToImages(
    Uint8List pdf, {
    double dpi = 144,
    ImageFormat format = ImageFormat.png,
    int quality = 90,
    List<int>? pages,
  }) async {
    lastPages = pages;
    final n = pages?.length ?? 3;
    return List.generate(n, (i) => Uint8List.fromList([i]));
  }

  @override
  Future<int> pdfPageCount(Uint8List pdf) async => 3;
}

void main() {
  final initialPlatform = ImageConverterPlatform.instance;

  test('$MethodChannelImageConverter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelImageConverter>());
  });

  group('with fake platform', () {
    late FakePlatform fake;
    const converter = ImageConverter();

    setUp(() => ImageConverterPlatform.instance = fake = FakePlatform());

    test('argument validation', () {
      expect(() => converter.imagesToPdf([]), throwsArgumentError);
      expect(
        () => converter.imagesToPdf([Uint8List(1)], margin: -1),
        throwsRangeError,
      );
      expect(
        () => converter.imagesToPdf(
          [Uint8List(1)],
          pageSize: const PdfPageSize(100, 100),
          margin: 50,
        ),
        throwsArgumentError,
      );
      expect(
        () => converter.pdfToImages(Uint8List(1), dpi: 0),
        throwsRangeError,
      );
      expect(
        () => converter.pdfToImages(Uint8List(1), quality: 101),
        throwsRangeError,
      );
      expect(
        () => converter.pdfToImages(Uint8List(1), pages: [-1]),
        throwsArgumentError,
      );
    });

    test('file helpers read and write files', () async {
      final dir = await Directory.systemTemp.createTemp('image_converter_test');
      addTearDown(() => dir.delete(recursive: true));

      final img = File('${dir.path}/a.png')..writeAsBytesSync([1, 2]);
      final pdf = await converter.imageFilesToPdfFile([
        img.path,
      ], '${dir.path}/out.pdf');
      expect(fake.lastImages, [
        [1, 2],
      ]);
      expect(pdf.readAsStringSync(), '%PDF');

      final pages = await converter.pdfFileToImageFiles(
        pdf.path,
        '${dir.path}/pages',
        pages: [0, 2],
        format: ImageFormat.jpeg,
      );
      expect(fake.lastPages, [0, 2]);
      expect(pages.map((f) => f.uri.pathSegments.last), [
        'page_1.jpg',
        'page_3.jpg',
      ]);
    });
  });

  test('PdfPageSize.landscape', () {
    expect(PdfPageSize.a4.landscape, const PdfPageSize(841.89, 595.28));
    expect(PdfPageSize.a4.landscape.landscape, PdfPageSize.a4.landscape);
  });
}
