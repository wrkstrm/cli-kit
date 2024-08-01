struct Rsync: CLI {

  static var name = "rsync"

  var shell: Shell

  @discardableResult func copy(from fromFilePath: String, to toFilePath: String) -> ShellResult {
    shell.input(options: "-a", command: [fromFilePath, toFilePath].joined(separator: " "))
  }
}

extension Shell {

  /// Returns a shell that automatically invokes `rsync`.
  private var rsync: Rsync { .init(with: self) }

  @discardableResult func rsync(from fromFilePath: String, to toFilePath: String) -> ShellResult {
    rsync.copy(from: fromFilePath, to: toFilePath)
  }
}
