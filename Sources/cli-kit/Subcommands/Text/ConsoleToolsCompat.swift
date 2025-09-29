import Foundation

enum ConsoleTools {
  static func stripANSI(_ text: String) -> String { text }
  static func cleanTranscriptLines(_ text: String) -> [String] {
    text.replacingOccurrences(of: "\r", with: "\n").split(separator: "\n").map(String.init)
  }
}
