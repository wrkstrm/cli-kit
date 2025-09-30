import Foundation
import WrkstrmFoundation

public struct TaskTimerOptions: Sendable {
  public var outputPath: String
  public var intervalSeconds: Int
  public var checkIntervalSeconds: Int
  public var task: String
  public var notes: String?
  public var maxIterations: Int
  public var traits: [String]
  public var tags: [String]
  public var sprintName: String?
  public var sprintStartAt: Date?
  public var sprintDurationMinutes: Int?
  public var pointsPerMinute: Double
  public var addPoints: [Double]
  public var detached: Bool

  public init(
    outputPath: String = ".wrkstrm/tmp/task-heartbeat.json",
    intervalSeconds: Int = 30,
    checkIntervalSeconds: Int = 450,
    task: String = "Task heartbeat",
    notes: String? = nil,
    maxIterations: Int = 0,
    traits: [String] = [],
    tags: [String] = [],
    sprintName: String? = nil,
    sprintStartAt: Date? = nil,
    sprintDurationMinutes: Int? = nil,
    pointsPerMinute: Double = 0.4,
    addPoints: [Double] = [],
    detached: Bool = false
  ) {
    self.outputPath = outputPath
    self.intervalSeconds = intervalSeconds
    self.checkIntervalSeconds = checkIntervalSeconds
    self.task = task
    self.notes = notes
    self.maxIterations = maxIterations
    self.traits = traits
    self.tags = tags
    self.sprintName = sprintName
    self.sprintStartAt = sprintStartAt
    self.sprintDurationMinutes = sprintDurationMinutes
    self.pointsPerMinute = pointsPerMinute
    self.addPoints = addPoints
    self.detached = detached
  }
}

public struct HeartbeatRunner: Sendable {
  public var options: TaskTimerOptions
  public init(options: TaskTimerOptions) { self.options = options }

  public func run() async throws {
    let fm = FileManager.default
    let outURL = URL(fileURLWithPath: options.outputPath)
    try fm.createDirectory(at: outURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    let startedAt = ISO8601DateFormatter().string(from: Date())
    var base: [String: Any] = [
      "task": options.task,
      "status": options.detached ? "detached" : "running",
      "startedAt": startedAt,
      "nextCheckIn": options.checkIntervalSeconds,
      "notes": options.notes ?? "",
      "traits": options.traits,
      "tags": options.tags,
      "pointsPerMinute": options.pointsPerMinute,
      "addPoints": options.addPoints,
    ]
    if let sprintName = options.sprintName { base["sprintName"] = sprintName }
    if let start = options.sprintStartAt { base["sprintStartAt"] = ISO8601DateFormatter().string(from: start) }
    if let dur = options.sprintDurationMinutes { base["sprintDurationMinutes"] = dur }

    if options.detached {
      try writeJSON(base, to: outURL)
      return
    }

    var i = 0
    while options.maxIterations == 0 || i < options.maxIterations {
      try writeJSON(base.merging(["tick": i + 1]) { _, new in new }, to: outURL)
      try await Task.sleep(nanoseconds: UInt64(options.intervalSeconds) * 1_000_000_000)
      i += 1
    }
  }

  private func writeJSON(_ dict: [String: Any], to url: URL) throws {
    try JSONFileWriter.writeJSONObject(dict, to: url, options: JSONFormatting.humanOptions)
  }
}
