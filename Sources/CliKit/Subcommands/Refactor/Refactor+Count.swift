import SwiftShell

extension Refactor {
  enum Count {
    @discardableResult
    static func run(info: Info) throws -> ShellResult {
      guard let searchTerms = info.step.searchTerms else {
        throw CliKitError.message("Step does not include a valid search term.")
      }
      Log.main.info("\(Self.self): '\(searchTerms)'")
      guard !info.partialResult.isEmpty else {
        throw CliKitError.message("Count cannot be the first step.")
      }
      let filePaths: [String] = info.partialResult.split(separator: "\n").map(String.init)
      var counted: [String] = []
      try filePaths.forEach { filePath in
        guard let source = try? String(contentsOfFile: filePath) else {
          throw CliKitError.message("Could not load source file at \(filePath)")
        }
        let count = searchTerms.reduce(into: 0) { $0 += source.count(of: $1) }
        counted.append("\(searchTerms) : \(count)\t\(filePath)")
      }
      return .success(counted.joined(separator: "\n"))
    }
  }
}
