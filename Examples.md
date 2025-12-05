# RealityKitGeoJsonParserKit - Usage Examples

このファイルは、RealityKitGeoJsonParserKitの使用例を紹介します。

This file provides usage examples for RealityKitGeoJsonParserKit.

## Example 1: Parse GeoJSON and Display Points

```swift
import RealityKitGeoJsonParserKit
#if canImport(RealityKit)
import RealityKit
#endif

// Tokyo landmarks GeoJSON
let tokyoLandmarks = """
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [139.7454, 35.6586]
      },
      "properties": {
        "name": "Tokyo Tower",
        "name_ja": "東京タワー",
        "height": 333
      }
    },
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [139.8107, 35.7101]
      },
      "properties": {
        "name": "Tokyo Skytree",
        "name_ja": "東京スカイツリー",
        "height": 634
      }
    },
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [139.6917, 35.6895]
      },
      "properties": {
        "name": "Shinjuku Station",
        "name_ja": "新宿駅"
      }
    }
  ]
}
"""

// Parse GeoJSON
do {
    let featureCollection = try GeoJSONParser.parse(jsonString: tokyoLandmarks)
    
    print("Parsed \(featureCollection.features.count) landmarks")
    
    for feature in featureCollection.features {
        if let properties = feature.properties,
           let nameValue = properties["name"]?.value as? String {
            print("- \(nameValue)")
        }
    }
    
    #if canImport(RealityKit)
    // Convert to RealityKit entities
    let transform = CoordinateTransform(
        config: .init(
            origin: (139.7454, 35.6586),  // Center on Tokyo Tower
            scale: 1000.0  // Scale for visibility
        )
    )
    
    let landmarksEntity = featureCollection.toModelEntity(transform: transform)
    // Add to your AR scene
    #endif
    
} catch {
    print("Error: \(error)")
}
```

## Example 2: Route Visualization with LineString

```swift
import RealityKitGeoJsonParserKit
#if canImport(RealityKit)
import RealityKit
#endif

// Route from Tokyo Station to Tokyo Tower
let route = """
{
  "type": "Feature",
  "geometry": {
    "type": "LineString",
    "coordinates": [
      [139.7673, 35.6812],
      [139.7644, 35.6751],
      [139.7513, 35.6661],
      [139.7454, 35.6586]
    ]
  },
  "properties": {
    "name": "Route to Tokyo Tower",
    "distance_km": 3.2
  }
}
"""

do {
    let feature = try GeoJSONParser.parseFeature(jsonString: route)
    
    #if canImport(RealityKit)
    let transform = CoordinateTransform(
        config: .init(
            origin: (139.7673, 35.6812),
            scale: 500.0
        )
    )
    
    // Create line with custom material
    let blueMaterial = SimpleMaterial(color: .blue, isMetallic: false)
    let routeEntity = feature.toModelEntity(
        transform: transform,
        material: blueMaterial
    )
    #endif
    
} catch {
    print("Error: \(error)")
}
```

## Example 3: Area Visualization with Polygon

```swift
import RealityKitGeoJsonParserKit
#if canImport(RealityKit)
import RealityKit
#endif

// Shibuya Crossing area
let shibuyaArea = """
{
  "type": "Feature",
  "geometry": {
    "type": "Polygon",
    "coordinates": [
      [
        [139.6997, 35.6595],
        [139.7013, 35.6595],
        [139.7013, 35.6608],
        [139.6997, 35.6608],
        [139.6997, 35.6595]
      ]
    ]
  },
  "properties": {
    "name": "Shibuya Crossing",
    "name_ja": "渋谷スクランブル交差点",
    "area_type": "pedestrian"
  }
}
"""

do {
    let feature = try GeoJSONParser.parseFeature(jsonString: shibuyaArea)
    
    #if canImport(RealityKit)
    let transform = CoordinateTransform(
        config: .init(
            origin: (139.6997, 35.6595),
            scale: 10000.0
        )
    )
    
    // Create polygon with semi-transparent material
    var material = SimpleMaterial()
    material.color = .init(tint: .green.withAlphaComponent(0.5))
    
    let areaEntity = feature.toModelEntity(
        transform: transform,
        material: material
    )
    #endif
    
} catch {
    print("Error: \(error)")
}
```

## Example 4: Coordinate Transformation

```swift
import RealityKitGeoJsonParserKit

// Different scale configurations for different use cases
let configurations = [
    CoordinateTransform.Configuration(
        origin: (139.6917, 35.6895),
        scale: 1.0  // 1:1 scale (meters)
    ),
    CoordinateTransform.Configuration(
        origin: (139.6917, 35.6895),
        scale: 100.0  // 100:1 scale
    ),
    CoordinateTransform.Configuration(
        origin: (139.6917, 35.6895),
        scale: 0.01,  // Miniature scale
        invertY: true  // Invert Y axis
    )
]

let position: Position = [139.7671, 35.6812, 50.0]

for (index, config) in configurations.enumerated() {
    let transform = CoordinateTransform(config: config)
    let point = transform.toPoint3D(position)
    print("Config \(index + 1): x=\(point.x), y=\(point.y), z=\(point.z)")
}
```

## Example 5: Working with Properties

```swift
import RealityKitGeoJsonParserKit

let dataWithProperties = """
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
        "name": "Tokyo Station",
        "type": "railway_station",
        "lines": ["Yamanote", "Chuo", "Keihin-Tohoku"],
        "opened": 1914,
        "is_major": true
      }
    }
  ]
}
"""

do {
    let collection = try GeoJSONParser.parse(jsonString: dataWithProperties)
    
    if let feature = collection.features.first,
       let properties = feature.properties {
        
        // Access string property
        if let name = properties["name"]?.value as? String {
            print("Name: \(name)")
        }
        
        // Access integer property
        if let opened = properties["opened"]?.value as? Int {
            print("Opened: \(opened)")
        }
        
        // Access boolean property
        if let isMajor = properties["is_major"]?.value as? Bool {
            print("Is major station: \(isMajor)")
        }
        
        // Access array property
        if let lines = properties["lines"]?.value as? [Any] {
            print("Lines: \(lines)")
        }
    }
} catch {
    print("Error: \(error)")
}
```

## Example 6: Load from File

```swift
import RealityKitGeoJsonParserKit
import Foundation

// Load GeoJSON from a file
func loadGeoJSON(filename: String) {
    guard let fileURL = Bundle.main.url(forResource: filename, withExtension: "geojson") else {
        print("File not found")
        return
    }
    
    do {
        let featureCollection = try GeoJSONParser.parse(from: fileURL)
        print("Loaded \(featureCollection.features.count) features")
        
        // Process features...
        for feature in featureCollection.features {
            if let geometry = feature.geometry {
                print("Geometry type: \(geometry.type)")
            }
        }
    } catch {
        print("Error loading GeoJSON: \(error)")
    }
}

// Usage
loadGeoJSON(filename: "tokyo_landmarks")
```

## Example 7: Complete AR Scene Setup

```swift
#if canImport(RealityKit) && canImport(ARKit)
import RealityKit
import ARKit
import RealityKitGeoJsonParserKit
import SwiftUI

struct GeoJSONARView: View {
    var body: some View {
        ARViewContainer()
            .edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Setup AR session
        let config = ARWorldTrackingConfiguration()
        arView.session.run(config)
        
        // Load and display GeoJSON
        loadGeoJSONData(into: arView)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func loadGeoJSONData(into arView: ARView) {
        let geoJSON = """
        {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {
                "type": "Point",
                "coordinates": [139.7671, 35.6812]
              }
            }
          ]
        }
        """
        
        do {
            let collection = try GeoJSONParser.parse(jsonString: geoJSON)
            
            let transform = CoordinateTransform(
                config: .init(
                    origin: (139.7671, 35.6812),
                    scale: 100.0
                )
            )
            
            let entity = collection.toModelEntity(transform: transform)
            
            // Create anchor and add to scene
            let anchor = AnchorEntity(world: [0, -1, -2])
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
            
        } catch {
            print("Error: \(error)")
        }
    }
}
#endif
```

## Example 8: Calculate Bounding Box

```swift
import RealityKitGeoJsonParserKit

let positions: [Position] = [
    [139.7671, 35.6812],
    [139.7681, 35.6822],
    [139.7691, 35.6832]
]

let transform = CoordinateTransform()

// Calculate bounding box
if let bbox = transform.boundingBox(for: positions) {
    print("Bounding box:")
    print("  Min: x=\(bbox.min.x), y=\(bbox.min.y), z=\(bbox.min.z)")
    print("  Max: x=\(bbox.max.x), y=\(bbox.max.y), z=\(bbox.max.z)")
    
    // Calculate dimensions
    let width = bbox.max.x - bbox.min.x
    let height = bbox.max.y - bbox.min.y
    let depth = bbox.max.z - bbox.min.z
    print("  Size: \(width) x \(height) x \(depth)")
}

// Calculate center point
if let center = transform.centerPoint(for: positions) {
    print("Center: x=\(center.x), y=\(center.y), z=\(center.z)")
}
```

## Tips and Best Practices

### 1. Choose Appropriate Scale

```swift
// For city-scale visualization (kilometers)
let cityScale = CoordinateTransform.Configuration(
    origin: (139.6917, 35.6895),
    scale: 0.1  // Compress large areas
)

// For building-scale visualization (meters)
let buildingScale = CoordinateTransform.Configuration(
    origin: (139.6917, 35.6895),
    scale: 1.0  // 1:1 scale
)

// For room-scale AR (closer viewing)
let roomScale = CoordinateTransform.Configuration(
    origin: (139.6917, 35.6895),
    scale: 100.0  // Magnify for better visibility
)
```

### 2. Handle Errors Gracefully

```swift
func safeParseGeoJSON(_ jsonString: String) -> FeatureCollection? {
    do {
        return try GeoJSONParser.parse(jsonString: jsonString)
    } catch let error as DecodingError {
        print("Decoding error: \(error)")
        return nil
    } catch GeoJSONError.invalidData {
        print("Invalid GeoJSON data")
        return nil
    } catch {
        print("Unknown error: \(error)")
        return nil
    }
}
```

### 3. Optimize Performance

```swift
// For large datasets, consider processing in batches
func processLargeGeoJSON(_ collection: FeatureCollection, batchSize: Int = 100) {
    let features = collection.features
    
    for i in stride(from: 0, to: features.count, by: batchSize) {
        let end = min(i + batchSize, features.count)
        let batch = Array(features[i..<end])
        
        // Process batch
        processBatch(batch)
    }
}

func processBatch(_ features: [Feature]) {
    // Process features in this batch
}
```

### 4. Dynamic Updates with GeoJSONModelEntity

```swift
#if canImport(RealityKit)
import RealityKit
import RealityKitGeoJsonParserKit

// Create an entity with parameter tracking
let geometry = try GeoJSONParser.parseGeometry(jsonString: """
{
  "type": "Point",
  "coordinates": [139.7671, 35.6812, 100.0]
}
""")

let initialTransform = CoordinateTransform(
    config: .init(origin: (139.7671, 35.6812), scale: 50.0)
)

guard let geoEntity = geometry.toGeoJSONModelEntity(
    transform: initialTransform,
    material: SimpleMaterial(color: .red, isMetallic: false)
) else {
    fatalError("Failed to create entity")
}

// Add to scene
let anchor = AnchorEntity(world: .zero)
anchor.addChild(geoEntity)
arView.scene.addAnchor(anchor)

// Later, update the scale dynamically (e.g., on user interaction)
func onScaleChanged(_ newScale: Float) {
    let newTransform = CoordinateTransform(
        config: .init(origin: (139.7671, 35.6812), scale: newScale)
    )
    geoEntity.updateTransform(newTransform)
}

// Update color based on some condition
func onColorChanged(_ color: UIColor) {
    let newMaterial = SimpleMaterial(color: color, isMetallic: false)
    geoEntity.updateMaterial(newMaterial)
}

// Animate changes over time
func animateEntity() {
    var scale: Float = 50.0
    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
        scale += 5.0
        if scale > 200.0 {
            timer.invalidate()
            return
        }
        
        let transform = CoordinateTransform(
            config: .init(origin: (139.7671, 35.6812), scale: scale)
        )
        geoEntity.updateTransform(transform)
    }
}
#endif
```

### 5. Batch Update Multiple Entities

```swift
#if canImport(RealityKit)
import RealityKit
import RealityKitGeoJsonParserKit

// Create multiple entities with tracking
let collection = try GeoJSONParser.parse(jsonString: featureCollectionJSON)

let initialTransform = CoordinateTransform(
    config: .init(origin: (139.7671, 35.6812), scale: 100.0)
)

let containerEntity = collection.toGeoJSONModelEntity(transform: initialTransform)
arView.scene.addAnchor(AnchorEntity(world: .zero).addChild(containerEntity))

// Update all children at once
func updateAllEntities(newScale: Float, color: UIColor) {
    let newTransform = CoordinateTransform(
        config: .init(origin: (139.7671, 35.6812), scale: newScale)
    )
    let newMaterial = SimpleMaterial(color: color, isMetallic: false)
    
    for child in containerEntity.children {
        if let geoChild = child as? GeoJSONModelEntity {
            geoChild.update(transform: newTransform, material: newMaterial)
        }
    }
}

// Update only specific entities based on properties
func updateByProperty(propertyName: String, propertyValue: Any) {
    for (index, feature) in collection.features.enumerated() {
        guard let properties = feature.properties,
              let value = properties[propertyName]?.value,
              "\(value)" == "\(propertyValue)" else {
            continue
        }
        
        if index < containerEntity.children.count,
           let geoChild = containerEntity.children[index] as? GeoJSONModelEntity {
            let highlightMaterial = SimpleMaterial(color: .yellow, isMetallic: false)
            geoChild.updateMaterial(highlightMaterial)
        }
    }
}
#endif
```
