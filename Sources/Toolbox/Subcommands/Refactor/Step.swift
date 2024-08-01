struct Step: Codable {

  var type: String

  var searchTerms: [String]?

  var replaceTerm: String?

  var exclusionTerms: [String]? = []

  var limit: Int?
}

// MARK: - Step.Type Enum

extension Step {

  enum `Type`: String {
    case addImport = "add-import"
    case count
    case find
    case format
    case prebuild
    case replace
    case removeImport = "remove-import"
    case scope
  }

  func typeEnumValue() -> `Type`? { `Type`(rawValue: type) }
}
