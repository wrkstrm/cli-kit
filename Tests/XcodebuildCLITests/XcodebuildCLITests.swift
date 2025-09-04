import XCTest

final class XcodebuildCLITests: XCTestCase {
  func testStubLogFile() throws {
    let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
      "xcodebuild-cli-stub.txt")
    try "stub-log".write(to: tmp, atomically: true, encoding: .utf8)
    XCTAssertTrue(FileManager.default.fileExists(atPath: tmp.path))
  }
}
