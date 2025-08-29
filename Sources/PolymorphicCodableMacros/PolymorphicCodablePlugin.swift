import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct PolymorphicCodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        Polymorphic.self,
        Codable.self,
        CodedName.self,
    ]
}
