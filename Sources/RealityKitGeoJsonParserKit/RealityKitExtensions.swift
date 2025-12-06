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

/// Wrapper for ModelEntity with GeoJSON geometry information and update capabilities
/// Uses composition instead of inheritance since ModelEntity is not open for subclassing
@available(iOS 13.0, macOS 10.15, *)
public class GeoJSONModelEntity {
    
    /// The underlying ModelEntity
    public let entity: ModelEntity
    
    /// The GeoJSON component storing geometry data
    private var geoJSONComponent: GeoJSONComponent? {
        get { entity.components[GeoJSONComponent.self] }
        set { entity.components[GeoJSONComponent.self] = newValue }
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
    
    /// Initialize with a ModelEntity
    /// - Parameter entity: The ModelEntity to wrap
    public init(entity: ModelEntity) {
        self.entity = entity
    }
    
    /// Update the entity's coordinate transformation and regenerate the visual representation
    /// - Parameter transform: New coordinate transformation
    @MainActor
    public func updateTransform(_ transform: CoordinateTransform) {
        guard let geometry = geometry else { return }
        
        // Update the component
        coordinateTransform = transform
        
        // Regenerate the entity
        regenerate()
    }
    
    /// Update the entity's material and reapply it to the visual representation
    /// - Parameter material: New material to apply
    @MainActor
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
    @MainActor
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
    @MainActor
    private func regenerate() {
        guard let component = geoJSONComponent else { return }
        
        // Remove all children
        entity.children.removeAll()
        
        // Recreate based on geometry type
        let newEntity = component.geometry.toModelEntity(
            transform: component.transform,
            material: component.material
        )
        
        if let newEntity = newEntity {
            // Copy children and properties from newly created entity
            for child in newEntity.children {
                entity.addChild(child)
            }
            
            // Copy mesh and materials if this is a simple entity
            if let modelEntity = newEntity as? ModelEntity {
                entity.model = modelEntity.model
            }
        }
    }
    
    /// Apply material to this entity and all children
    /// - Parameter material: Material to apply
    @MainActor
    private func applyMaterial(_ material: Material?) {
        guard let material = material else { return }
        
        // Apply to self if has model
        if entity.model != nil {
            entity.model?.materials = [material]
        }
        
        // Apply to all children recursively
        for child in entity.children {
            if let modelChild = child as? ModelEntity {
                modelChild.model?.materials = [material]
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
    @MainActor
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
    @MainActor
    public func toGeoJSONModelEntity(
        transform: CoordinateTransform = CoordinateTransform(),
        material: Material? = nil
    ) -> GeoJSONModelEntity? {
        guard let baseEntity = toModelEntity(transform: transform, material: material) else {
            return nil
        }
        
        // Create wrapper with the base entity
        let geoEntity = GeoJSONModelEntity(entity: baseEntity)
        
        // Store the geometry data as a component
        baseEntity.components[GeoJSONComponent.self] = GeoJSONComponent(
            geometry: self,
            transform: transform,
            material: material
        )
        
        return geoEntity
    }
    
    /// Convert geometry to GeoJSONModelEntity using user's current WGS coordinates as origin
    /// - Parameters:
    ///   - userLatitude: User's current latitude in WGS84 (degrees)
    ///   - userLongitude: User's current longitude in WGS84 (degrees)
    ///   - scale: Scale factor for visualization (default: 1.0)
    ///   - material: Optional material to apply to the entity
    /// - Returns: GeoJSONModelEntity with coordinate transformation centered on user's location
    @MainActor
    public func toGeoJSONModelEntity(
        userLatitude: Double,
        userLongitude: Double,
        scale: Float = 1.0,
        material: Material? = nil
    ) -> GeoJSONModelEntity? {
        let config = CoordinateTransform.Configuration(
            origin: (longitude: userLongitude, latitude: userLatitude),
            scale: scale
        )
        let transform = CoordinateTransform(config: config)
        return toGeoJSONModelEntity(transform: transform, material: material)
    }
    
    // MARK: - Private Entity Creation Methods
    
    @MainActor
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
    
    @MainActor
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
            
            let segmentLength = distance(start, end)
            let direction = normalize(end - start)
            let midpoint = (start + end) * 0.5
            
            let mesh = MeshResource.generateBox(width: 0.02, height: 0.02, depth: segmentLength)
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    @MainActor
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
    @MainActor
    func toGeoJSONModelEntity(
        transform: CoordinateTransform = CoordinateTransform(),
        material: Material? = nil
    ) -> GeoJSONModelEntity? {
        return geometry?.toGeoJSONModelEntity(transform: transform, material: material)
    }
    
    /// Convert feature to GeoJSONModelEntity using user's current WGS coordinates as origin
    /// - Parameters:
    ///   - userLatitude: User's current latitude in WGS84 (degrees)
    ///   - userLongitude: User's current longitude in WGS84 (degrees)
    ///   - scale: Scale factor for visualization (default: 1.0)
    ///   - material: Optional material to apply to the entity
    /// - Returns: GeoJSONModelEntity with coordinate transformation centered on user's location, or nil if no geometry
    @MainActor
    func toGeoJSONModelEntity(
        userLatitude: Double,
        userLongitude: Double,
        scale: Float = 1.0,
        material: Material? = nil
    ) -> GeoJSONModelEntity? {
        return geometry?.toGeoJSONModelEntity(
            userLatitude: userLatitude,
            userLongitude: userLongitude,
            scale: scale,
            material: material
        )
    }
}

@available(iOS 13.0, macOS 10.15, *)
public extension FeatureCollection {
    
    /// Convert feature collection to RealityKit ModelEntity
    /// - Parameters:
    ///   - transform: Coordinate transformation configuration
    ///   - material: Optional material to apply to all entities
    /// - Returns: ModelEntity containing all features as children
    @MainActor
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
    @MainActor
    func toGeoJSONModelEntity(
        transform: CoordinateTransform = CoordinateTransform(),
        material: Material? = nil
    ) -> ModelEntity {
        let containerEntity = ModelEntity()
        
        for feature in features {
            if let geoEntity = feature.toGeoJSONModelEntity(transform: transform, material: material) {
                containerEntity.addChild(geoEntity.entity)
            }
        }
        
        return containerEntity
    }
    
    /// Convert feature collection to array of GeoJSONModelEntity wrappers
    /// - Parameters:
    ///   - transform: Coordinate transformation configuration
    ///   - material: Optional material to apply to all entities
    /// - Returns: Array of GeoJSONModelEntity wrappers for each feature
    @MainActor
    func toGeoJSONModelEntities(
        transform: CoordinateTransform = CoordinateTransform(),
        material: Material? = nil
    ) -> [GeoJSONModelEntity] {
        return features.compactMap { feature in
            feature.toGeoJSONModelEntity(transform: transform, material: material)
        }
    }
    
    /// Convert feature collection to array of GeoJSONModelEntity wrappers using user's current WGS coordinates
    /// - Parameters:
    ///   - userLatitude: User's current latitude in WGS84 (degrees)
    ///   - userLongitude: User's current longitude in WGS84 (degrees)
    ///   - scale: Scale factor for visualization (default: 1.0)
    ///   - material: Optional material to apply to all entities
    /// - Returns: Array of GeoJSONModelEntity wrappers centered on user's location
    @MainActor
    func toGeoJSONModelEntities(
        userLatitude: Double,
        userLongitude: Double,
        scale: Float = 1.0,
        material: Material? = nil
    ) -> [GeoJSONModelEntity] {
        return features.compactMap { feature in
            feature.toGeoJSONModelEntity(
                userLatitude: userLatitude,
                userLongitude: userLongitude,
                scale: scale,
                material: material
            )
        }
    }
}

#endif
