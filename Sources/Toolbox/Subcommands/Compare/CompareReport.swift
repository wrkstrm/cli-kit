import ArgumentParser
import Foundation

struct CompareReport: ParsableCommand, ConfiguredShell {
  // MARK: CommandConfiguration

  static let configuration =
    CommandConfiguration(
      abstract: "🧾| Creates a report comparing two app builds.",
      helpNames: .shortAndLong
    )

  // MARK: - OptionGroups, Arguments, Options and Flags

  @OptionGroup var options: Toolbox.Options

  @Argument(help: "The name of the report.")
  var reportName: String

  @Argument(help: "Where to output the report.")
  var outputPath: String

  @Argument(help: "The path to iGMM with flags disabled.")
  var oldAppPath: String

  @Argument(help: "The path to iGMM with flags enabled.")
  var newAppPath: String

  @Flag(help: "Detailed Output")
  var detailed: Bool = false

  func run() throws {
    let shell = try configuredShell()
    guard
      case let .success(disabledReport) = shell.size(
        of: oldAppPath + ".app", detailed: detailed
      ),
      case let .success(enabledReport) = shell.size(of: newAppPath + ".app", detailed: detailed)
    else {
      throw "Could not create reports"
    }
    if detailed {
      try ComparisonReport.detailed(
        named: reportName, in: outputPath, disabledSizeReport: disabledReport,
        enabledSizeReport: enabledReport
      )
    } else {
      try ComparisonReport.summary(
        named: reportName, disabledSizeReport: disabledReport, enabledSizeReport: enabledReport
      )
    }
  }
}
