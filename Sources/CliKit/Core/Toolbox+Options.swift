import ArgumentParser
import Foundation
import CommonCLI
import CommonShell

extension CliKit {
  struct Options: ParsableArguments {
    @Option(
      name: .customLong("d"),
      help: "The working directory to use.",
    )
    var workingDirectory: String = ""

    @Option(
      name: .customLong("o"),
      help: "The output directory.",
    )
    var output: String?

    @Flag(
      name: .customLong("v"),
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
    CommonShell(path: try options.resolvedPath, cli: "/bin/sh", reprintCommands: options.verbose)
  }
}
