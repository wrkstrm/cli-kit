import Foundation
import WrkstrmMain

extension String {
  static let sizeParsingError = "Error Parsing Size."
}

struct Section {
  var title: String
  var files: [File]
}

struct File {
  var name: String
  var size: Int
  var delta: Int
}

enum ComparisonReport {
  static let tableHeader: String =
    """
    |`File`|`Size (kb)`|`Delta`|
    |:-----|----------:|------:|\n
    """

  static func headerItem(path: String, size: Int, delta: Int) -> String {
    "|`\(path)`|`\(size)`|`\(delta)`|\n"
  }

  static func reportFileName(_ name: String) -> String {
    "\(name.lowercased())_comparison_report.md"
  }

  static func summary(
    named reportName: String,
    disabledSizeReport: String,
    enabledSizeReport: String,
  ) throws {
    guard
      let enabledSizeString = enabledSizeReport.split(separator: "\t").first,
      let disabledSizeString = disabledSizeReport.split(separator: "\t").first,
      let enabledSize = Int(enabledSizeString),
      let disabledSize = Int(disabledSizeString)
    else {
      throw String.sizeParsingError
    }
    Log.main.info(
      """
      ---- Comparison Summary ----
      Size With \(reportName) Enabled: \(enabledSizeReport)
      Size With \(reportName) Disabled: \(disabledSizeReport)
      Size Diff: \(enabledSize - disabledSize) kb
      """,
    )
  }

  static func detailed(
    named reportName: String,
    in directory: String?,
    disabledSizeReport: String,
    enabledSizeReport: String,
  ) throws {
    // Create dictionaries of every file and size.
    var enabledBuildFiles: [String: Int] = [:]
    for item in enabledSizeReport.split(separator: "\n") {
      let valueKey = item.components(separatedBy: .whitespaces)
      enabledBuildFiles[String(valueKey[1])] = Int(valueKey[0])
    }
    var disabledBuildFiles: [String: Int] = [:]
    for item in disabledSizeReport.split(separator: "\n") {
      let valueKey = item.components(separatedBy: .whitespaces)
      disabledBuildFiles[String(valueKey[1])] = Int(valueKey[0])
    }

    // Categorize Artifacts
    var newArtifacts: [File] = []
    var changedArtifacts: [File] = []
    var unchangedArtifacts: [File] = []
    var removedArtifacts: [File] = []
    for fileInfoPair in enabledBuildFiles {
      guard let disabledFileSize = disabledBuildFiles[fileInfoPair.key] else {
        newArtifacts.append(File(name: fileInfoPair.key, size: fileInfoPair.value, delta: 0))
        continue
      }
      if disabledFileSize != fileInfoPair.value {
        changedArtifacts.append(
          File(
            name: fileInfoPair.key,
            size: fileInfoPair.value,
            delta: fileInfoPair.value - disabledFileSize,
          ))
      } else {
        unchangedArtifacts.append(
          File(name: fileInfoPair.key, size: fileInfoPair.value, delta: 0))
      }
      disabledBuildFiles.removeValue(forKey: fileInfoPair.key)
    }
    for disabledBuildFile in disabledBuildFiles {
      removedArtifacts.append(
        File(name: disabledBuildFile.key, size: disabledBuildFile.value, delta: 0))
    }

    let comparator = Sort<File>.by([
      .descending { $0.delta },
      .descending { $0.size },
      .ascending { $0.name },
    ])
    // Create Sections
    let sections: [Section] = [
      Section(title: "New Artifacts", files: newArtifacts.sorted(by: comparator)),
      Section(title: "Changed Artifacts", files: changedArtifacts.sorted(by: comparator)),
      Section(title: "Removed Artifacts", files: removedArtifacts.sorted(by: comparator)),
      Section(title: "Unchanged Artifacts", files: unchangedArtifacts.sorted(by: comparator)),
    ]

    // Generate Markdown
    var markdown = ""
    markdown.append(contentsOf: "# `\(reportName)` Comparison Report \n")
    markdown.append(
      contentsOf: "inspecting-build-products\n")
    markdown.append(contentsOf: "[TOC]\n")

    for section in sections {
      Log.main.info("Generating: \(section.title)")
      markdown.append(contentsOf: "## `\(section.title)`\n")
      guard !section.files.isEmpty else {
        markdown.append(contentsOf: "`None.`\n")
        continue
      }
      let sortedFiles = section.files.sorted { $0.size > $1.size }
      markdown.append(contentsOf: Self.tableHeader)
      for info in sortedFiles {
        // TODO: Fix
        let path = info.name.replacingOccurrences(of: "", with: "")
        guard !path.isEmpty else { continue }
        markdown.append(contentsOf: Self.headerItem(path: path, size: info.size, delta: info.delta))
      }
    }

    // Output Generated Report
    if let directory {
      let shell = RShell()
//      shell.createFolder(at: directory)
      let resolvedFileOutputPath = directory + "/" + Self.reportFileName(reportName)
//      shell.createFile(at: resolvedFileOutputPath)
      try markdown.write(toFile: resolvedFileOutputPath, atomically: true, encoding: .utf8)
    }
  }
}
