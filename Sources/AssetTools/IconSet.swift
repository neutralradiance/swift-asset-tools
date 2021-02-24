import Files
import Foundation
import Light
import PNG

/// A `Codable` representation of an`AppIcon.appiconset` folder
/// structure used to create an icon set within an app bundle.
public struct IconSet {
  public var contents: Contents = .standard
  public var icons: [String: PNG.Data.Rectangular] = [:]
  /// A color-based icon set.
  public init?<Color>(color: Color) where Color: ColorCodable {
    for image in contents.images {
      guard
        let name = image.filename,
        icons[name] == nil
      else { break }
      let fill = (
        UInt8(color.red * 255),
        UInt8(color.green * 255),
        UInt8(color.blue * 255)
      )
      let pixels =
        [PNG.RGBA<UInt8>](
          repeating:
          PNG.RGBA(
            fill.0,
            fill.1,
            fill.2,
            UInt8(color.alpha * 255)
          ),
          count: image.pixelCount
        )
      let size = (x: image.width, y: image.height)
      icons[name] =
        PNG.Data.Rectangular(
          packing: pixels,
          size: size,
          layout:
          .init(format: .rgba8(palette: [], fill: .none)
          )
        )
      debugPrint("Created icon named: \(name)")
      continue
    }
  }
}

extension IconSet: AssetProtocol {
  // MARK: Types
  public struct Contents: AssetContents {
    public var images: [Image] = [
      // MARK: iPhone
      .image(of: 40, for: .iphone, scale: 2),
      .image(of: 60, for: .iphone, scale: 3),
      .image(of: 29, for: .iphone),
      .image(of: 58, for: .iphone, scale: 2),
      .image(of: 87, for: .iphone, scale: 3),
      .image(of: 80, for: .iphone, scale: 2),
      .image(of: 120, for: .iphone, scale: 3),
      .image(of: 57, for: .iphone),
      .image(of: 114, for: .iphone, scale: 2),
      .image(of: 120, for: .iphone, scale: 2),
      .image(of: 180, for: .iphone, scale: 3),
      // MARK: iPad
      .image(of: 20, for: .ipad),
      .image(of: 40, for: .ipad, scale: 2),
      .image(of: 29, for: .ipad),
      .image(of: 58, for: .ipad, scale: 2),
      .image(of: 40, for: .ipad),
      .image(of: 80, for: .ipad, scale: 2),
      .image(of: 50, for: .ipad),
      .image(of: 100, for: .ipad, scale: 2),
      .image(of: 72, for: .ipad),
      .image(of: 144, for: .ipad, scale: 2),
      .image(of: 76, for: .ipad),
      .image(of: 152, for: .ipad, scale: 2),
      .image(of: 167, for: .ipad, scale: 2),
      // MARK: Marketing
      .image(of: 1024, for: .iosMarketing)
    ]
    public var info = AssetInfo()
    public static var standard: Self { Self() }
  }

  public struct Image: Hashable, Encodable {
    var filename: String? = .none,
        idiom: String = AssetIdiom.universal.rawValue,
        role: String? = .none,
        scale: String = "1x",
        size: String,
        subtype: String? = .none
    public static func image(
      of size: Int,
      for idiom: AssetIdiom,
      role: Role? = .none,
      scale: Int = 1,
      subtype: Subtype? = .none
    ) -> Self {
      let scaledSize = size / scale
      return
        self.init(
          filename: "\(size).png",
          idiom: idiom.rawValue,
          role: role?.rawValue ?? nil,
          scale: "\(scale)x",
          size: "\(scaledSize)x\(scaledSize)",
          subtype: subtype?.rawValue ?? nil
        )
    }

    public var width: Int {
      guard
        let first = size.components(separatedBy: "x").first,
        let size = Int(first)
      else { return 0 }
      return size * Int(actualScale)
    }

    public var height: Int { width }

    public var actualScale: Float {
      guard
        let first = scale.components(separatedBy: "x").first,
        let intValue = Int(first)
      else { return 0 }
      return Float(intValue)
    }

    public var pixelCount: Int {
      width * height
    }
  }

  public enum Role: String, Encodable {
    case
      notificationCenter,
      companionSettings,
      appLauncher,
      quickLook
  }

  public enum Subtype: String, Encodable {
    case _42mm = "42mm", _44mm = "44mm"
  }

  // MARK: Functions
  public func write(
    to path: String,
    with name: String = "AppIcon.iconset"
  ) throws {
    do {
      guard
        let baseURL = URL(string: path)
      else { throw POSIXError(.ENOTDIR) }
      let contentsData = try Self.encoder.encode(contents)
      do {
        let baseFolder = try Folder(path: baseURL.absoluteString)
        let subFolder = try baseFolder.createSubfolderIfNeeded(at: name)
        try subFolder.createFile(at: "Contents.json", contents: contentsData)
        for (name, image) in icons {
          do {
            let path = subFolder.path + name
            try image.compress(path: subFolder.path + name, level: 0)
            debugPrint("Saved icon to path: \(path)")
          } catch {
            debugPrint(error.localizedDescription)
          }
          continue
        }
      } catch let error as FilesError<String> {
        debugPrint(error.description)
      }
    } catch {
      debugPrint(error.localizedDescription)
    }
  }
}

#if canImport(SwiftUI)
  import SwiftUI
  #if os(iOS)
    extension PNG.Data.Rectangular {
      func compress(
        path: String,
        level: Int = 9,
        hint: Int = 1 << 15
      ) throws {
        try iOSByteStreamDestination.open(path: path) {
          try self.compress(stream: &$0, level: level, hint: hint)
        }
      }
    }

    struct iOSByteStreamDestination: _PNGBytestreamDestination {
      let descriptor: UnsafeMutablePointer<FILE>
      public static func open<R>(
        path: String,
        _ body: (inout Self) throws -> R
      ) rethrows -> R? {
        guard
          let descriptor: UnsafeMutablePointer<FILE> = fopen(path, "wb")
        else { return nil }
        var file: Self = .init(descriptor: descriptor)
        defer { fclose(file.descriptor) }
        return try body(&file)
      }

      mutating func write(_ buffer: [UInt8]) -> Void? {
        let count: Int = buffer.withUnsafeBufferPointer {
          fwrite(
            $0.baseAddress,
            MemoryLayout<UInt8>.stride,
            $0.count, self.descriptor
          )
        }
        guard count == buffer.count
        else { return nil }
        return ()
      }
    }
  #endif
  @available(iOS 13.0, macOS 10.13, *)
  public extension IconSet {
    static func accent() -> Self? {
      guard
        let accentColor = NativeColor(named: "AccentColor")?.light
      else { return nil }
      return Self(color: accentColor)
    }

    /// Replaces an `AppIcon.appiconset` folder in a bundle's `Assets.xcassets`.
    func replace(in bundle: Bundle) throws {
      guard
        let basePath =
        bundle.url(
          forResource: "Assets",
          withExtension: "xcassets",
          subdirectory: "AppIcon.appiconset"
        )
      else { throw POSIXError(.ENOENT) }
      try write(to: basePath.absoluteString)
    }
  }
#endif
