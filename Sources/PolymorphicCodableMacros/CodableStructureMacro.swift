import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


public struct CodableStructure: MemberMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingMembersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let structureDeclaration = declaration.as(StructDeclSyntax.self) else
        {
            throw PolymorphicCodableError.codableStructureNotAppliedOnStructure
        }
         
        var keys = ""
        for variable: MemberBlockItemSyntax in structureDeclaration.memberBlock.members {
            guard let variable = variable.decl.as(VariableDeclSyntax.self) else
            {
                continue
            }
            guard let variableName = variable.bindings.first?.pattern.description else
            {
                throw PolymorphicCodableError.codableFieldNotCorrectlyDeclared
            }
            
            let variableAttribute = String(describing: variable.attributes)
            guard variableAttribute.contains("CodableField") else {
                keys = keys + "case \(variableName)\n"
                continue
            }
            keys = keys + "case \(variableName)PolymorphicEnum = \"\(variableName)\"\n"
        }
       
        return [
            "private let polymorphicType = \"\(raw: structureDeclaration.name)\"",
          """
          enum CodingKeys: String, CodingKey {
              case polymorphicType = "$type"
          \(raw:keys)
          }
          """
        ]
    }
}
