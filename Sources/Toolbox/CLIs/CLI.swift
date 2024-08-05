public protocol CLI {
  static var name: String { get }

  var shell: Shell { get }

  init(shell: Shell)

  init(with shell: Shell)
}

extension CLI {
  init(with shell: Shell) {
    var shell = shell
    shell.cli = Self.name
    self.init(shell: shell)
  }
}
