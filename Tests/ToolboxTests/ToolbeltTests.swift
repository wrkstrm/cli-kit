import ArgumentParser
import XCTest

@testable import Toolbox

final class ToolboxTests: XCTestCase {

  func testOptions() {
    XCTAssertNotNil("Test")
  }

  static var allTests = [
    ("testOptions", testOptions)
  ]
}
