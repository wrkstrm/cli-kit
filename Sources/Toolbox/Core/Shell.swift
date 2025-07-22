import ArgumentParser
import Foundation
import Logging
import WrkstrmFoundation
import WrkstrmMain

extension Log {
  fileprivate static let shell = { () -> Logger in
    Logger(label: "refactor.shell")
  }()
}

typealias ShellResult = Result<Shell.Output, Shell.TerminationError>

public struct Shell {
  typealias Output = String

  static let defaultPath = URL(fileURLWithPath: ".")

  static let synchronizingOutputQueue = DispatchQueue(
    label: "ig-shell-output-synchronization-output-queue",
    qos: .userInitiated,
    autoreleaseFrequency: .workItem,
    target: .global(qos: .userInteractive),
  )

  static let synchronizingErrorQueue = DispatchQueue(
    label: "ig-shell-output-synchronization-error-queue",
    qos: .userInitiated,
    autoreleaseFrequency: .workItem,
    target: .global(qos: .userInteractive),
  )

  var path: URL? = Self.defaultPath

  var cli: String = ""

  var options: String = ""

  var handles: (output: FileHandle, error: FileHandle)? = (
    output: .standardOutput, error: .standardError,
  )

  var reprintCommands: Bool = false

  @discardableResult
  fileprivate static func input(
    path: URL = Self.defaultPath,
    cli: String = "",
    options: String = "",
    command: String,
    handles: (output: FileHandle, error: FileHandle)? = (
      output: .standardOutput, error: .standardError,
    ),
    reprintCommand: Bool = false,
  ) -> Result<Output, TerminationError> {
    // Example:
    // 📥📥📥📥 TERMINAL INPUT BEGIN 📥📥📥📥
    // 🛣 | Path: $(HOME)
    // ▶️ | Command: pwd
    // 📥📥📥📥  TERMINAL INPUT END  📥📥📥📥
    if reprintCommand {
      Log.shell.info(
        """
        \u{001B}[0;32m
        📥📥📥📥 TERMINAL INPUT BEGIN 📥📥📥📥
        \u{001B}[0;0m🛣 | Path: \(path)
        ▶️ | Command: \(cli) \(options) \(command)
        \u{001B}[0;32m📥📥📥📥  TERMINAL INPUT END  📥📥📥📥\u{001B}[0;0m
        """)
    }

    // Continue only after all actions have concluded.
    let dispatchGroup = DispatchGroup()

    var process = Process()
    #if os(macOS)
      // macOS output is easier to handle with `bash` than `sh`
      process.launchPath = "/bin/bash"
    #else  // os(macOS)
      // gLinux is Debian based which means it's default `sh` links to the Dash binary
      process.executableURL = URL(fileURLWithPath: "/bin/dash")
    #endif  // os(macOS)

    let absolutePath = path.absoluteString.replacingOccurrences(of: "file://", with: "")
    let finalCommand = ["cd", absolutePath, "&&", cli, options, command].joined(separator: " ")

    // https://man7.org/linux/man-pages/man1/dash.1.html
    process.arguments = ["-c", finalCommand]

    // Create Data and Pipe Tuples
    var data: (output: Data, error: Data) = (Data(), Data())
    let pipes: (output: Pipe, error: Pipe) = (Pipe(), Pipe())

    process.standardOutput = pipes.output
    process.standardError = pipes.error

    // `readabilityHandlers` are only available in macOS 10.7+
    #if os(macOS)
      pipes.output.fileHandleForReading.readabilityHandler = {
        let availableData = $0.availableData
        dispatchGroup.enter()
        synchronizingOutputQueue.sync {
          data.output.append(availableData)
          handles?.output.write(availableData)
          dispatchGroup.leave()
        }
      }

      pipes.error.fileHandleForReading.readabilityHandler = {
        let availableData = $0.availableData
        dispatchGroup.enter()
        synchronizingErrorQueue.sync {
          data.error.append(availableData)
          handles?.error.write(availableData)
          dispatchGroup.leave()
        }
      }
      process.launch()
    #else  // os(macOS)
      try? process.run()
      dispatchGroup.enter()
      synchronizingOutputQueue.async {
        data.output = pipes.output.fileHandleForReading.readDataToEndOfFile()
        dispatchGroup.leave()
      }

      dispatchGroup.enter()
      synchronizingErrorQueue.async {
        data.error = pipes.error.fileHandleForReading.readDataToEndOfFile()
        dispatchGroup.leave()
      }
    #endif  // os(macOS)
    process.waitUntilExit()

    dispatchGroup.enter()
    synchronizingOutputQueue.async {
      dispatchGroup.leave()
    }

    dispatchGroup.enter()
    synchronizingErrorQueue.async {
      dispatchGroup.leave()
    }

    // Simple semaphore: Block until all writes are done and throw if error
    let result = dispatchGroup.wait(wallTimeout: .now() + 10)
    if case .timedOut = result {
      Log.shell.error("Timeout reached.")
    }

    // Close custom file handles if necessary
    if handles?.output.isStandard == false {
      handles?.output.closeFile()
    }

    if handles?.error.isStandard == false {
      handles?.error.closeFile()
    }

    #if !os(macOS)
      pipes.output.fileHandleForReading.readabilityHandler = nil
      pipes.error.fileHandleForReading.readabilityHandler = nil
    #endif  // !os(macOS)

    guard process.terminationStatus != 0 else {
      // Return the data output as a String
      let successOutput = data.output.utf8StringValue()!
      // Example:
      // ⚙️ ⚙️ ⚙️ ⚙️ TERMINAL OUTPUT BEGIN ⚙️ ⚙️ ⚙️ ⚙️
      // google/src/cloud/cmonterroza/exp/google3/experimental/users/cmonterroza
      // ⚙️ ⚙️ ⚙️ ⚙️  TERMINAL OUTPUT END  ⚙️ ⚙️ ⚙️ ⚙️
      if reprintCommand {
        Log.shell.info(
          """
          \u{001B}[0;33m\n⚙️ ⚙️ ⚙️ ⚙️ TERMINAL OUTPUT BEGIN ⚙️ ⚙️ ⚙️ ⚙️
          \u{001B}[0;0m\(successOutput)\u{001B}[0;33m⚙️ ⚙️ ⚙️ ⚙️  TERMINAL OUTPUT END  ⚙️ ⚙️ ⚙️ ⚙️
          \u{001B}[0;0m
          """)
      }
      return .success(successOutput)
    }
    return .failure(TerminationError(process: process, processData: data))
  }
}

extension Shell {
  @discardableResult
  func input(
    path: URL? = Self.defaultPath,
    cli: String? = "",
    options: String? = "",
    command: String = "",
    handles: (output: FileHandle, error: FileHandle)? = (
      output: .standardOutput, error: .standardError,
    ),
  ) -> Result<Output, TerminationError> {
    let finalCLI: String =
      if let overrideCLI = cli, !overrideCLI.isEmpty {
        overrideCLI
      } else {
        self.cli
      }
    let finalOptions: String =
      if let overrideOptions = options, !overrideOptions.isEmpty {
        overrideOptions
      } else {
        self.options
      }
    return Self.input(
      path: self.path ?? path ?? Self.defaultPath,
      cli: finalCLI,
      options: finalOptions,
      command: command,
      handles: self.handles ?? handles,
      reprintCommand: reprintCommands,
    )
  }
}

extension Shell {
  static let error = "Failed due to a command line error."
}

extension Shell {
  /// Error type used by the `sh()` function when a `Process`'s `terminationStatus` is non-zero
  public struct TerminationError: Swift.Error {
    /// The process that was run.
    public let process: Process

    /// The termination status of the `Process` that was run
    var reason: Process.TerminationReason { process.terminationReason }

    /// The termination status of the `Process` that was run
    var status: Int32 { process.terminationStatus }

    /// The raw data buffers as returned via `STDOUT` and `STDERR`
    public let processData: (output: Data, error: Data)

    /// The output of the command as a` UTF8` string, as returned through `STDOUT`
    public var output: String { processData.output.utf8StringValue() ?? "" }

    /// The error message as a `UTF8` string, as returned through `STDERR`
    public var message: String {
      processData.error.utf8StringValue()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
  }
}

extension Shell.TerminationError: CustomStringConvertible, LocalizedError {
  public var errorDescription: String? { description }

  public var description: String {
    """
        Shell.TerminalError:BEGIN
        Process: \(process)
        Reason: \(reason)
        Status: \(status)
        Output: "\(output)"
        Message: "\(message)"
        Shell.TerminalError:END
    """
  }
}
