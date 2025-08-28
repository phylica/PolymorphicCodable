@attached(peer, names: suffixed(PolymorphicEnum))
public macro Polymorphic(_ children: Any.Type...) = #externalMacro(
    module: "PolymorphicCodableMacros",
    type: "Polymorphic"
)

@attached(accessor)
@attached(peer, names: suffixed(PolymorphicEnum))
public macro Polymorphic() = #externalMacro(
    module: "PolymorphicCodableMacros",
    type: "Polymorphic"
)

@attached(extension, conformances: Codable)
@attached(member, names: named(CodingKeys), named(polymorphicType))
public macro Codable() = #externalMacro(
    module: "PolymorphicCodableMacros",
    type: "Codable"
)
