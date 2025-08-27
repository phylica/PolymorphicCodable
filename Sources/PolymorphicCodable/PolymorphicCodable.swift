@attached(peer, names: suffixed(PolymorphicEnum))
public macro CodableProtocol(_ children: Any.Type...) = #externalMacro(
    module: "PolymorphicCodableMacros",
    type: "CodableProtocol"
)

@attached(accessor)
@attached(peer, names: suffixed(PolymorphicEnum), named(CodingKeys))
public macro CodableField() = #externalMacro(
    module: "PolymorphicCodableMacros",
    type: "CodableField"
)
