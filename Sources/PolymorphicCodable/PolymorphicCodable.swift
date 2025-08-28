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

@attached(member, names: named(CodingKeys), named(polymorphicType))
public macro CodableStructure() = #externalMacro(
    module: "PolymorphicCodableMacros",
    type: "CodableStructure"
)
