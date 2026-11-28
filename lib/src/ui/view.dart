import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../types.dart';
import '../controller.dart';
import 'theme.dart';
import 'widgets.dart';

/// Picks images for conversion. Return null or an empty list to cancel.
typedef ImagePickCallback = Future<List<Uint8List>?> Function();

/// Picks a PDF for conversion. Return null to cancel.
typedef PdfPickCallback = Future<Uint8List?> Function();

/// Builds one section of [ImageConverterView] from the controller state.
typedef ConverterSectionBuilder = Widget Function(
  BuildContext context,
  ImageConverterController controller,
);

/// A ready-made converter screen: action buttons, progress, status message
/// and a gallery of the resulting pages.
///
/// The plugin doesn't depend on any file picker. Supply [onPickImages]
/// and/or [onPickPdf] with your own (e.g. `file_picker`, `image_picker`). A
/// button only shows when its callback is set.
///
/// Customise it in three layers:
/// 1. [theme] (or an [ImageConverterTheme] / `ThemeData` extension above it)
///    for colours, text, shapes, spacing, icons and labels;
/// 2. the layout options (`galleryLayout`, `galleryColumns`, ...);
/// 3. the `*Builder` callbacks to replace any section entirely.
///
/// Must be given a bounded height (e.g. a `Scaffold` body); the gallery fills
/// the remaining space.
class ImageConverterView extends StatefulWidget {
  const ImageConverterView({
    super.key,
    this.onPickImages,
    this.onPickPdf,
    this.controller,
    this.theme,
    this.pageSize,
    this.margin = 0,
    this.previewDpi = 72,
    this.pdfDpi = 144,
    this.imageFormat = ImageFormat.png,
    this.quality = 90,
    this.onPdfCreated,
    this.onImagesCreated,
    this.onError,
    this.onPageTap,
    this.galleryLayout = PdfGalleryLayout.list,
    this.galleryColumns = 2,
    this.showStatus = true,
    this.header,
    this.actionsBuilder,
    this.progressBuilder,
    this.statusBuilder,
    this.galleryBuilder,
    this.pageItemBuilder,
    this.emptyBuilder,
  });

  final ImagePickCallback? onPickImages;
  final PdfPickCallback? onPickPdf;

  /// Supply one to read results or trigger conversions from outside.
  final ImageConverterController? controller;

  /// Overrides for this view only, layered over any ambient theme.
  final ImageConverterThemeData? theme;

  /// Page size for images → PDF. Null makes each page match its image.
  final PdfPageSize? pageSize;
  final double margin;

  /// Resolution of the preview rendered after images → PDF. Null skips it.
  final double? previewDpi;

  /// Resolution for PDF → images.
  final double pdfDpi;
  final ImageFormat imageFormat;
  final int quality;

  final ValueChanged<Uint8List>? onPdfCreated;
  final ValueChanged<List<Uint8List>>? onImagesCreated;
  final ValueChanged<Object>? onError;
  final void Function(int index, Uint8List bytes)? onPageTap;

  final PdfGalleryLayout galleryLayout;
  final int galleryColumns;
  final bool showStatus;

  /// Optional widget above the action buttons.
  final Widget? header;

  /// Replaces the row of action buttons. Call the controller (or your own
  /// pickers) from it.
  final ConverterSectionBuilder? actionsBuilder;

  /// Replaces the progress indicator (only built while converting).
  final ConverterSectionBuilder? progressBuilder;

  /// Replaces the status banner (only built after a run finishes).
  final ConverterSectionBuilder? statusBuilder;

  /// Replaces the whole gallery.
  final ConverterSectionBuilder? galleryBuilder;

  /// Replaces each page card in the default gallery.
  final PdfPageItemBuilder? pageItemBuilder;

  /// Replaces the default gallery's empty state.
  final WidgetBuilder? emptyBuilder;

  @override
  State<ImageConverterView> createState() => _ImageConverterViewState();
}

class _ImageConverterViewState extends State<ImageConverterView> {
  ImageConverterController? _ownController;

  ImageConverterController get _controller =>
      widget.controller ?? (_ownController ??= ImageConverterController());

  @override
  void didUpdateWidget(ImageConverterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && _ownController != null) {
      _ownController!.dispose();
      _ownController = null;
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  Future<void> _imagesToPdf() async {
    final images = await widget.onPickImages!();
    if (images == null || images.isEmpty || !mounted) return;
    final pdf = await _controller.imagesToPdf(
      images,
      pageSize: widget.pageSize,
      margin: widget.margin,
      previewDpi: widget.previewDpi,
    );
    _report(pdf, widget.onPdfCreated);
  }

  Future<void> _pdfToImages() async {
    final pdf = await widget.onPickPdf!();
    if (pdf == null || !mounted) return;
    final images = await _controller.pdfToImages(
      pdf,
      dpi: widget.pdfDpi,
      format: widget.imageFormat,
      quality: widget.quality,
    );
    _report(images, widget.onImagesCreated);
  }

  void _report<T>(T? result, ValueChanged<T>? onSuccess) {
    if (!mounted) return;
    if (result != null) {
      onSuccess?.call(result);
    } else if (_controller.error != null) {
      widget.onError?.call(_controller.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => _buildBody(context),
    );
    return widget.theme == null
        ? view
        : ImageConverterTheme(data: widget.theme!, child: view);
  }

  Widget _buildBody(BuildContext context) {
    final t = ImageConverterTheme.of(context);
    final c = _controller;
    final gap = t.spacing!;
    final finished =
        c.state == ConversionState.success || c.state == ConversionState.error;

    return ColoredBox(
      color: t.backgroundColor!,
      child: Padding(
        padding: t.contentPadding!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.header != null) ...[
              widget.header!,
              SizedBox(height: gap),
            ],
            widget.actionsBuilder?.call(context, c) ?? _defaultActions(t, c),
            SizedBox(height: gap),
            // Reserve the bar's height so content doesn't jump.
            SizedBox(
              height: t.progressHeight,
              child: c.isConverting
                  ? (widget.progressBuilder?.call(context, c) ??
                        const ConversionProgressBar())
                  : null,
            ),
            if (widget.showStatus && finished) ...[
              SizedBox(height: gap),
              widget.statusBuilder?.call(context, c) ?? _defaultStatus(t, c),
            ],
            SizedBox(height: gap),
            Expanded(
              child:
                  widget.galleryBuilder?.call(context, c) ??
                  PdfPageGallery(
                    pages: c.pages,
                    layout: widget.galleryLayout,
                    crossAxisCount: widget.galleryColumns,
                    itemBuilder: widget.pageItemBuilder,
                    emptyBuilder: widget.emptyBuilder,
                    onPageTap: widget.onPageTap,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultActions(
    ImageConverterThemeData t,
    ImageConverterController c,
  ) {
    final labels = t.labels!;
    return Wrap(
      spacing: t.spacing!,
      runSpacing: t.spacing!,
      children: [
        if (widget.onPickImages != null)
          ConverterButton(
            label: labels.imagesToPdf,
            icon: t.imagesToPdfIcon,
            isLoading: c.isConverting && c.kind == ConversionKind.imagesToPdf,
            onPressed: c.isConverting ? null : _imagesToPdf,
          ),
        if (widget.onPickPdf != null)
          ConverterButton(
            label: labels.pdfToImages,
            icon: t.pdfToImagesIcon,
            variant: ConverterButtonVariant.secondary,
            isLoading: c.isConverting && c.kind == ConversionKind.pdfToImages,
            onPressed: c.isConverting ? null : _pdfToImages,
          ),
      ],
    );
  }

  Widget _defaultStatus(ImageConverterThemeData t, ImageConverterController c) {
    final labels = t.labels!;
    if (c.state == ConversionState.error) {
      return ConversionStatusBanner(
        message: labels.error(c.error!),
        type: StatusType.error,
      );
    }
    final message = c.kind == ConversionKind.imagesToPdf
        ? labels.pdfCreated(c.pages.length, c.pdf?.lengthInBytes ?? 0)
        : labels.imagesCreated(c.pages.length);
    return ConversionStatusBanner(message: message, type: StatusType.success);
  }
}
