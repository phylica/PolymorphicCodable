import Cocoa

protocol Plant: Codable
{
    var name: String {get set}
}

struct Tree: Plant
{
    private let polymorphicType: String = "Tree"
    var name: String
    var height: Int
    enum CodingKeys: String, CodingKey {
        case polymorphicType = "$type"
        case name
        case height
    }
}

extension Tree: Codable{
}

struct Flower: Plant
{
    private let polymorphicType: String = "Flower"
    var name: String
    var petals: Int
    var persistence: Bool
}

extension Flower: Codable{
    enum CodingKeys: String, CodingKey {
        case polymorphicType = "$type"
        case name
        case petals
        case persistence
    }
}

struct Garden: Codable
{
    var name: String
    var plant: Plant
    {
        get{
            plantPolymorphicEnum.value()
        }
        set{
            do{
                plantPolymorphicEnum = try PlantPolymorphicEnum(newValue)
            }catch (let error){
                fatalError(String(describing: error))
            }
        }
    }
    private var plantPolymorphicEnum: PlantPolymorphicEnum
    
    enum CodingKeys: String, CodingKey {
        case name
        case plantPolymorphicEnum = "plant"
    }
}

enum PolymorphicJsonError: Error
{
    case missingTypeIndicator
    case typeNotDeclaredAsSubtype(String)
    case couldNotDeserializeSubType(String)
}

enum PlantPolymorphicEnum: Codable {
    case tree(Tree)
    case flower(Flower)
    
    init (from decoder: Decoder) throws {
        guard let plant = try? PolymorphicItem(from: decoder) else{
            throw PolymorphicJsonError.missingTypeIndicator
        }
        switch plant.type {
            case "Tree":
                guard let tree = try? Tree(from: decoder) else {
                    throw PolymorphicJsonError.couldNotDeserializeSubType("Tree")
                }
                self = .tree(tree)
            case "Flower":
                guard let flower = try? Flower(from: decoder) else{
                    throw PolymorphicJsonError.couldNotDeserializeSubType("Flower")
                }
                self = .flower(flower)
            default:
                throw PolymorphicJsonError.typeNotDeclaredAsSubtype(plant.type)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        switch self {
            case .tree(let tree):
                try tree.encode(to: encoder)
            case .flower(let flower):
                try flower.encode(to: encoder)
        }
    }
    
    init(_ plant: Plant) throws
    {
        switch(plant)
        {
            case let tree as Tree:
                self = .tree(tree)
            case let flower as Flower:
                self = .flower(flower)
            default:
                throw PolymorphicJsonError.typeNotDeclaredAsSubtype(String(describing: type(of: plant)))
        }
    }
    
    func value() -> Plant {
        switch self {
            case .tree(let tree):
                return tree
            case .flower(let flower):
                return flower
        }
    }
}

struct PolymorphicItem: Codable
{
    var type: String
    enum CodingKeys: String, CodingKey {
        case type = "$type"
    }
}

var json =
"""
{
  "plants": [
    {
      "$type": "Flower",
      "name": "Tulipe",
      "petals": 8,
      "persistence": true
    },
    {
      "$type": "Tree",
      "name": "Platane",
      "height": 27
    }
  ]
}
"""

var json1 =
"""
{
 "name": "Babylone",
  "plant": 
    {
      "$type": "Tree",
      "name": "Platane",
      "height": 30
   }
}
"""

var result = try? JSONDecoder().decode(Garden.self, from: json1.data(using: .utf8)!)

var reserializedData = try? JSONEncoder().encode(result)

var reserialized = String(data: reserializedData!, encoding: String.Encoding.utf8)
