struct Touch: CLI {

  static var name = "touch"

  var shell: Shell

  @discardableResult func createFile(at filePath: String) -> ShellResult {
    shell.input(command: filePath)
  }
}

extension Shell {

  /// Returns a shell that automatically invokes `touch`.
  private var touch: Touch { .init(with: self) }

  @discardableResult func createFile(at filePath: String) -> ShellResult {
    touch.createFile(at: filePath)
  }
}
