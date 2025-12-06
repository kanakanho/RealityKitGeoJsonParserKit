/// RealityKitGeoJsonParserKit
///
/// A library for parsing GeoJSON format data and converting it to RealityKit entities.
///
/// ## Overview
///
/// This library provides functionality to:
/// - Parse GeoJSON data (Point, LineString, Polygon, MultiPoint, MultiLineString, MultiPolygon, GeometryCollection)
/// - Transform geographic coordinates to 3D space
/// - Convert GeoJSON geometries to RealityKit ModelEntity objects
///
/// ## Usage Example
///
/// ```swift
/// import RealityKitGeoJsonParserKit
/// import RealityKit
///
/// // Parse GeoJSON data
/// let jsonString = """
/// {
///   "type": "FeatureCollection",
///   "features": [
///     {
///       "type": "Feature",
///       "geometry": {
///         "type": "Point",
///         "coordinates": [139.7671, 35.6812]
///       }
///     }
///   ]
/// }
/// """
///
/// let featureCollection = try GeoJSONParser.parse(jsonString: jsonString)
///
/// // Convert to RealityKit entity
/// let transform = CoordinateTransform(
///     config: .init(origin: (139.7671, 35.6812), scale: 100.0)
/// )
/// let entity = featureCollection.toModelEntity(transform: transform)
/// ```
///
/// ## Topics
///
/// ### Parsing GeoJSON
/// - ``GeoJSONParser``
/// - ``FeatureCollection``
/// - ``Feature``
/// - ``Geometry``
///
/// ### Coordinate Transformation
/// - ``CoordinateTransform``
///
/// ### RealityKit Integration
/// - ``Geometry/toModelEntity(transform:material:)``
/// - ``Feature/toModelEntity(transform:material:)``
/// - ``FeatureCollection/toModelEntity(transform:material:)``
