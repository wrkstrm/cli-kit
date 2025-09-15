import Foundation

public enum WrkstrmCLINotify {
  public struct DeliveryResult: Codable, Sendable {
    public var ok: Bool
    public var message: String
    public var status: Int32
    public var platform: String
    public var command: [String]
  }

  public struct Payload: Codable, Sendable {
    public var title: String
    public var message: String
    public var subtitle: String?
    public var sound: String?
    public var urgency: String?
    public init(title: String, message: String, subtitle: String? = nil, sound: String? = nil, urgency: String? = nil) {
      self.title = title; self.message = message; self.subtitle = subtitle; self.sound = sound; self.urgency = urgency
    }
  }

  public static func json(_ r: DeliveryResult) throws -> String {
    let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted, .sortedKeys]
    let d = try enc.encode(r); return String(decoding: d, as: UTF8.self)
  }

  #if os(macOS)
  public static func send(_ p: Payload) async -> DeliveryResult {
    let script = "display notification \"\(p.message)\" with title \"\(p.title)\""
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    task.arguments = ["-e", script]
    do {
      try task.run(); task.waitUntilExit()
      return DeliveryResult(
        ok: task.terminationStatus == 0,
        message: p.message,
        status: task.terminationStatus,
        platform: "macOS",
        command: ["osascript", "-e", script]
      )
    } catch {
      return DeliveryResult(ok: false, message: "failed: \(error)", status: -1, platform: "macOS", command: [])
    }
  }
  #else
  public static func send(_ p: Payload) async -> DeliveryResult {
    return DeliveryResult(ok: true, message: p.message, status: 0, platform: "linux", command: [])
  }
  #endif
}
