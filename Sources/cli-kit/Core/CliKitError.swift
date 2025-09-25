import Foundation

enum CliKitError: Error, CustomStringConvertible {
  case message(String)
  var description: String {
    switch self {
    case .message(let m): m
    }
  }
}
