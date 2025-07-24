import ArgumentParser
import WrkstrmMain

@preconcurrency
struct RandomCharacters: AsyncParsableCommand {
  nonisolated(unsafe) static var configuration = CommandConfiguration(
    commandName: "random",
    abstract: "Generate a string of random printable ASCII or emoji characters."
  )

  enum Kind: String, ExpressibleByArgument, CaseIterable {
    case ascii, emoji, mixed
  }

  @Option(name: [.short, .long], help: "Number of characters to generate.")
  var length: Int = 3

  @Option(name: [.customShort("k"), .long], help: "Character type: ascii, emoji, or mixed.")
  var kind: Kind = .mixed

  @Flag(help: "Avoid visually confusing characters (like 0/O, 1/l/I).")
  var noConfusing: Bool = false

  func run() throws {
    let output: String
    switch kind {
    case .ascii:
      output = Random.printableASCII(length: length, noConfusing: noConfusing)
    case .emoji:
      output = Random.emoji(length: length)
    case .mixed:
      output = Random.mixed(length: length, noConfusing: noConfusing)
    }
    print(output)
  }
}

