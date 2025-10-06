import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {
  // This is a basic test to ensure the app can be loaded.
  func testAppCanLoad() {
    XCTAssertNotNil(UIApplication.shared.delegate as? AppDelegate)
  }
}
