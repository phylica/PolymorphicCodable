public struct PolymorphicItem: Codable
{
    public var type: String
    enum CodingKeys: String, CodingKey {
        case type = "$type"
    }
}