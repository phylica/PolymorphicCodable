import SwiftSyntax

extension String {
    func lowercasingFirstLetter() -> String {
        return prefix(1).lowercased() + self.lowercased().dropFirst()
    }
    
    mutating func lowercaseFirstLetter() {
        self = self.lowercasingFirstLetter()
    }
}

extension TypeSyntax {
    
    var innerName : String{
        get throws{
            if let type = self.as(OptionalTypeSyntax.self)
            {
                let wrappedType = type.wrappedType
                return try wrappedType.innerName
            }
            if let type = self.as(ArrayTypeSyntax.self)
            {
                let wrappedType = type.element
                return try wrappedType.innerName
            }
            if let type = self.as(IdentifierTypeSyntax.self)
            {
                return type.name.description
            }
            throw PolymorphicCodableError.polymorphicVariableTypeNotManaged
        }
    }
}