import Foundation
import Logging

extension Log {
  fileprivate static let format = { () -> Logger in
    Logger(label: "refactor.refactor.format")
  }()
}

extension Refactor {
  enum Format {
    @discardableResult
    static func run(info: Info) throws -> ShellResult {
      Log.format.info("\(Self.self)")
      guard !info.partialResult.isEmpty else {
        throw "\(type(of: Self.self)) cannot be the first step."
      }
      for resolvedSearchPath in info.resolvedSearchPaths {
        let shell = RShell(path: URL(fileURLWithPath: resolvedSearchPath, isDirectory: true))
        let filePaths: [String] = info.partialResult.split(separator: "\n").map(String.init)
        // TODO: Format
      }
      return .success(info.partialResult)
    }
  }
}
