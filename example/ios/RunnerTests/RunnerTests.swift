import Flutter
import UIKit
import XCTest

@testable import image_converter

class RunnerTests: XCTestCase {

  private func call(_ method: String, _ args: [String: Any]) -> Any? {
    let plugin = ImageConverterPlugin()
    let done = expectation(description: "result block must be called.")
    var value: Any?
    plugin.handle(FlutterMethodCall(methodName: method, arguments: args)) { result in
      value = result
      done.fulfill()
    }
    waitForExpectations(timeout: 10)
    return value
  }

  func testImageToPdfAndBack() {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1  // 40x20 pixels, not 40x20 points at screen scale
    let png = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 20), format: format).pngData { ctx in
      UIColor.red.setFill()
      ctx.fill(CGRect(x: 0, y: 0, width: 40, height: 20))
    }
    let pdf = call("imagesToPdf", [
      "images": [FlutterStandardTypedData(bytes: png), FlutterStandardTypedData(bytes: png)],
      "margin": 0,
    ]) as! FlutterStandardTypedData

    XCTAssertEqual(call("pdfPageCount", ["pdf": pdf]) as? Int, 2)

    let pages = call("pdfToImages", [
      "pdf": pdf, "dpi": 144.0, "format": "png", "quality": 90, "pages": [1],
    ]) as! [FlutterStandardTypedData]
    XCTAssertEqual(pages.count, 1)
    let image = UIImage(data: pages[0].data)!
    XCTAssertEqual(image.size.width * image.scale, 80)
    XCTAssertEqual(image.size.height * image.scale, 40)
  }

  func testInvalidPdf() {
    let result = call("pdfPageCount", ["pdf": FlutterStandardTypedData(bytes: Data([1, 2, 3]))])
    XCTAssertEqual((result as? FlutterError)?.code, "INVALID_PDF")
  }
}
