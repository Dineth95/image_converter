import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

import 'labels.dart';

/// Every visual variable used by the image_converter widgets.
///
/// All fields are optional. Anything left null falls back to a value derived
/// from the app's [ThemeData] (colour scheme and text theme), so the widgets
/// match the host app out of the box and dark mode works automatically.
///
/// Provide it either app-wide as a theme extension:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(extensions: const [
///     ImageConverterThemeData(primaryColor: Colors.teal),
///   ]),
/// )
/// ```
///
/// or for a subtree with [ImageConverterTheme]. Values resolve in this order
/// (first non-null wins): widget constructor argument → nearest
/// [ImageConverterTheme] → [ThemeData] extension → defaults.
@immutable
class ImageConverterThemeData extends ThemeExtension<ImageConverterThemeData> {
  const ImageConverterThemeData({
    // Colours
    this.primaryColor,
    this.onPrimaryColor,
    this.secondaryColor,
    this.onSecondaryColor,
    this.backgroundColor,
    this.surfaceColor,
    this.onSurfaceColor,
    this.mutedColor,
    this.borderColor,
    this.errorColor,
    this.errorContainerColor,
    this.successColor,
    this.successContainerColor,
    this.progressColor,
    this.progressTrackColor,
    this.pageBackgroundColor,
    // Text
    this.buttonTextStyle,
    this.statusTextStyle,
    this.pageLabelTextStyle,
    this.emptyTextStyle,
    // Shape & spacing
    this.borderRadius,
    this.buttonBorderRadius,
    this.buttonPadding,
    this.buttonMinHeight,
    this.contentPadding,
    this.spacing,
    this.borderWidth,
    this.pageElevation,
    this.pagePadding,
    this.progressHeight,
    this.iconSize,
    // Icons
    this.imagesToPdfIcon,
    this.pdfToImagesIcon,
    this.successIcon,
    this.errorIcon,
    this.emptyIcon,
    // Text content
    this.labels,
  });

  /// Main action colour (primary button, progress bar default).
  final Color? primaryColor;

  /// Content (text/icon) colour on [primaryColor].
  final Color? onPrimaryColor;

  /// Secondary action colour.
  final Color? secondaryColor;

  /// Content colour on [secondaryColor].
  final Color? onSecondaryColor;

  /// Background of [ImageConverterView].
  final Color? backgroundColor;

  /// Background of neutral status banners and other panels.
  final Color? surfaceColor;

  /// Text/icon colour on [surfaceColor].
  final Color? onSurfaceColor;

  /// De-emphasised text and icons (empty state, page captions).
  final Color? mutedColor;

  /// Outline around page previews.
  final Color? borderColor;

  /// Error text/icon colour.
  final Color? errorColor;

  /// Background of error banners.
  final Color? errorContainerColor;

  /// Success text/icon colour.
  final Color? successColor;

  /// Background of success banners.
  final Color? successContainerColor;

  final Color? progressColor;
  final Color? progressTrackColor;

  /// Fill behind a rendered page (PDF pages are usually white).
  final Color? pageBackgroundColor;

  final TextStyle? buttonTextStyle;
  final TextStyle? statusTextStyle;
  final TextStyle? pageLabelTextStyle;
  final TextStyle? emptyTextStyle;

  /// Corner radius of banners and page previews.
  final BorderRadius? borderRadius;
  final BorderRadius? buttonBorderRadius;
  final EdgeInsetsGeometry? buttonPadding;
  final double? buttonMinHeight;

  /// Outer padding of [ImageConverterView].
  final EdgeInsetsGeometry? contentPadding;

  /// Gap between buttons, sections and gallery items.
  final double? spacing;

  /// Width of the page-preview outline. 0 hides it.
  final double? borderWidth;
  final double? pageElevation;

  /// Inner padding between a page preview's border and the image.
  final EdgeInsetsGeometry? pagePadding;
  final double? progressHeight;
  final double? iconSize;

  final IconData? imagesToPdfIcon;
  final IconData? pdfToImagesIcon;
  final IconData? successIcon;
  final IconData? errorIcon;
  final IconData? emptyIcon;

  final ImageConverterLabels? labels;

  /// Fully-populated defaults derived from the ambient [ThemeData].
  factory ImageConverterThemeData.fallback(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    return ImageConverterThemeData(
      primaryColor: cs.primary,
      onPrimaryColor: cs.onPrimary,
      secondaryColor: cs.secondaryContainer,
      onSecondaryColor: cs.onSecondaryContainer,
      backgroundColor: cs.surface,
      surfaceColor: cs.surfaceContainerHigh,
      onSurfaceColor: cs.onSurface,
      mutedColor: cs.onSurfaceVariant,
      borderColor: cs.outlineVariant,
      errorColor: cs.onErrorContainer,
      errorContainerColor: cs.errorContainer,
      successColor: cs.onPrimaryContainer,
      successContainerColor: cs.primaryContainer,
      progressColor: cs.primary,
      progressTrackColor: cs.primaryContainer,
      pageBackgroundColor: Colors.white,
      buttonTextStyle: tt.labelLarge,
      statusTextStyle: tt.bodyMedium,
      pageLabelTextStyle: tt.labelSmall,
      emptyTextStyle: tt.bodyMedium,
      borderRadius: BorderRadius.circular(12),
      buttonBorderRadius: BorderRadius.circular(24),
      buttonPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      buttonMinHeight: 44,
      contentPadding: const EdgeInsets.all(16),
      spacing: 12,
      borderWidth: 1,
      pageElevation: 1,
      pagePadding: EdgeInsets.zero,
      progressHeight: 4,
      iconSize: 20,
      imagesToPdfIcon: Icons.picture_as_pdf_outlined,
      pdfToImagesIcon: Icons.image_outlined,
      successIcon: Icons.check_circle_outline,
      errorIcon: Icons.error_outline,
      emptyIcon: Icons.photo_library_outlined,
      labels: const ImageConverterLabels(),
    );
  }

  /// Returns a copy where every non-null field of [other] replaces this one's.
  ImageConverterThemeData merge(ImageConverterThemeData? other) {
    if (other == null) return this;
    return copyWith(
      primaryColor: other.primaryColor,
      onPrimaryColor: other.onPrimaryColor,
      secondaryColor: other.secondaryColor,
      onSecondaryColor: other.onSecondaryColor,
      backgroundColor: other.backgroundColor,
      surfaceColor: other.surfaceColor,
      onSurfaceColor: other.onSurfaceColor,
      mutedColor: other.mutedColor,
      borderColor: other.borderColor,
      errorColor: other.errorColor,
      errorContainerColor: other.errorContainerColor,
      successColor: other.successColor,
      successContainerColor: other.successContainerColor,
      progressColor: other.progressColor,
      progressTrackColor: other.progressTrackColor,
      pageBackgroundColor: other.pageBackgroundColor,
      buttonTextStyle:
          buttonTextStyle?.merge(other.buttonTextStyle) ??
          other.buttonTextStyle,
      statusTextStyle:
          statusTextStyle?.merge(other.statusTextStyle) ??
          other.statusTextStyle,
      pageLabelTextStyle:
          pageLabelTextStyle?.merge(other.pageLabelTextStyle) ??
          other.pageLabelTextStyle,
      emptyTextStyle:
          emptyTextStyle?.merge(other.emptyTextStyle) ?? other.emptyTextStyle,
      borderRadius: other.borderRadius,
      buttonBorderRadius: other.buttonBorderRadius,
      buttonPadding: other.buttonPadding,
      buttonMinHeight: other.buttonMinHeight,
      contentPadding: other.contentPadding,
      spacing: other.spacing,
      borderWidth: other.borderWidth,
      pageElevation: other.pageElevation,
      pagePadding: other.pagePadding,
      progressHeight: other.progressHeight,
      iconSize: other.iconSize,
      imagesToPdfIcon: other.imagesToPdfIcon,
      pdfToImagesIcon: other.pdfToImagesIcon,
      successIcon: other.successIcon,
      errorIcon: other.errorIcon,
      emptyIcon: other.emptyIcon,
      labels: other.labels,
    );
  }

  @override
  ImageConverterThemeData copyWith({
    Color? primaryColor,
    Color? onPrimaryColor,
    Color? secondaryColor,
    Color? onSecondaryColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? onSurfaceColor,
    Color? mutedColor,
    Color? borderColor,
    Color? errorColor,
    Color? errorContainerColor,
    Color? successColor,
    Color? successContainerColor,
    Color? progressColor,
    Color? progressTrackColor,
    Color? pageBackgroundColor,
    TextStyle? buttonTextStyle,
    TextStyle? statusTextStyle,
    TextStyle? pageLabelTextStyle,
    TextStyle? emptyTextStyle,
    BorderRadius? borderRadius,
    BorderRadius? buttonBorderRadius,
    EdgeInsetsGeometry? buttonPadding,
    double? buttonMinHeight,
    EdgeInsetsGeometry? contentPadding,
    double? spacing,
    double? borderWidth,
    double? pageElevation,
    EdgeInsetsGeometry? pagePadding,
    double? progressHeight,
    double? iconSize,
    IconData? imagesToPdfIcon,
    IconData? pdfToImagesIcon,
    IconData? successIcon,
    IconData? errorIcon,
    IconData? emptyIcon,
    ImageConverterLabels? labels,
  }) {
    return ImageConverterThemeData(
      primaryColor: primaryColor ?? this.primaryColor,
      onPrimaryColor: onPrimaryColor ?? this.onPrimaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      onSecondaryColor: onSecondaryColor ?? this.onSecondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      onSurfaceColor: onSurfaceColor ?? this.onSurfaceColor,
      mutedColor: mutedColor ?? this.mutedColor,
      borderColor: borderColor ?? this.borderColor,
      errorColor: errorColor ?? this.errorColor,
      errorContainerColor: errorContainerColor ?? this.errorContainerColor,
      successColor: successColor ?? this.successColor,
      successContainerColor:
          successContainerColor ?? this.successContainerColor,
      progressColor: progressColor ?? this.progressColor,
      progressTrackColor: progressTrackColor ?? this.progressTrackColor,
      pageBackgroundColor: pageBackgroundColor ?? this.pageBackgroundColor,
      buttonTextStyle: buttonTextStyle ?? this.buttonTextStyle,
      statusTextStyle: statusTextStyle ?? this.statusTextStyle,
      pageLabelTextStyle: pageLabelTextStyle ?? this.pageLabelTextStyle,
      emptyTextStyle: emptyTextStyle ?? this.emptyTextStyle,
      borderRadius: borderRadius ?? this.borderRadius,
      buttonBorderRadius: buttonBorderRadius ?? this.buttonBorderRadius,
      buttonPadding: buttonPadding ?? this.buttonPadding,
      buttonMinHeight: buttonMinHeight ?? this.buttonMinHeight,
      contentPadding: contentPadding ?? this.contentPadding,
      spacing: spacing ?? this.spacing,
      borderWidth: borderWidth ?? this.borderWidth,
      pageElevation: pageElevation ?? this.pageElevation,
      pagePadding: pagePadding ?? this.pagePadding,
      progressHeight: progressHeight ?? this.progressHeight,
      iconSize: iconSize ?? this.iconSize,
      imagesToPdfIcon: imagesToPdfIcon ?? this.imagesToPdfIcon,
      pdfToImagesIcon: pdfToImagesIcon ?? this.pdfToImagesIcon,
      successIcon: successIcon ?? this.successIcon,
      errorIcon: errorIcon ?? this.errorIcon,
      emptyIcon: emptyIcon ?? this.emptyIcon,
      labels: labels ?? this.labels,
    );
  }

  @override
  ImageConverterThemeData lerp(
    covariant ImageConverterThemeData? other,
    double t,
  ) {
    if (other == null) return this;
    T? snap<T>(T? a, T? b) => t < 0.5 ? a : b;
    return ImageConverterThemeData(
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t),
      onPrimaryColor: Color.lerp(onPrimaryColor, other.onPrimaryColor, t),
      secondaryColor: Color.lerp(secondaryColor, other.secondaryColor, t),
      onSecondaryColor: Color.lerp(onSecondaryColor, other.onSecondaryColor, t),
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t),
      onSurfaceColor: Color.lerp(onSurfaceColor, other.onSurfaceColor, t),
      mutedColor: Color.lerp(mutedColor, other.mutedColor, t),
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      errorColor: Color.lerp(errorColor, other.errorColor, t),
      errorContainerColor: Color.lerp(
        errorContainerColor,
        other.errorContainerColor,
        t,
      ),
      successColor: Color.lerp(successColor, other.successColor, t),
      successContainerColor: Color.lerp(
        successContainerColor,
        other.successContainerColor,
        t,
      ),
      progressColor: Color.lerp(progressColor, other.progressColor, t),
      progressTrackColor: Color.lerp(
        progressTrackColor,
        other.progressTrackColor,
        t,
      ),
      pageBackgroundColor: Color.lerp(
        pageBackgroundColor,
        other.pageBackgroundColor,
        t,
      ),
      buttonTextStyle: TextStyle.lerp(
        buttonTextStyle,
        other.buttonTextStyle,
        t,
      ),
      statusTextStyle: TextStyle.lerp(
        statusTextStyle,
        other.statusTextStyle,
        t,
      ),
      pageLabelTextStyle: TextStyle.lerp(
        pageLabelTextStyle,
        other.pageLabelTextStyle,
        t,
      ),
      emptyTextStyle: TextStyle.lerp(emptyTextStyle, other.emptyTextStyle, t),
      borderRadius: BorderRadius.lerp(borderRadius, other.borderRadius, t),
      buttonBorderRadius: BorderRadius.lerp(
        buttonBorderRadius,
        other.buttonBorderRadius,
        t,
      ),
      buttonPadding: EdgeInsetsGeometry.lerp(
        buttonPadding,
        other.buttonPadding,
        t,
      ),
      buttonMinHeight: lerpDouble(buttonMinHeight, other.buttonMinHeight, t),
      contentPadding: EdgeInsetsGeometry.lerp(
        contentPadding,
        other.contentPadding,
        t,
      ),
      spacing: lerpDouble(spacing, other.spacing, t),
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t),
      pageElevation: lerpDouble(pageElevation, other.pageElevation, t),
      pagePadding: EdgeInsetsGeometry.lerp(pagePadding, other.pagePadding, t),
      progressHeight: lerpDouble(progressHeight, other.progressHeight, t),
      iconSize: lerpDouble(iconSize, other.iconSize, t),
      imagesToPdfIcon: snap(imagesToPdfIcon, other.imagesToPdfIcon),
      pdfToImagesIcon: snap(pdfToImagesIcon, other.pdfToImagesIcon),
      successIcon: snap(successIcon, other.successIcon),
      errorIcon: snap(errorIcon, other.errorIcon),
      emptyIcon: snap(emptyIcon, other.emptyIcon),
      labels: snap(labels, other.labels),
    );
  }

  List<Object?> get _props => [
    primaryColor,
    onPrimaryColor,
    secondaryColor,
    onSecondaryColor,
    backgroundColor,
    surfaceColor,
    onSurfaceColor,
    mutedColor,
    borderColor,
    errorColor,
    errorContainerColor,
    successColor,
    successContainerColor,
    progressColor,
    progressTrackColor,
    pageBackgroundColor,
    buttonTextStyle,
    statusTextStyle,
    pageLabelTextStyle,
    emptyTextStyle,
    borderRadius,
    buttonBorderRadius,
    buttonPadding,
    buttonMinHeight,
    contentPadding,
    spacing,
    borderWidth,
    pageElevation,
    pagePadding,
    progressHeight,
    iconSize,
    imagesToPdfIcon,
    pdfToImagesIcon,
    successIcon,
    errorIcon,
    emptyIcon,
    labels,
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ImageConverterThemeData) return false;
    final a = _props, b = other._props;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_props);
}

/// Applies an [ImageConverterThemeData] to the widgets below it.
///
/// Fields left null inherit from any enclosing [ImageConverterTheme], then the
/// [ThemeData] extension, then the defaults.
class ImageConverterTheme extends StatelessWidget {
  const ImageConverterTheme({
    super.key,
    required this.data,
    required this.child,
  });

  final ImageConverterThemeData data;
  final Widget child;

  /// The fully-resolved theme for [context]: every field is non-null.
  static ImageConverterThemeData of(BuildContext context) {
    final local = context
        .dependOnInheritedWidgetOfExactType<_InheritedImageConverterTheme>()
        ?.data;
    return ImageConverterThemeData.fallback(context)
        .merge(Theme.of(context).extension<ImageConverterThemeData>())
        .merge(local);
  }

  @override
  Widget build(BuildContext context) {
    final parent = context
        .dependOnInheritedWidgetOfExactType<_InheritedImageConverterTheme>()
        ?.data;
    return _InheritedImageConverterTheme(
      data: parent?.merge(data) ?? data,
      child: child,
    );
  }
}

class _InheritedImageConverterTheme extends InheritedTheme {
  const _InheritedImageConverterTheme({
    required this.data,
    required super.child,
  });

  final ImageConverterThemeData data;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      _InheritedImageConverterTheme(data: data, child: child);

  @override
  bool updateShouldNotify(_InheritedImageConverterTheme oldWidget) =>
      data != oldWidget.data;
}
