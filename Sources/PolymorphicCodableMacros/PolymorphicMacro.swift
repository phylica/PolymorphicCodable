import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


public struct Polymorphic: AccessorMacro, PeerMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.AccessorDeclSyntax] {
      
        if declaration.is(ProtocolDeclSyntax.self)
        {
            return []
        }
        
        if let variableDeclaration = declaration.as(VariableDeclSyntax.self)
        {
            return try variableAccessorsExpansion(variable: variableDeclaration)
        }
        
        throw PolymorphicCodableError.codableAppliedOnIncompatibleThing
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        
        if let protocolDeclaration = declaration.as(ProtocolDeclSyntax.self)
        {
            return try protocolPeersExpansion(protocol: protocolDeclaration, arguments: node.arguments)
        }
        
        if let variableDeclaration = declaration.as(VariableDeclSyntax.self)
        {
            return try variablePeersExpansion(variable: variableDeclaration)
        }
        
        throw PolymorphicCodableError.codableAppliedOnIncompatibleThing
    }
    
    public static func variablePeersExpansion(variable: VariableDeclSyntax) throws -> [SwiftSyntax.DeclSyntax]
    {
        
        guard let variableName = variable.bindings.first?.pattern.description,
              let variableType = variable.bindings.first?.typeAnnotation?.type else
        {
            throw PolymorphicCodableError.variableNotCorrectlyDeclared
        }
        
        let newTypeString : String = try replaceInnerName(variableType)
        return [
          """
            private var \(raw: variableName)PolymorphicEnum: \(raw: newTypeString)
          """
        ]
    }
    
    public static func variableAccessorsExpansion(variable: VariableDeclSyntax) throws -> [SwiftSyntax.AccessorDeclSyntax]
    {
        guard let variableName = variable.bindings.first?.pattern.description,
              let variableType = variable.bindings.first?.typeAnnotation?.type else
        {
            throw PolymorphicCodableError.variableNotCorrectlyDeclared
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
            
            
            throw PolymorphicCodableError.polymorphicVariableTypeNotManaged
        }
        if let type = variableType.as(ArrayTypeSyntax.self)
        {
            let wrappedType = type.element
            guard wrappedType.is(IdentifierTypeSyntax.self) else {
                throw PolymorphicCodableError.polymorphicVariableTypeNotManaged
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
        throw PolymorphicCodableError.polymorphicVariableTypeNotManaged
    }
    
    public static func protocolPeersExpansion(protocol protocolDeclaration: ProtocolDeclSyntax, arguments: AttributeSyntax.Arguments? ) throws -> [SwiftSyntax.DeclSyntax]
    {
        guard let arguments = arguments else
        {
            throw PolymorphicCodableError.codableProtocolMissingChildren
        }
        var types = [String]()
        switch(arguments)
        {
            case .argumentList(let list):
                list.forEach { (arg) in
                    types.append(String(arg.expression.description.split(separator: ".").first!))
                }
            default:
                throw PolymorphicCodableError.wrongArguments
        }
        
        var cases = ""
        for t in types{
            cases = cases + "case \(t.lowercasingFirstLetter())(\(t))\n"
        }
        
        let generic : String = protocolDeclaration.name.text
        
        var decoderCases : String = ""
        for t in types{
            decoderCases = decoderCases +
            """
               case \(t).staticCodedName:
                    guard let \(t.lowercasingFirstLetter()) = try? \(t)(from: decoder) else {
                        throw PolymorphicCodableError.couldNotDeserializeSubType("\(t)")
                    }
                    self = .\(t.lowercasingFirstLetter())(\(t.lowercasingFirstLetter()))
           """
        }
        
        let decoderInitializer =
          """
           init (from decoder: Decoder) throws {
              guard let \(generic.lowercasingFirstLetter()) = try? PolymorphicItem(from: decoder) else{
                  throw PolymorphicCodableError.missingTypeIndicator
              }
              switch \(generic.lowercasingFirstLetter()).type {
            \(decoderCases)
                  default:
                       throw PolymorphicCodableError.typeNotDeclaredAsSubtype(\(generic.lowercasingFirstLetter()).type)
              }
          }
          """
        
        var encoderCases : String = ""
        for t in types{
            encoderCases = encoderCases +
            """
               case .\(t.lowercasingFirstLetter())(let \(t.lowercasingFirstLetter())):
                    try \(t.lowercasingFirstLetter()).encode(to: encoder)
           """
        }
        
        let encoder =
          """
          func encode(to encoder: Encoder) throws {
              switch self {
              \(encoderCases)
              }
          }
          """
        
        var valueCases : String = ""
        for t in types{
            valueCases = valueCases +
            """
               case .\(t.lowercasingFirstLetter())(let \(t.lowercasingFirstLetter())):
                    return \(t.lowercasingFirstLetter())
            """
        }
        
        let valueGetter =
        """
        func value() -> \(generic) {
            switch self {
                \(valueCases)
            }
        }
        """
        
        var initializerCases : String = ""
        for t in types{
            initializerCases = initializerCases +
            """
               case let \(t.lowercasingFirstLetter()) as \(t):
                    self = .\(t.lowercasingFirstLetter())(\(t.lowercasingFirstLetter()))
            """
        }
        let valueInitializer =
        """
            init(_ \(generic.lowercasingFirstLetter()): \(generic)) throws
            {
                switch(\(generic.lowercasingFirstLetter()))
                {
                \(initializerCases)
                    default:
                        throw PolymorphicCodableError.typeNotDeclaredAsSubtype(String(describing: type(of: \(generic.lowercasingFirstLetter()))))
                }
            }  
        """
        
        
        return [
          """
          enum \(protocolDeclaration.name)PolymorphicEnum: Codable {
          \(raw: cases)
          
          \(raw: decoderInitializer)
          
          \(raw: encoder)
          
          \(raw: valueInitializer)
          
          \(raw: valueGetter)
          }
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
        throw PolymorphicCodableError.polymorphicVariableTypeNotManaged
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
        throw PolymorphicCodableError.polymorphicVariableTypeNotManaged
    }
}
