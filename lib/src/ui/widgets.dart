import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'theme.dart';

/// Visual weight of a [ConverterButton].
enum ConverterButtonVariant { primary, secondary }

/// A themed action button with a built-in loading state.
///
/// Every argument overrides the matching [ImageConverterThemeData] value;
/// [style] is merged on top of everything for full control.
class ConverterButton extends StatelessWidget {
  const ConverterButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.variant = ConverterButtonVariant.primary,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
    this.padding,
    this.borderRadius,
    this.minHeight,
    this.iconSize,
    this.style,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  /// Shows a spinner in place of the icon and disables the button.
  final bool isLoading;
  final ConverterButtonVariant variant;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? minHeight;
  final double? iconSize;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = ImageConverterTheme.of(context);
    final primary = variant == ConverterButtonVariant.primary;
    final bg =
        backgroundColor ?? (primary ? t.primaryColor! : t.secondaryColor!);
    final fg =
        foregroundColor ?? (primary ? t.onPrimaryColor! : t.onSecondaryColor!);
    final size = iconSize ?? t.iconSize!;

    final base = FilledButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      disabledBackgroundColor: bg.withValues(alpha: isLoading ? 0.7 : 0.38),
      disabledForegroundColor: fg.withValues(alpha: isLoading ? 0.9 : 0.6),
      textStyle: t.buttonTextStyle!.merge(textStyle),
      padding: padding ?? t.buttonPadding,
      minimumSize: Size(0, minHeight ?? t.buttonMinHeight!),
      iconSize: size,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? t.buttonBorderRadius!,
      ),
    );

    final leading = isLoading
        ? SizedBox.square(
            dimension: size * 0.8,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : (icon == null ? null : Icon(icon));

    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: style?.merge(base) ?? base,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 8)],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      enabled: !isLoading && onPressed != null,
      child: button,
    );
  }
}

/// A themed linear progress bar. Pass [value] for determinate progress.
class ConversionProgressBar extends StatelessWidget {
  const ConversionProgressBar({
    super.key,
    this.value,
    this.color,
    this.trackColor,
    this.height,
    this.borderRadius,
    this.semanticsLabel,
  });

  final double? value;

  /// Screen-reader label; defaults to [ImageConverterLabels.converting].
  final String? semanticsLabel;
  final Color? color;
  final Color? trackColor;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final t = ImageConverterTheme.of(context);
    final h = height ?? t.progressHeight!;
    return LinearProgressIndicator(
      value: value,
      semanticsLabel: semanticsLabel ?? t.labels!.converting,
      minHeight: h,
      color: color ?? t.progressColor,
      backgroundColor: trackColor ?? t.progressTrackColor,
      borderRadius: borderRadius ?? BorderRadius.circular(h / 2),
    );
  }
}

/// Kind of message shown by [ConversionStatusBanner].
enum StatusType { info, success, error }

/// A themed banner for status / result / error messages.
class ConversionStatusBanner extends StatelessWidget {
  const ConversionStatusBanner({
    super.key,
    required this.message,
    this.type = StatusType.info,
    this.icon,
    this.showIcon = true,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
    this.padding,
    this.borderRadius,
    this.iconSize,
    this.trailing,
  });

  final String message;
  final StatusType type;

  /// Defaults to the theme's success/error icon; info has no default icon.
  final IconData? icon;
  final bool showIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? iconSize;

  /// Optional widget at the end, e.g. a dismiss or share button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = ImageConverterTheme.of(context);
    final (bg, fg, defaultIcon) = switch (type) {
      StatusType.success => (
        t.successContainerColor!,
        t.successColor!,
        t.successIcon,
      ),
      StatusType.error => (t.errorContainerColor!, t.errorColor!, t.errorIcon),
      StatusType.info => (t.surfaceColor!, t.onSurfaceColor!, null),
    };
    final fgColor = foregroundColor ?? fg;
    final iconData = icon ?? defaultIcon;

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? bg,
          borderRadius: borderRadius ?? t.borderRadius,
        ),
        child: Padding(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              if (showIcon && iconData != null) ...[
                Icon(iconData, color: fgColor, size: iconSize ?? t.iconSize),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: SelectableText(
                  message,
                  style: t.statusTextStyle!
                      .copyWith(color: fgColor)
                      .merge(textStyle),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// A single rendered page (or any image) in a themed card with a caption.
class PdfPagePreview extends StatelessWidget {
  const PdfPagePreview({
    super.key,
    required this.bytes,
    this.pageNumber,
    this.showLabel = true,
    this.label,
    this.onTap,
    this.fit = BoxFit.contain,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.elevation,
    this.padding,
    this.labelStyle,
    this.semanticLabel,
  });

  /// Encoded image bytes (PNG/JPEG).
  final Uint8List bytes;

  /// 1-based page number used for the default caption.
  final int? pageNumber;
  final bool showLabel;

  /// Replaces the default caption entirely.
  final Widget? label;
  final VoidCallback? onTap;
  final BoxFit fit;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final BorderRadius? borderRadius;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final TextStyle? labelStyle;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = ImageConverterTheme.of(context);
    final width = borderWidth ?? t.borderWidth!;
    final caption =
        label ??
        (pageNumber == null
            ? null
            : Text(
                t.labels!.page(pageNumber!),
                textAlign: TextAlign.center,
                style: t.pageLabelTextStyle!
                    .copyWith(color: t.mutedColor)
                    .merge(labelStyle),
              ));

    final card = Material(
      color: backgroundColor ?? t.pageBackgroundColor,
      elevation: elevation ?? t.pageElevation!,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? t.borderRadius!,
        side: width > 0
            ? BorderSide(color: borderColor ?? t.borderColor!, width: width)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? t.pagePadding!,
          child: Image.memory(
            bytes,
            fit: fit,
            gaplessPlayback: true,
            semanticLabel:
                semanticLabel ??
                (pageNumber == null ? null : t.labels!.page(pageNumber!)),
          ),
        ),
      ),
    );

    // In a bounded slot (e.g. a grid cell) the page shrinks to leave room for
    // the caption; in an unbounded one (e.g. a list) it takes its natural size.
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          constraints.hasBoundedHeight ? Flexible(child: card) : card,
          if (showLabel && caption != null) ...[
            SizedBox(height: t.spacing! / 2),
            caption,
          ],
        ],
      ),
    );
  }
}

/// How [PdfPageGallery] lays out pages.
enum PdfGalleryLayout { list, grid }

/// Signature for building one gallery item.
typedef PdfPageItemBuilder =
    Widget Function(BuildContext context, int index, Uint8List bytes);

/// A scrollable list or grid of page images, with an empty state.
class PdfPageGallery extends StatelessWidget {
  const PdfPageGallery({
    super.key,
    required this.pages,
    this.layout = PdfGalleryLayout.list,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.64,
    this.spacing,
    this.padding,
    this.itemBuilder,
    this.emptyBuilder,
    this.onPageTap,
    this.showPageLabels = true,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<Uint8List> pages;
  final PdfGalleryLayout layout;

  /// Grid columns ([PdfGalleryLayout.grid] only).
  final int crossAxisCount;

  /// Grid cell width / height ([PdfGalleryLayout.grid] only).
  final double childAspectRatio;
  final double? spacing;
  final EdgeInsetsGeometry? padding;

  /// Replaces the default [PdfPagePreview] for each page.
  final PdfPageItemBuilder? itemBuilder;

  /// Replaces the default empty state.
  final WidgetBuilder? emptyBuilder;
  final void Function(int index, Uint8List bytes)? onPageTap;
  final bool showPageLabels;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final t = ImageConverterTheme.of(context);
    if (pages.isEmpty) {
      return emptyBuilder?.call(context) ?? const _EmptyGallery();
    }
    final gap = spacing ?? t.spacing!;

    Widget item(BuildContext context, int i) =>
        itemBuilder?.call(context, i, pages[i]) ??
        PdfPagePreview(
          bytes: pages[i],
          pageNumber: i + 1,
          showLabel: showPageLabels,
          onTap: onPageTap == null ? null : () => onPageTap!(i, pages[i]),
        );

    return switch (layout) {
      PdfGalleryLayout.list => ListView.separated(
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemCount: pages.length,
        separatorBuilder: (_, _) => SizedBox(height: gap),
        itemBuilder: item,
      ),
      PdfGalleryLayout.grid => GridView.builder(
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemCount: pages.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: item,
      ),
    };
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery();

  @override
  Widget build(BuildContext context) {
    final t = ImageConverterTheme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(t.spacing! * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(t.emptyIcon, size: t.iconSize! * 2.4, color: t.mutedColor),
            SizedBox(height: t.spacing),
            Text(
              t.labels!.empty,
              textAlign: TextAlign.center,
              style: t.emptyTextStyle!.copyWith(color: t.mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}
