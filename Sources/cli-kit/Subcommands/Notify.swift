import ArgumentParser
import CliKitNotifications

struct Notify: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "notify",
    abstract: "Send a local notification (macOS: osascript; linux: notify-send)."
  )

  @Option(name: .long) var title: String = "CLI"
  @Argument var message: String

  func run() throws {
    Task {
      _ = await WrkstrmCLINotify.send(.init(title: title, message: message))
    }
  }
}
