#if canImport(RealityKit)
import RealityKit
import simd

/// Component to store GeoJSON geometry data in a ModelEntity
@available(iOS 13.0, macOS 10.15, *)
public struct GeoJSONComponent: Component {
    /// The original geometry
    public let geometry: Geometry
    
    /// The coordinate transformation used
    public var transform: CoordinateTransform
    
    /// The material applied to the entity
    public var material: Material?
    
    public init(geometry: Geometry, transform: CoordinateTransform, material: Material? = nil) {
        self.geometry = geometry
        self.transform = transform
        self.material = material
    }
}

/// Extended ModelEntity with GeoJSON geometry information and update capabilities
@available(iOS 13.0, macOS 10.15, *)
public class GeoJSONModelEntity: ModelEntity {
    
    /// The GeoJSON component storing geometry data
    public var geoJSONComponent: GeoJSONComponent? {
        get { components[GeoJSONComponent.self] }
        set { components[GeoJSONComponent.self] = newValue }
    }
    
    /// The original geometry
    public var geometry: Geometry? {
        return geoJSONComponent?.geometry
    }
    
    /// The coordinate transformation configuration
    public var coordinateTransform: CoordinateTransform? {
        get { geoJSONComponent?.transform }
        set {
            if let newValue = newValue, var component = geoJSONComponent {
                component.transform = newValue
                geoJSONComponent = component
            }
        }
    }
    
    /// The material applied to this entity
    public var appliedMaterial: Material? {
        get { geoJSONComponent?.material }
        set {
            if var component = geoJSONComponent {
                component.material = newValue
                geoJSONComponent = component
            }
        }
    }
    
    /// Update the entity's coordinate transformation and regenerate the visual representation
    /// - Parameter transform: New coordinate transformation
    public func updateTransform(_ transform: CoordinateTransform) {
        guard let geometry = geometry else { return }
        
        // Update the component
        coordinateTransform = transform
        
        // Regenerate the entity
        regenerate()
    }
    
    /// Update the entity's material and reapply it to the visual representation
    /// - Parameter material: New material to apply
    public func updateMaterial(_ material: Material?) {
        guard geometry != nil else { return }
        
        // Update the component
        appliedMaterial = material
        
        // Reapply material
        applyMaterial(material)
    }
    
    /// Update both transform and material, then regenerate
    /// - Parameters:
    ///   - transform: New coordinate transformation
    ///   - material: New material to apply
    public func update(transform: CoordinateTransform? = nil, material: Material? = nil) {
        guard geometry != nil else { return }
        
        let needsRegenerate = transform != nil
        
        if let transform = transform {
            coordinateTransform = transform
        }
        
        if let material = material {
            appliedMaterial = material
        }
        
        // Optimize: only regenerate if transform changed
        if needsRegenerate {
            regenerate()
        } else if material != nil {
            // If only material changed, just reapply it
            applyMaterial(material)
        }
    }
    
    /// Regenerate the visual representation based on current parameters
    /// Note: This is a full regeneration which recreates all meshes.
    /// This approach is simpler and more reliable than differential updates,
    /// though less efficient for frequent updates.
    private func regenerate() {
        guard let component = geoJSONComponent else { return }
        
        // Remove all children
        children.removeAll()
        
        // Recreate based on geometry type
        let newEntity = component.geometry.toModelEntity(
            transform: component.transform,
            material: component.material
        )
        
        if let newEntity = newEntity {
            // Copy children and properties from newly created entity
            for child in newEntity.children {
                addChild(child)
            }
            
            // Copy mesh and materials if this is a simple entity
            if let modelEntity = newEntity as? ModelEntity {
                self.model = modelEntity.model
            }
        }
    }
    
    /// Apply material to this entity and all children
    /// - Parameter material: Material to apply
    private func applyMaterial(_ material: Material?) {
        guard let material = material else { return }
        
        // Apply to self if has model
        if self.model != nil {
            self.model?.materials = [material]
        }
        
        // Apply to all children recursively
        for child in children {
            if let modelChild = child as? ModelEntity {
                modelChild.model?.materials = [material]
            }
            if let geoChild = child as? GeoJSONModelEntity {
                geoChild.applyMaterial(material)
            }
        }
    }
}

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
    
    /// Convert geometry to GeoJSONModelEntity with parameter tracking and update capabilities
    /// - Parameters:
    ///   - transform: Coordinate transformation configuration
    ///   - material: Optional material to apply to the entity
    /// - Returns: GeoJSONModelEntity with geometry data and update methods
    public func toGeoJSONModelEntity(
        transform: CoordinateTransform = CoordinateTransform(),
        material: Material? = nil
    ) -> GeoJSONModelEntity? {
        guard let baseEntity = toModelEntity(transform: transform, material: material) else {
            return nil
        }
        
        let geoEntity = GeoJSONModelEntity()
        
        // Store the geometry data as a component
        geoEntity.geoJSONComponent = GeoJSONComponent(
            geometry: self,
            transform: transform,
            material: material
        )
        
        // Copy the visual representation
        for child in baseEntity.children {
            geoEntity.addChild(child)
        }
        
        // Copy model if it exists
        if let modelEntity = baseEntity as? ModelEntity {
            geoEntity.model = modelEntity.model
            geoEntity.position = modelEntity.position
            geoEntity.orientation = modelEntity.orientation
            geoEntity.scale = modelEntity.scale
        }
        
        return geoEntity
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
    
    /// Convert feature to GeoJSONModelEntity with parameter tracking and update capabilities
    /// - Parameters:
    ///   - transform: Coordinate transformation configuration
    ///   - material: Optional material to apply to the entity
    /// - Returns: GeoJSONModelEntity with geometry data and update methods, or nil if no geometry
    func toGeoJSONModelEntity(
        transform: CoordinateTransform = CoordinateTransform(),
        material: Material? = nil
    ) -> GeoJSONModelEntity? {
        return geometry?.toGeoJSONModelEntity(transform: transform, material: material)
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
    
    /// Convert feature collection to container with GeoJSONModelEntity children
    /// - Parameters:
    ///   - transform: Coordinate transformation configuration
    ///   - material: Optional material to apply to all entities
    /// - Returns: ModelEntity containing all features as GeoJSONModelEntity children with update capabilities
    func toGeoJSONModelEntity(
        transform: CoordinateTransform = CoordinateTransform(),
        material: Material? = nil
    ) -> ModelEntity {
        let containerEntity = ModelEntity()
        
        for feature in features {
            if let entity = feature.toGeoJSONModelEntity(transform: transform, material: material) {
                containerEntity.addChild(entity)
            }
        }
        
        return containerEntity
    }
}

#endif
