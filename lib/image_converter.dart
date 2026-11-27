/// Core image <-> PDF conversion API, with no UI.
///
/// Uses the platform's native PDF engines (Android `PdfDocument` /
/// `PdfRenderer`, iOS CoreGraphics). This library imports nothing from
/// Flutter's widget or Material layers, so it is safe to use in apps without
/// the bundled widgets, in services, and in background isolates.
///
/// For the ready-made widgets and theme, import
/// `package:image_converter/image_converter_ui.dart` instead (it re-exports
/// everything here).
library;

export 'src/controller.dart';
export 'src/converter.dart';
export 'src/types.dart';
