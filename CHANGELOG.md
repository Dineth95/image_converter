## 0.0.1

* Initial release: `imagesToPdf`, `pdfToImages`, `pdfPageCount`, plus file helpers, for Android and iOS.
* Customisable UI widgets (`ImageConverterView`, `ConverterButton`, `ConversionProgressBar`, `ConversionStatusBanner`, `PdfPagePreview`, `PdfPageGallery`), `ImageConverterController`, and `ImageConverterThemeData` theme variables / `ImageConverterLabels`.
* Two entry points: `image_converter.dart` (core, no UI dependency, works in background isolates) and `image_converter_ui.dart` (core + widgets).
