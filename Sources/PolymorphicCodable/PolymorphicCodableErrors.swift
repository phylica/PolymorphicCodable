public enum PolymorphicCodableError: Error {
    case missingTypeIndicator
    case unknownType(String)
    case couldNotDeserializeSubType(String)
}
