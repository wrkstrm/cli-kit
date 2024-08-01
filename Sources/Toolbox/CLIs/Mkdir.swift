struct Mkdir: CLI {

  static var name = "mkdir"

  var shell: Shell

  @discardableResult func createFolder(at filePath: String) -> ShellResult {
    shell.input(options: "-p", command: filePath)
  }
}

extension Shell {

  /// Returns a shell that automatically invokes `mkdir`.
  private var mkdir: Mkdir { .init(with: self) }

  @discardableResult func createFolder(at filePath: String) -> ShellResult {
    mkdir.createFolder(at: filePath)
  }
}
