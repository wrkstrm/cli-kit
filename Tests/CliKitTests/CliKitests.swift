import Testing

@testable import CliKit

@Suite struct ToolboxTests {
  @Test func printWorkingDirectory() throws {
    let shell = CommonShell(executablePath: "/usr/bin/env")
    let directory = try shell.printWorkingDirectory()
    #expect(!directory.isEmpty)
  }
}
