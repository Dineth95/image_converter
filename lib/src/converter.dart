import 'dart:io';
import 'dart:typed_data';

import '../image_converter_platform_interface.dart';
import 'types.dart';

/// Native errors arrive as `PlatformException` with one of these codes:
/// `INVALID_ARGUMENT`, `INVALID_IMAGE`, `INVALID_PDF`, `PDF_ENCRYPTED`,
/// `INVALID_PAGE`, `CONVERSION_FAILED`.
class ImageConverter {
  const ImageConverter();

  ImageConverterPlatform get _platform => ImageConverterPlatform.instance;

  /// Builds a PDF with one page per image (PNG, JPEG, HEIC/WebP where the
  /// platform decodes them). EXIF orientation is respected.
  ///
  /// When [pageSize] is null each page matches its image's pixel size
  /// (1 px = 1 pt). Otherwise the image is scaled to fit inside the page,
  /// preserving aspect ratio, centred, with [margin] points on every side.
  Future<Uint8List> imagesToPdf(
    List<Uint8List> images, {
    PdfPageSize? pageSize,
    double margin = 0,
  }) {
    if (images.isEmpty) {
      throw ArgumentError.value(images, 'images', 'must not be empty');
    }
    if (margin < 0) {
      throw RangeError.value(margin, 'margin', 'must be >= 0');
    }
    if (pageSize != null &&
        (margin * 2 >= pageSize.width || margin * 2 >= pageSize.height)) {
      throw ArgumentError.value(margin, 'margin', 'leaves no room on the page');
    }
    return _platform.imagesToPdf(images, pageSize: pageSize, margin: margin);
  }

  /// Renders PDF pages to images, one per page, in page order.
  ///
  /// [dpi] controls output resolution (72 = 1 px per point). [quality]
  /// (0–100) applies to JPEG only. [pages] selects zero-based page indexes;
  /// null renders every page.
  Future<List<Uint8List>> pdfToImages(
    Uint8List pdf, {
    double dpi = 144,
    ImageFormat format = ImageFormat.png,
    int quality = 90,
    List<int>? pages,
  }) {
    if (dpi <= 0) throw RangeError.value(dpi, 'dpi', 'must be > 0');
    RangeError.checkValueInInterval(quality, 0, 100, 'quality');
    if (pages != null && pages.any((p) => p < 0)) {
      throw ArgumentError.value(pages, 'pages', 'indexes must be >= 0');
    }
    return _platform.pdfToImages(
      pdf,
      dpi: dpi,
      format: format,
      quality: quality,
      pages: pages,
    );
  }

  /// Number of pages in [pdf].
  Future<int> pdfPageCount(Uint8List pdf) => _platform.pdfPageCount(pdf);

  /// File-based wrapper around [imagesToPdf]. Returns the written file.
  Future<File> imageFilesToPdfFile(
    List<String> imagePaths,
    String outputPath, {
    PdfPageSize? pageSize,
    double margin = 0,
  }) async {
    final images = await Future.wait(
      imagePaths.map((p) => File(p).readAsBytes()),
    );
    final pdf = await imagesToPdf(images, pageSize: pageSize, margin: margin);
    return File(outputPath).writeAsBytes(pdf, flush: true);
  }

  /// File-based wrapper around [pdfToImages]. Writes
  /// `<fileNamePrefix>_<pageNumber>.<ext>` (1-based page numbers) into
  /// [outputDirectory], creating it if needed, and returns the files.
  Future<List<File>> pdfFileToImageFiles(
    String pdfPath,
    String outputDirectory, {
    double dpi = 144,
    ImageFormat format = ImageFormat.png,
    int quality = 90,
    List<int>? pages,
    String fileNamePrefix = 'page',
  }) async {
    final pdf = await File(pdfPath).readAsBytes();
    final images = await pdfToImages(
      pdf,
      dpi: dpi,
      format: format,
      quality: quality,
      pages: pages,
    );
    final dir = await Directory(outputDirectory).create(recursive: true);
    final ext = format == ImageFormat.png ? 'png' : 'jpg';
    final indexes = pages ?? List.generate(images.length, (i) => i);
    return Future.wait([
      for (var i = 0; i < images.length; i++)
        File(
          '${dir.path}/${fileNamePrefix}_${indexes[i] + 1}.$ext',
        ).writeAsBytes(images[i], flush: true),
    ]);
  }
}
