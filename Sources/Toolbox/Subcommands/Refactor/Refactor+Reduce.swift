extension Refactor {
  mutating func reduce(steps: [Step]) throws -> String {
    return try steps.reduce(into: String()) { partialResult, step in
      guard let type = step.typeEnumValue() else {
        throw "Could not parse type: \(step.type) for \(step)"
      }
      switch type {
      case .scope:
        guard
          case .success(let scope) = try? Scope.run(
            info: (
              partialResult: partialResult, step: step, resolvedSearchPaths: resolvedSearchPaths
            ))
        else {
          throw "Scope could not find \(step.searchTerms ?? [""]) in \(resolvedSearchPaths)"
        }
        searchPaths = scope.components(separatedBy: .whitespaces).map { String($0) }
      case .find:
        guard
          case .success(let result) = try? Find.run(
            info: (
              partialResult: partialResult,
              step: step,
              resolvedSearchPaths: resolvedSearchPaths
            ))
        else {
          throw "Find could not find \(step.searchTerms ?? [""]) in \(resolvedSearchPaths)"
        }
        partialResult = result
      case .count:
        guard
          case .success(let result) = try? Count.run(
            info: (
              partialResult: partialResult,
              step: step,
              resolvedSearchPaths: resolvedSearchPaths
            ))
        else {
          throw "Could not count at \(resolvedSearchPaths)"
        }
        partialResult = result
        Log.main.info("\(partialResult)")
      case .replace:
        guard
          case .success(let result) = try? Replace.run(
            info: (
              partialResult: partialResult,
              step: step,
              resolvedSearchPaths: resolvedSearchPaths
            ))
        else {
          throw "Could not complete replace at \(resolvedSearchPaths)"
        }
        partialResult = result
      case .addImport:
        try AddImport.run(
          info: (
            partialResult: partialResult,
            step: step,
            resolvedSearchPaths: resolvedSearchPaths
          ))
      case .removeImport:
        try RemoveImport.run(
          info: (
            partialResult: partialResult,
            step: step,
            resolvedSearchPaths: resolvedSearchPaths
          ))
      case .loadScubaTests:
        guard
          case .success(let result) = try? LoadScubaTests.run(
            info: (
              partialResult: partialResult,
              step: step,
              resolvedSearchPaths: resolvedSearchPaths
            ))
        else {
          throw "\(type) could not find \(step.searchTerms ?? ["ERROR"]) in \(resolvedSearchPaths)"
        }
        partialResult = result
      case .approveScubaTests:
        guard
          case .success(let result) = try? ApproveScubaTests.run(
            info: (
              partialResult: partialResult,
              step: step,
              resolvedSearchPaths: resolvedSearchPaths
            ))
        else {
          throw "\(type) could not parse \(partialResult) in \(resolvedSearchPaths)"
        }
        partialResult = result
      case .format:
        try Format.run(
          info: (
            partialResult: partialResult,
            step: step,
            resolvedSearchPaths: resolvedSearchPaths
          ))
      case .prebuild:
        try PrebuildReminder.run(
          info: (
            partialResult: partialResult,
            step: step,
            resolvedSearchPaths: resolvedSearchPaths
          ))
      }
    }
  }
}
