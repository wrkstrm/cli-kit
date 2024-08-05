struct Rm: CLI {
  static var name = "rm"

  var shell: Shell

  @discardableResult func remove(from deletedItemPath: String) -> ShellResult {
    shell.input(options: "-rf", command: deletedItemPath)
  }
}

extension Shell {
  /// Returns a shell that automatically invokes `rm`.
  private var rm: Rm { .init(with: self) }

  @discardableResult func remove(from deletedItemPath: String) -> ShellResult {
    rm.remove(from: deletedItemPath)
  }
}
