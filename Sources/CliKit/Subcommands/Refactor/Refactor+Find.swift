import Foundation
import Logging

extension Log {
  fileprivate static let find = { () -> Logger in
    Logger(label: "refactor.refactor.find")
  }()
}

extension Refactor {
  enum Find {
    @discardableResult
    static func run(info: Info) throws -> ShellResult {
      guard let searchTerms = info.step.searchTerms else {
        throw CliKitError.message("Step does not include a valid search term.")
      }
      Log.find.info("\(Self.self): '\(searchTerms)'")
      var filePaths: [String] = []
      for resolvedSearchPath in info.resolvedSearchPaths {
        guard
          let contents = try? Refactor.fileManager.subpathsOfDirectory(atPath: resolvedSearchPath),
          var sourceFilePaths = contents.sourceFiles
        else {
          throw CliKitError.message("Could not find directories at \(resolvedSearchPath)")
        }

        sourceFilePaths.removeAll { sourceFilePath in
          // swiftlint:disable:next contains_over_first_not_nil
          (info.step.exclusionTerms ?? []).first { exclusionPrefix in
            sourceFilePath.hasPrefix(exclusionPrefix)
          } != nil ? true : false
        }
        for fileSuffix in sourceFilePaths {
          let sourceFilePath = [resolvedSearchPath, fileSuffix].joined(separator: "/")
          guard let source = try? String(contentsOfFile: sourceFilePath) else {
            throw CliKitError.message("Could not load source file at \(sourceFilePath)")
          }
          for searchTerm in searchTerms where source.contains(searchTerm) {
            filePaths.append(sourceFilePath)
            break
          }
          let limit = info.step.limit ?? Int.max
          guard filePaths.count < limit else {
            return .success(filePaths.joined(separator: "\n"))
          }
        }
      }
      guard !filePaths.isEmpty else { throw CliKitError.message("Could not find \(searchTerms) in \(info.resolvedSearchPaths)") }
      Log.find.info("\(Self.self): Found \(filePaths.count) files containing term.")
      return .success(filePaths.joined(separator: "\n"))
    }
  }
}
