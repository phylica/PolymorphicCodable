public enum PolymorphicCodableError: Error {
    case missingTypeIndicator
    case typeNotDeclaredAsSubtype(String)
    case couldNotDeserializeSubType(String)
}
