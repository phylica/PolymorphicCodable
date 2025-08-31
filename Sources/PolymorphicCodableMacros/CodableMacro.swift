import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


public struct Codable: MemberMacro, ExtensionMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingMembersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax]
    {
        if declaration.is(EnumDeclSyntax.self){
            return []
        }
        guard let structure = declaration.as(StructDeclSyntax.self) else
        {
            throw PolymorphicCodableError.codableAppliedOnIncompatibleThing
        }
        
        var codedTypeName: String = structure.name.text
        if let codedNameArgument = getArguments(fromAttribute: node).first(where: {$0.label == "codedName"})
        {
            guard let stringExpression = codedNameArgument.expression.as(StringLiteralExprSyntax.self) else
            {
                throw PolymorphicCodableError.wrongArguments
            }
            codedTypeName = stringExpression.representedLiteralValue ?? codedTypeName
        }
        
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
            var isPolymorphic = false
            var codedName : String? = nil
            for attribute in variable.attributes
            {
                switch(attribute)
                {
                    case .attribute(let attribute):
                        switch(attribute.attributeName.trimmed.description)
                        {
                            case "Polymorphic":
                                isPolymorphic = true
                            case "CodedName":
                                if let codedNameArgument = getArguments(fromAttribute: attribute).first
                                {
                                    guard let stringExpression = codedNameArgument.expression.as(StringLiteralExprSyntax.self) else
                                    {
                                        throw PolymorphicCodableError.wrongArguments
                                    }
                                    codedName = stringExpression.representedLiteralValue
                                }
                            default:
                                ()
                        }
                    case .ifConfigDecl(_):
                        () // Do nothing
                }
            }
            
            if isPolymorphic{
                keys = keys + "case \(variableName)PolymorphicEnum = \"\(codedName ?? variableName)\"\n"
            }else{
                if let codedName{
                    keys = keys + "case \(variableName) = \"\(codedName)\"\n"
                }
                else{
                    keys = keys + "case \(variableName)\n"
                }
            }
            
        }
        
        return [
            "private let codedName = \"\(raw: codedTypeName)\"",
            "static let staticCodedName = \"\(raw: codedTypeName)\"",
          """
          enum CodingKeys: String, CodingKey {
              case codedName = "$type"
          \(raw:keys)
          }
          """
        ]
    }
    
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
                                 providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                                 conformingTo protocols: [SwiftSyntax.TypeSyntax],
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax]
    {
        let structure = declaration.as(StructDeclSyntax.self)
        let enumerated = declaration.as(EnumDeclSyntax.self)
        guard let name = structure?.name ?? enumerated?.name else
        {
            throw PolymorphicCodableError.codableAppliedOnIncompatibleThing
        }
        
        
        
        let codableExtension: DeclSyntax =
      """
      extension \(name): Codable {}
      """
        
        guard let extensionDecl = codableExtension.as(ExtensionDeclSyntax.self) else {
            return []
        }
        
        return [extensionDecl]
    }
    
    private static func getArguments(fromAttribute attribute: SwiftSyntax.AttributeSyntax) -> [(
        label: String,
        expression: ExprSyntax
    )]
    {
        var result = [(label: String, expression: ExprSyntax)]()
        switch(attribute.arguments)
        {
            case .argumentList(let list):
                for item in list{
                    result.append((label: item.label?.description ?? "", expression: item.expression))
                }
            default:
                () // Do nothing.
        }
        return result
    }
}
