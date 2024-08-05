struct Cat: CLI {
  static var name = "cat"

  var shell: Shell

  @discardableResult func concatonate(files filePaths: [String]) -> ShellResult {
    shell.input(command: filePaths.joined(separator: " "))
  }
}

extension Shell {
  /// Returns a shell that automatically invokes `cat`.
  private var cat: Cat { .init(with: self) }

  @discardableResult func concatonate(files filePaths: [String]) -> ShellResult {
    cat.concatonate(files: filePaths)
  }
}
