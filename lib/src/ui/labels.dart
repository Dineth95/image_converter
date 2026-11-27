import 'package:flutter/services.dart';

/// User-facing text used by the image_converter widgets. Override any of it
/// (e.g. for localisation) through [ImageConverterThemeData.labels].
class ImageConverterLabels {
  const ImageConverterLabels({
    this.imagesToPdf = 'Images → PDF',
    this.pdfToImages = 'PDF → Images',
    this.converting = 'Converting…',
    this.empty = 'Converted pages will appear here',
    this.pdfCreated = _defaultPdfCreated,
    this.imagesCreated = _defaultImagesCreated,
    this.error = _defaultError,
    this.page = _defaultPage,
  });

  final String imagesToPdf;
  final String pdfToImages;
  final String converting;
  final String empty;

  /// Status after images -> PDF. [bytes] is the PDF size.
  final String Function(int pageCount, int bytes) pdfCreated;

  /// Status after PDF -> images.
  final String Function(int imageCount) imagesCreated;

  /// Status text for a failed conversion.
  final String Function(Object error) error;

  /// Caption under a page preview (1-based).
  final String Function(int pageNumber) page;

  ImageConverterLabels copyWith({
    String? imagesToPdf,
    String? pdfToImages,
    String? converting,
    String? empty,
    String Function(int pageCount, int bytes)? pdfCreated,
    String Function(int imageCount)? imagesCreated,
    String Function(Object error)? error,
    String Function(int pageNumber)? page,
  }) {
    return ImageConverterLabels(
      imagesToPdf: imagesToPdf ?? this.imagesToPdf,
      pdfToImages: pdfToImages ?? this.pdfToImages,
      converting: converting ?? this.converting,
      empty: empty ?? this.empty,
      pdfCreated: pdfCreated ?? this.pdfCreated,
      imagesCreated: imagesCreated ?? this.imagesCreated,
      error: error ?? this.error,
      page: page ?? this.page,
    );
  }

  static String _defaultPdfCreated(int pageCount, int bytes) {
    final size = bytes >= 1024 * 1024
        ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(bytes / 1024).ceil()} KB';
    return 'Created a $pageCount-page PDF ($size)';
  }

  static String _defaultImagesCreated(int count) =>
      'Rendered $count image${count == 1 ? '' : 's'}';

  static String _defaultError(Object error) => switch (error) {
    PlatformException(:final code, :final message) =>
      'Conversion failed ($code)${message == null ? '' : ': $message'}',
    ArgumentError(:final message) => 'Invalid input: $message',
    _ => 'Conversion failed: $error',
  };

  static String _defaultPage(int pageNumber) => 'Page $pageNumber';
}
