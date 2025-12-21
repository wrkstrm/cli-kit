import TaskTimerCore
import Testing

@Test("TaskTimerOptions defaults are stable")
func taskTimerOptionsDefaults() {
  let options = TaskTimerOptions()
  #expect(options.outputPath == ".clia/tmp/task-heartbeat.json")
  #expect(options.intervalSeconds == 30)
  #expect(options.checkIntervalSeconds == 450)
}
