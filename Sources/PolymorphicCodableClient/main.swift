import PolymorphicCodable
import Foundation

@CodableProtocol(Tree.self, Flower.self)
protocol Plant: Codable
{
    var name: String {get set}
}

struct Tree: Plant
{
    var name: String
    var height: Int
}

struct Flower: Plant
{
    var name: String
    var petals: Int
    var persistence: Bool
}

@CodableStructure
struct Garden: Codable
{
    var name: String
    @CodableField var plant: Plant
}

var json1 =
"""
{
 "name": "Babylone",
  "plant": 
    {
      "$type": "Tree",
      "name": "Platane",
      "height": 27
   }
}
"""

var result = try? JSONDecoder().decode(Garden.self, from: json1.data(using: .utf8)!)