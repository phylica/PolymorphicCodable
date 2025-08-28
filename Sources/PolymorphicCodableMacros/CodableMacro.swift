import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


public struct Codable: MemberMacro, ExtensionMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingMembersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax]
    {
        if let structureDeclaration = declaration.as(StructDeclSyntax.self)
        {
            return try structureMembersExpansion(structure: structureDeclaration)
        }
        
        if declaration.is(ProtocolDeclSyntax.self)
        {
            return []
        }
        
        throw PolymorphicCodableError.codableAppliedOnIncompatibleThing
    }
    
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
                                 providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                                 conformingTo protocols: [SwiftSyntax.TypeSyntax],
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax]
    {
        if let structureDeclaration = declaration.as(StructDeclSyntax.self)
        {
            return try structureExtensionsExpansion(structure: structureDeclaration)
        }
        
        if declaration.is(ProtocolDeclSyntax.self)
        {
            return []
        }
        
        throw PolymorphicCodableError.codableAppliedOnIncompatibleThing
    }
    
    
    public static func structureMembersExpansion(structure: StructDeclSyntax) throws -> [SwiftSyntax.DeclSyntax]
    {
        
        var keys = ""
        for member in structure.memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self) else
            {
                continue
            }
            guard let variableName = variable.bindings.first?.pattern.description else
            {
                throw PolymorphicCodableError.variableNotCorrectlyDeclared
            }
            
            let variableAttribute = String(describing: variable.attributes)
            guard variableAttribute.contains("Polymorphic") else {
                keys = keys + "case \(variableName)\n"
                continue
            }
            keys = keys + "case \(variableName)PolymorphicEnum = \"\(variableName)\"\n"
        }
        
        return [
            "private let polymorphicType = \"\(raw: structure.name)\"",
          """
          enum CodingKeys: String, CodingKey {
              case polymorphicType = "$type"
          \(raw:keys)
          }
          """
        ]
    }
    
    public static func structureExtensionsExpansion(structure: StructDeclSyntax) throws -> [SwiftSyntax.ExtensionDeclSyntax]
    {
        let codableExtension: DeclSyntax =
      """
      extension \(structure.name): Codable {}
      """
        
        guard let extensionDecl = codableExtension.as(ExtensionDeclSyntax.self) else {
            return []
        }
        
        return [extensionDecl]
    }
}
