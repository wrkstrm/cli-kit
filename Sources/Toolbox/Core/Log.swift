import Logging

/// The applications logging name space.
enum Log {
  static let main = { () -> Logger in
    Logger(label: "refactor.main")
  }()
}
