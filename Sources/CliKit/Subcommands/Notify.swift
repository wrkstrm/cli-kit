import ArgumentParser
import CliKitNotifications
import Foundation

struct Notify: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "notify",
    abstract: "Send a local desktop notification (best-effort)."
  )

  @Argument(help: "Notification message body.")
  var message: String

  @Option(name: .customLong("title"), help: "Notification title (default: Task Complete)")
  var title: String = "Task Complete"

  @Option(name: .customLong("subtitle"), help: "Notification subtitle")
  var subtitle: String?

  @Option(name: .customLong("sound"), help: "Sound name (macOS only; e.g., default, Ping)")
  var sound: String?

  @Flag(name: .customLong("quiet"), help: "Suppress stderr fallback when delivery fails")
  var quiet: Bool = false

  @Flag(name: .customLong("json"), help: "Emit JSON with platform, command, status, fallbackUsed")
  var json: Bool = false

  func run() async throws {
    let payload = WrkstrmCLINotify.Payload(
      title: title,
      message: message,
      subtitle: subtitle,
      sound: sound,
      urgency: nil
    )
    let result = await WrkstrmCLINotify.send(payload)

    if json {
      if let encoded = try? WrkstrmCLINotify.json(result) {
        print(encoded)
      }
      return
    }

    if result.status != 0, !quiet {
      let command = result.command.joined(separator: " ")
      print("[notify] failed (status=\(result.status)) on \(result.platform): \(command)")
    }
  }
}
