//
//  Extensions.swift
//  PolymorphicJson
//
//  Created by Pierre Marandon on 27/08/2025.
//

extension String {
    func lowercasingFirstLetter() -> String {
        return prefix(1).lowercased() + self.lowercased().dropFirst()
    }
    
    mutating func lowercaseFirstLetter() {
        self = self.lowercasingFirstLetter()
    }
}