import Files
import Light
#if os(iOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

public struct ColorSet {
  public var contents: Contents = .standard
}

extension ColorSet: AssetProtocol, Codable {
  // MARK: Types
  public struct Contents: AssetContents, Codable {
    public var colors: [ColorContext] = []
    public var info = AssetInfo()
    public static var standard: Self { Self() }
  }

  public struct Color: Codable {
    public var colorSpace: ColorSpace = .srgb
    public var components = Components()
    public struct Components: Codable {
      var alpha: Double = 1
      var blue: Double = 1
      var green: Double = 1
      var red: Double = 1
    }

    enum CodingKeys: String, CodingKey {
      case
        colorSpace = "color-space",
        components
    }
  }

  public enum ColorSpace: String, Codable {
    case srgb
  }

  public struct ColorContext: Codable {
    var color = Color()
    var idiom: AssetIdiom = .universal
  }

  // MARK: Functions
  public func write(to path: String, with name: String) throws {
    guard
      let baseURL = URL(string: path)?.appendingPathComponent(name)
    else { throw POSIXError(.ENOTDIR) }
    let data = try Self.encoder.encode(contents)
    do {
      let baseFolder = try Folder(path: baseURL.absoluteString)
      try baseFolder.createFile(named: "Contents.json", contents: data)
    } catch let error as FilesError<String> {
      debugPrint(error.description)
    }
  }
}

#if canImport(SwiftUI)
  import SwiftUI
  public extension ColorSet {
    init(_ color: Light) {
      let components =
        Color.Components(
          alpha: color.alpha,
          blue: color.blue,
          green: color.green,
          red: color.red
        )
      let context =
        ColorContext(
          color: Color(components: components)
        )
      self.init(
        contents: Contents(colors: [context])
      )
    }

    /// Replaces a `colorset` folder in a bundle's `Assets.xcassets`.
    func replace(in bundle: Bundle, with name: String = "AccentColor") throws {
      guard
        let basePath = bundle.path(forResource: name, ofType: "colorset")
      else { throw POSIXError(.ENOENT) }
      try write(to: basePath, with: "\(name).colorset")
    }
  }
#endif
