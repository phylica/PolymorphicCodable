public enum PolymorphicJsonError: Error {
    case missingTypeIndicator
    case unknownType(String)
    case couldNotDeserializeSubType(String)
}