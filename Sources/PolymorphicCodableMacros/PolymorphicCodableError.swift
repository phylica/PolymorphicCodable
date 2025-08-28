public enum PolymorphicCodableError: Error {
    case codableProtocolMissingChildren
    case variableNotCorrectlyDeclared
    case polymorphicVariableTypeNotManaged
    case codableAppliedOnIncompatibleThing
    case wrongArguments
}
