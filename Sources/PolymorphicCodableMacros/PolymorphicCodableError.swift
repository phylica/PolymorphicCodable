public enum PolymorphicCodableError: Error {
    case codableProtocolNotAppliedOnProtocol
    case codableProtocolMissingChildren
    case codableFieldNotAppliedOnField
    case codableFieldNotCorrectlyDeclared
    case codableStructureNotAppliedOnStructure
    case wrongArguments
}
