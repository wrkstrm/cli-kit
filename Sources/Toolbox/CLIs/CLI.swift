public protocol CLI {
  static var name: String { get }

  var shell: Shell { get }

  init(shell: Shell)

  public init(with shell: Shell)
}

public extension CLI {
  public init(with shell: Shell) {
    var shell = shell
    shell.cli = Self.name
    self.init(shell: shell)
  }
}
