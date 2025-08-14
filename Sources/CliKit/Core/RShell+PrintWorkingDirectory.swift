import Foundation

extension RShell {
  /// Returns the current working directory as reported by the shell.
  public func printWorkingDirectory() throws -> String {
    switch input(command: "pwd") {
    case .success(let output):
      return output.trimmingCharacters(in: .whitespacesAndNewlines)
    case .failure(let error):
      throw error
    }
  }
}
