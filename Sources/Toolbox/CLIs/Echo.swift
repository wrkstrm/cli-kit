struct Echo: CLI {
  static var name = "echo"

  var shell: Shell

  @discardableResult func echo(string: String) throws -> ShellResult {
    guard
      let final = try? string.split(separator: "\n").reduce(
        into: String(),
        { partialResult, newLine in
          switch shell.input(command: "\(newLine)") {
            case let .success(output):
              partialResult.append(output)

            case let .failure(error):
              throw error
          }
        })
    else {
      throw "Echo failed"
    }
    return .success(final)
  }
}

extension Shell {
  /// Returns a shell that automatically invokes `pwd`.
  private var echo: Echo { .init(with: self) }

  @discardableResult func echo(_ string: String) throws -> ShellResult {
    try echo.echo(string: string)
  }
}
