extension Refactor {

  struct AddImport {

    @discardableResult
    static func run(info: Info) throws -> ShellResult {
      guard let searchTerms = info.step.searchTerms else {
        throw "Step does not include a valid search term."
      }
      Log.main.info("\(Self.self): '\(searchTerms)'")
      guard !info.partialResult.isEmpty else {
        throw "Add Import cannot be the first step."
      }
      let filePaths: [String] = info.partialResult.split(separator: "\n").map(String.init)
      for filePath in filePaths {
        guard let source = try? String(contentsOfFile: filePath) else {
          throw "Could not load source file at \(filePath)"
        }

        let containsExclussionTerm =
          info.step.exclusionTerms?.reduce(
            into: Bool(false),
            { reducedResult, term in
              if source.contains(term) {
                reducedResult = true
              }
            }) ?? false
        if !containsExclussionTerm {
          for searchTerm in searchTerms where !source.contains(searchTerm) {
            var base = searchTerm + "\n"
            base.append(contentsOf: source)
            guard let _ = try? base.write(toFile: filePath, atomically: true, encoding: .utf8)
            else {
              continue
            }
          }
        }
      }
      return .success(info.partialResult)
    }
  }

  struct RemoveImport {

    @discardableResult
    static func run(info: Info) throws -> ShellResult {
      guard let searchTerms = info.step.searchTerms else {
        throw "Step does not include a valid search term."
      }
      Log.main.info("\(Self.self): '\(searchTerms)'")
      guard !info.partialResult.isEmpty else {
        throw "Remove Import cannot be the first step."
      }
      let filePaths: [String] = info.partialResult.split(separator: "\n").map(String.init)
      for filePath in filePaths {
        guard let source = try? String(contentsOfFile: filePath) else {
          throw "Could not load source file at \(filePath)"
        }
        for searchTerm in searchTerms where source.contains(searchTerm) {
          let containsExclussionTerm =
            info.step.exclusionTerms?.reduce(
              into: Bool(false),
              { reducedResult, term in
                if source.contains(term) {
                  reducedResult = true
                }
              }) ?? false
          if !containsExclussionTerm {
            let cleanedUpSource = source.replacingOccurrences(of: searchTerm, with: "")
            guard
              let _ = try? cleanedUpSource.write(
                toFile: filePath,
                atomically: true,
                encoding: .utf8)
            else {
              continue
            }
          }
        }
      }
      return .success(info.partialResult)
    }
  }
}
