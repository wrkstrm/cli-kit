import Logging

extension Log {
  fileprivate static let replace = { () -> Logger in
    Logger(label: "refactor.refactor.replace")
  }()
}

extension Refactor {

  struct Replace {

    @discardableResult
    static func run(info: Info) throws -> ShellResult {
      guard let searchTerms = info.step.searchTerms else {
        throw "Step does not include a valid search term."
      }
      Log.replace.info("\(Self.self): '\(searchTerms)'")
      let filePaths: [String] = info.partialResult.split(separator: "\n").map(String.init)
      try filePaths.forEach {
        switch String.replace(filePath: $0, step: info.step) {
        case .failedToLoad(let filePath):
          throw "Could not load source file at \(filePath)"
        case .excluded:
          Log.replace.info("Exclusion term found. No edit at \($0)")
        case .searchTermNotFound:
          throw "No search terms changed in source."
        case .failedToWrite(let path):
          throw "Could not write edited file to \(path)"
        case .edited(_):
          Log.replace.info("Search terms edited at \($0)")
        }
      }
      return .success(info.partialResult)
    }
  }
}
