import Foundation

public enum CliKitConsoleTools {
  public static func stripANSI(_ s: String) -> String {
    var text = s
    text = text.replacingOccurrences(
      of: #"\u{001B}\[[0-9;?]*[ -/]*[@-~]"#,
      with: "",
      options: .regularExpression,
    )
    text = text.replacingOccurrences(
      of: #"\u{001B}\][^\u{0007}]*?(\u{0007}|\u{001B}\\)"#,
      with: "",
      options: .regularExpression,
    )
    text = text.replacingOccurrences(
      of: #"\u{001B}[\(\)][A-Za-z0-9]"#,
      with: "",
      options: .regularExpression,
    )
    while text.range(of: #"[^\n]\x08"#, options: .regularExpression) != nil {
      text = text.replacingOccurrences(of: #"[^\n]\x08"#, with: "", options: .regularExpression)
    }
    text = text.replacingOccurrences(of: #".*\r"#, with: "", options: .regularExpression)
    text = text.replacingOccurrences(of: "\r", with: "")
    return text
  }

  public static func containsANSI(_ s: String) -> Bool {
    s.contains("\u{001B}[") || s.contains("\u{001B}]")
  }

  public static func cleanTranscriptLines(_ s: String) -> [String] {
    let t = containsANSI(s) ? stripANSI(s) : s
    var out: [String] = []
    out.reserveCapacity(t.count / 40)
    var prev = ""
    t.enumerateLines { raw, _ in
      let line = raw
      let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.isEmpty { return }
      if trimmed.range(of: #"^[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏]$"#, options: .regularExpression) != nil { return }
      if line.contains("⏎") { return }
      if trimmed.range(of: #"Ctrl\+T\s*transcript|Ctrl\+C\s*quit"#, options: .regularExpression)
        != nil
      {
        return
      }
      if trimmed.range(
        of: #"^\s*Working\b|Crafting Final Mess|tokens used"#, options: .regularExpression,
      ) != nil {
        return
      }
      if trimmed.range(
        of: #"^\s*/(diff|status|model|approvals|compact)\b"#, options: .regularExpression,
      ) != nil {
        return
      }
      if trimmed == prev { return }
      prev = trimmed
      out.append(line)
    }
    return out
  }
}
