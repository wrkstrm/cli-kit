import CommonShell
import Foundation

public enum WrkstrmCLINotify {
  public struct DeliveryResult: Codable, Sendable {
    public var ok: Bool
    public var message: String
    public var status: Int32
    public var platform: String
    public var command: [String]
    public var fallbackUsed: Bool
  }

  public struct Payload: Codable, Sendable {
    public var title: String
    public var message: String
    public var subtitle: String?
    public var sound: String?
    public var urgency: String?
    public init(
      title: String, message: String, subtitle: String? = nil, sound: String? = nil,
      urgency: String? = nil,
    ) {
      self.title = title
      self.message = message
      self.subtitle = subtitle
      self.sound = sound
      self.urgency = urgency
    }
  }

  public static func json(_ r: DeliveryResult) throws -> String {
    let enc = JSONEncoder()
    enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    let d = try enc.encode(r)
    return String(decoding: d, as: UTF8.self)
  }

  #if os(macOS)
  public static func send(_ p: Payload) async -> DeliveryResult {
    let script = "display notification \"\(p.message)\" with title \"\(p.title)\""
    let shell = CommonShell(executable: .path("/usr/bin/osascript"))
    do {
      let out = try await shell.launch(options: ["-e", script])
      let ok: Bool
      let status: Int32
      switch out.exitStatus {
      case .exited(code: let c):
        ok = (c == 0)
        status = Int32(c)
      case .signalled(let s):
        ok = false
        status = Int32(s)
      }
      return DeliveryResult(
        ok: ok,
        message: p.message,
        status: status,
        platform: "macOS",
        command: ["/usr/bin/osascript", "-e", script],
        fallbackUsed: !ok
      )
    } catch {
      return DeliveryResult(
        ok: false,
        message: "failed: \(error)",
        status: -1,
        platform: "macOS",
        command: [],
        fallbackUsed: true
      )
    }
  }
  #else
  public static func send(_ p: Payload) async -> DeliveryResult {
    // Linux: best-effort via `notify-send` if available
    let exe = "/usr/bin/env"
    var args: [String] = ["notify-send"]
    if let u = p.urgency, !u.isEmpty { args += ["-u", u] }
    args.append(contentsOf: [p.title, p.message])
    let shell = CommonShell(executable: .path(exe))
    do {
      let out = try await shell.launch(options: args)
      let ok: Bool
      let status: Int32
      switch out.exitStatus {
      case .exited(code: let c):
        ok = (c == 0)
        status = Int32(c)
      case .signalled(let s):
        ok = false
        status = Int32(s)
      }
      return DeliveryResult(
        ok: ok,
        message: p.message,
        status: status,
        platform: "linux",
        command: [exe] + args,
        fallbackUsed: !ok
      )
    } catch {
      return DeliveryResult(
        ok: false,
        message: "failed: \(error)",
        status: -1,
        platform: "linux",
        command: [],
        fallbackUsed: true
      )
    }
  }
  #endif
}
