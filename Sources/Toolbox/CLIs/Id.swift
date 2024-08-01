struct Id: CLI {

  static var name = "id"

  var shell: Shell

  @discardableResult func username() -> ShellResult {
    switch shell.input(options: "-un") {
    case .success(let userName):
      return .success(userName.trimmingCharacters(in: .newlines))
    case .failure(let failure):
      return .failure(failure)
    }
  }
}

extension Shell {

  /// Returns a shell that automatically invokes `cp`.
  private var id: Id { .init(with: self) }

  @discardableResult func username() -> ShellResult {
    id.username()
  }
}
