import PolymorphicCodable
import Foundation

@Polymorphic(Tree.self, Flower.self)
protocol Plant
{
    var name: String {get set}
}

@Codable(codedName: "Baum")
struct Tree: Plant
{
    var name: String
    var height: Int
}

@Codable
struct Flower: Plant
{
    var name: String
    @CodedName("pepetatals") var petals: Int
    var persistence: Bool
}

@Codable
struct Garden
{
    var name: String
    @Polymorphic var mainPlant: Plant
    @CodedName("pflanzen") @Polymorphic var plants: [Plant]
}

var originalJson =
"""
{
 "name": "Babylone",
  "mainPlant": 
    {
      "$type": "Baum",
      "name": "Platane",
      "height": 27
   },
  "pflanzen": [
    {
      "$type": "Flower",
      "name": "Tulipe",
      "pepetatals": 8,
      "persistence": true
    },
    {
      "$type": "Baum",
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
