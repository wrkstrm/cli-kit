import ArgumentParser

/// Generates random character strings from ASCII, emoji, or a mix of both.
struct RandomCharacters: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "random",
    abstract: "Generate a string of random printable ASCII or emoji characters."
  )

  enum Kind: String, ExpressibleByArgument, CaseIterable { case ascii, emoji, mixed }

  enum EmojiCategory: String, ExpressibleByArgument, CaseIterable {
    case conventions  // default curated set from docs
    case status  // accepted/rejected/caution
    case momentum  // launch/polish/growth
    case work  // fix/tests/docs/review
    case all  // union of all above
  }

  @Option(name: [.short, .long], help: "Number of characters to generate.")
  var length: Int = 3

  @Option(name: [.customShort("k"), .long], help: "Character type: ascii, emoji, or mixed.")
  var kind: Kind = .mixed

  @Option(name: [.long], help: "Emoji category when using --kind emoji or mixed.")
  var category: EmojiCategory = .conventions

  @Flag(help: "Avoid visually confusing characters (like 0/O, 1/l/I).")
  var noConfusing: Bool = false

  func run() throws {
    let output: String
    switch kind {
    case .ascii:
      output = Self.printableASCII(length: length, noConfusing: noConfusing)
    case .emoji:
      output = Self.emoji(length: length, category: category)
    case .mixed:
      let a = Self.printableASCII(length: max(0, length - 1), noConfusing: noConfusing)
      let e = Self.emoji(length: 1, category: category)
      output = a + e
    }
    print(output)
  }

  private static func printableASCII(length: Int, noConfusing: Bool) -> String {
    let base = (32...126).compactMap { UnicodeScalar($0).map(Character.init) }
    let table: [Character] =
      noConfusing
      ? base.filter { !"0O1lI".contains($0) }
      : base
    return String((0..<max(0, length)).map { _ in table.randomElement()! })
  }

  private static func emojiTable(for category: EmojiCategory) -> [Character] {
    let status: [Character] = ["✅", "❌", "⚠️"]
    let momentum: [Character] = ["🚀", "✨", "📈"]
    let work: [Character] = ["🛠️", "🧪", "📚", "🔍"]
    switch category {
    case .status: return status
    case .momentum: return momentum
    case .work: return work
    case .all: return status + momentum + work
    case .conventions: return status + momentum + work
    }
  }

  private static func emoji(length: Int, category: EmojiCategory) -> String {
    let table = emojiTable(for: category)
    guard !table.isEmpty else { return "" }
    return String((0..<max(0, length)).map { _ in table.randomElement()! })
  }
}
