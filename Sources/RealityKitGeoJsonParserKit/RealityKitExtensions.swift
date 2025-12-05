#if canImport(RealityKit)
import RealityKit
import simd

/// Extensions for converting GeoJSON geometries to RealityKit entities
@available(iOS 13.0, macOS 10.15, *)
public extension Geometry {
    
    /// Convert geometry to RealityKit ModelEntity
    /// - Parameters:
    ///   - transform: Coordinate transformation configuration
    ///   - material: Optional material to apply to the entity
    /// - Returns: ModelEntity representing the geometry, or nil if conversion is not supported
    func toModelEntity(
        transform: CoordinateTransform = CoordinateTransform(),
        material: Material? = nil
    ) -> ModelEntity? {
        switch self {
        case .point(let coordinates):
            return createPointEntity(coordinates: coordinates, transform: transform, material: material)
            
        case .lineString(let coordinates):
            return createLineStringEntity(coordinates: coordinates, transform: transform, material: material)
            
        case .polygon(let coordinates):
            return createPolygonEntity(coordinates: coordinates, transform: transform, material: material)
            
        case .multiPoint(let coordinates):
            return createMultiPointEntity(coordinates: coordinates, transform: transform, material: material)
            
        case .multiLineString(let coordinates):
            return createMultiLineStringEntity(coordinates: coordinates, transform: transform, material: material)
            
        case .multiPolygon(let coordinates):
            return createMultiPolygonEntity(coordinates: coordinates, transform: transform, material: material)
            
        case .geometryCollection(let geometries):
            return createGeometryCollectionEntity(geometries: geometries, transform: transform, material: material)
        }
    }
    
    // MARK: - Private Entity Creation Methods
    
    private func createPointEntity(
        coordinates: Position,
        transform: CoordinateTransform,
        material: Material?
    ) -> ModelEntity? {
        let position = transform.toPoint3D(coordinates)
        
        let mesh = MeshResource.generateSphere(radius: 0.05)
        let usedMaterial = material ?? SimpleMaterial(color: .red, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [usedMaterial])
        entity.position = position
        
        return entity
    }
    
    private func createLineStringEntity(
        coordinates: [Position],
        transform: CoordinateTransform,
        material: Material?
    ) -> ModelEntity? {
        guard coordinates.count >= 2 else { return nil }
        
        let points = transform.toPoints3D(coordinates)
        
        // Create line segments as thin boxes between consecutive points
        let containerEntity = ModelEntity()
        
        for i in 0..<(points.count - 1) {
            let start = points[i]
            let end = points[i + 1]
            
            let length = distance(start, end)
            let direction = normalize(end - start)
            let midpoint = (start + end) * 0.5
            
            let mesh = MeshResource.generateBox(width: 0.02, height: 0.02, depth: length)
            let usedMaterial = material ?? SimpleMaterial(color: .blue, isMetallic: false)
            let segment = ModelEntity(mesh: mesh, materials: [usedMaterial])
            
            segment.position = midpoint
            
            // Calculate rotation to align with direction
            let up = SIMD3<Float>(0, 0, 1)
            let angle = acos(dot(up, direction))
            let axis = cross(up, direction)
            if length(axis) > 0.001 {
                segment.orientation = simd_quatf(angle: angle, axis: normalize(axis))
            }
            
            containerEntity.addChild(segment)
        }
        
        return containerEntity
    }
    
    private func createPolygonEntity(
        coordinates: [[Position]],
        transform: CoordinateTransform,
        material: Material?
    ) -> ModelEntity? {
        guard let exteriorRing = coordinates.first, exteriorRing.count >= 3 else { return nil }
        
        let points = transform.toPoints3D(exteriorRing)
        
        // Create a simple flat polygon using triangulation
        // For simplicity, we'll create a plane at the average height
        let avgHeight = points.reduce(0.0) { $0 + $1.y } / Float(points.count)
        
        // Create a simple mesh for the polygon
        // Note: This is a simplified approach; complex polygons may need better triangulation
        var vertices: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        
        // Simple fan triangulation from first point
        let basePoint = points[0]
        for i in 1..<(points.count - 2) {
            vertices.append(basePoint)
            vertices.append(points[i])
            vertices.append(points[i + 1])
            
            let baseIndex = UInt32((i - 1) * 3)
            indices.append(baseIndex)
            indices.append(baseIndex + 1)
            indices.append(baseIndex + 2)
        }
        
        var descriptor = MeshDescriptor(name: "polygon")
        descriptor.positions = MeshBuffer(vertices)
        descriptor.primitives = .triangles(indices)
        
        guard let mesh = try? MeshResource.generate(from: [descriptor]) else { return nil }
        
        let usedMaterial = material ?? SimpleMaterial(color: .green, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [usedMaterial])
        
        return entity
    }
    
    private func createMultiPointEntity(
        coordinates: [Position],
        transform: CoordinateTransform,
        material: Material?
    ) -> ModelEntity? {
        let containerEntity = ModelEntity()
        
        for coordinate in coordinates {
            if let pointEntity = createPointEntity(coordinates: coordinate, transform: transform, material: material) {
                containerEntity.addChild(pointEntity)
            }
        }
        
        return containerEntity
    }
    
    private func createMultiLineStringEntity(
        coordinates: [[Position]],
        transform: CoordinateTransform,
        material: Material?
    ) -> ModelEntity? {
        let containerEntity = ModelEntity()
        
        for lineCoordinates in coordinates {
            if let lineEntity = createLineStringEntity(coordinates: lineCoordinates, transform: transform, material: material) {
                containerEntity.addChild(lineEntity)
            }
        }
        
        return containerEntity
    }
    
    private func createMultiPolygonEntity(
        coordinates: [[[Position]]],
        transform: CoordinateTransform,
        material: Material?
    ) -> ModelEntity? {
        let containerEntity = ModelEntity()
        
        for polygonCoordinates in coordinates {
            if let polygonEntity = createPolygonEntity(coordinates: polygonCoordinates, transform: transform, material: material) {
                containerEntity.addChild(polygonEntity)
            }
        }
        
        return containerEntity
    }
    
    private func createGeometryCollectionEntity(
        geometries: [Geometry],
        transform: CoordinateTransform,
        material: Material?
    ) -> ModelEntity? {
        let containerEntity = ModelEntity()
        
        for geometry in geometries {
            if let entity = geometry.toModelEntity(transform: transform, material: material) {
                containerEntity.addChild(entity)
            }
        }
        
        return containerEntity
    }
}

@available(iOS 13.0, macOS 10.15, *)
public extension Feature {
    
    /// Convert feature to RealityKit ModelEntity
    /// - Parameters:
    ///   - transform: Coordinate transformation configuration
    ///   - material: Optional material to apply to the entity
    /// - Returns: ModelEntity representing the feature, or nil if no geometry
    func toModelEntity(
        transform: CoordinateTransform = CoordinateTransform(),
        material: Material? = nil
    ) -> ModelEntity? {
        return geometry?.toModelEntity(transform: transform, material: material)
    }
}

@available(iOS 13.0, macOS 10.15, *)
public extension FeatureCollection {
    
    /// Convert feature collection to RealityKit ModelEntity
    /// - Parameters:
    ///   - transform: Coordinate transformation configuration
    ///   - material: Optional material to apply to all entities
    /// - Returns: ModelEntity containing all features as children
    func toModelEntity(
        transform: CoordinateTransform = CoordinateTransform(),
        material: Material? = nil
    ) -> ModelEntity {
        let containerEntity = ModelEntity()
        
        for feature in features {
            if let entity = feature.toModelEntity(transform: transform, material: material) {
                containerEntity.addChild(entity)
            }
        }
        
        return containerEntity
    }
}

#endif
