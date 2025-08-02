#if os(macOS)
  import ArgumentParser
  import Foundation

  /// Reference: go/macOS-notifications-applescript
  struct Notification {
    // MARK: Command literal templates

    /// Notification template with options format field.
    enum Template {
      static let notification = "osascript -e \'display notification \"%@\"%@\'"
      static let title = " with title \"%@\""
      static let subtitle = " subtitle \"%@\""
    }

    // MARK: - Model Properties

    var message: String = "Toolbox Notification Message"
    var title: String = "Toolbox Notification Title"
    var subtitle: String?

    // MARK: - Computed Properties

    var resolvedTitle: String { String(format: Template.title, title) }

    var resolvedSubtitle: String { String(format: Template.subtitle, subtitle ?? "") }

    var resolvedOptions: String { [resolvedTitle, resolvedSubtitle].joined() }

    var resolvedCommand: String { String(format: Template.notification, message, resolvedOptions) }
  }

  struct Notify: ParsableCommand, ConfiguredShell {
    static let configuration =
      CommandConfiguration(
        commandName: "notify",
        abstract: "⏰| Notify a user with a notification on macOS.",
      )

    // MARK: - Arguments, Options and Flags

    @OptionGroup
    var options: CliKit.Options

    @Argument(help: "The notification to display on macOS.")
    var messageFlag: String

    @Option(help: "The title to be displayed in a notification.")
    var title: String

    @Option(help: "The subtitle to be displayed in a notification.")
    var subtitle: String?

    // MARK: - Invoke Command

    func logArgs() {
      Log.main.info(
        """
        🔬🔬🔬 Display Notification Command Arguments 🔬🔬🔬
        MessageFlag: \(messageFlag)
              Title: \(title)
           Subtitle: \(subtitle ?? "No subtitle set.")
        🔬🔬🔬 Display Notification Command Arguments 🔬🔬🔬
        """)
    }

    func run() throws {
      logArgs()
      let notification = Notification(message: messageFlag, title: title, subtitle: subtitle)
      try configuredShell().input(command: notification.resolvedCommand)
    }
  }
#endif  // os(macOS)
