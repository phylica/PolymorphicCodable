import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


public struct CodableField: AccessorMacro, PeerMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.AccessorDeclSyntax] {
        guard let variableDeclaration = declaration.as(VariableDeclSyntax.self) else
        {
            throw PolymorphicCodableError.codableFieldNotAppliedOnField
        }

        
        return [
          """
            get{
             switch plantPolymorphicEnum {
                 case .tree(let tree):
                     return tree
                 case .flower(let flower):
                     return flower
             }
            }
          """
        ]
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let variableDeclaration = declaration.as(VariableDeclSyntax.self) else
        {
            throw PolymorphicCodableError.codableFieldNotAppliedOnField
        }
        
        
        return [
          """
            
            private var plantPolymorphicEnum: PlantPolymorphicEnum
          """
        ]
    }
}