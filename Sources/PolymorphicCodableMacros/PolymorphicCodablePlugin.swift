import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct PolymorphicCodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CodableProtocol.self,
        CodableField.self,
    ]
}
