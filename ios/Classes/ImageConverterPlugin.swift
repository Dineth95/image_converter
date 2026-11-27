import Flutter
import UIKit

/// Image <-> PDF conversion using CoreGraphics / UIKit's built-in PDF support.
public class ImageConverterPlugin: NSObject, FlutterPlugin {
  private let queue = DispatchQueue(label: "image_converter", qos: .userInitiated)

  private struct ConversionError: Error {
    let code: String
    let message: String
  }

  /// ~ 10000 x 10000 px; beyond this a single RGBA bitmap needs > 400 MB.
  private static let maxPixels: CGFloat = 100_000_000

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "image_converter", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(ImageConverterPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    let task: () throws -> Any
    switch call.method {
    case "imagesToPdf": task = { try self.imagesToPdf(args) }
    case "pdfToImages": task = { try self.pdfToImages(args) }
    case "pdfPageCount": task = { try self.openPdf(args).numberOfPages }
    default:
      result(FlutterMethodNotImplemented)
      return
    }
    queue.async {
      do {
        let value = try autoreleasepool { try task() }
        DispatchQueue.main.async { result(value) }
      } catch let e as ConversionError {
        DispatchQueue.main.async { result(FlutterError(code: e.code, message: e.message, details: nil)) }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "CONVERSION_FAILED", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  // MARK: - image -> pdf

  private func imagesToPdf(_ args: [String: Any]) throws -> FlutterStandardTypedData {
    guard let images = args["images"] as? [FlutterStandardTypedData] else {
      throw ConversionError(code: "INVALID_ARGUMENT", message: "images is required")
    }
    let pageSize = args["pageSize"] as? [String: Double]
    let margin = CGFloat((args["margin"] as? NSNumber)?.doubleValue ?? 0)

    // Decode everything first so a bad image fails before any rendering.
    let decoded: [UIImage] = try images.enumerated().map { index, data in
      // scale 1 => image.size is in pixels, so "fit image" pages are 1 px = 1 pt.
      guard let image = UIImage(data: data.data, scale: 1) else {
        throw ConversionError(code: "INVALID_IMAGE", message: "Image at index \(index) could not be decoded")
      }
      return image
    }

    let renderer = UIGraphicsPDFRenderer(bounds: .zero)
    let pdf = renderer.pdfData { ctx in
      for image in decoded {
        // UIImage.size and draw(in:) already account for EXIF orientation.
        let imgSize = image.size
        let page: CGRect
        let dest: CGRect
        if let ps = pageSize, let w = ps["width"], let h = ps["height"] {
          page = CGRect(x: 0, y: 0, width: w, height: h)
          let box = page.insetBy(dx: margin, dy: margin)
          let scale = min(box.width / imgSize.width, box.height / imgSize.height)
          let size = CGSize(width: imgSize.width * scale, height: imgSize.height * scale)
          dest = CGRect(
            x: (page.width - size.width) / 2, y: (page.height - size.height) / 2,
            width: size.width, height: size.height)
        } else {
          page = CGRect(origin: .zero, size: imgSize)
          dest = page
        }
        ctx.beginPage(withBounds: page, pageInfo: [:])
        image.draw(in: dest)
      }
    }
    return FlutterStandardTypedData(bytes: pdf)
  }

  // MARK: - pdf -> image

  private func openPdf(_ args: [String: Any]) throws -> CGPDFDocument {
    guard let data = args["pdf"] as? FlutterStandardTypedData else {
      throw ConversionError(code: "INVALID_ARGUMENT", message: "pdf is required")
    }
    guard let provider = CGDataProvider(data: data.data as CFData),
          let doc = CGPDFDocument(provider) else {
      throw ConversionError(code: "INVALID_PDF", message: "Not a valid PDF")
    }
    // Encrypted PDFs with an empty user password open fine; others are rejected.
    if doc.isEncrypted && !doc.isUnlocked && !doc.unlockWithPassword("") {
      throw ConversionError(code: "PDF_ENCRYPTED", message: "PDF is password protected")
    }
    return doc
  }

  private func pdfToImages(_ args: [String: Any]) throws -> [FlutterStandardTypedData] {
    let doc = try openPdf(args)
    let dpi = CGFloat((args["dpi"] as? NSNumber)?.doubleValue ?? 144)
    let jpeg = (args["format"] as? String) == "jpeg"
    let quality = CGFloat((args["quality"] as? NSNumber)?.doubleValue ?? 90) / 100
    let count = doc.numberOfPages
    let indexes = (args["pages"] as? [Int]) ?? Array(0..<count)
    for i in indexes where i < 0 || i >= count {
      throw ConversionError(
        code: "INVALID_PAGE", message: "Page index \(i) is out of range (document has \(count) pages)")
    }

    let scale = dpi / 72
    return try indexes.map { index in
      try autoreleasepool {
        // CGPDFDocument pages are 1-based.
        guard let page = doc.page(at: index + 1) else {
          throw ConversionError(code: "INVALID_PAGE", message: "Page \(index) could not be read")
        }
        let box = page.getBoxRect(.cropBox)
        let rotated = abs(page.rotationAngle) % 180 == 90
        let pointSize = rotated ? CGSize(width: box.height, height: box.width) : box.size
        let pixelSize = CGSize(
          width: max(1, (pointSize.width * scale).rounded()),
          height: max(1, (pointSize.height * scale).rounded()))
        if pixelSize.width * pixelSize.height > Self.maxPixels {
          throw ConversionError(
            code: "INVALID_ARGUMENT",
            message: "Page \(index) at \(dpi) dpi is too large (\(Int(pixelSize.width))x\(Int(pixelSize.height)))")
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: pixelSize, format: format).image { ctx in
          let cg = ctx.cgContext
          UIColor.white.setFill()
          cg.fill(CGRect(origin: .zero, size: pixelSize))
          // Flip to PDF's bottom-left origin, scale to pixels, then let
          // CoreGraphics map the crop box (incl. /Rotate) onto the page rect.
          cg.translateBy(x: 0, y: pixelSize.height)
          cg.scaleBy(x: scale, y: -scale)
          cg.concatenate(page.getDrawingTransform(
            .cropBox, rect: CGRect(origin: .zero, size: pointSize), rotate: 0, preserveAspectRatio: true))
          cg.interpolationQuality = .high
          cg.setRenderingIntent(.defaultIntent)
          cg.drawPDFPage(page)
        }
        guard let encoded = jpeg ? image.jpegData(compressionQuality: quality) : image.pngData() else {
          throw ConversionError(code: "CONVERSION_FAILED", message: "Failed to encode page \(index)")
        }
        return FlutterStandardTypedData(bytes: encoded)
      }
    }
  }
}
