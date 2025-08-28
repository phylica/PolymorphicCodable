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
    @CodableField var mainPlant: Plant
}

var json =
"""
{
 "name": "Babylone",
  "mainPlant": 
    {
      "$type": "Tree",
      "name": "Platane",
      "height": 27
   },
  "plants": [
    {
      "$type": "Flower",
      "name": "Tulipe",
      "petals": 8,
      "persistence": true
    },
    {
      "$type": "Tree",
      "name": "Érable",
      "height": 12
    }
  ]
}
"""

var result = try? JSONDecoder().decode(Garden.self, from: json.data(using: .utf8)!)

assert(result?.name == "Babylone")
assert(result?.mainPlant.name == "Platane")
assert((result?.mainPlant as? Tree)?.height == 27)