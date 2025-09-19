import CommonShell
import Foundation
import Testing

@testable import CliKit

@Suite struct CliKitTests {
  @Test func printWorkingDirectory() async throws {
    let shell = CommonShell()
    let directory = try await shell.run(
      host: .env(options: []),
      executable: .name("pwd")
    ).trimmingCharacters(in: .whitespacesAndNewlines)
    #expect(!directory.isEmpty)
    #expect(directory == FileManager.default.currentDirectoryPath)
  }
}
