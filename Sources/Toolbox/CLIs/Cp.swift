struct Cp: CLI {
  static var name = "cp"

  var shell: Shell

  @discardableResult func copy(from initialPath: String, to destinationPath: String) -> ShellResult
  {
    shell.input(command: [initialPath, destinationPath].joined(separator: " "))
  }
}

extension Shell {
  /// Returns a shell that automatically invokes `cp`.
  private var cp: Cp { .init(with: self) }

  @discardableResult func cp(from initialPath: String, to destinationPath: String) -> ShellResult {
    cp.copy(from: initialPath, to: destinationPath)
  }
}
