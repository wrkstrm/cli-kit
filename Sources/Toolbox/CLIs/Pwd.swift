struct Pwd: CLI {

  static var name = "pwd"

  var shell: Shell

  @discardableResult func run() -> String {
    switch shell.input() {
    case .success(let directory):
      return directory.trimmingCharacters(in: .whitespacesAndNewlines)
    case .failure(let error):
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
