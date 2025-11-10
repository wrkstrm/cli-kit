import ArgumentParser
import CommonCLI
import CommonProcess
import CommonShell
import Foundation

extension CliKit {
  struct Options: ParsableArguments {
    @Option(
      name: .long,
      help: "The working directory to use.",
    )
    var workingDirectory: String = ""

    @Option(
      name: .long,
      help: "The output directory.",
    )
    var output: String?

    @Flag(
      name: .long,
      help: "Reprints command info.",
    )
    var verbose: Bool = false

    var resolvedPath: URL {
      get throws {
        let path = workingDirectory
        guard let url = URL(string: path) else {
          throw CliKitError.message("Unparsable URL")
        }
        return url
      }
    }
  }
}

protocol ConfiguredShell {
  var options: CliKit.Options { get }
}

extension ConfiguredShell {
  func configuredShell() throws -> CommonShell {
    let workingDirectory = try options.resolvedPath.path
    var shell =
      workingDirectory.isEmpty
      ? CommonShell()
      : CommonShell(workingDirectory: workingDirectory)
    let exposure: ProcessExposure = options.verbose ? .summary : .none
    shell.logOptions.exposure = exposure
    return shell
  }
}
