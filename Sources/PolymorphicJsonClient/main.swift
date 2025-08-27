import PolymorphicJson

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