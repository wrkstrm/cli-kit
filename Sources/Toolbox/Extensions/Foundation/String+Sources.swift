import Foundation

extension [String] {
  var sourceFiles: [String]? {
    filter { $0.hasSuffix(".swift") || $0.hasSuffix(".m") || $0.hasSuffix(".mm") }
  }
}
