import ArgumentParser
import XCTest

@testable import CliKit

final class ToolboxTests: XCTestCase {
  func testOptions() {
    XCTAssertNotNil("Test")
  }

  static var allTests = [
    ("testOptions", testOptions)
  ]
}
