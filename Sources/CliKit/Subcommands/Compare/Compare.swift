import ArgumentParser
import CommonShell
import CommonShellArguments
import Foundation

struct Compare: ParsableCommand, ConfiguredShell {
  // MARK: CommandConfiguration

  static let configuration =
    CommandConfiguration(
      commandName: "compare",
      _superCommandName: "tb",
      abstract: "🔃| Compare build sizes by build flag.",
    )

  // MARK: - Output Creatation Literals

  func resolvedOutputPath() throws -> String {
    guard let output = options.output else {
      throw CliKitError.message("Output required. Could not resolve final save path")
    }
    return "\(output)/Compare"
  }

  // MARK: - OptionGroups, Arguments, Options and Flags

  @OptionGroup var options: CliKit.Options

  @Flag(name: .customLong("detailed", withSingleDash: true), help: "Detailed Output")
  var detailed: Bool = false

  func logArgs() {
    Log.main.info(
      """
      🔬🔬🔬 Compare Arguments 🔬🔬🔬
      Detailed Report: \(detailed ? "Yes." : "No.")
      Output Directory: \(options.output ?? "None.")
      Resolved Report Output Directory: \(try! resolvedOutputPath())
      🔬🔬🔬 Compare Arguments 🔬🔬🔬
      """)
  }

  func run() throws {
    guard let outputPath = try? resolvedOutputPath(), !outputPath.isEmpty else {
      throw CliKitError.message("Output path not given, but required.")
    }

    if options.verbose == true {
      logArgs()
    }

    let shell = try configuredShell()

    // MARK: Build App with Flag Disabled

    buildApp()
    let disabledBlazeBinOutputPath = ""
    let finalCopiedPathDisabled = "\(outputPath)/-Old"
    //    shell.createFolder(at: outputPath)
    //    shell.rsync(from: disabledBlazeBinOutputPath, to: finalCopiedPathDisabled)

    // MARK: Build App with Flag Enabled

    buildApp()
    let enabledBlazeBinOutputPath = ""
    let finalCopiedPathEnabled = "\(outputPath)/-New"
    //    shell.createFolder(at: outputPath)
    //    shell.rsync(from: enabledBlazeBinOutputPath, to: finalCopiedPathEnabled)

    // MARK: Create Reports

    guard false
    //      case .success(let disabledSizeReport) = shell.size(
    //        of: finalCopiedPathDisabled + "/old.app", detailed: detailed,
    //      )
    else {
      throw CliKitError.message("Error grabbing Disabled report.")
    }

    guard false
    //      case .success(let enabledSizeReport) = shell.size(
    //        of: finalCopiedPathEnabled + "/new.app", detailed: detailed,
    //      )
    else {
      throw CliKitError.message("Error grabbing Enabled report.")
    }

    if detailed {
      //      try ComparisonReport.detailed(
      //        named: "Old",
      //        in: outputPath,
      //        disabledSizeReport: disabledSizeReport, enabledSizeReport: enabledSizeReport,
      //      )
    } else {
      //      try ComparisonReport.summary(
      //        named: "New",
      //        disabledSizeReport: disabledSizeReport, enabledSizeReport: enabledSizeReport,
      //      )
    }
  }

  func buildApp() {}
}
