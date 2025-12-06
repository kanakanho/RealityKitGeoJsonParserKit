# RealityKitGeoJsonParserKit

RealityKit用のGeoJSON形式のデータを扱うためのSwiftライブラリです。

A Swift library for handling GeoJSON format data with RealityKit.

## 特徴 (Features)

- ✅ GeoJSON形式のデータのパース (Parse GeoJSON format data)
- ✅ 全てのGeoJSONジオメトリタイプに対応 (Support all GeoJSON geometry types)
  - Point, LineString, Polygon
  - MultiPoint, MultiLineString, MultiPolygon
  - GeometryCollection
- ✅ Feature and FeatureCollectionのサポート
- ✅ 地理座標から3D座標への変換 (Geographic to 3D coordinate transformation)
- ✅ RealityKitエンティティへの変換 (Convert to RealityKit entities)
- ✅ パラメータ追跡と動的更新機能 (Parameter tracking and dynamic update capabilities)
  - ジオメトリパラメータの保存 (Store geometry parameters)
  - 座標変換の動的更新 (Dynamic transform updates)
  - マテリアルの動的変更 (Dynamic material changes)

## インストール (Installation)

### Swift Package Manager

`Package.swift`ファイルの`dependencies`に以下を追加してください：

```swift
dependencies: [
    .package(url: "https://github.com/kanakanho/RealityKitGeoJsonParserKit.git", from: "1.0.0")
]
```

そして、ターゲットの`dependencies`に追加：

```swift
.target(
    name: "YourTarget",
    dependencies: ["RealityKitGeoJsonParserKit"]
)
```

## 使い方 (Usage)

### 基本的なGeoJSONのパース (Basic GeoJSON Parsing)

```swift
import RealityKitGeoJsonParserKit

// JSONから解析
let geoJSON = """
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
        "name": "Tokyo Tower"
      }
    }
  ]
}
"""

do {
    let featureCollection = try GeoJSONParser.parse(jsonString: geoJSON)
    print("Features: \(featureCollection.features.count)")
} catch {
    print("Error parsing GeoJSON: \(error)")
}
```

### 座標変換 (Coordinate Transformation)

```swift
import RealityKitGeoJsonParserKit

// 座標変換の設定
let config = CoordinateTransform.Configuration(
    origin: (longitude: 139.7671, latitude: 35.6812),  // 原点となる座標
    metersPerDegree: 111320.0,  // 度からメートルへの変換係数
    scale: 100.0,  // 表示スケール
    invertY: false  // Y軸の反転
)

let transform = CoordinateTransform(config: config)

// 地理座標を3D空間の座標に変換
let position: Position = [139.7671, 35.6812, 50.0]  // [経度, 緯度, 高度]
let point3D = transform.toPoint3D(position)

print("3D Position: x=\(point3D.x), y=\(point3D.y), z=\(point3D.z)")
```

### RealityKitエンティティへの変換 (Convert to RealityKit Entities)

```swift
#if canImport(RealityKit)
import RealityKit
import RealityKitGeoJsonParserKit

// GeoJSONをパース
let featureCollection = try GeoJSONParser.parse(jsonString: geoJSON)

// 座標変換の設定
let transform = CoordinateTransform(
    config: .init(
        origin: (139.7671, 35.6812),
        scale: 100.0
    )
)

// RealityKitのエンティティに変換
let entity = featureCollection.toModelEntity(transform: transform)

// カスタムマテリアルの適用も可能
let material = SimpleMaterial(color: .blue, isMetallic: false)
let entityWithMaterial = featureCollection.toModelEntity(
    transform: transform,
    material: material
)

// ARViewに追加
let anchorEntity = AnchorEntity(world: .zero)
anchorEntity.addChild(entity)
arView.scene.addAnchor(anchorEntity)
#endif
```

### パラメータ追跡と動的更新 (Parameter Tracking and Dynamic Updates)

GeoJSONModelEntityを使用すると、ジオメトリパラメータを保存し、後で動的に更新できます。

Using GeoJSONModelEntity, you can store geometry parameters and update them dynamically later.

```swift
#if canImport(RealityKit)
import RealityKit
import RealityKitGeoJsonParserKit

// GeoJSONをパース
let geometry = try GeoJSONParser.parseGeometry(jsonString: pointJSON)

// GeoJSONModelEntityとして作成（パラメータ追跡機能付き）
let transform = CoordinateTransform(
    config: .init(origin: (139.7671, 35.6812), scale: 100.0)
)
guard let geoEntity = geometry.toGeoJSONModelEntity(transform: transform) else {
    return
}

// 元のジオメトリにアクセス
if let originalGeometry = geoEntity.geometry {
    print("Geometry type: \(originalGeometry.type)")
}

// 基となるModelEntityにアクセス
let modelEntity = geoEntity.entity
arView.scene.addAnchor(AnchorEntity().addChild(modelEntity))

// 座標変換を動的に更新
let newTransform = CoordinateTransform(
    config: .init(origin: (139.7671, 35.6812), scale: 200.0)
)
geoEntity.updateTransform(newTransform)

// マテリアルを動的に変更
let newMaterial = SimpleMaterial(color: .green, isMetallic: false)
geoEntity.updateMaterial(newMaterial)

// 複数のパラメータを同時に更新
geoEntity.update(
    transform: newTransform,
    material: newMaterial
)

// FeatureCollectionから複数のGeoJSONModelEntityを取得
let geoEntities = featureCollection.toGeoJSONModelEntities(transform: transform)

// 各エンティティを個別に更新可能
for geoEntity in geoEntities {
    geoEntity.updateMaterial(SimpleMaterial(color: .blue, isMetallic: false))
    // ModelEntityをシーンに追加
    arView.scene.addAnchor(AnchorEntity().addChild(geoEntity.entity))
}
#endif
```

### ユーザーの現在位置を基準とした座標変換 (Coordinate Transform Based on User Location)

ユーザーの現在のWGS84座標（緯度・経度）を基準点として使用し、GeoJSONの座標を**基準点からの差分（オフセット）**として3D空間に配置できます。

You can use the user's current WGS84 coordinates (latitude and longitude) as a reference point, and place GeoJSON coordinates in 3D space as **offsets from the reference point**.

**仕組み (How it works):**
- ユーザーの位置を原点（0, 0, 0）とする
- GeoJSON内の各座標は、ユーザーの位置からの相対的な位置として計算される
- 例：ユーザーが東京駅にいて、100m東のポイントがある場合、そのポイントは(100, 0, 0)の位置に配置される

**Mechanism:**
- User's position becomes the origin (0, 0, 0)
- Each coordinate in GeoJSON is calculated as a relative position from the user's location
- Example: If the user is at Tokyo Station and there's a point 100m to the east, that point will be placed at position (100, 0, 0)

```swift
#if canImport(RealityKit)
import RealityKit
import CoreLocation
import RealityKitGeoJsonParserKit

// ユーザーの現在位置を取得（例：東京駅）
let userLatitude = 35.6812  // 東京の緯度
let userLongitude = 139.7671  // 東京の経度

// GeoJSONをパース（例：東京駅から100m東にあるポイント）
// 139.7671° + 0.001° ≈ 100m東
let pointJSON = """
{
  "type": "Point",
  "coordinates": [139.7681, 35.6812]
}
"""
let geometry = try GeoJSONParser.parseGeometry(jsonString: pointJSON)

// ユーザーの位置を基準点として、差分を計算して3D座標に変換
// この例では約100m東に配置される
guard let geoEntity = geometry.toGeoJSONModelEntity(
    userLatitude: userLatitude,
    userLongitude: userLongitude,
    scale: 100.0  // スケールファクター
) else {
    return
}

// ARシーンに追加
arView.scene.addAnchor(AnchorEntity().addChild(geoEntity.entity))

// FeatureCollectionでも使用可能
let geoEntities = featureCollection.toGeoJSONModelEntities(
    userLatitude: userLatitude,
    userLongitude: userLongitude,
    scale: 100.0
)

for geoEntity in geoEntities {
    arView.scene.addAnchor(AnchorEntity().addChild(geoEntity.entity))
}
#endif
```

### 各ジオメトリタイプの例 (Geometry Type Examples)

#### Point (点)

```swift
let pointJSON = """
{
  "type": "Point",
  "coordinates": [139.7671, 35.6812]
}
"""

let geometry = try GeoJSONParser.parseGeometry(jsonString: pointJSON)
// RealityKitでは小さな球体として表現されます
```

#### LineString (線)

```swift
let lineJSON = """
{
  "type": "LineString",
  "coordinates": [
    [139.7671, 35.6812],
    [139.7681, 35.6822],
    [139.7691, 35.6832]
  ]
}
"""

let geometry = try GeoJSONParser.parseGeometry(jsonString: lineJSON)
// RealityKitでは連続する線分として表現されます
```

#### Polygon (ポリゴン)

```swift
let polygonJSON = """
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

let geometry = try GeoJSONParser.parseGeometry(jsonString: polygonJSON)
// RealityKitでは3Dメッシュとして表現されます
```

## API リファレンス (API Reference)

### GeoJSONParser

GeoJSONデータをパースするための主要なクラスです。

- `parse(jsonString: String) throws -> FeatureCollection` - JSON文字列からFeatureCollectionをパース
- `parse(data: Data) throws -> FeatureCollection` - DataからFeatureCollectionをパース
- `parse(from url: URL) throws -> FeatureCollection` - ファイルURLからパース
- `parseFeature(jsonString: String) throws -> Feature` - 単一のFeatureをパース
- `parseGeometry(jsonString: String) throws -> Geometry` - 単一のジオメトリをパース

### CoordinateTransform

地理座標を3D空間の座標に変換するためのユーティリティです。

#### Configuration

- `origin: (longitude: Double, latitude: Double)` - 原点となる地理座標 (デフォルト: (0, 0))
- `metersPerDegree: Double` - 度からメートルへの変換係数 (デフォルト: 111,320m)
- `scale: Float` - 表示スケール係数 (デフォルト: 1.0)
- `invertY: Bool` - Y軸を反転するかどうか (デフォルト: false)

#### Methods

- `toPoint3D(_ position: Position) -> Point3D` - 単一の座標を3D点に変換
- `toPoints3D(_ positions: [Position]) -> [Point3D]` - 複数の座標を3D点に変換
- `boundingBox(for positions: [Position]) -> (min: Point3D, max: Point3D)?` - 境界ボックスを計算
- `centerPoint(for positions: [Position]) -> Point3D?` - 中心点を計算

### Geometry Extensions (RealityKit)

GeoJSONジオメトリをRealityKitのModelEntityに変換します。

- `toModelEntity(transform:material:) -> ModelEntity?` - ジオメトリをRealityKitエンティティに変換
- `toGeoJSONModelEntity(transform:material:) -> GeoJSONModelEntity?` - パラメータ追跡機能付きエンティティに変換

### GeoJSONModelEntity (RealityKit)

ジオメトリパラメータを保存し、動的更新が可能なModelEntityのサブクラス。

Subclass of ModelEntity that stores geometry parameters and allows dynamic updates.

#### Properties

- `entity: ModelEntity` - 基となるRealityKit ModelEntity (Underlying RealityKit ModelEntity)
- `geometry: Geometry?` - 元のGeoJSONジオメトリ (Original GeoJSON geometry)
- `coordinateTransform: CoordinateTransform?` - 現在の座標変換設定 (Current coordinate transformation)
- `appliedMaterial: Material?` - 適用されているマテリアル (Applied material)

#### Methods

- `updateTransform(_ transform: CoordinateTransform)` - 座標変換を更新して表示を再生成 (Update transform and regenerate display)
- `updateMaterial(_ material: Material?)` - マテリアルを更新して再適用 (Update and reapply material)
- `update(transform:material:)` - 複数のパラメータを同時に更新 (Update multiple parameters simultaneously)

#### Usage Example

```swift
// Create entity with parameter tracking
guard let geoEntity = geometry.toGeoJSONModelEntity(transform: transform) else {
    return
}

// Access stored parameters
print("Geometry type: \(geoEntity.geometry?.type)")

// Access underlying ModelEntity to add to scene
arView.scene.addAnchor(AnchorEntity().addChild(geoEntity.entity))

// Update transform dynamically
let newTransform = CoordinateTransform(config: .init(scale: 200.0))
geoEntity.updateTransform(newTransform)

// Update material dynamically
geoEntity.updateMaterial(SimpleMaterial(color: .blue, isMetallic: false))
```

## 座標系について (Coordinate System)

このライブラリでは以下の座標系を使用しています：

- **X軸**: 東西方向 (経度の差)
- **Y軸**: 高度
- **Z軸**: 南北方向 (緯度の差)

座標変換は近似的な平面投影を使用しており、小規模なエリア（数キロメートル程度）での使用に適しています。大規模なエリアでは、より正確な座標変換が必要になる場合があります。

## 注意事項 (Notes)

- RealityKitの機能はAppleプラットフォーム（iOS 13.0+, macOS 10.15+）でのみ利用可能です
- GeoJSONのパース機能はすべてのプラットフォームで利用可能です
- 座標変換は近似値を使用しており、高精度な測地計算には対応していません

## ライセンス (License)

MIT License

## 貢献 (Contributing)

プルリクエストやイシューの報告を歓迎します！

## 作者 (Author)

kanakanho
