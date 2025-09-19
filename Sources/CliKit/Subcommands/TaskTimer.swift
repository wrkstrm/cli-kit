import ArgumentParser
import Foundation
import TaskTimer

struct TaskTimerCommand: AsyncParsableCommand {
  static let configuration: CommandConfiguration = .init(
    commandName: "task-timer",
    abstract: "Emit task heartbeat JSON periodically or once (detached)."
  )

  @Option(name: .customLong("output"), help: "Output file path")
  var outputPath: String = ".wrkstrm/tmp/task-heartbeat.json"

  @Option(name: .customLong("interval"), help: "Seconds between heartbeats")
  var intervalSeconds: Int = 30

  @Option(name: .customLong("check-interval"), help: "Seconds to next check-in")
  var checkIntervalSeconds: Int = 450

  @Option(name: .customLong("task"), help: "Task label")
  var task: String = "Task heartbeat"

  @Option(name: .customLong("notes"), help: "Freeform notes")
  var notes: String?

  @Option(name: .customLong("max-iterations"), help: "Stop after N iterations (0 = infinite)")
  var maxIterations: Int = 0

  @Option(name: .customLong("traits"), help: "Comma-separated list of traits")
  var traitsCSV: String = ""

  @Option(name: .customLong("tags"), help: "Comma-separated list of tags")
  var tagsCSV: String = ""

  @Option(name: .customLong("sprint-name"), help: "Sprint name")
  var sprintName: String?

  @Option(name: .customLong("sprint-start"), help: "Sprint start (ISO8601)")
  var sprintStart: String?

  @Option(name: .customLong("sprint-duration"), help: "Sprint duration in minutes")
  var sprintDurationMinutes: Int?

  @Option(name: .customLong("points-per-minute"), help: "Points per minute (default 0.4)")
  var pointsPerMinute: Double = 0.4

  @Option(
    name: .customLong("add-points"), parsing: .unconditionalSingleValue,
    help: "Add manual points (repeatable)"
  )
  var addPoints: [Double] = []

  @Flag(name: .customLong("detached"), help: "Write a single heartbeat and exit")
  var detached: Bool = false

  func run() async throws {
    let traits = traitsCSV.split(separator: ",").map {
      String($0).trimmingCharacters(in: .whitespaces)
    }.filter { !$0.isEmpty }

    let tags = tagsCSV.split(separator: ",").map {
      String($0).trimmingCharacters(in: .whitespaces)
    }.filter { !$0.isEmpty }

    let sprintStartAt: Date? =
      if let value = sprintStart, !value.isEmpty {
        ISO8601DateFormatter().date(from: value)
      } else {
        nil
      }

    let options = TaskTimerOptions(
      outputPath: outputPath,
      intervalSeconds: intervalSeconds,
      checkIntervalSeconds: checkIntervalSeconds,
      task: task,
      notes: notes,
      maxIterations: max(0, maxIterations),
      traits: traits,
      tags: tags,
      sprintName: sprintName,
      sprintStartAt: sprintStartAt,
      sprintDurationMinutes: sprintDurationMinutes,
      pointsPerMinute: pointsPerMinute,
      addPoints: addPoints,
      detached: detached
    )

    let runner = HeartbeatRunner(options: options)
    try await runner.run()
  }
}
