import Dependencies
import Foundation
import RBKit
import os

let logger = Logger()

public struct FrecencyStore<Key: FrecencyID>: Sendable {
  @Dependency(\.diskClient) var diskClient

  public init(url: URL?) {
    self.url = url
  }

  public mutating func load() throws {
    guard let url else { return }
    let data = try diskClient.read(sourceURL: url)
    items = try decoder.decode(FrecencyCollection<Key>.self, from: data)
  }

  public func save() throws {
    guard let url else { return }
    let data = try encoder.encode(items)
    try diskClient.write(data: data, destinationURL: url, options: [])
  }

  public mutating func add(_ value: Key, query: String? = nil, timestamp: Date = .now) {
    items.add(entry: value, query: query, timestamp: timestamp)
  }

  public func score(for item: Key) -> FrecencyScore {
    items.score(for: item)
  }

  // MARK: Private

  public private(set) var items = FrecencyCollection<Key>()
  private var url: URL?
  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

  public static func defaultURL() -> URL? {
    @Dependency(\.bundleClient) var bundleClient
    @Dependency(\.urlClient) var urlClient
    @Dependency(\.fileManagerClient) var fileManagerClient

    let applicationSupportDirectory = urlClient.applicationSupportDirectory()

    guard let selfBundleId = bundleClient.bundleIdentifier(bundle: bundleClient.main()) else {
      logger.log("Failed to get self bundle identifier")
      return nil
    }

    let parentDir = applicationSupportDirectory.appending(
      component: selfBundleId, directoryHint: .isDirectory)

    do {
      try fileManagerClient.createDirectory(
        atURL: parentDir, withIntermediateDirectories: true, attributes: nil)
    } catch {
      logger.log("Failed to create the application support directory, error: \(error)")
      return nil
    }

    return parentDir.appending(component: "recents", directoryHint: .notDirectory)
      .appendingPathExtension("json")
  }
}
