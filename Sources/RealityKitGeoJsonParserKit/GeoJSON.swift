import Foundation

/// GeoJSON Position: [longitude, latitude, altitude (optional)]
/// 
/// **IMPORTANT:** GeoJSON uses [longitude, latitude] order, NOT [latitude, longitude]!
/// - Longitude comes FIRST (East/West: -180 to +180)
/// - Latitude comes SECOND (North/South: -90 to +90)
/// 
/// Example: Tokyo Station is at [139.7671, 35.6812] (longitude first, then latitude)
public typealias Position = [Double]

/// GeoJSON Geometry Types
public enum GeometryType: String, Codable {
    case point = "Point"
    case lineString = "LineString"
    case polygon = "Polygon"
    case multiPoint = "MultiPoint"
    case multiLineString = "MultiLineString"
    case multiPolygon = "MultiPolygon"
    case geometryCollection = "GeometryCollection"
}

/// GeoJSON Geometry
public indirect enum Geometry: Codable {
    case point(coordinates: Position)
    case lineString(coordinates: [Position])
    case polygon(coordinates: [[Position]])
    case multiPoint(coordinates: [Position])
    case multiLineString(coordinates: [[Position]])
    case multiPolygon(coordinates: [[[Position]]])
    case geometryCollection(geometries: [Geometry])
    
    private enum CodingKeys: String, CodingKey {
        case type
        case coordinates
        case geometries
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(GeometryType.self, forKey: .type)
        
        switch type {
        case .point:
            let coordinates = try container.decode(Position.self, forKey: .coordinates)
            self = .point(coordinates: coordinates)
        case .lineString:
            let coordinates = try container.decode([Position].self, forKey: .coordinates)
            self = .lineString(coordinates: coordinates)
        case .polygon:
            let coordinates = try container.decode([[Position]].self, forKey: .coordinates)
            self = .polygon(coordinates: coordinates)
        case .multiPoint:
            let coordinates = try container.decode([Position].self, forKey: .coordinates)
            self = .multiPoint(coordinates: coordinates)
        case .multiLineString:
            let coordinates = try container.decode([[Position]].self, forKey: .coordinates)
            self = .multiLineString(coordinates: coordinates)
        case .multiPolygon:
            let coordinates = try container.decode([[[Position]]].self, forKey: .coordinates)
            self = .multiPolygon(coordinates: coordinates)
        case .geometryCollection:
            let geometries = try container.decode([Geometry].self, forKey: .geometries)
            self = .geometryCollection(geometries: geometries)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .point(let coordinates):
            try container.encode(GeometryType.point, forKey: .type)
            try container.encode(coordinates, forKey: .coordinates)
        case .lineString(let coordinates):
            try container.encode(GeometryType.lineString, forKey: .type)
            try container.encode(coordinates, forKey: .coordinates)
        case .polygon(let coordinates):
            try container.encode(GeometryType.polygon, forKey: .type)
            try container.encode(coordinates, forKey: .coordinates)
        case .multiPoint(let coordinates):
            try container.encode(GeometryType.multiPoint, forKey: .type)
            try container.encode(coordinates, forKey: .coordinates)
        case .multiLineString(let coordinates):
            try container.encode(GeometryType.multiLineString, forKey: .type)
            try container.encode(coordinates, forKey: .coordinates)
        case .multiPolygon(let coordinates):
            try container.encode(GeometryType.multiPolygon, forKey: .type)
            try container.encode(coordinates, forKey: .coordinates)
        case .geometryCollection(let geometries):
            try container.encode(GeometryType.geometryCollection, forKey: .type)
            try container.encode(geometries, forKey: .geometries)
        }
    }
    
    /// Returns the geometry type
    public var type: GeometryType {
        switch self {
        case .point: return .point
        case .lineString: return .lineString
        case .polygon: return .polygon
        case .multiPoint: return .multiPoint
        case .multiLineString: return .multiLineString
        case .multiPolygon: return .multiPolygon
        case .geometryCollection: return .geometryCollection
        }
    }
}

/// GeoJSON Feature
public struct Feature: Codable {
    public let type: String
    public let geometry: Geometry?
    public let properties: [String: AnyCodable]?
    public let id: AnyCodable?
    
    public init(geometry: Geometry?, properties: [String: AnyCodable]? = nil, id: AnyCodable? = nil) {
        self.type = "Feature"
        self.geometry = geometry
        self.properties = properties
        self.id = id
    }
}

/// GeoJSON FeatureCollection
public struct FeatureCollection: Codable {
    public let type: String
    public let features: [Feature]
    
    public init(features: [Feature]) {
        self.type = "FeatureCollection"
        self.features = features
    }
}

/// Helper struct to handle dynamic JSON values
/// Note: This is a lightweight implementation for self-contained library functionality.
/// For more complex use cases, consider using a third-party JSON handling library.
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable value cannot be decoded"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        case is NSNull:
            try container.encodeNil()
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "AnyCodable value cannot be encoded"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}
