public struct Swiftlint: CLI {
  public static var name = "swiftlint"

  public var shell: Shell

  @discardableResult func lint(_ files: [String]) -> String {
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
  /// Returns a shell that automatically invokes `swiftlint`.
  private var swiftlint: Swiftlint { .init(with: self) }

  @discardableResult func swiftlint(files: [String]) -> String {
    swiftlint.lint(files)
  }
}
