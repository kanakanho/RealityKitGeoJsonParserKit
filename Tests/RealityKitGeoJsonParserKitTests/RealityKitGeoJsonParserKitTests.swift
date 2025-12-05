import Testing
import Foundation
@testable import RealityKitGeoJsonParserKit

// MARK: - GeoJSON Parsing Tests

@Test func testParsePoint() throws {
    let json = """
    {
        "type": "Point",
        "coordinates": [139.7671, 35.6812]
    }
    """
    
    let geometry = try GeoJSONParser.parseGeometry(jsonString: json)
    
    if case .point(let coordinates) = geometry {
        #expect(coordinates.count == 2)
        #expect(coordinates[0] == 139.7671)
        #expect(coordinates[1] == 35.6812)
    } else {
        Issue.record("Expected point geometry")
    }
}

@Test func testParseLineString() throws {
    let json = """
    {
        "type": "LineString",
        "coordinates": [
            [139.7671, 35.6812],
            [139.7681, 35.6822],
            [139.7691, 35.6832]
        ]
    }
    """
    
    let geometry = try GeoJSONParser.parseGeometry(jsonString: json)
    
    if case .lineString(let coordinates) = geometry {
        #expect(coordinates.count == 3)
        #expect(coordinates[0][0] == 139.7671)
        #expect(coordinates[2][1] == 35.6832)
    } else {
        Issue.record("Expected lineString geometry")
    }
}

@Test func testParsePolygon() throws {
    let json = """
    {
        "type": "Polygon",
        "coordinates": [
            [
                [139.7671, 35.6812],
                [139.7681, 35.6812],
                [139.7681, 35.6822],
                [139.7671, 35.6822],
                [139.7671, 35.6812]
            ]
        ]
    }
    """
    
    let geometry = try GeoJSONParser.parseGeometry(jsonString: json)
    
    if case .polygon(let coordinates) = geometry {
        #expect(coordinates.count == 1)
        #expect(coordinates[0].count == 5)
    } else {
        Issue.record("Expected polygon geometry")
    }
}

@Test func testParseFeature() throws {
    let json = """
    {
        "type": "Feature",
        "geometry": {
            "type": "Point",
            "coordinates": [139.7671, 35.6812]
        },
        "properties": {
            "name": "Tokyo"
        }
    }
    """
    
    let feature = try GeoJSONParser.parseFeature(jsonString: json)
    
    #expect(feature.type == "Feature")
    #expect(feature.geometry != nil)
    
    if let properties = feature.properties {
        #expect(properties["name"] != nil)
    }
}

@Test func testParseFeatureCollection() throws {
    let json = """
    {
        "type": "FeatureCollection",
        "features": [
            {
                "type": "Feature",
                "geometry": {
                    "type": "Point",
                    "coordinates": [139.7671, 35.6812]
                },
                "properties": {
                    "name": "Tokyo"
                }
            },
            {
                "type": "Feature",
                "geometry": {
                    "type": "Point",
                    "coordinates": [139.6917, 35.6895]
                },
                "properties": {
                    "name": "Shinjuku"
                }
            }
        ]
    }
    """
    
    let collection = try GeoJSONParser.parse(jsonString: json)
    
    #expect(collection.type == "FeatureCollection")
    #expect(collection.features.count == 2)
}

@Test func testParseMultiPoint() throws {
    let json = """
    {
        "type": "MultiPoint",
        "coordinates": [
            [139.7671, 35.6812],
            [139.7681, 35.6822]
        ]
    }
    """
    
    let geometry = try GeoJSONParser.parseGeometry(jsonString: json)
    
    if case .multiPoint(let coordinates) = geometry {
        #expect(coordinates.count == 2)
    } else {
        Issue.record("Expected multiPoint geometry")
    }
}

@Test func testParseMultiLineString() throws {
    let json = """
    {
        "type": "MultiLineString",
        "coordinates": [
            [[139.7671, 35.6812], [139.7681, 35.6822]],
            [[139.7691, 35.6832], [139.7701, 35.6842]]
        ]
    }
    """
    
    let geometry = try GeoJSONParser.parseGeometry(jsonString: json)
    
    if case .multiLineString(let coordinates) = geometry {
        #expect(coordinates.count == 2)
        #expect(coordinates[0].count == 2)
    } else {
        Issue.record("Expected multiLineString geometry")
    }
}

@Test func testParseMultiPolygon() throws {
    let json = """
    {
        "type": "MultiPolygon",
        "coordinates": [
            [
                [
                    [139.7671, 35.6812],
                    [139.7681, 35.6812],
                    [139.7681, 35.6822],
                    [139.7671, 35.6822],
                    [139.7671, 35.6812]
                ]
            ],
            [
                [
                    [139.7691, 35.6832],
                    [139.7701, 35.6832],
                    [139.7701, 35.6842],
                    [139.7691, 35.6842],
                    [139.7691, 35.6832]
                ]
            ]
        ]
    }
    """
    
    let geometry = try GeoJSONParser.parseGeometry(jsonString: json)
    
    if case .multiPolygon(let coordinates) = geometry {
        #expect(coordinates.count == 2)
    } else {
        Issue.record("Expected multiPolygon geometry")
    }
}

@Test func testParseGeometryCollection() throws {
    let json = """
    {
        "type": "GeometryCollection",
        "geometries": [
            {
                "type": "Point",
                "coordinates": [139.7671, 35.6812]
            },
            {
                "type": "LineString",
                "coordinates": [
                    [139.7671, 35.6812],
                    [139.7681, 35.6822]
                ]
            }
        ]
    }
    """
    
    let geometry = try GeoJSONParser.parseGeometry(jsonString: json)
    
    if case .geometryCollection(let geometries) = geometry {
        #expect(geometries.count == 2)
    } else {
        Issue.record("Expected geometryCollection")
    }
}

// MARK: - Coordinate Transformation Tests

@Test func testCoordinateTransformBasic() {
    let transform = CoordinateTransform()
    let position: Position = [139.7671, 35.6812]
    
    let point3D = transform.toPoint3D(position)
    
    // Should not be zero
    #expect(point3D.x != 0 || point3D.z != 0)
}

@Test func testCoordinateTransformWithOrigin() {
    let config = CoordinateTransform.Configuration(
        origin: (139.7671, 35.6812),
        scale: 1.0
    )
    let transform = CoordinateTransform(config: config)
    
    // Transform the origin point itself
    let position: Position = [139.7671, 35.6812]
    let point3D = transform.toPoint3D(position)
    
    // Origin should map to (0, 0, 0)
    #expect(abs(point3D.x) < 0.001)
    #expect(abs(point3D.y) < 0.001)
    #expect(abs(point3D.z) < 0.001)
}

@Test func testCoordinateTransformWithScale() {
    let config = CoordinateTransform.Configuration(
        origin: (0, 0),
        scale: 100.0
    )
    let transform = CoordinateTransform(config: config)
    
    let position: Position = [1.0, 1.0]
    let point3D = transform.toPoint3D(position)
    
    // With scale, values should be larger
    #expect(abs(point3D.x) > 1000.0 || abs(point3D.z) > 1000.0)
}

@Test func testCoordinateTransformWithAltitude() {
    let transform = CoordinateTransform()
    let position: Position = [139.7671, 35.6812, 100.0]
    
    let point3D = transform.toPoint3D(position)
    
    // Y should reflect altitude
    #expect(point3D.y == 100.0)
}

@Test func testBoundingBox() {
    let transform = CoordinateTransform()
    let positions: [Position] = [
        [0, 0],
        [1, 1],
        [2, 2]
    ]
    
    let bbox = transform.boundingBox(for: positions)
    
    #expect(bbox != nil)
    if let bbox = bbox {
        // Min should be less than max
        #expect(bbox.min.x <= bbox.max.x)
        #expect(bbox.min.y <= bbox.max.y)
        #expect(bbox.min.z <= bbox.max.z)
    }
}

@Test func testCenterPoint() {
    let transform = CoordinateTransform()
    let positions: [Position] = [
        [0, 0],
        [2, 2]
    ]
    
    let center = transform.centerPoint(for: positions)
    
    #expect(center != nil)
}

@Test func testMultiplePoints() {
    let transform = CoordinateTransform()
    let positions: [Position] = [
        [139.7671, 35.6812],
        [139.7681, 35.6822],
        [139.7691, 35.6832]
    ]
    
    let points = transform.toPoints3D(positions)
    
    #expect(points.count == 3)
}

// MARK: - Error Handling Tests

@Test func testInvalidJSON() throws {
    let json = "{ invalid json }"
    
    #expect(throws: Error.self) {
        try GeoJSONParser.parse(jsonString: json)
    }
}

@Test func testInvalidDataError() throws {
    #expect(throws: Error.self) {
        let invalidData = Data([0xFF, 0xFE])
        _ = try GeoJSONParser.parse(data: invalidData)
    }
}

// MARK: - Geometry Type Tests

@Test func testGeometryTypeProperty() throws {
    let pointJSON = """
    {
        "type": "Point",
        "coordinates": [139.7671, 35.6812]
    }
    """
    
    let geometry = try GeoJSONParser.parseGeometry(jsonString: pointJSON)
    #expect(geometry.type == .point)
}

// MARK: - GeoJSONModelEntity Tests

#if canImport(RealityKit)
@Test func testGeoJSONModelEntityProperties() throws {
    let pointJSON = """
    {
        "type": "Point",
        "coordinates": [139.7671, 35.6812, 50.0]
    }
    """
    
    let geometry = try GeoJSONParser.parseGeometry(jsonString: pointJSON)
    
    let config = CoordinateTransform.Configuration(
        origin: (139.7671, 35.6812),
        scale: 1.0
    )
    let transform = CoordinateTransform(config: config)
    
    let entity = geometry.toGeoJSONModelEntity(transform: transform)
    
    #expect(entity != nil)
    if let entity = entity {
        // Check that geometry is stored
        #expect(entity.geometry != nil)
        
        // Check that transform is stored
        #expect(entity.coordinateTransform != nil)
    }
}

@Test func testGeoJSONModelEntityUpdateTransform() throws {
    let pointJSON = """
    {
        "type": "Point",
        "coordinates": [139.7671, 35.6812]
    }
    """
    
    let geometry = try GeoJSONParser.parseGeometry(jsonString: pointJSON)
    
    let initialConfig = CoordinateTransform.Configuration(
        origin: (139.7671, 35.6812),
        scale: 1.0
    )
    let initialTransform = CoordinateTransform(config: initialConfig)
    
    let entity = geometry.toGeoJSONModelEntity(transform: initialTransform)
    
    #expect(entity != nil)
    if let entity = entity {
        // Update transform with new scale
        let newConfig = CoordinateTransform.Configuration(
            origin: (139.7671, 35.6812),
            scale: 100.0
        )
        let newTransform = CoordinateTransform(config: newConfig)
        
        entity.updateTransform(newTransform)
        
        // Verify transform was updated
        #expect(entity.coordinateTransform != nil)
    }
}

@Test func testFeatureToGeoJSONModelEntity() throws {
    let featureJSON = """
    {
        "type": "Feature",
        "geometry": {
            "type": "Point",
            "coordinates": [139.7671, 35.6812]
        },
        "properties": {
            "name": "Tokyo"
        }
    }
    """
    
    let feature = try GeoJSONParser.parseFeature(jsonString: featureJSON)
    
    let transform = CoordinateTransform()
    let entity = feature.toGeoJSONModelEntity(transform: transform)
    
    #expect(entity != nil)
    if let entity = entity {
        #expect(entity.geometry != nil)
    }
}

@Test func testFeatureCollectionToGeoJSONModelEntity() throws {
    let collectionJSON = """
    {
        "type": "FeatureCollection",
        "features": [
            {
                "type": "Feature",
                "geometry": {
                    "type": "Point",
                    "coordinates": [139.7671, 35.6812]
                }
            },
            {
                "type": "Feature",
                "geometry": {
                    "type": "Point",
                    "coordinates": [139.7681, 35.6822]
                }
            }
        ]
    }
    """
    
    let collection = try GeoJSONParser.parse(jsonString: collectionJSON)
    
    let transform = CoordinateTransform()
    let containerEntity = collection.toGeoJSONModelEntity(transform: transform)
    
    // Should have 2 children (one for each feature)
    #expect(containerEntity.children.count == 2)
}
#endif

// MARK: - Integration Tests

@Test func testCompleteWorkflow() throws {
    // Create a complete GeoJSON workflow
    let json = """
    {
        "type": "FeatureCollection",
        "features": [
            {
                "type": "Feature",
                "geometry": {
                    "type": "Point",
                    "coordinates": [139.7671, 35.6812, 50.0]
                },
                "properties": {
                    "name": "Tokyo Tower",
                    "height": 333
                }
            }
        ]
    }
    """
    
    // Parse
    let collection = try GeoJSONParser.parse(jsonString: json)
    #expect(collection.features.count == 1)
    
    // Get feature
    let feature = collection.features[0]
    #expect(feature.properties != nil)
    
    // Transform coordinates
    let config = CoordinateTransform.Configuration(
        origin: (139.7671, 35.6812),
        scale: 1.0
    )
    let transform = CoordinateTransform(config: config)
    
    if let geometry = feature.geometry,
       case .point(let coordinates) = geometry {
        let point3D = transform.toPoint3D(coordinates)
        
        // Origin point should be near (0, 0, 0) with Y = altitude
        #expect(abs(point3D.x) < 0.001)
        #expect(abs(point3D.z) < 0.001)
        #expect(point3D.y == 50.0)
    }
}
