#if os(macOS)
import ArgumentParser
import CliKitNotifications
import Foundation

struct Notify: AsyncParsableCommand {
  static let configuration =
    CommandConfiguration(
      commandName: "notify",
      abstract: "⏰| Notify a user with a notification on macOS.",
    )

  // MARK: - Arguments, Options and Flags

  @Argument(help: "The notification to display on macOS.")
  var messageFlag: String

  @Option(help: "The title to be displayed in a notification.")
  var title: String

  @Option(help: "The subtitle to be displayed in a notification.")
  var subtitle: String?

  // MARK: - Invoke Command

  func run() async throws {
    _ = await WrkstrmCLINotify.send(
      .init(title: title, message: messageFlag, subtitle: subtitle, sound: nil, urgency: nil)
    )
  }
}
#endif  // os(macOS)
