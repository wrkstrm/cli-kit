struct Du: CLI {

  static var name = "du"

  var shell: Shell

  @discardableResult func size(of filePath: String, detailed: Bool) -> ShellResult {
    detailed ? self.detailed(filePath: filePath) : simple(filePath: filePath)
  }

  @discardableResult fileprivate func detailed(filePath: String) -> ShellResult {
    size(of: filePath, options: "-akc")
  }

  @discardableResult fileprivate func simple(filePath: String) -> ShellResult {
    size(of: filePath, options: "-sk")
  }

  @discardableResult private func size(of filePath: String, options: String) -> ShellResult {
    let shellResult = shell.input(options: options, command: filePath)
    guard case .success(let output) = shellResult else {
      return shellResult
    }
    let sanitizedOutput = output.replacingOccurrences(of: filePath, with: "")
    return .success(sanitizedOutput)
  }
}

extension Shell {

  /// Returns a shell that automatically invokes Disk Usage (`du`) automatically.
  private var du: Du { .init(with: self) }

  @discardableResult func size(of filePath: String, detailed: Bool) -> ShellResult {
    detailed ? du.detailed(filePath: filePath) : du.simple(filePath: filePath)
  }
}
