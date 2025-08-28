import PolymorphicCodable
import Foundation

@CodableProtocol(Tree.self, Flower.self)
protocol Plant: Codable
{
    var name: String {get set}
}

@CodableStructure
struct Tree: Plant
{
    var name: String
    var height: Int
}

@CodableStructure
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
    @CodableField var plants: [Plant]
}

var originalJson =
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

var result = try? JSONDecoder().decode(Garden.self, from: originalJson.data(using: .utf8)!)

assert(result?.name == "Babylone")
assert(result?.mainPlant.name == "Platane")
assert((result?.mainPlant as? Tree)?.height == 27)

assert(result?.plants.first?.name == "Tulipe")
assert((result?.plants.first as? Flower)?.petals == 8)
assert((result?.plants.first as? Flower)?.persistence == true)

assert(result?.plants.last?.name == "Érable")
assert((result?.plants.last as? Tree)?.height == 12)

let reserializedJson = (String(data: try JSONEncoder().encode(result) , encoding: String.Encoding.utf8))

assert(originalJson == reserializedJson)