## 0.1.0

* Widgets now use `package:material_ui`, replacing the deprecated `package:flutter/material.dart` (fixes the pub.dev static analysis issues).
* iOS: Swift Package Manager support (`ios/image_converter/Package.swift`); CocoaPods still works. Minimum iOS raised from 12.0 to 13.0.
* Android: migrated to built-in Kotlin (AGP 9) and the Kotlin DSL build script.
* **Breaking:** requires Flutter 3.47+ / Dart 3.13+, which `material_ui` and built-in Kotlin need.

## 0.0.1

* Initial release: `imagesToPdf`, `pdfToImages`, `pdfPageCount`, plus file helpers, for Android and iOS.
* Customisable UI widgets (`ImageConverterView`, `ConverterButton`, `ConversionProgressBar`, `ConversionStatusBanner`, `PdfPagePreview`, `PdfPageGallery`), `ImageConverterController`, and `ImageConverterThemeData` theme variables / `ImageConverterLabels`.
* Two entry points: `image_converter.dart` (core, no UI dependency, works in background isolates) and `image_converter_ui.dart` (core + widgets).
