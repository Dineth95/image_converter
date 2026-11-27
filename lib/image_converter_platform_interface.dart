import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'image_converter_method_channel.dart';
import 'src/types.dart';

abstract class ImageConverterPlatform extends PlatformInterface {
  /// Constructs a ImageConverterPlatform.
  ImageConverterPlatform() : super(token: _token);

  static final Object _token = Object();

  static ImageConverterPlatform _instance = MethodChannelImageConverter();

  /// The default instance of [ImageConverterPlatform] to use.
  ///
  /// Defaults to [MethodChannelImageConverter].
  static ImageConverterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ImageConverterPlatform] when
  /// they register themselves.
  static set instance(ImageConverterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Builds a PDF with one page per image in [images].
  Future<Uint8List> imagesToPdf(
    List<Uint8List> images, {
    PdfPageSize? pageSize,
    double margin = 0,
  }) {
    throw UnimplementedError('imagesToPdf() has not been implemented.');
  }

  /// Renders pages of [pdf] to encoded images.
  Future<List<Uint8List>> pdfToImages(
    Uint8List pdf, {
    double dpi = 144,
    ImageFormat format = ImageFormat.png,
    int quality = 90,
    List<int>? pages,
  }) {
    throw UnimplementedError('pdfToImages() has not been implemented.');
  }

  /// Returns the number of pages in [pdf].
  Future<int> pdfPageCount(Uint8List pdf) {
    throw UnimplementedError('pdfPageCount() has not been implemented.');
  }
}
