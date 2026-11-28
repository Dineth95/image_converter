import 'package:flutter/foundation.dart';

import 'converter.dart';
import 'types.dart';

/// Where a conversion run is.
enum ConversionState { idle, converting, success, error }

/// Which direction the last conversion went.
enum ConversionKind { imagesToPdf, pdfToImages }

/// Runs conversions and holds their result for the UI widgets.
///
/// It only depends on `package:flutter/foundation.dart`, so it works with
/// any state-management approach and with no widgets at all. The bundled
/// `ImageConverterView` (from `image_converter_ui.dart`) can also use one.
class ImageConverterController extends ChangeNotifier {
  /// [converter] defaults to `const ImageConverter()`; pass your own to
  /// customise or fake it.
  ImageConverterController({this._converter = const ImageConverter()});

  final ImageConverter _converter;
  bool _disposed = false;

  ConversionState _state = ConversionState.idle;
  ConversionKind? _kind;
  Object? _error;
  Uint8List? _pdf;
  List<Uint8List> _pages = const [];

  ConversionState get state => _state;
  ConversionKind? get kind => _kind;
  bool get isConverting => _state == ConversionState.converting;

  /// The last error, when [state] is [ConversionState.error].
  Object? get error => _error;

  /// The PDF produced by the last images → PDF run.
  Uint8List? get pdf => _pdf;

  /// Page images: the rendered PDF pages after PDF → images, or a preview of
  /// the new PDF after images → PDF (when previews are enabled).
  List<Uint8List> get pages => _pages;

  /// Converts [images] to a PDF. Returns null if it failed (see [error]).
  ///
  /// When [previewDpi] is non-null the new PDF is also rendered at that
  /// resolution into [pages] so it can be shown in a gallery.
  Future<Uint8List?> imagesToPdf(
    List<Uint8List> images, {
    PdfPageSize? pageSize,
    double margin = 0,
    double? previewDpi = 72,
  }) {
    return _run(ConversionKind.imagesToPdf, () async {
      final pdf = await _converter.imagesToPdf(
        images,
        pageSize: pageSize,
        margin: margin,
      );
      final previews = previewDpi == null
          ? const <Uint8List>[]
          : await _converter.pdfToImages(pdf, dpi: previewDpi);
      _pdf = pdf;
      _pages = previews;
      return pdf;
    });
  }

  /// Renders [pdf] to images. Returns null if it failed (see [error]).
  Future<List<Uint8List>?> pdfToImages(
    Uint8List pdf, {
    double dpi = 144,
    ImageFormat format = ImageFormat.png,
    int quality = 90,
    List<int>? pages,
  }) {
    return _run(ConversionKind.pdfToImages, () async {
      final images = await _converter.pdfToImages(
        pdf,
        dpi: dpi,
        format: format,
        quality: quality,
        pages: pages,
      );
      _pdf = null;
      _pages = images;
      return images;
    });
  }

  /// Clears results and returns to [ConversionState.idle].
  void reset() {
    _state = ConversionState.idle;
    _kind = null;
    _error = null;
    _pdf = null;
    _pages = const [];
    _notify();
  }

  Future<T?> _run<T>(ConversionKind kind, Future<T> Function() task) async {
    _state = ConversionState.converting;
    _kind = kind;
    _error = null;
    _notify();
    try {
      final result = await task();
      _state = ConversionState.success;
      return result;
    } catch (e) {
      _state = ConversionState.error;
      _error = e;
      return null;
    } finally {
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
