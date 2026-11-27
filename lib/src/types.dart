/// Encoding used for images rendered from a PDF.
enum ImageFormat { png, jpeg }

/// A PDF page size in PostScript points (1/72 inch).
class PdfPageSize {
  const PdfPageSize(this.width, this.height)
    : assert(width > 0),
      assert(height > 0);

  final double width;
  final double height;

  static const a4 = PdfPageSize(595.28, 841.89);
  static const a5 = PdfPageSize(419.53, 595.28);
  static const letter = PdfPageSize(612, 792);
  static const legal = PdfPageSize(612, 1008);

  /// The same size rotated 90 degrees.
  PdfPageSize get landscape =>
      width >= height ? this : PdfPageSize(height, width);

  Map<String, double> toMap() => {'width': width, 'height': height};

  @override
  bool operator ==(Object other) =>
      other is PdfPageSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'PdfPageSize($width x $height pt)';
}
