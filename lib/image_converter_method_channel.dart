import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'image_converter_platform_interface.dart';
import 'src/types.dart';

/// An implementation of [ImageConverterPlatform] that uses method channels.
class MethodChannelImageConverter extends ImageConverterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('image_converter');

  @override
  Future<Uint8List> imagesToPdf(
    List<Uint8List> images, {
    PdfPageSize? pageSize,
    double margin = 0,
  }) async {
    final pdf = await methodChannel.invokeMethod<Uint8List>('imagesToPdf', {
      'images': images,
      'pageSize': pageSize?.toMap(),
      'margin': margin,
    });
    return pdf!;
  }

  @override
  Future<List<Uint8List>> pdfToImages(
    Uint8List pdf, {
    double dpi = 144,
    ImageFormat format = ImageFormat.png,
    int quality = 90,
    List<int>? pages,
  }) async {
    final images = await methodChannel.invokeListMethod<Uint8List>(
      'pdfToImages',
      {
        'pdf': pdf,
        'dpi': dpi,
        'format': format.name,
        'quality': quality,
        'pages': pages,
      },
    );
    return images!;
  }

  @override
  Future<int> pdfPageCount(Uint8List pdf) async {
    final count = await methodChannel.invokeMethod<int>('pdfPageCount', {
      'pdf': pdf,
    });
    return count!;
  }
}
