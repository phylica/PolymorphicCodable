@attached(peer, names: suffixed(PolymorphicEnum))
public macro CodableProtocol(_ children: Any.Type...) = #externalMacro(
    module: "PolymorphicCodableMacros",
    type: "CodableProtocol"
)
