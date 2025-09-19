import CommonProcess
import CommonShell
import Testing

@testable import CliKit

@Suite struct CliKitTests {
  @Test func printWorkingDirectory() throws {
    let shell = CommonShell()
    let directory = try shell.printWorkingDirectory()
    #expect(!directory.isEmpty)
  }
}
