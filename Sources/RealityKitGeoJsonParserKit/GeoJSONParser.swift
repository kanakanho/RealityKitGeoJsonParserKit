import Foundation

/// GeoJSON Parser for parsing GeoJSON data from various sources
public struct GeoJSONParser {
    
    /// Parse GeoJSON data from JSON string
    /// - Parameter jsonString: JSON string containing GeoJSON data
    /// - Returns: FeatureCollection parsed from the JSON
    /// - Throws: Error if parsing fails
    public static func parse(jsonString: String) throws -> FeatureCollection {
        guard let data = jsonString.data(using: .utf8) else {
            throw GeoJSONError.invalidData
        }
        return try parse(data: data)
    }
    
    /// Parse GeoJSON data from Data
    /// - Parameter data: Data containing GeoJSON
    /// - Returns: FeatureCollection parsed from the data
    /// - Throws: Error if parsing fails
    public static func parse(data: Data) throws -> FeatureCollection {
        let decoder = JSONDecoder()
        return try decoder.decode(FeatureCollection.self, from: data)
    }
    
    /// Parse GeoJSON from a file URL
    /// - Parameter url: URL to the GeoJSON file
    /// - Returns: FeatureCollection parsed from the file
    /// - Throws: Error if file reading or parsing fails
    public static func parse(from url: URL) throws -> FeatureCollection {
        let data = try Data(contentsOf: url)
        return try parse(data: data)
    }
    
    /// Parse a single Feature from JSON string
    /// - Parameter jsonString: JSON string containing a GeoJSON Feature
    /// - Returns: Feature parsed from the JSON
    /// - Throws: Error if parsing fails
    public static func parseFeature(jsonString: String) throws -> Feature {
        guard let data = jsonString.data(using: .utf8) else {
            throw GeoJSONError.invalidData
        }
        let decoder = JSONDecoder()
        return try decoder.decode(Feature.self, from: data)
    }
    
    /// Parse a single Geometry from JSON string
    /// - Parameter jsonString: JSON string containing a GeoJSON Geometry
    /// - Returns: Geometry parsed from the JSON
    /// - Throws: Error if parsing fails
    public static func parseGeometry(jsonString: String) throws -> Geometry {
        guard let data = jsonString.data(using: .utf8) else {
            throw GeoJSONError.invalidData
        }
        let decoder = JSONDecoder()
        return try decoder.decode(Geometry.self, from: data)
    }
}

/// GeoJSON related errors
public enum GeoJSONError: Error {
    case invalidData
    case invalidCoordinates
    case unsupportedGeometryType
    
    public var localizedDescription: String {
        switch self {
        case .invalidData:
            return "Invalid GeoJSON data"
        case .invalidCoordinates:
            return "Invalid coordinates in GeoJSON"
        case .unsupportedGeometryType:
            return "Unsupported geometry type"
        }
    }
}
