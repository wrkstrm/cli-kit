+#if os(macOS)
import ArgumentParser
import CommonProcess
import CommonShell
import Foundation
import WrkstrmLog

struct ExtractSDEF: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "extract-sdef",
    abstract: "Dump scripting definitions for apps under /Applications",
    discussion:
      "Runs /usr/bin/sdef for each .app bundle and writes XML next to the chosen output root.",
  )

  @Option(
    name: [.customShort("o"), .customLong("output"), .customLong("output-directory")],
    help: "Destination directory for generated .sdef files (defaults to current directory)."
  )
  var outputDirectory: String?

  func run() async throws {
    let fileManager = FileManager.default
    let destination = URL(
      fileURLWithPath: outputDirectory ?? fileManager.currentDirectoryPath,
      isDirectory: true
    )
    try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)

    let applicationsURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
    let contents = try fileManager.contentsOfDirectory(
      at: applicationsURL,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles]
    )

    let shell = CommonShell(
      workingDirectory: applicationsURL.path,
      executable: Executable.path("/usr/bin/sdef")
    )

    for appURL in contents where appURL.pathExtension == "app" {
      let baseName = appURL.deletingPathExtension().lastPathComponent
      let outputURL = destination.appendingPathComponent("\(baseName).sdef")
      do {
        let xml = try await shell.run([appURL.path])
        try xml.write(to: outputURL, atomically: true, encoding: String.Encoding.utf8)
        Log.main.info("extract-sdef: \(baseName) -> \(outputURL.path)")
      } catch {
        Log.main.error(
          "extract-sdef failed (\(appURL.lastPathComponent)): \(String(describing: error))")
      }
    }
  }
}
#endif
