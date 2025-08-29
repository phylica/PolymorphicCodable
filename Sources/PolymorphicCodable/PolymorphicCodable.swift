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
@attached(member, names: named(CodingKeys), named(polymorphicType), named(codedName), named(staticCodedName))
public macro Codable(codedName: String? = nil) = #externalMacro(
    module: "PolymorphicCodableMacros",
    type: "Codable"
)

@attached(peer)
public macro CodedName(_ codedName: String) = #externalMacro(
    module: "PolymorphicCodableMacros",
    type: "CodedName"
)