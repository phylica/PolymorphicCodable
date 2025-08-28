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
        
        if let type = variableType.as(OptionalTypeSyntax.self)
        {
            let wrappedType = type.wrappedType
            if wrappedType.is(ArrayTypeSyntax.self)
            {
                return [
          """
            get{
             return \(raw: variableName)PolymorphicEnum?.map{$0.value()}
            }
            set{
                guard let newValue != nil else
                { return nil }
                do{
                    \(raw: variableName)PolymorphicEnum = try newValue.map{ try \(raw:  try getInnerName(variableType))PolymorphicEnum($0)}
                }catch (let error){
                    fatalError(String(describing: error))
                }
            }
          """
                ]
            }
            if wrappedType.is(IdentifierTypeSyntax.self)
            {
                return [
          """
            get{
             return \(raw: variableName)PolymorphicEnum?.value()
            }
            set{
                guard let newValue != nil else 
                { return nil }
                do{
                    \(raw: variableName)PolymorphicEnum = try \(raw:  try getInnerName(variableType))PolymorphicEnum(newValue)
                }catch (let error){
                    fatalError(String(describing: error))
                }
            }
          """
                ]
            }
            
            
            throw PolymorphicCodableError.codableFieldTypeNotManaged
        }
        if let type = variableType.as(ArrayTypeSyntax.self)
        {
            let wrappedType = type.element
            guard wrappedType.is(IdentifierTypeSyntax.self) else {
                throw PolymorphicCodableError.codableFieldTypeNotManaged
            }
            return [
          """
            get{
             return \(raw: variableName)PolymorphicEnum.map{$0.value()}
            }
            set{
                do{
                    \(raw: variableName)PolymorphicEnum = try newValue.map{try \(raw: try getInnerName(variableType))PolymorphicEnum($0)}
                }catch (let error){
                    fatalError(String(describing: error))
                }
            }
          """
            ]
        }
        if variableType.is(IdentifierTypeSyntax.self)
        {
            return [
          """
            get{
             return \(raw: variableName)PolymorphicEnum.value()
            }
            set{
                do{
                    \(raw: variableName)PolymorphicEnum = try \(raw: try getInnerName(variableType))PolymorphicEnum(newValue)
                }catch (let error){
                    fatalError(String(describing: error))
                }
            }
          """
            ]
        }
        throw PolymorphicCodableError.codableFieldTypeNotManaged
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let variableDeclaration = declaration.as(VariableDeclSyntax.self) else
        {
            throw PolymorphicCodableError.codableFieldNotAppliedOnField
        }
        
        guard let variableName = variableDeclaration.bindings.first?.pattern.description,
              let variableType = variableDeclaration.bindings.first?.typeAnnotation?.type else
        {
            throw PolymorphicCodableError.codableFieldNotCorrectlyDeclared
        }
        
        let newTypeString : String = try replaceInnerName(variableType)
            return [
          """
            private var \(raw: variableName)PolymorphicEnum: \(raw: newTypeString)
          """
            ]
        
    }
    
    private static func replaceInnerName(_ type: TypeSyntax) throws -> String{
        if let type = type.as(OptionalTypeSyntax.self)
        {
            let wrappedType = type.wrappedType
            return try "\(replaceInnerName(wrappedType))?"
        }
        if let type = type.as(ArrayTypeSyntax.self)
        {
            let wrappedType = type.element
            return try "[\(replaceInnerName(wrappedType))]"
        }
        if let type = type.as(IdentifierTypeSyntax.self)
        {
            return "\(type.name)PolymorphicEnum"
        }
        throw PolymorphicCodableError.codableFieldTypeNotManaged
    }
    
    private static func getInnerName(_ type: TypeSyntax) throws -> String{
        if let type = type.as(OptionalTypeSyntax.self)
        {
            let wrappedType = type.wrappedType
            return try getInnerName(wrappedType)
        }
        if let type = type.as(ArrayTypeSyntax.self)
        {
            let wrappedType = type.element
            return try getInnerName(wrappedType)
        }
        if let type = type.as(IdentifierTypeSyntax.self)
        {
            return type.name.description
        }
        throw PolymorphicCodableError.codableFieldTypeNotManaged
    }
}
