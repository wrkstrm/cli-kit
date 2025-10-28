import Foundation
import Testing
@testable import CliKit

@Suite struct FormatCommandTests {
  @Test func jsonFormattingCheckDetectsChange() async throws {
    // Create a temp JSON file with unstable formatting
    let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
    let file = tmpDir.appendingPathComponent("format-json-test-\(UUID().uuidString).json")
    let original = "{\n  \"b\":1, \"a\": 2\n}"
    try original.write(to: file, atomically: true, encoding: .utf8)

    // Build a Format command instance restricted to json kind and the file
    var cmd = Format()
    cmd.kinds = [.json]
    cmd.files = [file.path]
    cmd.check = true

    // Expect non-zero exit in check mode (throws ExitCode)
    var threw = false
    do { try await cmd.run() } catch { threw = true }
    #expect(threw == true)
  }
}

