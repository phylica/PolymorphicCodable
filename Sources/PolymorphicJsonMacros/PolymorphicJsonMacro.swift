import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


public struct CodableProtocol: PeerMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let protocolDeclaration = declaration.as(ProtocolDeclSyntax.self) else
        {
            throw PolymorphicJsonError.codableProtocolNotAppliedOnProtocol
        }
        guard let arguments = node.arguments else
        {
            throw PolymorphicJsonError.codableProtocolMissingChildren
        }
        var types = [String]()
        switch(arguments)
        {
            case .argumentList(let list):
                list.forEach { (arg) in
                    types.append(String(arg.expression.description.split(separator: ".").first!))
                }
            default:
                throw PolymorphicJsonError.wrongArguments
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
               case "\(t)":
                    guard let \(t.lowercasingFirstLetter()) = try? \(t)(from: decoder) else {
                        throw PolymorphicJsonError.couldNotDeserializeSubType("\(t)")
                    }
                    self = .\(t.lowercasingFirstLetter())(\(t.lowercasingFirstLetter()))
           """
        }
        
        let initializer =
        """
           init (from decoder: Decoder) throws {
              guard let \(generic.lowercasingFirstLetter()) = try? PolymorphicItem(from: decoder) else{
                  throw PolymorphicJsonError.missingTypeIndicator
              }
              switch \(generic.lowercasingFirstLetter()).type {
            \(decoderCases)
                  default:
                       throw PolymorphicJsonError.unknownType(\(generic.lowercasingFirstLetter()).type)
              }
          }
          """
        
        
        return [
          """
          enum \(protocolDeclaration.name)PolymorphicEnum {
          \(raw: cases)
          
          \(raw: initializer)
          }
          """
        ]
    }
}

@main
struct PolymorphicJsonPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CodableProtocol.self,
    ]
}
