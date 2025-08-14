import Testing

@testable import CliKit

@Suite struct ToolboxTests {
  @Test func printWorkingDirectory() throws {
    let shell = RShell()
    let directory = try shell.printWorkingDirectory()
    #expect(!directory.isEmpty)
  }
}
