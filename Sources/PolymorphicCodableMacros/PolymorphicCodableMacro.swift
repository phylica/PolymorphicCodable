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
            throw PolymorphicCodableError.codableProtocolNotAppliedOnProtocol
        }
        guard let arguments = node.arguments else
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
               case "\(t)":
                    guard let \(t.lowercasingFirstLetter()) = try? \(t)(from: decoder) else {
                        throw PolymorphicCodableError.couldNotDeserializeSubType("\(t)")
                    }
                    self = .\(t.lowercasingFirstLetter())(\(t.lowercasingFirstLetter()))
           """
        }
        
        let initializer =
        """
           init (from decoder: Decoder) throws {
              guard let \(generic.lowercasingFirstLetter()) = try? PolymorphicItem(from: decoder) else{
                  throw PolymorphicCodableError.missingTypeIndicator
              }
              switch \(generic.lowercasingFirstLetter()).type {
            \(decoderCases)
                  default:
                       throw PolymorphicCodableError.unknownType(\(generic.lowercasingFirstLetter()).type)
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
struct PolymorphicCodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CodableProtocol.self,
    ]
}
