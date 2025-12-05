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
