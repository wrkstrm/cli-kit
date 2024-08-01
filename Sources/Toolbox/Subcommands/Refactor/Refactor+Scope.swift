import Logging

extension Log {
  fileprivate static let scope = { () -> Logger in
    Logger(label: "refactor.refactor.scope")
  }()
}

extension Refactor {
  struct Scope {

    @discardableResult
    static func run(info: Info) throws -> ShellResult {
      guard let searchTerms = info.step.searchTerms else {
        throw "Step does not include a valid search term."
      }
      Log.scope.info("\(Self.self): '\(searchTerms)'")
      let reduction = searchTerms.reduce(into: "") { $0 += $1 + " " }
        .trimmingCharacters(in: .whitespaces)
      Log.scope.info("Final scopes: \(reduction)")
      return .success(reduction)
    }
  }
}
