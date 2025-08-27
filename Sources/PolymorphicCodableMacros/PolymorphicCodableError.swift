public enum PolymorphicCodableError: Error {
    case codableProtocolNotAppliedOnProtocol
    case codableFieldNotAppliedOnField
    case codableProtocolMissingChildren
    case wrongArguments
}
