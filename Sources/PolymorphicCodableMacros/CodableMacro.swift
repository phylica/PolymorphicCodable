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
        var initAffectations = ""
        var initParameters = ""
        for member in structure.memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self) else
            {
                continue
            }
            guard let variableName = variable.bindings.first?.pattern.description,
                  let variableType = variable.bindings.first?.typeAnnotation?.type.trimmed else
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
                
                if let type = variableType.as(OptionalTypeSyntax.self)
                {
                    let wrappedType = type.wrappedType
                    if wrappedType.is(ArrayTypeSyntax.self)
                    {
                        initAffectations = initAffectations + "self.\(variableName)PolymorphicEnum = try \(variableName)?.map{ try \(try variableType.innerName)PolymorphicEnum($0)}\n"
                    }
                    else if wrappedType.is(IdentifierTypeSyntax.self)
                    {
                        initAffectations = initAffectations + "self.\(variableName)PolymorphicEnum = \(variableName) == nil ? nil : try \(try variableType.innerName)PolymorphicEnum(\(variableName)!)\n"
                    }
                    else{
                        throw PolymorphicCodableError.polymorphicVariableTypeNotManaged
                    }
                }
                else if variableType.is(ArrayTypeSyntax.self)
                {
                    initAffectations = initAffectations + "self.\(variableName)PolymorphicEnum = try \(variableName).map{ try  \(try variableType.innerName)PolymorphicEnum($0)}\n"
                }
                else if variableType.is(IdentifierTypeSyntax.self)
                {
                    initAffectations = initAffectations + "self.\(variableName)PolymorphicEnum = try \(try variableType.innerName)PolymorphicEnum(\(variableName))\n"
                }
                else
                {
                    throw PolymorphicCodableError.polymorphicVariableTypeNotManaged
                }
                
                
            }else{
                if let codedName{
                    keys = keys + "case \(variableName) = \"\(codedName)\"\n"
                }
                else{
                    keys = keys + "case \(variableName)\n"
                }
                initAffectations = initAffectations + "self.\(variableName) = \(variableName)\n"
            }
            if variableType.is(OptionalTypeSyntax.self) {
                initParameters  = initParameters + "\(variableName): \(variableType) = nil,"
            }else{
                initParameters  = initParameters + "\(variableName): \(variableType),"
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
          """,
            """
       init(\(raw: initParameters)) {
      do{
        \(raw: initAffectations)
      }catch(let error){
        fatalError(error.localizedDescription)
      }
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
        guard let name = structure?.name.trimmed.text ?? enumerated?.name.trimmed.text else
        {
            throw PolymorphicCodableError.codableAppliedOnIncompatibleThing
        }
        
        
        
        let codableExtension: DeclSyntax =
      """
      extension \(raw:name): Codable {}
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
