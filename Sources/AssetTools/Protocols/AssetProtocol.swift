import Foundation

public protocol AssetProtocol {
  /// A `Codable`instance of the `Contents.json`
  /// file used for generating an assets folder structure.
  associatedtype Contents: AssetContents
  var contents: Contents { get set }
  func write(to path: String, with name: String) throws
}

extension AssetProtocol {
  public static var encoder: JSONEncoder { JSONEncoder() }
  public static var decoder: JSONDecoder { JSONDecoder() }
}
