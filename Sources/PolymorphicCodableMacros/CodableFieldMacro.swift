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
        
        guard let variableName = variableDeclaration.bindings.first?.pattern.description,
              let variableType = variableDeclaration.bindings.first?.typeAnnotation?.type else
        {
            throw PolymorphicCodableError.codableFieldNotCorrectlyDeclared
        }
        
        
        return [
          """
            get{
             return \(raw: variableName)PolymorphicEnum.value()
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
        
        guard let variableName = variableDeclaration.bindings.first?.pattern.description,
              let variableType = variableDeclaration.bindings.first?.typeAnnotation?.type.description else
        {
            throw PolymorphicCodableError.codableFieldNotCorrectlyDeclared
        }
        
        return [
          """
            private var \(raw: variableName)PolymorphicEnum: \(raw: variableType)PolymorphicEnum
          """
        ]
    }
}
