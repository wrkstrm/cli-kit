import ArgumentParser
import CommonShell

struct Notify: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "notify",
    abstract: "Send a local notification (macOS: osascript; linux: notify-send)."
  )

  @Option(name: .long) var title: String = "CLI"
  @Argument var message: String

  func run() async throws {
    #if os(macOS)
    let script = "display notification \"\(message)\" with title \"\(title)\""
    let shell = CommonShell(executable: .path("/usr/bin/osascript"))
    _ = try await shell.launch(options: ["-e", script])
    #else
    let shell = CommonShell(executable: .name("env"))
    _ = try await shell.launch(options: ["notify-send", title, message])
    #endif
  }
}
