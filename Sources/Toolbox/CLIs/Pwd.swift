struct Pwd: CLI {
  static var name = "pwd"

  var shell: Shell

  @discardableResult func run() -> String {
    switch shell.input() {
      case let .success(directory):
        return directory.trimmingCharacters(in: .whitespacesAndNewlines)

      case let .failure(error):
        Log.main.error("\(error)")
        return ""
    }
  }
}

extension Shell {
  /// Returns a shell that automatically invokes `pwd`.
  private var pwd: Pwd { .init(with: self) }

  @discardableResult func printWorkingDirectory() -> String { pwd.run() }
}
