import Foundation

#if canImport(simd)
import simd

/// Represents a 3D point in space
public typealias Point3D = SIMD3<Float>
#else
/// Represents a 3D point in space
public struct Point3D {
    public var x: Float
    public var y: Float
    public var z: Float
    
    public init(_ x: Float, _ y: Float, _ z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    public static func +(lhs: Point3D, rhs: Point3D) -> Point3D {
        return Point3D(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }
    
    public static func *(lhs: Point3D, rhs: Float) -> Point3D {
        return Point3D(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }
    
    public static func -(lhs: Point3D, rhs: Point3D) -> Point3D {
        return Point3D(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }
}
#endif

/// Coordinate transformation utilities for converting geographic coordinates to 3D space
public struct CoordinateTransform {
    
    /// Configuration for coordinate transformation
    public struct Configuration {
        /// Origin point in geographic coordinates (longitude, latitude)
        public let origin: (longitude: Double, latitude: Double)
        
        /// Scale factor for converting degrees to meters (approximate)
        /// At the equator: 1 degree latitude ≈ 111,320 meters
        /// 1 degree longitude varies by latitude
        public let metersPerDegree: Double
        
        /// Scale factor to apply to all coordinates (useful for visualization)
        public let scale: Float
        
        /// Whether to invert the Y-axis (some coordinate systems use inverted Y)
        public let invertY: Bool
        
        public init(
            origin: (longitude: Double, latitude: Double) = (0, 0),
            metersPerDegree: Double = 111320.0,
            scale: Float = 1.0,
            invertY: Bool = false
        ) {
            self.origin = origin
            self.metersPerDegree = metersPerDegree
            self.scale = scale
            self.invertY = invertY
        }
    }
    
    private let config: Configuration
    
    public init(config: Configuration = Configuration()) {
        self.config = config
    }
    
    /// Convert a GeoJSON position (longitude, latitude, altitude) to a 3D point
    /// This method calculates the difference from the reference point (origin) and converts it to 3D coordinates
    /// - Parameter position: GeoJSON position array [longitude, latitude, altitude?]
    ///                       **IMPORTANT:** Longitude comes FIRST, latitude SECOND!
    /// - Returns: Point3D representing the offset from the origin in 3D space
    public func toPoint3D(_ position: Position) -> Point3D {
        guard position.count >= 2 else {
            #if canImport(simd)
            return SIMD3<Float>(0, 0, 0)
            #else
            return Point3D(0, 0, 0)
            #endif
        }
        
        let longitude = position[0]  // First element is longitude (East/West)
        let latitude = position[1]   // Second element is latitude (North/South)
        let altitude = position.count > 2 ? position[2] : 0.0
        
        // Validation: Check if coordinates might be swapped (common mistake)
        // Valid ranges: longitude [-180, 180], latitude [-90, 90]
        #if DEBUG
        if abs(longitude) > 180.0 || abs(latitude) > 90.0 {
            print("⚠️ Warning: Suspicious coordinates detected!")
            print("   Position: [\(longitude), \(latitude)]")
            print("   Longitude (position[0]) should be in range [-180, 180]")
            print("   Latitude (position[1]) should be in range [-90, 90]")
            print("   Did you swap latitude and longitude? GeoJSON uses [longitude, latitude] order!")
        }
        #endif
        
        // Calculate difference from origin (reference point)
        // This gives us the offset from the user's position when origin is set to user coordinates
        let deltaLon = longitude - config.origin.longitude
        let deltaLat = latitude - config.origin.latitude
        
        // Convert the geographic difference to meters (approximation)
        // X = longitude difference * meters per degree * cos(latitude) - East/West offset
        // Z = latitude difference * meters per degree - North/South offset
        // Y = altitude - Vertical offset
        let latRad = config.origin.latitude * .pi / 180.0
        let x = Float(deltaLon * config.metersPerDegree * cos(latRad)) * config.scale
        var y = Float(altitude) * config.scale
        let z = Float(deltaLat * config.metersPerDegree) * config.scale
        
        if config.invertY {
            y = -y
        }
        
        #if canImport(simd)
        return SIMD3<Float>(x, y, z)
        #else
        return Point3D(x, y, z)
        #endif
    }
    
    /// Convert an array of positions to an array of 3D points
    /// - Parameter positions: Array of GeoJSON positions
    /// - Returns: Array of Point3D points
    public func toPoints3D(_ positions: [Position]) -> [Point3D] {
        return positions.map { toPoint3D($0) }
    }
    
    /// Calculate the bounding box for a set of positions
    /// - Parameter positions: Array of GeoJSON positions
    /// - Returns: Tuple containing min and max corners of the bounding box
    public func boundingBox(for positions: [Position]) -> (min: Point3D, max: Point3D)? {
        guard !positions.isEmpty else { return nil }
        
        let points = toPoints3D(positions)
        
        var minPoint = points[0]
        var maxPoint = points[0]
        
        for point in points.dropFirst() {
            #if canImport(simd)
            minPoint = SIMD3<Float>(
                min(minPoint.x, point.x),
                min(minPoint.y, point.y),
                min(minPoint.z, point.z)
            )
            maxPoint = SIMD3<Float>(
                max(maxPoint.x, point.x),
                max(maxPoint.y, point.y),
                max(maxPoint.z, point.z)
            )
            #else
            minPoint = Point3D(
                min(minPoint.x, point.x),
                min(minPoint.y, point.y),
                min(minPoint.z, point.z)
            )
            maxPoint = Point3D(
                max(maxPoint.x, point.x),
                max(maxPoint.y, point.y),
                max(maxPoint.z, point.z)
            )
            #endif
        }
        
        return (min: minPoint, max: maxPoint)
    }
    
    /// Calculate the center point of a set of positions
    /// - Parameter positions: Array of GeoJSON positions
    /// - Returns: The center point as Point3D
    public func centerPoint(for positions: [Position]) -> Point3D? {
        guard let bbox = boundingBox(for: positions) else { return nil }
        let sum = bbox.min + bbox.max
        return sum * 0.5
    }
}
