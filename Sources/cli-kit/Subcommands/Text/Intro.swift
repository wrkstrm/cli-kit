import ArgumentParser
import Foundation
import SwiftFigletKit
import CommonLog

struct Intro: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "intro",
    abstract: "Render Figlet intros with optional color and gradient.",
    discussion: "Matches the historical CLIA intro command; moved under CLIKit for shared use.",
    helpNames: .shortAndLong
  )

  enum BannerColorTheme: String, ExpressibleByArgument {
    case none, info, success, warning, accent, random
  }

  enum BannerGradientStyle: String, ExpressibleByArgument { case off, lines }

  @Argument(help: "Number of intros to print (default: 1)")
  var count: Int = 1

  @Option(name: .long, help: "Text to render (default: C.L.I.A.)")
  var text: String = "C.L.I.A."

  @Flag(name: .long, help: "Insert a blank line between banners")
  var spaced: Bool = true

  @Option(
    name: .customLong("banner-color"),
    help: "Banner color: none|info|success|warning|accent|random (default: none)"
  )
  var bannerColor: BannerColorTheme = .none

  @Option(
    name: .customLong("banner-gradient"),
    help: "Banner gradient: off|lines (default: off)"
  )
  var bannerGradient: BannerGradientStyle = .off

  @Flag(
    name: .customLong("print-figlet-details"),
    help: "Print font/color/gradient details after each intro"
  )
  var printFigletDetails: Bool = false

  @Option(name: .customLong("font"), help: "FIGlet font name to use (default: random)")
  var fontOverride: String?

  func run() async throws {
    let iterations = max(1, count)
    for index in 0..<iterations {
      let result = renderBanner(text: text)
      FileHandle.standardOutput.write(Data(result.output.utf8))
      if printFigletDetails {
        FileHandle.standardOutput.write(
          Data(
            "Figlet: font=\(result.fontName) color=\(result.colorDescription) gradient=\(result.gradientDescription)\n"
              .utf8)
        )
      }
      if spaced, index < iterations - 1 {
        FileHandle.standardOutput.write(Data("\n".utf8))
      }
    }
  }

  private func renderBanner(text: String) -> BannerRenderResult {
    let resolvedFontURL: URL? = {
      if let f = fontOverride, !f.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return SFKFonts.find(f)
      }
      if let env = ProcessInfo.processInfo.environment["CLIKIT_FIGLET_FONT"], !env.isEmpty {
        return SFKFonts.find(env)
      }
      return SFKFonts.randomURL()
    }()
    let fontURL = resolvedFontURL
    let fontName = fontURL?.deletingPathExtension().lastPathComponent ?? "Standard"

    if bannerGradient == .lines {
      let output =
        (fontURL.flatMap {
          SFKRenderer.renderGradientLines(
            text: text,
            fontURL: $0,
            palette: nil,
            randomizePalette: bannerColor == .random,
            forceColor: false,
            disableColorInXcode: true
          )
        }) ?? SFKRenderer.renderGradientLines(
          text: text,
          fontName: "random",
          palette: nil,
          randomizePalette: bannerColor == .random,
          forceColor: false,
          disableColorInXcode: true
        ) ?? (text + "\n")

      let gradientDescriptor = "lines"
      let colorDescriptor = bannerColor == .random ? "random-palette" : "palette"
      return BannerRenderResult(
        output: output,
        fontName: fontName,
        colorDescription: colorDescriptor,
        gradientDescription: gradientDescriptor
      )
    }

    let ansiColor = mapColor(bannerColor)
    let rendered =
      (fontURL.flatMap {
        SFKRenderer.render(
          text: text,
          fontURL: $0,
          color: ansiColor,
          forceColor: false,
          disableColorInXcode: true
        )
      }) ?? SFKRenderer.render(
        text: text,
        fontName: "random",
        color: ansiColor,
        forceColor: false,
        disableColorInXcode: true
      ) ?? (text + "\n")

    return BannerRenderResult(
      output: rendered,
      fontName: fontName,
      colorDescription: describeColor(theme: bannerColor, resolved: ansiColor),
      gradientDescription: "off"
    )
  }

  private func mapColor(_ theme: BannerColorTheme) -> SFKRenderer.ANSIColor {
    switch theme {
    case .none: return .none
    case .info: return .cyan
    case .success: return .green
    case .warning: return .yellow
    case .accent: return .magenta
    case .random:
      let options: [SFKRenderer.ANSIColor] = [
        .cyan, .green, .yellow, .magenta, .blue, .red, .white,
      ]
      return options.randomElement() ?? .cyan
    }
  }

  private func describeColor(theme: BannerColorTheme, resolved: SFKRenderer.ANSIColor) -> String {
    switch theme {
    case .none, .info, .success, .warning, .accent:
      return theme.rawValue
    case .random:
      return "random(\(resolved.rawValue))"
    }
  }

  private struct BannerRenderResult {
    let output: String
    let fontName: String
    let colorDescription: String
    let gradientDescription: String
  }
}
