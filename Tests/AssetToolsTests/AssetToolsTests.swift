@testable import AssetTools
@testable import Light
import XCTest

final class AssetToolsTests: XCTestCase {
  func testWrite() throws {
    let iconSet =
      IconSet(
        color:
        Light(red: 0, green: 150, blue: 255, alpha: 1)
      )
//    try iconSet?.write(to: "")
  }
}
